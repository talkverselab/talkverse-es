#!/usr/bin/env python3
"""회화 단어 목록 — 회화 전 편의 레마 중 절벽 단어(2,000위) 밖이면서 단어장(lang_es_top.csv)에 있는 것.
절벽 단어 화면의 「회화 단어 포함」이 읽는다(사용자 지시 2026-11-07). 회화를 다시 만들면 tools/add_lemmas.py 뒤에 다시 돌릴 것.
  python3 tools/conv_words.py   → assets/data/freq/conv_words_es.json"""
import collections, csv, glob, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CAP = 2000
db = {r['word']: r for r in csv.DictReader(open(ROOT / 'assets/data/freq/lang_es_top.csv', encoding='utf-8'))}
lem = collections.Counter()
files = [ROOT / 'assets/data/dialogues/L1.json'] + [Path(p) for p in glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json'))]
for f in files:
    d = json.load(open(f, encoding='utf-8'))
    for ep in d.get('episodes') or [d]:
        for t in ep.get('turns', []):
            for l in t.get('lemmas', []):
                if len(l) >= 2 and l[1] in db and int(db[l[1]]['rank']) > CAP:
                    lem[l[1]] += 1
out = [{'word': w, 'ko': db[w]['ko'], 'n': n} for w, n in lem.most_common()]
json.dump({'_meta': '회화 레마 중 절벽 단어(2,000위) 밖이면서 단어장에 있는 것 · tools/conv_words.py', 'words': out},
          open(ROOT / 'assets/data/freq/conv_words_es.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(out), [w['word'] for w in out])
