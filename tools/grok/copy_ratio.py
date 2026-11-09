#!/usr/bin/env python3
"""초안(편 JSON tl)과 Grok 답이 같은 줄 수.  copy_ratio.py <편.json> <답.md>"""
import json, re, sys
d = json.load(open(sys.argv[1], encoding='utf-8')); raw = open(sys.argv[2], encoding='utf-8').read()
n = lambda s: re.sub(r'[\W_]+', '', re.sub(r'^[a-z]+:', '', s.lower()))[:40]
g = {int(m.group(1)): m.group(2).split(' / ')[0] for m in re.finditer(r'^(\d+) [A-D]:\s*(.*)$', raw, re.M)}
print(sum(1 for t in d['turns'] if n(g.get(t['num'], '')) == n(t['tl'])))
