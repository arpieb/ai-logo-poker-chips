"""Rewrite an SVG path's d= with every number explicitly separated,
splitting packed arc flags (e.g. 'a1 1 0 01-2 3' -> 'a 1 1 0 0 1 -2 3')."""
import re, sys
NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
ARGS = dict(M=2, L=2, H=1, V=1, C=6, S=4, Q=4, T=2, A=7, Z=0)

def normalize(d):
    out, i, cmd = [], 0, None
    while i < len(d):
        ch = d[i]
        if ch.isalpha():
            cmd = ch; out.append(ch); i += 1
            if cmd in 'Zz': cmd = None
            continue
        if ch in ' ,\t\n': i += 1; continue
        n = ARGS[cmd.upper()]
        vals = []
        while len(vals) < n:
            while d[i] in ' ,\t\n': i += 1
            if cmd in 'Aa' and len(vals) in (3, 4):   # flags: single char
                vals.append(d[i]); i += 1
            else:
                m = NUM.match(d, i); vals.append(m.group()); i = m.end()
        out.append(' '.join(vals))
        if cmd == 'm': cmd = 'l'
        elif cmd == 'M': cmd = 'L'
    return ' '.join(out)

src, dst = sys.argv[1], sys.argv[2]
svg = open(src).read()
svg = re.sub(r'\bd=(["\'])(.*?)\1', lambda m: 'd="%s"' % normalize(m.group(2)), svg, flags=re.S)
open(dst, 'w').write(svg)
