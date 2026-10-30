#!/usr/bin/env python3
"""Survey the world art in the release SWF, for the rendering rebuild.

For every art symbol named in the game config (unit / building / effect
graphics; ground tiles excluded, they are drawn by GroundChunks), report how
its timeline is built: frames, frame labels, nested animated sprites and how
deep they go, the loop lengths of nested timelines (which decide how long a
pre-rendered sequence has to be), and whether the symbol has frame scripts.

usage: artsurvey.py <release.swf> <army_config_base.json> <decompiled scripts dir> [out.json]
"""
import json
import math
import os
import re
import struct
import sys
from collections import Counter, defaultdict

from swfabc import iter_tags, read_swf

GROUND_FIELDS = {'GraphicsFriendly', 'GraphicsEnemy', 'OverlaysFriendly', 'OverlaysEnemy'}


def parse_sprites(body):
    """id -> {frames, labels {frame: [names]}, children [ids per frame placed]}"""
    sprites = {}
    symbols = {}
    for code, off, ln, _, _ in iter_tags(body):
        if code == 76:  # SymbolClass
            n = struct.unpack('<H', body[off:off + 2])[0]
            q = off + 2
            for _ in range(n):
                cid = struct.unpack('<H', body[q:q + 2])[0]
                q += 2
                e = body.index(b'\0', q)
                symbols[body[q:e].decode('latin1')] = cid
                q = e + 1
        elif code == 39:  # DefineSprite
            sid, frames = struct.unpack('<HH', body[off:off + 4])
            labels = defaultdict(list)
            placed = set()
            frame = 1
            for c2, o2, l2, _, _ in iter_tags(body, off + 4, off + ln):
                if c2 == 1:  # ShowFrame
                    frame += 1
                elif c2 == 43:  # FrameLabel
                    e = body.index(b'\0', o2)
                    labels[frame].append(body[o2:e].decode('latin1'))
                elif c2 in (26, 70):  # PlaceObject2/3
                    f1 = body[o2]
                    q = o2 + 3 if c2 == 26 else o2 + 4
                    if c2 == 70:
                        f2 = body[o2 + 1]
                        if f2 & 0x08 or (f2 & 0x10 and f1 & 0x02):
                            q = body.index(b'\0', q) + 1
                    if f1 & 0x02:
                        placed.add(struct.unpack('<H', body[q:q + 2])[0])
            sprites[sid] = {'frames': frames, 'labels': dict(labels), 'children': placed}
    return sprites, symbols


