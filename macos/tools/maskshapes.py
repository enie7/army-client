"""Mask geometry for the GPU timeline player.

Shapes a timeline uses as masks draw as nothing when the runtime rasterises
them (Flash treats the instance as a clip layer), so their geometry is taken
from the SWF instead: the shape's edges, curves flattened, filled with a
scanline pass, as rectangles in art units (rows of runs, merged downwards).
"""
import struct

from timelines import Bits

STEP = 0.5          # scanline / column resolution, in art units (pixels)
CURVE_SEGMENTS = 8


def _rect_bits(data, pos):
    nbits = data[pos] >> 3
    return pos + (5 + 4 * nbits + 7) // 8


def _skip_matrix(r):
    if r.u(1):
        n = r.u(5); r.u(n); r.u(n)
    if r.u(1):
        n = r.u(5); r.u(n); r.u(n)
    n = r.u(5); r.u(n); r.u(n)


def _fill_len(data, pos, code):
    """Length of one FILLSTYLE record."""
    start = pos
    kind = data[pos]; pos += 1
    color = 4 if code in (32, 83) else 3
    if kind == 0x00:
        pos += color
    elif kind in (0x10, 0x12, 0x13):
        r = Bits(data, pos); _skip_matrix(r); pos = r.align()
        n = data[pos] & 0x0f; pos += 1 + n * (1 + color)
        if kind == 0x13:
            pos += 2
    elif 0x40 <= kind <= 0x43:
        pos += 2
        r = Bits(data, pos); _skip_matrix(r); pos = r.align()
    else:
        raise ValueError('fill style %#x' % kind)
    return pos - start


def _count(data, pos):
    count = data[pos]; pos += 1
    if count == 0xff:
        count = struct.unpack('<H', data[pos:pos + 2])[0]; pos += 2
    return count, pos


def _skip_styles(data, pos, code):
    """Skip a FILLSTYLEARRAY and a LINESTYLEARRAY; return the new position."""
    count, pos = _count(data, pos)
    for _ in range(count):
        pos += _fill_len(data, pos, code)
    count, pos = _count(data, pos)
    color = 4 if code in (32, 83) else 3
    for _ in range(count):
        pos += 2                                       # Width
        if code == 83:                                 # LINESTYLE2
            flags = struct.unpack('>H', data[pos:pos + 2])[0]; pos += 2
            join = (flags >> 12) & 3
            has_fill = (flags >> 11) & 1
            if join == 2:
                pos += 2                               # MiterLimitFactor
            pos += _fill_len(data, pos, code) if has_fill else 4
        else:
            pos += color
    return pos


def segments(data, off, code):
    """Line segments (x0, y0, x1, y1) in art units of the shape's filled edges."""
    pos = _rect_bits(data, off + 2)
    if code == 83:
        pos = _rect_bits(data, pos) + 1
    pos = _skip_styles(data, pos, code)
    r = Bits(data, pos)
    fill_bits = r.u(4); line_bits = r.u(4)
    x = y = 0
    fill0 = fill1 = 0
    out = []
    while True:
        if r.u(1) == 0:                                # non-edge record
            flags = r.u(5)
            if flags == 0:
                break
            if flags & 1:
                n = r.u(5); x = r.s(n); y = r.s(n)
            if flags & 2:
                fill0 = r.u(fill_bits)
            if flags & 4:
                fill1 = r.u(fill_bits)
            if flags & 8:
                r.u(line_bits)
            if flags & 16:                             # new styles
                pos = r.align()
                pos = _skip_styles(data, pos, code)
                r = Bits(data, pos)
                fill_bits = r.u(4); line_bits = r.u(4)
            continue
        filled = fill0 or fill1
        if r.u(1):                                     # straight
            n = r.u(4) + 2
            if r.u(1):
                dx = r.s(n); dy = r.s(n)
            elif r.u(1):
                dx = 0; dy = r.s(n)
            else:
                dx = r.s(n); dy = 0
            if filled:
                out.append((x / 20, y / 20, (x + dx) / 20, (y + dy) / 20))
            x += dx; y += dy
        else:                                          # quadratic curve
            n = r.u(4) + 2
            cx = x + r.s(n); cy = y + r.s(n)
            ax = cx + r.s(n); ay = cy + r.s(n)
            if filled:
                px, py = x, y
                for i in range(1, CURVE_SEGMENTS + 1):
                    t = i / CURVE_SEGMENTS
                    qx = (1 - t) ** 2 * x + 2 * (1 - t) * t * cx + t * t * ax
                    qy = (1 - t) ** 2 * y + 2 * (1 - t) * t * cy + t * t * ay
                    out.append((px / 20, py / 20, qx / 20, qy / 20))
                    px, py = qx, qy
            x, y = ax, ay
    return out


def rects(segs):
    """Even-odd scanline fill of segments -> [x, y, w, h] rectangles."""
    if not segs:
        return []
    ys = [v for s in segs for v in (s[1], s[3])]
    y_min, y_max = min(ys), max(ys)
    rows = int((y_max - y_min) / STEP) + 1
    out = []
    open_runs = {}                                     # (x0, x1) -> start row
    for row in range(rows + 1):
        runs = set()
        if row < rows:
            yc = y_min + (row + 0.5) * STEP
            xs = []
            for x0, y0, x1, y1 in segs:
                if (y0 <= yc < y1) or (y1 <= yc < y0):
                    xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                a = round(xs[i] / STEP); b = round(xs[i + 1] / STEP)
                if b > a:
                    runs.add((a, b))
        for run in list(open_runs):
            if run not in runs:
                start = open_runs.pop(run)
                out.append([round(run[0] * STEP, 2), round(y_min + start * STEP, 2),
                            round((run[1] - run[0]) * STEP, 2), round((row - start) * STEP, 2)])
        for run in runs:
            open_runs.setdefault(run, row)
    return out
