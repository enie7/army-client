#!/usr/bin/env python3
"""Extract the timelines of the game's world art from the release SWF.

The GPU timeline player (src/game/render/timeline) replays these instead of
Flash's own MovieClips. For each sprite reachable from the world symbols
named in the game config it writes the per-frame placement stream exactly as
the SWF defines it (place / move / replace / remove at a depth, with matrix,
colour transform, morph ratio, instance name, mask depth, filters and blend
mode) and the frame labels.

Leaf graphics (shapes, morph shapes, text) are not exported from the SWF, so
for each one it also records where a live instance can be found: an exported
symbol plus (frame, child index) steps down the display list. At runtime the
player instantiates that symbol, walks the path and rasterises the leaf.

usage: timelines.py <release.swf> <army_config_base.json> <out.json>
"""
import json
import struct
import sys
from collections import deque

from artsurvey import GROUND_FIELDS, config_symbols
from swfabc import doabc_payload, frame_stops, iter_tags, read_swf
import maskshapes

SPRITE = 39
LEAF_KINDS = {2: 'shape', 22: 'shape', 32: 'shape', 83: 'shape', 46: 'morph', 84: 'morph',
              11: 'text', 33: 'text', 37: 'edittext'}
BLEND_MODES = {0: 'normal', 1: 'normal', 2: 'layer', 3: 'multiply', 4: 'screen', 5: 'lighten',
               6: 'darken', 7: 'difference', 8: 'add', 9: 'subtract', 10: 'invert', 11: 'alpha',
               12: 'erase', 13: 'overlay', 14: 'hardlight'}


class Bits:
    def __init__(self, data, pos):
        self.data = data
        self.bit = pos * 8

    def u(self, n):
        v = 0
        for _ in range(n):
            v = (v << 1) | ((self.data[self.bit >> 3] >> (7 - (self.bit & 7))) & 1)
            self.bit += 1
        return v

    def s(self, n):
        v = self.u(n)
        return v - (1 << n) if n and v & (1 << (n - 1)) else v

    def align(self):
        self.bit = (self.bit + 7) & ~7
        return self.bit >> 3


def read_matrix(data, pos):
    r = Bits(data, pos)
    a = d = 1.0
    b = c = 0.0
    if r.u(1):
        n = r.u(5)
        a = r.s(n) / 65536.0
        d = r.s(n) / 65536.0
    if r.u(1):
        n = r.u(5)
        b = r.s(n) / 65536.0
        c = r.s(n) / 65536.0
    n = r.u(5)
    tx = r.s(n) / 20.0
    ty = r.s(n) / 20.0
    return [round(a, 6), round(b, 6), round(c, 6), round(d, 6), round(tx, 3), round(ty, 3)], r.align()


def read_cxform(data, pos):
    """CXFORMWITHALPHA -> [rm, gm, bm, am, ro, go, bo, ao] (multipliers as fractions)."""
    r = Bits(data, pos)
    has_add = r.u(1)
    has_mult = r.u(1)
    n = r.u(4)
    mult = [1.0, 1.0, 1.0, 1.0]
    add = [0, 0, 0, 0]
    if has_mult:
        mult = [round(r.s(n) / 256.0, 4) for _ in range(4)]
    if has_add:
        add = [r.s(n) for _ in range(4)]
    return mult + add, r.align()


