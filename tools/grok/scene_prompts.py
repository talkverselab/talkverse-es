#!/usr/bin/env python3
"""편 JSON → 장면 컷 요청문(A·B 대화 한 쌍 = 컷 1장, 말풍선·글자 없음). 중국어앱 tools/scene_prompts.py 를 옮김.
  python3 tools/grok/scene_prompts.py <편.json>... [--female]  → data/review/art/<편id>[_f]/cut<n>_req.md
그림은 tools/grok/cuts_run.sh 가 한 장씩(인물 기준 그림 data/review/art/chars_es_v1.jpg + 화면 톤 sian_es_01.jpg 첨부) 받는다."""
import json, os, re, sys
FEMALE = '--female' in sys.argv
CHAR = {
 'Lucía': '루시아(Lucía, 20대 초 여성 — 진갈색 긴 웨이브 머리를 느슨하게 묶음, 테라코타 니트 + 연청 데님 미디 스커트 + 흰 스니커즈, 작은 갈색 크로스백, 쾌활)',
 'Marta': '마르타(Marta, 20대 중반 여성 — 검은 단발 + 동그란 금테 안경, 올리브 셔츠 원피스 + 짙은 갈색 앵클부츠, 책 든 캔버스 토트백, 차분)',
 'Javi': '하비(Javi, 20대 초 남성 — 짧은 곱슬 흑발, 로고 없는 진초록 축구 저지 + 회색 조거 + 흰 운동화, 느긋)',
 'Diego': '디에고(Diego, 20대 중반 남성 — 짙은 갈색 웨이브 중간 길이·짧은 수염, 소매 걷은 흰 린넨 셔츠 + 네이비 치노, 가장 키 큼, 다정)',
}
MINOR = {  # 조연 고정 묘사 — 컷마다 같은 사람
 'Casera': '집주인(스페인 여성 60대, 짧은 회색 파마, 꽃무늬 블라우스 + 베이지 카디건)', 'Vecina': '이웃 아주머니(스페인 여성 60대, 갈색 파마, 앞치마, 큰 목소리)',
 'Madre de Javi': '하비의 어머니(스페인 여성 50대, 짧은 갈색 머리, 빨간 카디건, 하비와 닮은 웃음)', 'Abuela': '할머니(스페인 여성 80대, 은발 쪽진 머리, 검은 원피스 + 진주 목걸이)',
 'Primo': '사촌(스페인 남성 20대, 짧은 머리, 줄무늬 폴로셔츠)', 'Jefe': '부장(스페인 남성 50대, 반백 머리, 회색 정장 + 넥타이 없음)',
 'Jefa': '팀장(스페인 여성 40대, 단정한 단발, 네이비 블레이저)', 'Compañera': '여자 동료(스페인 여성 20대 후반, 포니테일, 흰 블라우스)',
 'Compañero': '남자 동료(스페인 남성 30대, 안경, 하늘색 셔츠)', 'Camarera': '종업원(스페인 여성 20대, 검은 앞치마, 올림머리)',
 'Camarero': '종업원(스페인 남성 40대, 흰 셔츠 + 검은 조끼, 콧수염)', 'Vigilante': '미술관 경비원(스페인 남성 50대, 남색 제복·모자)',
 'Secretaria': '학교 행정실 직원(스페인 여성 50대, 안경 목걸이, 회색 카디건)', 'Agente': '부동산 중개인(스페인 남성 30대, 매끈한 머리, 정장 + 서류철)',
 'Repartidor': '배달원(스페인 남성 20대, 글자 없는 주황 재킷 + 헬멧)', 'Doctora': '의사(스페인 여성 40대, 흰 가운, 묶은 머리)',
 'Empleada': '역 직원(스페인 여성 30대, 남색 제복)', 'Nerea': '네레아(Nerea, 20대 여성 — 갈색 긴 생머리, 노란 원피스, 데이팅앱 상대)',
}
LEARNER = '학습자(20대, 국적이 드러나지 않는 생김새 — 첨부 기준 그림의 {g} 쪽: {d})'
LD = {'남성': '황토색(#C8901E) 후드티 + 베이지 팬츠 + 갈색 백팩', '여성': '검은 단발 보브, 남색 자켓 안에 황토색 티 + 베이지 팬츠 + 갈색 백팩'}
for path in [a for a in sys.argv[1:] if a.endswith('.json')]:
    e = json.load(open(path, encoding='utf-8'))
    g = '여성' if FEMALE else '남성'
    out = f"data/review/art/{e['id']}{'_f' if FEMALE else ''}"; os.makedirs(out, exist_ok=True)
    def who(n):
        if n == '{name}': return LEARNER.format(g=g, d=LD[g])
        return CHAR.get(n) or MINOR.get(n) or f'{n}(조연, 스페인 사람)'
    people = ' / '.join(who(v) for v in e['speakers'].values())
    ts = e['turns']; cuts = [ts[i:i + 2] for i in range(0, len(ts), 2)]
    chat = ('\n**채팅 편**: 두 사람은 서로 다른 장소에 있다 — 각자 자기 자리에서 폰을 보는 모습으로, 화면을 세로로 반 나눠 왼쪽/오른쪽에 한 사람씩. 같은 방에 두지 말 것.' if e.get('kind') == 'chat' else '')
    for k, pair in enumerate(cuts, 1):
        desc = ' → '.join(f"{e['speakers'].get(t['speaker'], t['speaker']).replace('{name}', '학습자')}: 「{re.sub(r'[(（].*?[)）]', '', (t.get('ko_f') if FEMALE and t.get('ko_f') else t['ko'])).replace('{name}', '○○').strip()}」" for t in pair)
        txt = f"""[ES-{e['id']}{'_f' if FEMALE else ''}-{k}] 회화 장면 컷 {k}/{len(cuts)} — 편 「{e['title']}」. 첨부 1번 = 인물 기준 그림(얼굴·머리·옷을 그대로 유지), 첨부 2번 = 앱 화면 톤(UI 를 그리지 말고 장면 그림만).
스타일: 부드러운 3D 점토/펠트 인형, 둥근 얼굴, 파스텔, 스페인 마드리드의 생활 공간(바·광장·골목·지하철·아파트·헌책방 등, 글자 없는 간판), 밝고 따뜻한 조명(밤 장면도 밝게), 부드러운 그림자. 가로 16:9. 같은 편 컷끼리 장소·옷·조명이 이어지게.
장면: {e['scene']}
등장: {people}{chat}
이 컷의 순간(그림에 글자로 넣지 말 것 — 표정·몸짓·소품으로만): {desc}
톤: 카오스·웃음·심쿵이 표정·몸짓·소품으로 확실히 보이게(놀라 커진 눈, 당황한 손짓, 수줍은 미소와 눈 마주침).
반드시: **말풍선·글자·간판 글씨·자막·숫자·로고 없음**(대사는 앱이 얹는다 — 인물 머리 위 여백). 두 인물이 모두 보이게, 말하는 사람이 조금 앞에. 조연은 앞 컷과 같은 얼굴·머리·옷. 실존 인물·브랜드 금지.
출력: 그림 1장만. 설명 없이.
"""
        open(f'{out}/cut{k}_req.md', 'w', encoding='utf-8').write(txt)
    print(e['id'], len(cuts))
