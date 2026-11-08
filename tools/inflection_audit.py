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
    docs = [nlp(re.sub(r'\{[a-z_]+\}', ' ', t['tl']).lower()) for t in d['turns']]
    verbs = {x.lemma_.lower() for doc in docs for x in doc if x.pos_ in ('VERB', 'AUX') and re.search(r'(ar|er|ir)$', x.lemma_.lower())}
    for t in d['turns']:
        for tok in nlp(re.sub(r'\{[a-z_]+\}', ' ', t['tl']).lower()):  # 소문자로 — 문장 첫 낱말을 고유명사로 잡는 것 방지
            if not tok.is_alpha:
                continue
            lem = tok.lemma_.lower().split()[0]
            pos = tok.pos_
            # spaCy 가 2인칭·1인칭 활용형을 기본형으로 못 묶는 경우: 같은 편의 동사 기본형 어간과 맞춰 본다
            if pos in ('NOUN', 'PROPN', 'ADJ', 'X') or lem == tok.text.lower():
                for v in verbs:
                    st = v[:-2]
                    if len(st) >= 3 and tok.text.lower().startswith(st) and tok.text.lower() != v and re.search(r'(o|as|es|a|e|amos|emos|imos|áis|éis|ís|an|en|é|aste|iste|ó|ió)$', tok.text.lower()):
                        lem, pos = v, 'VERB'
                        break
            if pos in KEEP:
                forms[(lem, pos if pos != 'AUX' else 'VERB')].add(tok.text.lower())
            if pos in ('NOUN', 'VERB', 'ADJ', 'ADV', 'AUX'):
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
