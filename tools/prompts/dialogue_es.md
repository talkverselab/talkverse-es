# 회화 초안 작성 규칙 — 스페인어(카스티야)

공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ · 공통 프롬프터 §12 · 일본어앱 `docs/DIALOGUE_WORKFLOW_JA.md` §1·§5-1 의 스페인어판. 초안은 Claude 가 쓰고 뒤에 Grok 이 재작성한다(`draft`).

## 톤
- **학습자가 외우고 싶어지는 대사.** 편마다 입에 남는 한 줄. 스페인 사람이 지금 정말 쓰는 말 — 교과서체·번역투·설명 대사·AI 티 금지. 다짐·감사 인사로 끝내지 말 것. 끝 줄은 짧은 한 방.
- 구조: 질문 → 대답 + 이유나 농담 → 상대가 그 말을 받아 되치기. 설명 대신 반응으로 정보가 나온다. 중반에 오해·놀림·내기·흥정 같은 작은 갈등.
- **최우선: 짧은 구어 표현**(`data/expressions/top_expressions_es.csv`)을 편마다 2개 이상, 많을수록 좋게, 맞장구·추임새로 자연스럽게. 편끼리 같은 표현을 반복해도 된다.
- SNS·DM·채팅·데이팅앱 장면을 많이. 연애 = 썸·플러팅까지(클럽 포함), **여성이 먼저 다가가는 편을 더 많이**, 클리셰는 일부만. 심쿵(마음을 들키는 말·말끝 흐리기·침묵 「…」·여운)을 연애 편마다 한 줄, 다른 주제에도 자주. 웃음 킥과는 다른 턴.
- 수위 12+: 성적 묘사 없음. 술은 드물게, `flags` 에 `alcohol`·`profanity_mild`·`jealousy`·`haggle`.
- 말투: 낯선 사이·가게 = usted 또는 정중한 tú(스페인 젊은 점원은 tú 가 자연스럽다), 친구·연인 = tú, 2인칭 복수 **vosotros**. 사이가 가까워지는 전환 장면도 넣는다. ko 도 같은 말투(존댓말/반말), **직역 금지**, 한국 사람이 실제로 하는 말로.
- 출처·작품명·실존 인물·실존 브랜드 금지. 전부 자체 작문.

## 인물(`CHARACTERS.md`) — 무대 마드리드
A = 학습자 `{name}`(국적·성별 비고정, `{country}`·`{city}` 변수 가능, 나라 이름을 대사에 고정 금지). 성격이 대사로 드러나게:
- **Lucía** 친구·문화: 쾌활·수다·직설, 동네 맛집을 다 앎, `tío/tía`·`qué fuerte` 남발.
- **Marta** 연애: 차분·건조한 유머, 헌책방 알바, 사실은 로맨스 소설광, 놀리다가 먼저 마음을 들킴.
- **Javi** 친구: 느긋한 먹보, 축구, 늘 늦음, 추로스.
- **Diego** 생활: 셰어하우스 룸메이트, 솔직·다정, 기타.
- 이름 없는 조연(C·D): `Camarera`·`Dependiente`·`Taxista`·`Farmacéutica`·`Vecina`… 매뉴얼 말투인데 타이밍이 기막힘.
화자 코드 A·B·C·D, `speakers` 에 이름. 앞 편 대사를 다시 쓰는 콜백은 `tags` 에 `callback:<편id>`.

## 학습자 성별
A 는 남녀 모두다. A 의 말이나 A 를 부르는 말이 성에 따라 바뀌면(`cansado/cansada`, `¿Estás listo?/lista`, `tío/tía`) **기본 tl 은 남성형으로 쓰고 그 턴에 여성형 `tl_f` 를 함께 둔다**. 되도록 성이 안 드러나는 말을 고르되 억지로 피하지는 않는다.

## 길이
- R1: 6~8턴, 턴당 **8단어 이하**, 1~2문장, 1단어 단답 금지(반전 턴·마지막 턴·표현 풀 한마디·chat 예외). R2: 8~12턴, 12단어 이하. R3: 12~16턴, 문장 2개까지(22단어 이하). 역부호 ¡ ¿ 항상.
- 긴 턴 다음엔 짧게 받아치는 교대가 좋다.

