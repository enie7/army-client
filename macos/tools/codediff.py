#!/usr/bin/env python3
"""Compare two FFDec decompile trees, ignoring decompiler/compiler noise.

FFDec output from different builds of the same source differs in register
numbering (_locN_), hoisted default declarations and import order. This
normalizes those away so only real code changes remain.

usage: codediff.py <old-scripts-dir> <new-scripts-dir> [out-prefix]
"""
import os
import re
import sys

DEFAULT_DECL = re.compile(r'^\s*var (_loc\d+_|param\d+):[\w.<>*$]+ = (null|0|NaN|false|undefined|""|-1)\s*;\s*$')
VAR_DECL = re.compile(r'\bvar (_loc\d+_):[\w.<>*$]+\s*=')
LOC = re.compile(r'\b_loc\d+_\b')
BARE_DEFAULT = re.compile(r'^_loc\d+_ = (null|0|NaN|false|undefined|"")\s*;$')


def normalize(text):
    out, mapping = [], {}
    for line in text.split('\n'):
        s = line.strip()
        if not s or s.startswith('import '):
            continue
        if re.search(r'\bfunction\b', s):
            mapping = {}
        if DEFAULT_DECL.match(line):
            continue
        s = VAR_DECL.sub(r'\1 =', s)
        if BARE_DEFAULT.match(s):
            continue
        s = LOC.sub(lambda m: mapping.setdefault(m.group(0), 'L%d' % len(mapping)), s)
        out.append(s)
    return '\n'.join(out)


def files(d):
    return {os.path.relpath(os.path.join(r, f), d)
            for r, _, fs in os.walk(d) for f in fs if f.endswith('.as')}


def main(a, b, prefix=None):
    A, B = files(a), files(b)
    scope = lambda p: p.startswith(('game/', 'com/')) or '/' not in p
    changed = sorted(p for p in A & B if scope(p) and
                     normalize(open(os.path.join(a, p)).read()) != normalize(open(os.path.join(b, p)).read()))
    same = len([p for p in A & B if scope(p)]) - len(changed)
    new = sorted(p for p in B - A if scope(p))
    print('identical %d, changed %d, new %d, removed %d' % (same, len(changed), len(new), len([p for p in A - B if scope(p)])))
    if prefix:
        open(prefix + 'changed.txt', 'w').write('\n'.join(changed))
        open(prefix + 'new.txt', 'w').write('\n'.join(new))
    return changed, new


if __name__ == '__main__':
    changed, new = main(*sys.argv[1:4])
    print('CHANGED:', ' '.join(changed))
    print('NEW:', ' '.join(new))