def read_filters(data, pos):
    count = data[pos]
    pos += 1
    out = []
    for _ in range(count):
        kind = data[pos]
        pos += 1
        if kind in (0, 2):  # DropShadow / Glow
            rgba = data[pos:pos + 4]
            pos += 4
            blur_x, blur_y = struct.unpack('<ii', data[pos:pos + 8])
            pos += 8
            if kind == 0:
                angle, distance = struct.unpack('<ii', data[pos:pos + 8])
                pos += 8
            strength = struct.unpack('<H', data[pos:pos + 2])[0]
            pos += 2
            flags = data[pos]
            pos += 1
            f = {'type': 'dropshadow' if kind == 0 else 'glow', 'color': rgba[0] << 16 | rgba[1] << 8 | rgba[2],
                 'alpha': round(rgba[3] / 255.0, 3), 'blurX': blur_x / 65536.0, 'blurY': blur_y / 65536.0,
                 'strength': strength / 256.0, 'inner': bool(flags & 0x80), 'knockout': bool(flags & 0x40),
                 'quality': flags & 0x1f}
            if kind == 0:
                f['angle'] = angle / 65536.0
                f['distance'] = distance / 65536.0
            out.append(f)
        elif kind == 1:  # Blur
            blur_x, blur_y = struct.unpack('<ii', data[pos:pos + 8])
            pos += 8
            quality = data[pos] >> 3
            pos += 1
            out.append({'type': 'blur', 'blurX': blur_x / 65536.0, 'blurY': blur_y / 65536.0, 'quality': quality})
        elif kind == 6:  # ColorMatrix
            values = struct.unpack('<20f', data[pos:pos + 80])
            pos += 80
            out.append({'type': 'colormatrix', 'matrix': [round(v, 5) for v in values]})
        elif kind == 3:  # Bevel
            pos += 27
            out.append({'type': 'bevel'})
        elif kind in (4, 7):  # GradientGlow / GradientBevel
            n = data[pos]
            pos += 1 + n * 5 + 19
            out.append({'type': 'gradient'})
        elif kind == 5:  # Convolution
            mx, my = data[pos], data[pos + 1]
            pos += 2 + 8 + 4 * mx * my + 4 + 1
            out.append({'type': 'convolution'})
        else:
            raise ValueError('unknown filter %d' % kind)
    return out, pos


def read_place(code, data, pos):
    """One PlaceObject2/3 -> op dict (only the fields present)."""
    f1 = data[pos]
    f2 = data[pos + 1] if code == 70 else 0
    q = pos + (2 if code == 70 else 1)
    depth = struct.unpack('<H', data[q:q + 2])[0]
    q += 2
    op = {'d': depth}
    if f1 & 0x01:
        op['move'] = 1
    if code == 70 and (f2 & 0x08 or (f2 & 0x10 and f1 & 0x02)):
        q = data.index(b'\0', q) + 1
    if f1 & 0x02:
        op['c'] = struct.unpack('<H', data[q:q + 2])[0]
        q += 2
    if f1 & 0x04:
        op['m'], q = read_matrix(data, q)
    if f1 & 0x08:
        op['ct'], q = read_cxform(data, q)
    if f1 & 0x10:
        op['r'] = struct.unpack('<H', data[q:q + 2])[0]
        q += 2
    if f1 & 0x20:
        e = data.index(b'\0', q)
        op['n'] = data[q:e].decode('latin1')
        q = e + 1
    if f1 & 0x40:
        op['clip'] = struct.unpack('<H', data[q:q + 2])[0]
        q += 2
    if f2 & 0x01:
        op['f'], q = read_filters(data, q)
    if f2 & 0x02:
        op['b'] = BLEND_MODES.get(data[q], 'normal')
        q += 1
    if f2 & 0x04:
        op['cab'] = 1
        q += 1
    if f2 & 0x20:
        op['v'] = data[q]
        q += 1
    return op


def parse(body):
    kinds = {}
    sprites = {}
    symbols = {}
    stops = {}
    for code, off, ln, _, _ in iter_tags(body):
        if code in (72, 82):
            stops.update(frame_stops(doabc_payload(body, off, ln, code)))
        elif code in LEAF_KINDS:
            kinds[struct.unpack('<H', body[off:off + 2])[0]] = LEAF_KINDS[code]
        elif code == 76:
            n = struct.unpack('<H', body[off:off + 2])[0]
            q = off + 2
            for _ in range(n):
                cid = struct.unpack('<H', body[q:q + 2])[0]
                q += 2
                e = body.index(b'\0', q)
                symbols[body[q:e].decode('latin1')] = cid
                q = e + 1
        elif code == SPRITE:
            sid, count = struct.unpack('<HH', body[off:off + 4])
            kinds[sid] = 'sprite'
            frames = [[]]
            labels = {}
            for c2, o2, l2, _, _ in iter_tags(body, off + 4, off + ln):
                if c2 == 1:
                    frames.append([])
                elif c2 == 43:
                    e = body.index(b'\0', o2)
                    labels[body[o2:e].decode('latin1')] = len(frames)
                elif c2 in (26, 70):
                    frames[-1].append(read_place(c2, body, o2))
                elif c2 == 28:
                    frames[-1].append({'d': struct.unpack('<H', body[o2:o2 + 2])[0], 'rm': 1})
                elif c2 == 5:
                    frames[-1].append({'d': struct.unpack('<H', body[o2 + 2:o2 + 4])[0], 'rm': 1})
            # A sprite always has at least one frame: some declare a frame count
            # of 0 yet place children (with no ShowFrame), which Flash shows.
            frames = frames[:max(count, 1)]
            while len(frames) < count:
                frames.append([])
            sprites[sid] = {'frames': frames, 'labels': labels}
    # Frame scripts (all of them are stop()) belong to the symbol's class.
    for name, frames in stops.items():
        if symbols.get(name) in sprites:
            sprites[symbols[name]]['stops'] = frames
    return kinds, sprites, symbols


