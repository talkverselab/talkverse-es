#!/usr/bin/env python3
"""Grok 언어감각 대사(data/review/grok/sense/<L>_rewrite.md, 줄 = `n 화자: 스페인어 / 한국어 / 감정`)를
assets/data/grammar/sense_course.json 의 memorize 문장에 그대로 붙인다(원칙: 대사는 Grok 것 그대로).
  python3 tools/grok/apply_sense.py L1 ...
- 줄 수·화자 순서가 초안과 같아야 반영. 색 표시 {낱말|n} 는 스페인어·한국어 짝 번호가 맞는지 검사.
- rd(한글 독음)는 tools/rd_es.py 로 다시 만든다. 초안은 draft_claude 칸에 보관. 감정은 emotion 칸."""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from rd_es import rd
MARK = re.compile(r'\{([^{}|]+)\|(\d+)\}')
P = ROOT / 'assets/data/grammar/sense_course.json'
d = json.load(open(P, encoding='utf-8'))
bad = 0
for lid in sys.argv[1:]:
    L = next(x for x in d['levels'] if x['id'] == lid)
    m = next(x for x in L['lessons'] if x['kind'] == 'memorize')
    raw = (ROOT / f'data/review/grok/sense/{lid}_rewrite.md').read_text(encoding='utf-8')
    rows = []
    for ln in raw.splitlines():
        g = re.match(r'^\**(\d+)\**\s+([^:：]+)[:：]\s*(.*)$', ln.strip())
        if g:
            parts = [x.strip() for x in g.group(3).split(' / ')]
            rows.append((int(g.group(1)), g.group(2).strip(' *'), parts))
    ss = m['sentences']
    err = []
    if [r[0] for r in rows] != list(range(1, len(ss) + 1)): err.append(f'줄 번호 {[r[0] for r in rows]}')
    elif [r[1] for r in rows] != [s['who'] for s in ss]: err.append('화자 순서 다름')
    for n, _, parts in rows:
        if len(parts) < 2: err.append(f'{n}줄 칸 부족'); continue
        a = sorted(set(x[1] for x in MARK.findall(parts[0]))); b = sorted(set(x[1] for x in MARK.findall(parts[1])))
        if a != b: err.append(f'{n}줄 색 번호 스페인어 {a} ≠ 한국어 {b}')
    if err:
        bad += 1; print(lid, '반영 안 함:', '; '.join(err)); continue
    for s, (n, _, parts) in zip(ss, rows):
        s.setdefault('draft_claude', {'tl': s['tl'], 'ko': s['ko']})
        s['tl'], s['ko'] = parts[0], parts[1]
        s['rd'] = rd(MARK.sub(r'\1', parts[0]))
        if len(parts) > 2 and parts[-1]: s['emotion'] = parts[-1].split()[0].lower()
    m['draft'] = 'grok'
    print(lid, '반영', len(rows), '줄')
P.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
sys.exit(1 if bad else 0)
