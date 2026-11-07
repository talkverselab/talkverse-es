#!/usr/bin/python3
"""회화 파일의 `emotion`·`segs` → 감정 계획 data/tts/plan/<편id>.json 자동 생성(사용자 지시 2026-11-07 — 감정을 손으로 다시 적지 않는다).
  python3 tools/tts/make_plan.py [편id...]   (없으면 회화 전편) · 끝나면 check_plan.py 로 검사
- 목소리: 인물 이름 → CAST. 이름 없는 조연은 편 JSON `cast`({"C":"man_m"})로 준다.
- `tl_f` 가 있는 턴은 여성판 `f` 를 만든다. 조각이 여럿이면 `tl`·`tl_f` 에서 달라진 낱말을 조각마다 바꾼다(`segs_f` 가 있으면 그것을 쓴다)."""
import json, os, re, sys
import ttslib as L

CAST = {'Lucía': 'lucia', 'Marta': 'marta', 'Javi': 'javi', 'Diego': 'diego', 'Directora': 'directora', 'Vecina': 'vecina'}
clean = lambda s: s.replace('«', '').replace('»', '')  # 인용 부호는 읽지 않는다


def female(t, segs):
    if t.get('segs_f'):
        return [[e, clean(x)] for e, x in t['segs_f']]
    a, b = t['tl'].split(), t['tl_f'].split()
    pairs = [(x, y) for x, y in zip(a, b) if x != y] if len(a) == len(b) else []
    if len(segs) > 1 and not pairs:
        sys.exit(f"{t['num']}: tl_f 와 낱말 수가 달라 segs_f 가 필요합니다")
    if len(segs) == 1:
        return [[segs[0][0], clean(t['tl_f'])]]
    out = []
    for e, x in segs:
        for p, q in pairs:
            x = x.replace(clean(p), clean(q))
        out.append([e, x])
    return out


def plan(ep):
    d = json.load(open(L.EP[ep], encoding='utf-8'))
    cast = {}
    for k, name in d['speakers'].items():
        if k == 'A':
            continue
        v = (d.get('cast') or {}).get(k) or CAST.get(name)
        if not v:
            sys.exit(f'{ep}: 목소리 없음 {k}={name} — 편 JSON cast 또는 CAST 에 넣을 것')
        cast[k] = v
    turns = {}
    for t in d['turns']:
        segs = [[s[0], clean(s[1])] for s in t['segs']] if t.get('segs') else [[t['emotion'], clean(t['tl'])]]
        T = {'segs': segs}
        if t.get('tl_f'):
            T['f'] = {'text': t['tl_f'], 'rd': t.get('rd_f') or t['rd'], 'ko': t.get('ko_f') or t['ko'], 'segs': female(t, segs)}
        turns[str(t['num'])] = T
    json.dump({'ep': ep, 'cast': cast, 'turns': turns}, open(f'{L.R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


ids = sys.argv[1:] or sorted(L.EP)
for ep in ids:
    plan(ep)
print('계획', len(ids), '편')