def config_symbols(config):
    out = defaultdict(set)  # symbol -> set of fields

    def walk(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if isinstance(v, str) and v.startswith('swf/') and k not in GROUND_FIELDS:
                    for part in v.split(','):
                        part = part.strip()
                        if part.startswith('swf/'):
                            out[part.rsplit('/', 1)[1]].add(k)
                walk(v)
        elif isinstance(o, list):
            for x in o:
                walk(x)
    walk(config)
    return out


def frame_script_classes(scripts_dir):
    """Class names (qualified with '.') whose source calls addFrameScript."""
    out = set()
    for root, _, files in os.walk(scripts_dir):
        for f in files:
            if f.endswith('.as'):
                p = os.path.join(root, f)
                if 'addFrameScript' in open(p, encoding='utf8', errors='replace').read():
                    rel = os.path.relpath(p, scripts_dir)[:-3]
                    out.add(rel.replace(os.sep, '.'))
    return out


def analyse(sid, sprites, depth=0, seen=None):
    """Nested animated sprites below sid: max depth and the loop lengths."""
    seen = seen or set()
    if sid in seen or sid not in sprites:
        return 0, set(), 0
    seen = seen | {sid}
    max_depth = 0
    loops = set()
    count = 0
    for child in sprites[sid]['children']:
        if child not in sprites:
            continue
        cf = sprites[child]['frames']
        d, sub, n = analyse(child, sprites, depth + 1, seen)
        if cf > 1:
            loops.add(cf)
            count += 1
            max_depth = max(max_depth, 1 + d)
        else:
            max_depth = max(max_depth, d)
        loops |= sub
        count += n
    return max_depth, loops, count


def main(swf_path, config_path, scripts_dir, out_path=None):
    _, body = read_swf(swf_path)
    sprites, symbols = parse_sprites(body)
    wanted = config_symbols(json.load(open(config_path, encoding='utf8')))
    scripted = frame_script_classes(scripts_dir)
    by_id = {v: k for k, v in symbols.items()}
    rows = []
    missing = []
    for name in sorted(wanted):
        sid = symbols.get(name)
        if sid is None or sid not in sprites:
            missing.append(name)
            continue
        s = sprites[sid]
        depth, loops, nested = analyse(sid, sprites)
        own = s['frames']
        period = own
        for n in loops:
            period = period * n // math.gcd(period, n)
        scripted_children = sorted({by_id[c] for c in s['children'] if c in by_id and by_id[c] in scripted})
        rows.append({
            'symbol': name, 'fields': sorted(wanted[name]), 'frames': own,
            'labels': {str(k): v for k, v in sorted(s['labels'].items())},
            'nested_animated': nested, 'nested_depth': depth, 'nested_loops': sorted(loops),
            'flattened_period': period, 'frame_script': name in scripted,
            'scripted_children': scripted_children,
        })

    print('%d config symbols, %d found as sprites, %d missing' % (len(wanted), len(rows), len(missing)))
    total_frames = sum(r['frames'] for r in rows)
    print('own frames total %d; symbols with frame scripts %d' % (total_frames, sum(r['frame_script'] for r in rows)))
    print('nested animation depth:', dict(sorted(Counter(r['nested_depth'] for r in rows).items())))
    flat = [r for r in rows if r['nested_loops'] and r['flattened_period'] > r['frames']]
    print('symbols whose nested loops outlast their own timeline: %d' % len(flat))
    labels = Counter(l for r in rows for ls in r['labels'].values() for l in ls)
    print('frame labels used:', dict(labels.most_common(20)))
    print('\nlargest flattened sequences (own frames -> frames needed to bake nested loops):')
    for r in sorted(rows, key=lambda r: -r['flattened_period'])[:15]:
        print('  %-48s %4d -> %6d  loops %s' % (r['symbol'], r['frames'], r['flattened_period'], r['nested_loops'][:8]))
    if missing:
        print('\nnot found as sprites (%d): %s' % (len(missing), ', '.join(missing[:20])))
    if out_path:
        json.dump(rows, open(out_path, 'w'), indent=1)
        print('\nwrote', out_path)


if __name__ == '__main__' and not (len(sys.argv) > 5 and sys.argv[5] == '--features'):
    main(*sys.argv[1:5])


# ---- feature census: which PlaceObject features world art uses ----

SHAPES = {2: 'DefineShape', 22: 'DefineShape2', 32: 'DefineShape3', 83: 'DefineShape4'}
MORPHS = {46: 'DefineMorphShape', 84: 'DefineMorphShape2'}
TEXTS = {11: 'DefineText', 33: 'DefineText2', 37: 'DefineEditText'}
BITMAPS = {6: 'DefineBits', 21: 'DefineBitsJPEG2', 35: 'DefineBitsJPEG3', 36: 'DefineBitsLossless2', 20: 'DefineBitsLossless', 90: 'DefineBitsJPEG4'}


def character_kinds(body):
    kinds = {}
    for code, off, ln, _, _ in iter_tags(body):
        for table in (SHAPES, MORPHS, TEXTS, BITMAPS):
            if code in table:
                kinds[struct.unpack('<H', body[off:off + 2])[0]] = table[code]
        if code == 39:
            kinds[struct.unpack('<H', body[off:off + 2])[0]] = 'DefineSprite'
    return kinds


def feature_census(swf_path, config_path):
    _, body = read_swf(swf_path)
    sprites, symbols = parse_sprites(body)
    kinds = character_kinds(body)
    wanted = config_symbols(json.load(open(config_path, encoding='utf8')))
    reach = set()
    stack = [symbols[n] for n in wanted if n in symbols]
    while stack:
        s = stack.pop()
        if s in reach:
            continue
        reach.add(s)
        stack.extend(c for c in sprites.get(s, {}).get('children', ()) if c in sprites)
    feats = Counter()
    leaf_kinds = Counter()
    leaves = set()
    for code, off, ln, _, _ in iter_tags(body):
        if code != 39:
            continue
        sid = struct.unpack('<H', body[off:off + 2])[0]
        if sid not in reach:
            continue
        for c2, o2, l2, _, _ in iter_tags(body, off + 4, off + ln):
            if c2 in (4, 5, 28):
                feats['RemoveObject'] += 1
            if c2 not in (26, 70):
                continue
            f1 = body[o2]
            f2 = body[o2 + 1] if c2 == 70 else 0
            if f1 & 0x01 and not f1 & 0x02:
                feats['move only'] += 1
            if f1 & 0x01 and f1 & 0x02:
                feats['replace character'] += 1
            if f1 & 0x08:
                feats['color transform'] += 1
            if f1 & 0x10:
                feats['ratio (morph)'] += 1
            if f1 & 0x20:
                feats['instance name'] += 1
            if f1 & 0x40:
                feats['clip depth (mask)'] += 1
            if f1 & 0x80:
                feats['clip actions'] += 1
            if f2 & 0x01:
                feats['filters'] += 1
            if f2 & 0x02:
                feats['blend mode'] += 1
            if f2 & 0x04:
                feats['cacheAsBitmap'] += 1
            if f2 & 0x20:
                feats['visible flag'] += 1
            if f1 & 0x02:
                q = o2 + 3 if c2 == 26 else o2 + 4
                if c2 == 70 and (f2 & 0x08 or (f2 & 0x10 and f1 & 0x02)):
                    q = body.index(b'\0', q) + 1
                cid = struct.unpack('<H', body[q:q + 2])[0]
                if kinds.get(cid) != 'DefineSprite':
                    leaves.add(cid)
    for cid in leaves:
        leaf_kinds[kinds.get(cid, 'unknown')] += 1
    print('reachable sprites from world symbols: %d' % len(reach))
    print('distinct leaf characters: %d by kind %s' % (len(leaves), dict(leaf_kinds.most_common())))
    print('placement features:', dict(feats.most_common()))


if __name__ == '__main__' and len(sys.argv) > 5 and sys.argv[5] == '--features':
    feature_census(sys.argv[1], sys.argv[2])
