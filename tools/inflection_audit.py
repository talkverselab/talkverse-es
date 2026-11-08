#!/usr/bin/env python3
"""굴절 반복 점검 — 편마다 같은 기본형이 몇 가지 굴절형(인칭·성·수·시제)으로 나오는지 + 많이 쓰이는 단어 비율.
  <spaCy python> tools/inflection_audit.py [--md out.md]
굴절 반복 = 기본형 하나가 서로 다른 형태(활용·성수)로 2번 이상 나온 것. 목표(굴절어 전략): 편마다 3개 이상."""
import collections, csv, glob, json, re, sys
from pathlib import Path
import spacy
ROOT = Path(__file__).resolve().parent.parent
nlp = spacy.load('es_core_news_md', disable=['parser', 'ner'])
rank = {r['word']: int(r['rank']) for r in csv.DictReader(open(ROOT / 'assets/data/freq/lang_es_top.csv', encoding='utf-8'))}
CAP = {'R0': 570, 'R1': 570, 'R2': 570, 'R3': 570, 'R4': 1000, 'R5': 2000}
KEEP = {'VERB', 'AUX', 'ADJ', 'NOUN', 'DET', 'PRON'}
rows = []
for f in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json'))):
    d = json.load(open(f, encoding='utf-8'))
    if d.get('stage') is None:
        continue
    forms = collections.defaultdict(set); toks = within = 0
    for t in d['turns']:
        for tok in nlp(re.sub(r'\{[a-z_]+\}', ' ', t['tl'])):
            if not tok.is_alpha:
                continue
            lem = tok.lemma_.lower().split()[0]
            if tok.pos_ in KEEP and tok.pos_ != 'PROPN':
                forms[(lem, tok.pos_ if tok.pos_ != 'AUX' else 'VERB')].add(tok.text.lower())
            if tok.pos_ in ('NOUN', 'VERB', 'ADJ', 'ADV', 'AUX'):
                toks += 1
                within += rank.get(lem, 99999) <= CAP[d['region']]
    rep = sorted(f'{l}({"/".join(sorted(v))})' for (l, p), v in forms.items() if len(v) >= 2 and p in ('VERB', 'ADJ', 'NOUN'))
    rows.append((d['region'], d['id'], d['title'], len(rep), round(100 * within / max(toks, 1)), rep))
low = [r for r in rows if r[3] < 3]
out = ['| 레벨 | 편 | 제목 | 굴절 반복 수 | 많이 쓰는 단어 % | 반복된 말 |', '|---|---|---|---|---|---|']
out += [f'| {a} | {b} | {c} | {n} | {p} | {", ".join(rep[:6])} |' for a, b, c, n, p, rep in rows]
summary = f'{len(rows)}편 · 굴절 반복 3개 미만 {len(low)}편 · 평균 {sum(r[3] for r in rows) / max(len(rows), 1):.1f}개 · 많이 쓰는 단어 평균 {sum(r[4] for r in rows) / max(len(rows), 1):.0f}%'
if '--md' in sys.argv:
    Path(sys.argv[sys.argv.index('--md') + 1]).write_text(summary + '\n\n' + '\n'.join(out) + '\n', encoding='utf-8')
print(summary)
for r in rows:
    print(r[0], r[1], r[3], f'{r[4]}%', ', '.join(r[5][:5]))
