#!/usr/bin/env python3
"""언어감각 외울 대화(sense_course.json memorize) → Grok 대사 작성 요청문.
python3 tools/grok/sense_request.py [L1 ...] → data/review/grok/sense/<id>_prompt.md
원칙(uk 2026-11-18): Claude 는 초안까지, 대사는 Grok 이 쓰고 그대로 붙여 넣는다."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
d = json.load(open(ROOT / 'assets/data/grammar/sense_course.json', encoding='utf-8'))
want = set(sys.argv[1:])
for L in d['levels']:
    if want and L['id'] not in want: continue
    m = next(x for x in L['lessons'] if x['kind'] == 'memorize')
    who = []
    for s in m['sentences']:
        if s['who'] not in who: who.append(s['who'])
    lines = '\n'.join(f"{i+1} {s['who']}: {s['tl']} / {s['ko']}" for i, s in enumerate(m['sentences']))
    notes = '\n'.join(f"- {f}" for f in m.get('footnotes', []))
    txt = f"""[ES-SENSE-{L['id']}] 스페인어 학습 앱(한국인 학습자) 「언어감각 익히기」 {L['id']} — 주제: {L['title']}.
문법을 설명하지 않고, 짧은 대화 하나를 통째로 외우면 이 문법이 몸에 붙게 만드는 과정입니다. 아래 **Claude 초안**을 참고해 **모든 줄을 새로 써 주세요**(초안 문장을 그대로 옮기면 안 됨). 지금 마드리드 20대가 실제 일상(카페·바·집·길·채팅)에서 그대로 말할 카스티야 구어로, 재미·반전·심쿵 한 방 포함, 비현실적 설정 금지.
등장: {' / '.join(who)} ('나' = 학습자, 남자 기준) · 줄 수 {len(m['sentences'])} 그대로 · 화자 순서 그대로 · 한 줄 12단어 이하 · 역부호 ¡ ¿ 항상 · 실존 인물·브랜드 금지.
이 대화가 보여 줄 문법(초안의 설명): 
{notes}
**색 표시 규칙(꼭 지킬 것)**: 초안처럼 이 문법이 드러나는 낱말을 `{{낱말|번호}}` 로 감쌉니다. 번호는 초안과 같은 뜻(예: 1·2 = 대비되는 두 꼴). 스페인어와 한국어 양쪽에, 짝이 되는 부분에 같은 번호. 한 줄에 표시 1~3개, 대화 전체에서 각 번호가 3번 이상 나오게.
출력 형식(이것만, 설명 없이): 줄마다 `번호 화자: 스페인어 / 한국어(자연스러운 구어) / 감정` — 감정은 neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle 중 하나.

초안:
{lines}
"""
    out = ROOT / f"data/review/grok/sense/{L['id']}_prompt.md"; out.write_text(txt, encoding='utf-8'); print(out)