## 어휘
단어 순위는 `assets/data/freq/lang_es_top.csv`(rank, word = 기본형). 절벽 45·69·168·570 은 R1 까지로 쓰기엔 너무 좁으므로 회화 레벨은 **R1 = 주로 570위 안, R2 = 주로 1,000위 안, R3 = 주로 2,000위 안**(장면에 꼭 필요한 명사는 편당 1~3개 벗어나도 되고 note 에 뜻). 문법: R1 = 현재·ir a·gustar·perfecto 소량, R2 = + 단순과거·불완료·명령, R3 = + 접속법 일부·조건.

## 반전
모든 편 1회, 본론 후반. `twist` = 턴 번호, `twist_type` = chaos(일이 걷잡을 수 없이 커짐) · slip(말실수·오해) · reveal(의외 사실) · emotion(심쿵·감정) · ignore(읽씹). **chaos 는 묶음마다 30% 이상**, 스페인 생활의 현실 사고로(예: 「sí」만 했더니 봉투·영수증·포인트 카드까지 / 「lo que sea」에 메뉴 전부 / 하트 셋을 단톡방에 / 셀카에 행인·개까지).

## 스페인어 함정(자주 틀림 — AI 지문)
`usted` 남용 금지(또래끼리), `tú` 주어를 굳이 쓰지 않는다, `¿Cómo estás?` 대신 `¿Qué tal?`, 카스티야 어휘(`móvil`·`ordenador`·`coche`·`zumo`·`patata`·`vale`·`piso`), 중남미 어휘(`celular`·`carro`·`ahorita`·`ustedes` 친구끼리) 금지, 현재완료 `he comido` 를 오늘 일에 쓴다.

## 편 JSON — `assets/data/dialogues/R<n>/<island>/<id>.json`
```json
{"id":"r1_friends_a1","region":"R1","island":"friends","kind":"short",
 "title":"한국어 제목","emoji":"☕","scene":"장면 한 줄(한국어)",
 "speakers":{"A":"{name}","B":"Lucía"},"register":"casual","twist":6,"twist_type":"chaos","flags":[],
 "purpose":["making_friends"],"domain":["friends"],"goal":"학습 목표 한 줄","expressions":["vale","en serio"],
 "turns":[{"num":1,"speaker":"B","tl":"¡Oye! ¿Tú eres {name}?","rd":"","ko":"저기! 네가 {name}이야?","note":"oye = 부를 때 「저기」","tags":["expr:oye"],"new":["oye"]}],
 "draft":"claude"}
```
- `kind`: survival · short(a) · long(b) · chat(c). `register`: polite·casual·chat·mixed. `purpose`: travel·study_abroad·work_spain·media·reading·love·making_friends. `domain`: life·friends·love·work·study·culture·travel.
- 채팅 편: 턴에 `"ui":"bubble"`, 시간 `"at":"23:12"`, 이모지·스탬프 `"stamp":"😂"`, 읽씹은 `"read":false`. 채팅 말투(`q`·`xq`·`jajaja`·`tb`)는 살짝만.
- `note` = 그 턴 핵심 하나 「X = 뜻」(한국어). `tags` = `expr:`·`form:`·`callback:`. `new` = 이 턴에서 처음 가르치는 말(기본형).
- **감정(사용자 지시 2026-11-07)**: 턴마다 음성을 고려한 `emotion` 을 쓴다. 값 = neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. 한 턴에서 감정이 바뀌면 `emotion` 대신 `segs`(`[[감정, 본문], …]`, 이어 붙이면 `tl`)로 나눈다. neutral 만 쓰지 말 것 — 심쿵 턴은 gentle·shy, 받아치기는 tsukkomi.
- `rd` 는 비워 두고 `python3 tools/check_dialogues.py --fix-rd <폴더>` 로 채운다. 틀린 곳만 손으로 고치고 `"rd_manual":true`.