def display_lists(sprite):
    """Replay a sprite's ops: per frame, the sorted list of (depth, character)."""
    state = {}
    out = []
    for ops in sprite['frames']:
        for op in ops:
            d = op['d']
            if op.get('rm'):
                state.pop(d, None)
            elif 'c' in op:
                state[d] = op['c']
        out.append(sorted(state.items()))
    return out


# World art that game code instantiates by class name rather than through the
# config (environment effects: game/environment/RiverEffect).
CODE_SYMBOLS = [
    'Bg_RiverTile_Shine_01', 'Bg_RiverTile_Shine_02', 'Bg_RiverTile_Shine_03',
    'Bg_RiverTile_Shine_05', 'Bg_BadRiverTile_Bubbles_05',
]


def main(swf_path, config_path, out_path):
    _, body = read_swf(swf_path)
    kinds, sprites, symbols = parse(body)
    wanted = config_symbols(json.load(open(config_path, encoding='utf8')))
    # Plus every other exported sprite: game code instantiates many by class
    # name (effects, icons, environment), and any of them may end up drawn by
    # the GPU player (GpuClip).
    wanted = set(wanted) | set(CODE_SYMBOLS) | {n for n, i in symbols.items() if i in sprites and '.' not in n}
    roots = {name: symbols[name] for name in wanted if symbols.get(name) in sprites}

    # Breadth-first from the exported world symbols: every reachable sprite,
    # and the shortest path to a live instance of every character.
    paths = {}
    queue = deque()
    for name, sid in sorted(roots.items()):
        if sid not in paths:
            paths[sid] = [name]
            queue.append(sid)
    lists = {}
    while queue:
        sid = queue.popleft()
        lists[sid] = display_lists(sprites[sid])
        for frame, entries in enumerate(lists[sid]):
            for index, (depth, cid) in enumerate(entries):
                if cid in paths:
                    continue
                paths[cid] = paths[sid] + [[frame + 1, index]]
                if kinds.get(cid) == 'sprite':
                    queue.append(cid)

    out_sprites = {}
    for sid in lists:
        s = sprites[sid]
        out_sprites[str(sid)] = {'frames': s['frames'], 'labels': s['labels']}
        if 'stops' in s:
            out_sprites[str(sid)]['stops'] = s['stops']
    leaves = {str(cid): {'kind': kinds.get(cid, 'unknown'), 'path': p}
              for cid, p in paths.items() if kinds.get(cid) != 'sprite'}
    # Shapes drawn as (part of) masks: placed with a clip depth, or inside a
    # sprite that is. The runtime draws those as nothing, so their geometry
    # comes from the SWF (maskshapes.py).
    in_mask = set()

    def mark(cid):
        if cid in in_mask:
            return
        in_mask.add(cid)
        if cid in sprites:
            for frame in sprites[cid]['frames']:
                for op in frame:
                    if 'c' in op:
                        mark(op['c'])

    for s in sprites.values():
        for frame in s['frames']:
            for op in frame:
                if 'c' in op and 'clip' in op:
                    mark(op['c'])
    for code, off, ln, _, _ in iter_tags(body):
        if code in (2, 22, 32, 83):
            cid = struct.unpack('<H', body[off:off + 2])[0]
            if cid in in_mask and str(cid) in leaves:
                leaves[str(cid)]['mask'] = maskshapes.rects(maskshapes.segments(body, off, code))
    data = {'version': 1, 'symbols': {n: s for n, s in sorted(roots.items())},
            'sprites': out_sprites, 'leaves': leaves}
    with open(out_path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    ops = sum(len(fr) for s in out_sprites.values() for fr in s['frames'])
    print('%s: %d symbols, %d sprites, %d frames, %d placement ops, %d leaves (%d mask shapes), %d with stop() frames' % (
        out_path, len(roots), len(out_sprites), sum(len(s['frames']) for s in out_sprites.values()), ops, len(leaves),
        sum('mask' in l for l in leaves.values()), sum('stops' in s for s in out_sprites.values())))


if __name__ == '__main__':
    main(*sys.argv[1:4])
