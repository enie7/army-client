#!/usr/bin/env python3
"""Small fixes to art in the release SWF that can't be made from source.

usage: patch_art.py <in.swf> <out.swf>
"""
import struct
import sys

from swfabc import iter_tags, read_swf, write_swf

# DefineEditText character id -> (expected RGBA, new RGBA)
TEXT_COLORS = {
    # "Tap Here!" mission pointer: dark text under a same-colour glow rendered
    # as a smudge; white text keeps the glow as an outline, like "New!".
    7245: ('333333ff', 'ffffffff'),
}


def edit_text_color_offset(body, off):
    """Offset of the TextColor field of a DefineEditText tag, or None."""
    nbits = body[off + 2] >> 3
    q = off + 2 + (5 + 4 * nbits + 7) // 8
    flags = struct.unpack('<H', body[q:q + 2])[0]
    q += 2
    if flags & 0x0001:            # HasFont
        q += 4
    if flags & 0x8000:            # HasFontClass
        q = body.index(b'\0', q) + 1 + 2
    return q if flags & 0x0004 else None


def main(src, dst):
    version, body = read_swf(src)
    body = bytearray(body)
    todo = dict(TEXT_COLORS)
    for code, off, _, _, _ in iter_tags(body):
        if code != 37:
            continue
        cid = struct.unpack('<H', body[off:off + 2])[0]
        if cid not in todo:
            continue
        want, new = todo.pop(cid)
        q = edit_text_color_offset(body, off)
        if q is None or body[q:q + 4].hex() != want:
            sys.exit('text %d: unexpected colour, release SWF changed?' % cid)
        body[q:q + 4] = bytes.fromhex(new)
    if todo:
        sys.exit('text ids not found: %s' % sorted(todo))
    write_swf(dst, version, bytes(body))
    print('%s: %d text colour fix(es)' % (dst, len(TEXT_COLORS)))


if __name__ == '__main__':
    main(*sys.argv[1:3])