## 굴절 반복(사용자 지시 2026-11-08 — 학습자가 굴절에 익숙해지게)
- 편마다 핵심 동사·형용사·명사 **3개 이상(레벨 0 은 2개 이상)이 서로 다른 형태로** 나오게 쓴다. 주고받기 속에서 자연스럽게: `¿Tienes hambre? — Tengo mucha. — Javi siempre tiene hambre.` / `¿Estás cansado? — Cansada no, estoy muerta.` / 단수 레벨은 yo·tú·él/ella 와 남성·여성(cansado/cansada, guapo/guapa), 레벨 3 부터 복수(tenemos·tenéis·tienen, cansados/cansadas).
- 단어는 **많이 쓰이는 말(절벽구간 상위 단어)을 우선** — 레벨 0~3 은 내용어의 80% 이상이 570위 안이면 좋다. 절대 기준은 아니고 **재미와 자연스러움이 먼저**.
- 점검: `<spaCy 가 든 python> tools/inflection_audit.py` — 편마다 굴절 반복 수와 많이 쓰는 단어 비율.

## 레벨 = 문법 단계(굴절어 전략 A1, 사용자 결정 2026-11-08) — 폴더 R 숫자 = 회화 레벨
`docs/DIALOGUE_RULES_es.md` 참고. 단어 메뉴 R1~R5(절벽 tier)와 다른 번호다. 각 편에 `stage`(단계 번호)와 `level_name` 을 적는다. 핵심 문장 = 회화 편의 줄(변형 카드 450 은 동결 대상이라 아직 안 씀).

| 폴더 | 레벨 | 편 | 턴 | 어휘 | 문법·말투 |
|---|---|---|---|---|---|
| R0 | 0 소리·짧은 회화 | 8편(r0_<주제>_a1~) | 6 | 주로 300위 안 | 현재형·인사·짧은 반응. 반말 관계만, 단수만 |
| R1 | 1 관사·성수·활용 골격 | 10편 = 골격 10단계 × 1(편 id r1_s01~s10_<주제>) | 6~8 | 주로 570위 안 | 단계: ①관사·성수 일치 ②ser/estar ③현재 규칙 -ar/-er/-ir ④gustar 구문 ⑤목적 대명사 lo/la/le ⑥전치사 a·de·en·con ⑦현재완료(오늘 일) ⑧ir a+원형 ⑨재귀동사 ⑩단순과거 씨앗. **단수 1·2·3인칭만**(nosotros·vosotros·ellos·ustedes 금지), **반말 관계만**(친구·채팅·연인·룸메이트 — 가게·낯선 사이 장면 금지, usted 금지). 불규칙 8동사(ser·estar·ir·tener·hacer·poder·querer·decir)는 통문장으로 |
| R2 | 2 챗 실전 | 10편 = 채팅 상황 10(첫 인사·사진·약속·늦음·사과·취소·농담·오해·화해·다음 약속) | 6~8 | 주로 570위 안 + 채팅 말 | 모두 chat(ui bubble·at·stamp·read). 단수만, 반말만. 진짜 스페인 채팅 말투(jajaja·q·xq·tb 살짝) |
| R3 | 3 그래머2 | 10편 = R1 10편을 **복수·존댓말로 갈아끼운 것**(같은 이야기, 새 단어 0) | 6~8 | R1 과 같음 | nosotros·vosotros·ellos/ellas·usted·ustedes 해금. 가게·낯선 사이 장면은 여기부터 |
| R4 | 4 어려운 문법 | 10편 = 문법 10(접속법 현재-바람·감정 / cuando+접속법 / 조건법 / 단순과거↔불완료 / 과거완료 / 명령형 긍정·부정 / 대명사 결합 se lo / 무인칭·수동 se / por↔para / si+접속법 과거) | 12~16 | 주로 1,000위 안 | 「정복」이 아니라 씨앗 — 그 문법이 자연스럽게 두세 번 나오면 된다 |
| R5 | 5 어휘 완주 | 10편 = 주제 10(집·일·건강·감정·날씨/계절·여행/이동·돈·가족 행사·갈등·미래) | 12~16 | 571~2,000위 단어를 편마다 많이 | 새 문법 없음 |

2026-11-07 의 레벨별 한 편 초안 4편(R1 love·R2 life·R3 friends·R4 work)은 옛 번호 기준이라 그대로 두고, 위 구성의 편과 별도다(점검표 `docs/DIALOGUE_RULES_es.md` C-2).

## 묶음 구성
R1 = survival s1~s3(6턴) + 주제 5개(friends·love·life·travel·culture) × 16편(a1~a6 짧은 6턴 · b1~b6 긴 7~8턴 · c1~c4 채팅 6~8턴). R2 = 7주제(+work·study) × b1~b8. R3 = 7주제 중 6 × b1~b6(편 id `r2_love_b1` 식).
