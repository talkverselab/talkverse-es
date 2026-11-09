#!/usr/bin/env python3
"""편 JSON → Grok 재작성 요청문(tools/prompts/rewrite_grok_es.md 틀).  python3 tools/grok/rewrite_request.py <편.json>... → data/review/grok/<편id>_prompt.md"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
tpl = re.search(r'```\n(.*?)```', (ROOT / 'tools/prompts/rewrite_grok_es.md').read_text(encoding='utf-8'), re.S).group(1)
REG = {'casual': '친구·연인 사이 반말(tú)', 'chat': '1:1 채팅(반말·줄임말·이모지, WhatsApp 말투)', 'polite': '처음 보는 사이·가게·회사(usted 존댓말)', 'mixed': '상대에 따라 tú/usted 섞임'}
LEVEL = {
 'R0': ('레벨 0 — 왕초보, 아주 짧은 반말 회화(한 턴 3~6단어)', '현재형만, 단수 1·2·3인칭만(yo·tú·él/ella), 반말 관계만(nosotros·vosotros·ellos·usted 금지)', 8),
 'R1': ('레벨 1 — 관사·성수·활용 골격(초급)', '단수 1·2·3인칭만, tú 만(복수형·usted 금지). 가게·낯선 사이 장면도 tú 로. 이 편의 문법 단계를 여러 번 보여 줄 것: {goal}', 8),
 'R2': ('레벨 2 — 챗 실전(초급, 1:1 채팅)', '단수 1·2·3인칭·tú 만(복수·usted 금지). 단순과거는 자유롭게, 불완료는 estaba·era·tenía 덩어리만', 10),
 'R3': ('레벨 3 — 그래머2(복수·존댓말 갈아끼우기)', '이 편은 같은 이야기를 복수(nosotros·vosotros·ellos)·usted 로 다시 말하는 편 — 새 단어를 늘리지 말 것. {goal}', 10),
 'R4': ('레벨 4 — 어려운 문법(중급)', '이 편의 문법을 자연스럽게 2~4번: {goal}. 복수·usted 자유', 22),
 'R5': ('레벨 5 — 어휘 완주(중급, 주제 어휘)', '새 문법 없이 이 주제의 어휘를 많이: {goal}', 22),
}
SHORT = '--short' in sys.argv
for p in [x for x in sys.argv[1:] if x.endswith('.json')]:
    e = json.load(open(p, encoding='utf-8'))
    roles = ' / '.join(f"{k} = {'학습자(한국인 20대, 이름 {name})' if v == '{name}' else v}" for k, v in e['speakers'].items())
    lines = '\n'.join(f"{t['num']} {t['speaker']}: {t['tl']} / {t['ko']}" + (f" / F: {t['tl_f']}" if t.get('tl_f') else '') for t in e['turns'])
    lv, gr, w = LEVEL[e['region']]
    txt = (tpl.replace('{code}', f"ES-{e['id']}").replace('{roles}', roles).replace('{scene}', e['scene'])
           .replace('{register}', REG.get(e.get('register'), e.get('register', ''))).replace('{level}', lv)
           .replace('{grammar}', gr.replace('{goal}', e.get('goal', ''))).replace('{twist}', str(e.get('twist')))
           .replace('{n}', str(len(e['turns']))).replace('{words}', str(w)).replace('{lines}', lines))
    if SHORT:  # 사용자 지시 2026-11-09: 규칙은 방에 한 번(rules_es.md), 편마다 최소 요청
        txt = (f"[ES-{e['id']}] 앞의 규칙 그대로(형식·감정 열·F: 여성판 포함). {lv} · 문법: {gr.replace('{goal}', e.get('goal', ''))}\n"
               f"등장 {roles} · 장면 {e['scene']} · 말투 {REG.get(e.get('register'), '')} · 반전 턴 {e.get('twist')} · {len(e['turns'])}턴 · 한 턴 {w}단어 이하\n초안:\n{lines}")
    out = ROOT / f"data/review/grok/{e['id']}_prompt.md"; out.write_text(txt, encoding='utf-8'); print(out)
