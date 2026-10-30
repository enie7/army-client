"""Minimal SWF / ABC reader used by the macOS build tools.

Only parses what the tools need: the tag list, and for each DoABC tag the
script-level definitions (class/function/var/const names per script).
"""
import lzma
import struct
import zlib


def read_swf(path):
    """Return (header_bytes, version, body) with body decompressed."""
    data = open(path, 'rb').read()
    sig, version = data[:3], data[3]
    if sig == b'CWS':
        body = zlib.decompress(data[8:])
    elif sig == b'ZWS':
        # 4-byte compressed length, 5-byte LZMA props, raw stream. Rebuild a
        # .lzma ("alone") header with an unknown size, then trim to FileLength.
        size = struct.unpack('<I', data[4:8])[0] - 8
        alone = data[12:17] + b'\xff' * 8 + data[17:]
        body = lzma.LZMADecompressor(format=lzma.FORMAT_ALONE).decompress(alone)[:size]
    elif sig == b'FWS':
        body = data[8:]
    else:
        raise ValueError('unsupported SWF signature %r' % sig)
    return version, body


def write_swf(path, version, body, compress=True):
    length = 8 + len(body)
    if compress:
        out = b'CWS' + bytes([version]) + struct.pack('<I', length) + zlib.compress(body, 9)
    else:
        out = b'FWS' + bytes([version]) + struct.pack('<I', length) + body
    open(path, 'wb').write(out)


def header_len(body):
    """Length of the RECT + frame rate + frame count preceding the first tag."""
    nbits = body[0] >> 3
    return (5 + 4 * nbits + 7) // 8 + 4


def iter_tags(body, start=None, end=None):
    """Yield (code, data_offset, data_len, tag_offset, tag_total_len)."""
    p = header_len(body) if start is None else start
    end = len(body) if end is None else end
    while p < end:
        tag_off = p
        code_len = struct.unpack('<H', body[p:p + 2])[0]
        p += 2
        code, ln = code_len >> 6, code_len & 0x3f
        if ln == 0x3f:
            ln = struct.unpack('<I', body[p:p + 4])[0]
            p += 4
        yield code, p, ln, tag_off, (p - tag_off) + ln
        p += ln


def make_tag(code, data):
    if len(data) < 0x3f and code not in (82,):
        return struct.pack('<H', (code << 6) | len(data)) + data
    return struct.pack('<H', (code << 6) | 0x3f) + struct.pack('<I', len(data)) + data


class _Reader:
    def __init__(self, b, p=0):
        self.b, self.p = b, p

    def u8(self):
        v = self.b[self.p]
        self.p += 1
        return v

    def u16(self):
        v = struct.unpack('<H', self.b[self.p:self.p + 2])[0]
        self.p += 2
        return v

    def u30(self):
        r = sh = 0
        while True:
            b = self.u8()
            r |= (b & 0x7f) << sh
            sh += 7
            if not b & 0x80 or sh >= 35:
                return r


def abc_definitions(abc):
    """Return a list of scripts, each a list of 'pkg:name' / 'name' definitions."""
    r = _Reader(abc)
    r.u16(); r.u16()
    for _ in range(max(0, r.u30() - 1)): r.u30()          # ints
    for _ in range(max(0, r.u30() - 1)): r.u30()          # uints
    n_doubles = max(0, r.u30() - 1)
    r.p += 8 * n_doubles                                  # doubles
    strs = ['']
    for _ in range(max(0, r.u30() - 1)):
        n = r.u30()
        strs.append(r.b[r.p:r.p + n].decode('utf8', 'replace'))
        r.p += n
    ns = [(0, '')]
    for _ in range(max(0, r.u30() - 1)):
        kind = r.u8()
        ns.append((kind, strs[r.u30()]))
    for _ in range(max(0, r.u30() - 1)):                  # ns sets
        for _ in range(r.u30()): r.u30()
    mn = [None]
    for _ in range(max(0, r.u30() - 1)):
        k = r.u8()
        if k in (0x07, 0x0d):
            a = r.u30(); b = r.u30(); mn.append((ns[a], strs[b]))
        elif k in (0x0f, 0x10):
            r.u30(); mn.append(None)
        elif k in (0x11, 0x12):
            mn.append(None)
        elif k in (0x09, 0x0e):
            r.u30(); r.u30(); mn.append(None)
        elif k in (0x1b, 0x1c):
            r.u30(); mn.append(None)
        elif k == 0x1d:
            r.u30()
            for _ in range(r.u30()): r.u30()
            mn.append(None)
        else:
            raise ValueError('unknown multiname kind 0x%x' % k)
    for _ in range(r.u30()):                              # methods
        pc = r.u30(); r.u30()
        for _ in range(pc): r.u30()
        r.u30()
        flags = r.u8()
        if flags & 0x08:
            for _ in range(r.u30()): r.u30(); r.u8()
        if flags & 0x80:
            for _ in range(pc): r.u30()
    for _ in range(r.u30()):                              # metadata
        r.u30()
        for _ in range(r.u30()): r.u30(); r.u30()

    def traits():
        out = []
        for _ in range(r.u30()):
            name = r.u30()
            kind = r.u8()
            k = kind & 0x0f
            if k in (0, 6):
                r.u30(); r.u30()
                if r.u30(): r.u8()
            else:
                r.u30(); r.u30()
            if kind & 0x40:
                for _ in range(r.u30()): r.u30()
            out.append(mn[name])
        return out

    n_inst = r.u30()
    for _ in range(n_inst):
        r.u30(); r.u30()
        flags = r.u8()
        if flags & 0x08: r.u30()
        for _ in range(r.u30()): r.u30()
        r.u30()
        traits()
    for _ in range(n_inst):
        r.u30()
        traits()
    scripts = []
    for _ in range(r.u30()):
        r.u30()
        defs = []
        for t in traits():
            if t is None:
                continue
            (ns_kind, pkg), name = t
            if ns_kind not in (0x16, 0x08):   # package / public-like namespaces only
                continue
            defs.append('%s:%s' % (pkg, name) if pkg else name)
        scripts.append(defs)
    return scripts


