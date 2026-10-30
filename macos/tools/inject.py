#!/usr/bin/env python3
"""Inject freshly compiled code into the release SWF.

The DoABC tags from <code.swf> are inserted ahead of the release SWF's own
DoABC tag. The player keeps the first definition of each class name, so the
newly compiled classes take over while art symbols, their frame scripts and
anything we did not recompile keep coming from the release build.

usage: inject.py <release.swf> <code.swf> <out.swf>
"""
import sys

from swfabc import iter_tags, read_swf, write_swf

DOABC = (72, 82)


def main(release, code, out):
    version, body = read_swf(release)
    _, code_body = read_swf(code)
    new_abc = b''.join(code_body[t:t + n] for c, _, _, t, n in iter_tags(code_body) if c in DOABC)
    if not new_abc:
        sys.exit('no DoABC tags in %s' % code)

    result, injected = bytearray(), False
    first = next(iter_tags(body))[3]
    result += body[:first]
    for c, _, _, t, n in iter_tags(body):
        if c in DOABC and not injected:
            result += new_abc
            injected = True
        result += body[t:t + n]
    if not injected:
        sys.exit('no DoABC tag in %s' % release)
    write_swf(out, version, bytes(result))
    print('%s: injected %d bytes of code' % (out, len(new_abc)))


if __name__ == '__main__':
    main(*sys.argv[1:4])
