#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 읽기]) 를 채운다 — 문장 레마 ↔ 단어장 연결(사용자 지시 2026-11-04).
일본어앱 tools/add_lemmas.py 와 같은 역할. 스페인어는 형태소 분석기(spaCy es_core_news_md) 로 원형을 찾고 읽기 칸은 비운다.
내용어 = 명사·동사·형용사·부사·감탄사(관사·전치사·대명사·접속사·숫자·고유명사·문장부호 제외).
단어장에 없는 레마는 data/review/write/missing_lemmas.csv 로(uk 세션에 넘겨 단어·그림 제작).
  <spacy 가 든 python> tools/add_lemmas.py        (예: 스크래치 venv — pip install spacy && python -m spacy download es_core_news_md)
"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path

import spacy

ROOT = Path(__file__).resolve().parent.parent
VAR = re.compile(r'\{[a-z_]+\}')
KEEP = {'NOUN', 'VERB', 'AUX', 'ADJ', 'ADV', 'INTJ'}
FIX = {'ajo': 'ajo', 'callos': 'callos', 'rosa': 'rosa', 'seis': 'seis', 'tapas': 'tapa', 'trozo': 'trozo', 'vistas': 'vista', 'décimo': 'décimo', 'educado': 'educado',
       'mayo': 'mayo', 'falta': 'falta', 'previstas': 'previsto', 'portada': 'portada', 'bienvenido': 'bienvenido', 'bienvenida': 'bienvenido', 'bienvenidos': 'bienvenido',
       'suéltalo': 'soltar', 'vámonos': 'ir', 'dale': 'dar', 'dame': 'dar', 'dime': 'decir', 'córtala': 'cortar', 'quédate': 'quedar', 'molan': 'molar', 'friega': 'fregar',
       'muy': 'muy', 'bien': 'bien', 'mejor': 'mejor', 'encantada': 'encantado', 'español': 'español', 'gracias': 'gracias', 'hola': 'hola', 'adiós': 'adiós', 'vale': 'vale'}
SKIP = {'nosotros', 'nosotras', 'vosotros', 'vosotras', 'cuatrocientos', 'ciento', 'cien', 'mil'}  # 대명사·수사(분석기가 형용사로 오인)
FORCE = {'hola', 'gracias', 'adiós', 'vale'}  # 감탄사로 안 잡혀도 내용어로 넣는 말
nlp = spacy.load('es_core_news_md', disable=['parser', 'ner'])
# spaCy 규칙 원형이 틀리는 것(lees·vas·lleguser…) — 원형 대조표(spacy-lookups-data es_lemma_lookup)로 보정(2026-11-19)
try:
    import gzip, os, spacy_lookups_data
    LOOK = json.load(gzip.open(os.path.join(os.path.dirname(spacy_lookups_data.__file__), 'data/es_lemma_lookup.json.gz'), 'rt', encoding='utf-8'))
except Exception:
    LOOK = {}
CLITIC = re.compile(r'(?:(?:me|te|se|nos|os)(?:lo|la|los|las|le|les)?|lo|la|los|las|le|les)$')

# 단어장 = 앱 빈도 단어표(assets/data/freq/lang_es_top.csv, word 열)
db = set()
with open(ROOT / 'assets/data/freq/lang_es_top.csv', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        db.add(r['word'].strip().lower())

def lemmas_of(text, names=()):
    out = []
    doc = nlp(VAR.sub(' ', text))
    for i, tok in enumerate(doc):
        if tok.is_punct or tok.is_space or not re.search(r'[a-záéíóúüñ]', tok.text, re.I):
            continue
        pos = tok.pos_
        low = tok.text.lower()
        if low in names or low in SKIP:
            continue
        # 문장 중간의 대문자 낱말 = 이름·지명 → 뺀다
        at_start = i == 0 or doc[i - 1].text in {'.', '!', '?', '¡', '¿', '…'} or doc[i - 1].is_punct and i >= 1 and (i < 2 or doc[i - 2].text in {'.', '!', '?'})
        if tok.text[0].isupper() and not at_start:
            continue
        if low in FORCE:
            out.append([tok.text, FIX.get(low, low), ''])
            continue
        # 문장 첫머리 대문자를 고유명사로 오인하는 것(Encantada): 소문자로 다시 보고 내용어면 살린다
        if pos == 'PROPN':
            t2 = nlp(low)[0]
            if t2.pos_ not in KEEP:
                continue
            pos, tok = t2.pos_, t2
        if pos not in KEEP:
            continue
        base = FIX.get(low, tok.lemma_.lower()).split()[0]  # verlo → 「ver él」 처럼 대명사가 붙으면 동사만
        if low not in FIX and base not in db:
            cands = [LOOK.get(low, '')]
            if pos in ('VERB', 'AUX'):  # 대명사 붙은 명령·부정사(llévatelo·dártela·quédate) → 떼고 다시
                bare = CLITIC.sub('', low)
                if bare != low and len(bare) > 2:
                    plain = bare.translate(str.maketrans('áéíóú', 'aeiou'))
                    cands += [LOOK.get(bare, ''), LOOK.get(plain, ''), plain if plain in db else '']
            good = next((c for c in cands if c and c in db), '')
            if good:
                base = good
            elif cands[0]:
                base = cands[0]
        out.append([tok.text, base, ''])
    return out

miss, ex, tot, hit = Counter(), {}, 0, 0
def add(t, names):
    global tot, hit
    out = lemmas_of(t.get('tl') or t.get('es', ''), names)
    for _, base, _ in out:
        tot += 1
        if base in db:
            hit += 1
        else:
            miss[base] += 1
            ex.setdefault(base, t.get('tl') or t.get('es', ''))
    if t.get('lemmas') != out:
        t['lemmas'] = out
        return True
    return False

# 편 파일(2026-11-19~): assets/data/dialogues/R<n>/<주제>/<id>.json, 화자 이름 = speakers(+speakers_f)
for fpath in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R[0-5]/*/*.json'))):
    e = json.load(open(fpath, encoding='utf-8'))
    names = {str(v).lower() for v in list((e.get('speakers') or {}).values()) + list((e.get('speakers_f') or {}).values())}
    changed = False
    for t in e.get('turns', []):
        changed |= add(t, names)
    if changed:
        open(fpath, 'w', encoding='utf-8').write(json.dumps(e, ensure_ascii=False, indent=1) + '\n')
# 옛 묶음 파일(assets/data/dialogues/*.json, episodes 칸)
for fpath in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/*.json'))):
    d = json.load(open(fpath, encoding='utf-8'))
    if 'episodes' not in d:
        continue
    names = {str(v.get('name', '')).lower() for v in (d.get('characters') or {}).values() if isinstance(v, dict)}
    changed = False
    for ep in d['episodes']:
        for t in ep.get('turns', []):
            changed |= add(t, names)
    if changed:
        open(fpath, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
out_dir = ROOT / 'data/review/write'
out_dir.mkdir(parents=True, exist_ok=True)
with open(out_dir / 'missing_lemmas.csv', 'w', encoding='utf-8', newline='') as fo:
    w = csv.writer(fo)
    w.writerow(['lemma', 'reading', 'count', 'example'])
    for b, n in miss.most_common():
        w.writerow([b, '', n, ex[b]])
print(f'내용어 {tot} · 단어장 있음 {hit / max(tot, 1):.0%} · 없는 레마 {len(miss)} → data/review/write/missing_lemmas.csv')