def frame_stops(abc):
    """Timeline frame scripts: {'pkg.Class': [frame, ...]} for every frameN
    method (Animate's naming, frame N is index N-1) whose body calls stop()."""
    r = _Reader(abc)
    r.u16(); r.u16()
    for _ in range(max(0, r.u30() - 1)): r.u30()
    for _ in range(max(0, r.u30() - 1)): r.u30()
    n_doubles = max(0, r.u30() - 1)
    r.p += 8 * n_doubles
    strs = ['']
    for _ in range(max(0, r.u30() - 1)):
        n = r.u30()
        strs.append(r.b[r.p:r.p + n].decode('utf8', 'replace'))
        r.p += n
    ns = ['']
    for _ in range(max(0, r.u30() - 1)):
        r.u8()
        ns.append(strs[r.u30()])
    for _ in range(max(0, r.u30() - 1)):
        for _ in range(r.u30()): r.u30()
    mn = [None]
    for _ in range(max(0, r.u30() - 1)):
        k = r.u8()
        if k in (0x07, 0x0d):
            a = r.u30(); b = r.u30(); mn.append((ns[a], strs[b]))
        elif k in (0x0f, 0x10):
            mn.append((None, strs[r.u30()]))
        elif k in (0x11, 0x12):
            mn.append(None)
        elif k in (0x09, 0x0e):
            b = r.u30(); r.u30(); mn.append((None, strs[b]))
        elif k in (0x1b, 0x1c):
            r.u30(); mn.append(None)
        elif k == 0x1d:
            r.u30()
            for _ in range(r.u30()): r.u30()
            mn.append(None)
        else:
            raise ValueError('unknown multiname kind 0x%x' % k)
    for _ in range(r.u30()):
        pc = r.u30(); r.u30()
        for _ in range(pc): r.u30()
        r.u30()
        flags = r.u8()
        if flags & 0x08:
            for _ in range(r.u30()): r.u30(); r.u8()
        if flags & 0x80:
            for _ in range(pc): r.u30()
    for _ in range(r.u30()):
        r.u30()
        for _ in range(r.u30()): r.u30(); r.u30()

    def traits():
        methods = {}
        for _ in range(r.u30()):
            name = r.u30()
            kind = r.u8()
            k = kind & 0x0f
            if k in (0, 6):
                r.u30(); r.u30()
                if r.u30(): r.u8()
            else:
                r.u30(); idx = r.u30()
                if k == 1 and mn[name]:
                    methods[mn[name][1]] = idx
            if kind & 0x40:
                for _ in range(r.u30()): r.u30()
        return methods

    n_inst = r.u30()
    classes = []
    for _ in range(n_inst):
        name = mn[r.u30()]; r.u30()
        flags = r.u8()
        if flags & 0x08: r.u30()
        for _ in range(r.u30()): r.u30()
        r.u30()
        classes.append(('%s.%s' % name if name[0] else name[1], traits()))
    for _ in range(n_inst):
        r.u30(); traits()
    for _ in range(r.u30()):
        r.u30(); traits()
    bodies = {}
    for _ in range(r.u30()):
        method = r.u30()
        r.u30(); r.u30(); r.u30(); r.u30()
        n = r.u30()
        bodies[method] = r.b[r.p:r.p + n]
        r.p += n
        for _ in range(r.u30()):
            r.u30(); r.u30(); r.u30(); r.u30(); r.u30()
        traits()

    def calls_stop(code):
        # callpropvoid (0x4f) / callproperty (0x46) on 'stop' with no arguments.
        for i, op in enumerate(code):
            if op in (0x4f, 0x46):
                c = _Reader(code, i + 1)
                try:
                    m = mn[c.u30()]
                    if m and m[1] == 'stop' and c.u30() == 0:
                        return True
                except (IndexError, ValueError):
                    pass
        return False

    out = {}
    for cls, methods in classes:
        frames = sorted(int(m[5:]) for m, idx in methods.items()
                        if m[:5] == 'frame' and m[5:].isdigit() and calls_stop(bodies.get(idx, b'')))
        if frames:
            out[cls] = frames
    return out


def doabc_payload(body, data_off, data_len, code):
    """Return the raw ABC bytes of a DoABC (82) or DoABC1 (72) tag."""
    if code == 72:
        return body[data_off:data_off + data_len]
    e = body.index(b'\0', data_off + 4)
    return body[e + 1:data_off + data_len]
