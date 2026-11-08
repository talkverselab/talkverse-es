#!/usr/bin/env python3
"""회화 편 검사기(스페인어). 규칙 = tools/prompts/dialogue_es.md.
  python3 tools/check_dialogues.py [--fix-rd] [파일·폴더 ...]   (없으면 assets/data/dialogues/R*)
오류가 0 이어야 초안 통과. --fix-rd 는 rd 를 tools/rd_es.py 로 채운다(rd_manual 턴은 그대로)."""
import collections, csv, glob, json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from rd_es import rd

ROOT = Path(__file__).resolve().parent.parent
TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (6, 12), 'R3': (6, 16), 'R4': (12, 16), 'R5': (12, 16)}
WORDS = {'R0': 8, 'R1': 8, 'R2': 10, 'R3': 10, 'R4': 22, 'R5': 22}
# 2026-11-07 옛 번호로 쓴 4편(stage 없음)은 옛 기준
OLD_TURNS = {'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16), 'R4': (12, 16)}
OLD_WORDS = {'R1': 8, 'R2': 12, 'R3': 22, 'R4': 22}
TWIST = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
ISLANDS = {'survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'}
NEED = ['id', 'region', 'island', 'kind', 'title', 'emoji', 'scene', 'speakers', 'register', 'twist', 'twist_type', 'expressions', 'purpose', 'domain', 'turns']
EMOTIONS = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
BAD = re.compile(r'[A-Za-z]')
PLURAL = re.compile(r'(?<![\wáéíóúñ])(nosotros|nosotras|vosotros|vosotras|ellos|ellas|usted|ustedes|os|vuestro|vuestra|vuestros|vuestras|nuestro|nuestra|nuestros|nuestras|somos|sois|son|estamos|estáis|están|tenemos|tenéis|tienen|vamos|vais|van|podemos|podéis|pueden|queremos|queréis|quieren|hacemos|hacéis|hacen|habéis|hemos|han|perdone|oiga|disculpe)(?![\wáéíóúñ])', re.I)
pool = {r['expr'].lower() for r in csv.DictReader(open(ROOT / 'data/expressions/top_expressions_es.csv', encoding='utf-8'))}


def norm(s):
    return re.sub(r'\s+', ' ', re.sub(r'[¡!¿?.,…:;"«»()]', ' ', s.lower())).strip()


def nwords(s):
    return len(re.findall(r"[\wáéíóúüñÁÉÍÓÚÜÑ{}]+", s))


def check(path, fix):
    d = json.load(open(path, encoding='utf-8'))
    e = []
    for k in NEED:
        if k not in d or d[k] in ('', None):
            e.append(f'{k} 없음')
    if e:
        return e, d
    lv = d['region']
    if Path(path).stem != d['id']:
        e.append('파일 이름 ≠ id')
    if d['island'] not in ISLANDS:
        e.append(f"island {d['island']}")
    if d['twist_type'] not in TWIST:
        e.append(f"twist_type {d['twist_type']}")
    old = d.get('stage') is None and lv in OLD_TURNS
    lo, hi = (OLD_TURNS if old else TURNS)[lv]
    wmax = (OLD_WORDS if old else WORDS)[lv]
    ts = d['turns']
    if not lo <= len(ts) <= hi:
        e.append(f'턴 수 {len(ts)} (허용 {lo}~{hi})')
    if not any(t['num'] == d['twist'] for t in ts):
        e.append('twist 턴 없음')
    elif d['twist'] <= len(ts) // 2 - 1:
        e.append('twist 위치가 너무 앞(본론 후반에)')
    if 'A' not in d['speakers'] or d['speakers']['A'] != '{name}':
        e.append('speakers.A 는 {name}')
    text = ' | '.join(norm(t.get('tl', '')) for t in ts)
    hit = [x for x in pool if re.search(r'(?<![\wáéíóúüñ])' + re.escape(x) + r'(?![\wáéíóúüñ])', text)]
    if len(hit) < 2:
        e.append(f'표현 풀 {len(hit)}개(≥2)')
    # 레벨 1·2(골격·챗)와 0: 단수·반말만(굴절어 전략 A3·A4) — 옛 4편(stage 없음)은 건너뜀
    if d.get('stage') is not None and lv in ('R0', 'R1', 'R2'):
        for t in ts:
            for x in (t.get('tl', ''), t.get('tl_f', '')):
                m = PLURAL.search(x)
                if m:
                    e.append(f"{t['num']}: 단수·반말 레벨에 「{m[0]}」")
    changed = False
    for i, t in enumerate(ts):
        n = t.get('num')
        if n != i + 1:
            e.append(f'턴 번호 {n}')
        for k in ('speaker', 'tl', 'ko', 'note'):
            if not t.get(k):
                e.append(f'{n}: {k} 없음')
        tl = t.get('tl', '')
        if t.get('speaker') not in d['speakers']:
            e.append(f'{n}: 화자 {t.get("speaker")} 가 speakers 에 없음')
        w = nwords(tl)
        if w > wmax:
            e.append(f'{n}: 단어 {w} (≤{wmax})')
        if lv in ('R0', 'R1', 'R2', 'R3') and w == 1 and n != d['twist'] and n != len(ts) and norm(tl) not in pool and d['kind'] != 'chat':
            e.append(f'{n}: 1단어 턴')
        for a, b in (('¿', '?'), ('¡', '!')):
            if tl.count(a) != tl.count(b):
                e.append(f'{n}: {a}{b} 짝 안 맞음')
        if BAD.search(t.get('ko', '').replace('{name}', '').replace('{city}', '').replace('{country}', '')) and not t.get('ko_latin'):
            pass
        if fix and not t.get('rd_manual'):
            r = rd(tl)
            if t.get('rd') != r:
                t['rd'] = r
                changed = True
            if t.get('tl_f'):
                r = rd(t['tl_f'])
                if t.get('rd_f') != r:
                    t['rd_f'] = r
                    changed = True
        if t.get('segs'):
            if norm(' '.join(s[1] for s in t['segs'])).replace(' ', '') != norm(tl).replace(' ', ''):
                e.append(f'{n}: segs 본문 ≠ tl')
            emos = [s[0] for s in t['segs']]
        else:
            emos = [t.get('emotion')]
        for x in emos:
            if x not in EMOTIONS:
                e.append(f'{n}: 감정 {x}')
        if not t.get('rd'):
            e.append(f'{n}: rd 없음')
        elif BAD.search(re.sub(r'\{[a-z_]+\}', '', t['rd'])):
            e.append(f'{n}: rd 에 로마자')
        if t.get('speaker') != 'A' and '{name}' not in tl and False:
            pass
    if changed:
        open(path, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    return e, d


def main():
    a = sys.argv[1:]
    fix = '--fix-rd' in a
    a = [x for x in a if not x.startswith('--')] or [str(ROOT / 'assets/data/dialogues')]
    files = []
    for x in a:
        files += [x] if x.endswith('.json') else glob.glob(x + '/**/*.json', recursive=True)
    files = [f for f in files if re.search(r'/R[0-5]/', f)]
    bad, tw, kinds = 0, collections.Counter(), collections.Counter()
    for f in sorted(files):
        try:
            e, d = check(f, fix)
        except Exception as x:
            e, d = [f'읽기 실패 {x!r}'], {}
        tw[d.get('twist_type')] += 1
        kinds[(d.get('region'), d.get('island'))] += 1
        if e:
            bad += 1
            print(Path(f).name, '; '.join(e))
    n = len(files) or 1
    print(f'{len(files)}편 · 오류 편 {bad} · 반전 {dict(tw)} · chaos {tw["chaos"] / n:.0%}')
    sys.exit(1 if bad else 0)


main()
