#!/usr/bin/env python3
"""편 JSON → Grok 「빠른」용 뼈대 요청문(대사 칸 비움). uk 2026-11-19: 대사째 주면 빠른 모드가 초안을 베낌 → 뼈대만.
  python3 tools/grok/skeleton_request.py <편.json>... → data/review/grok/<id>_prompt.md
출력 형식은 apply_rewrite.py 와 같다(`n S: 스페인어 / 한국어 / 이 줄이 하는 일 / 감정 [/ F: …]`)."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
REG = {'casual': '친구·또래 사이 반말(tú)', 'chat': '1:1 채팅(반말·줄임말)', 'polite': '처음 보는 사이·회사(usted 존댓말)', 'mixed': '상대에 따라 tú/usted 섞임'}
TW = {'emotion': '감정 반전(설렘·마음 들킴)', 'chaos': '카오스(꼬임이 걷잡을 수 없이 커짐)', 'reveal': '숨은 사실이 드러남'}
WORDS = {'R1': 8, 'R2': 12, 'R3': 14, 'R4': 18}
for p in sys.argv[1:]:
    e = json.load(open(p, encoding='utf-8'))
    roles = ' / '.join(f"{k} = {'학습자(한국인 20대, 남자 기준, 이름 {name})' if v == '{name}' else v}" for k, v in e['speakers'].items())
    sk = '\n'.join(f"{t['num']} {t['speaker']}: " for t in e['turns'])
    n = len(e['turns'])
    txt = f"""[ES-{e['id']}] 스페인어 학습 앱(한국인 학습자)의 회화 1편을 처음부터 써 주세요. 지금 마드리드 20대가 이 장면에서 실제로 그대로 말할 카스티야 구어로(vale·tío/tía·en plan·qué fuerte·venga 같은 말을 자연스럽게). 교과서체·번역투·중남미식 말·설명하는 대사 금지.
제목: {e['title']} · 장면: {e['scene']}
등장: {roles} · 말투: {REG.get(e.get('register'), e.get('register'))}
꼭 넣을 표현·문법: {e.get('goal', '')} — 같은 동사가 여러 인칭으로 되풀이되게.
턴 {e.get('twist')} 근처에서 {TW.get(e.get('twist_type'), e.get('twist_type'))}. 웃음·킥 대사·설레는 한 줄 포함, 실제 일상 장면 안에서(비현실·판타지 금지).
지킬 것: 턴 {n}개, 아래 화자 순서 그대로 · {{name}} 은 그대로 · 쉬운 단어 위주 · 한 턴 {WORDS.get(e['region'], 14)}단어 이하 · ¡ ¿ 항상 · 실존 인물·브랜드 금지 · 성적 묘사 금지.
학습자 A 의 말이나 A 를 부르는 말이 성에 따라 바뀌면(cansado/cansada, tío/tía) 그 줄 끝에 ` / F: 여성 학습자판 문장`.
출력 형식(이것만, 설명 없이): 줄마다 `번호 화자글자: 스페인어 / 한국어(자연스러운 구어) / 이 줄이 하는 일 한 줄 / 감정`. 화자는 A·B·C 글자로. 감정은 다음 중 하나(영어 그대로): neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. 한 턴 안에서 바뀌면 `surprised:¿En serio?|gentle:Pues vamos.`.
마지막 줄 `추천 표현:` 이 장면에서 스페인 사람이 자주 쓰는 짧은 말 2개.

뼈대(화자 순서):
{sk}
"""
    out = ROOT / f"data/review/grok/{e['id']}_prompt.md"; out.write_text(txt, encoding='utf-8'); print(out, n)
