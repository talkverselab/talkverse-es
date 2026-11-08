# 앱 빌드 전략 — 스페인어유니버스 (굴절어 전략 전달문 → 앱 구조)

_2026-11-08 초안. 바탕 = `~/talkverse/INFLECTED_LANG_STRATEGY.md`(A1~A12·B1~B15, 사용자 결정 2026-11-08) + `docs/DIALOGUE_RULES_es.md`(스페인어 적용표). 이 문서는 **코드·데이터·작업 순서**만 다룬다. 회화 작성 규칙은 `tools/prompts/dialogue_es.md`, 운영 규칙은 `CLAUDE.md`·`HANDOFF.md`._

> **2026-11-08 갱신:** 이 초안을 쓴 직후 사용자가 회화 편 수 제한과 회화 밖 콘텐츠 동결을 **둘 다 해제**했다. 아래의 「동결 해제 뒤」 단계는 지금 시작할 수 있다. 레벨별 회화 초안(R0 8편·R1~R5 각 10편)은 작성 중이다.

## 1. 한 줄 요약 · 지금 상태

**레벨(0~5) = 문법 단계 길 위에 「회화 편(핵심) + 말 조각 카드(변형 1:9) + 음성」을 올리고, 라임 직후에 페이월을 둔다.** 코드는 지금부터 만들 수 있고, 콘텐츠는 동결 해제 뒤 A12 순서로 채운다.

| 전략이 요구하는 것 | 지금 있는 것 | 모자란 것 |
|---|---|---|
| 레벨 0~5 길(A1) | `DialogueHomeScreen` = 레벨→주제 목록(`regions`/`islandsOf`), `levelKo = {'L1':'이야기'}` | 레벨 길 화면, 단계(stage) 개념, 레벨 이름표 |
| 회화 편 JSON(B14) | `assets/data/dialogues/R1~R4/<주제>/` 각 1편(`draft: claude`, 검사기 통과) | **앱이 안 읽음** — `dialogue_service.dart` 는 옛 `L1.json` 만, pubspec 은 하위 폴더 미포함 |
| 음성(A9·B12) | D1 `audio_lines` lang es 4편 102줄, `tools/tts/` | 앱 재생 코드 없음(일본어앱 `dialogue_audio.dart` 이식 전) |
| 성별판(A9) | 편 JSON 에 `tl_f`·`rd_f`, 음성 m/f 두 줄, 컷 `<편id>_f` | `DialogueTurn` 모델에 `tl_f`·`rd_f` 칸 없음 → 화면이 못 씀 |
| morph_tags(A8) | `tools/add_lemmas.py`(spaCy, 레마만, 옛 L1 형식만 읽음) | 성·수·인칭·시제 태그, R 폴더 읽기, 「성·수」 자막 |
| 변형 카드 1:9(A2) | 없음(`dialogue_card_screen.dart` 는 편 턴 카드) | 카드 파일 형식·선별 스크립트·덱 화면 |
| 페이월(A10) | `Entitlement.premium`·`PaywallScreen`·결제 완성, **잠근 기능 0** | 잠금 선 = 레벨 1 3단계부터, 라임 장면, 외계인 화자 |
| 절벽 단어 R1~R5(A11) | `lib/core/cliff.dart` 45/69/168/570, 상한 2,000, `word_freq_screen.dart`, `about_screen.dart` | 「회화 레벨 번호와 다름」 문구, 레벨 어휘 상한 표시 |

제약(바꾸지 않고 그 안에서 짠다): 회화 = 레벨별 한 편까지 · 회화 밖 콘텐츠 동결 · Grok 재작성 11/10 뒤 사용자 지시 때만 · Android(Zealot)+iOS(TestFlight) 항상 함께 · 공개 저장소(코퍼스·출처·작품명 금지) · 서명 키 새로 만들지 않음.

## 2. 레벨 구조 → 앱 구조

### 2-1. 레벨과 폴더
- 레벨 번호 = 문법 단계(A1). 폴더 `assets/data/dialogues/R<n>/` 의 n = **회화 레벨**(B14). R0 소리·짧은 회화 / R1 관사·성수·활용 골격 / R2 챗 실전 / R3 그래머2(복수 vosotros·ustedes + usted) / R4 어려운 문법(접속법·조건법·과거 구분) / R5 어휘 완주.
- `DialogueService.levels = ['R0','R1','R2','R3','R4','R5']`, `levelKo = {'R0':'소리·짧은 회화','R1':'골격','R2':'챗 실전','R3':'그래머2','R4':'어려운 문법','R5':'어휘 완주'}` (사전 `l10n_dict.dart` 세 개에 같은 키 추가).
- 레벨 안의 **단계(stage)** = 골격 묶음(R1 은 10단계: 관사·성수 → ser/estar → -ar/-er/-ir → gustar → lo/la/le → a·de·en·con → 현재완료 → ir a → 재귀 → 단순과거 씨앗). 단계 정의는 코드가 아니라 데이터 `assets/data/dialogues/levels.json` 한 파일:
  ```json
  {"levels":[{"id":"R1","name":"골격","vocab_cap":570,"free_stages":2,
    "stages":[{"id":"s01","name":"관사·성·수 일치","slot":"Gender|Number","episodes":["r1_love_a1"],"deck":"R1/s01"}, …]}]}
  ```
  `vocab_cap` = 그 레벨 회화의 단어 순위 상한(§7-1 결정 뒤 확정), `free_stages` = 무료 단계 수(A10: 레벨 1 은 2), `episodes` = 핵심 회화 편 id, `deck` = 변형 카드 파일(§3-3).

### 2-2. 배우기 탭(`main_screen.dart` `LearnTab`)
- 「회화」 섹션 → **「레벨 길」**(`level_path_screen.dart`, 신규) 한 줄로 바꾼다. 세로 길: 레벨 0→5, 레벨 안에 단계 줄(핵심 편 ▶ · 말 조각 n장 · 잠금 아이콘). `_TodayCard` 「이어서 읽기」는 그대로(마지막 편).
- 「문법」 섹션의 「성·수(준비 중)」 → morph 태그가 들어온 뒤 「성·수 자막」 설정(§4-4)으로 연결. 「동사 활용」은 그대로.
- 지금의 `DialogueHomeScreen`(레벨→주제 목록)은 **탐색 탭**으로 옮겨 「주제별 회화」로 남긴다(코드 재사용, 삭제 없음).

### 2-3. 단어 메뉴 R1~R5 와의 분리(A1·A11)
- `cliff.dart` 의 R1~R5 는 **절벽 tier** — 건드리지 않는다. 화면 표기만 구분: `word_freq_screen.dart`·`about_screen.dart` 의 「R1~R5」 → 「단어 구간 R1~R5」, 레벨 길은 「레벨 0~5」로 쓴다.
- `about_screen.dart` 에 한 단락 추가: *「회화 레벨(0~5)은 문법 단계 순서이고, 단어 구간(R1~R5)은 빈도 절벽입니다. 번호가 같아도 뜻이 다릅니다. 레벨마다 쓰는 단어 상한만 단어 구간으로 정합니다.」* 상한 2,000·87.9% 는 그대로(A11 — 레마 목록이 2,500위까지라 올리려면 목록 확장 = 동결 대상).

### 2-4. 무료 / 유료 선(A10)
- 무료 = R0 전부 + **골격 매핑표**(관사·성·수·동사 활용 한 장, `assets/data/grammar/skeleton_map_es.json`, 신규 — 콘텐츠라 동결 해제 뒤) + 코어 20~30 단어 카드 + **라임**(외계인 화자) + R1 s01·s02. **페이월 = 라임 직후**, R1 s03 부터 `Entitlement.premium`.
- 코드: `levels.json` 의 `free_stages` 로 판정하는 `LevelAccess.isLocked(levelId, stageId)` (`lib/data/entitlement.dart` 옆 `level_access.dart`). 잠긴 단계의 편·덱을 열면 `Entitlement.showPaywall`. `paywall_screen.dart` 혜택 문구 = 「레벨 1 3단계부터 레벨 5까지 전부 · 말 조각 카드 · 음성」. **잠금은 사용자가 범위를 확정한 뒤 켠다**(HANDOFF §3-1 — A10 이 그 답의 후보).
- 라임 장면 = R1 s02 끝에 붙는 특수 편(`kind: "rhyme"`, `speakers.B` = 외계인). 캐릭터 시트는 uk 세션 대기(A10 ⚠) — 시트 전에는 자리만.

## 3. 데이터 모델

### 3-1. 회화 편 JSON(지금 쓰는 칸, 유지)
편: `id region island kind title emoji scene speakers register twist twist_type flags purpose domain goal expressions draft` (+ 음성용 `cast`·`fill`). 턴: `num speaker tl tl_f rd rd_f ko note tags new emotion segs segs_f` (+ `lemmas` 는 아직 R 폴더 편에 없음).

### 3-2. 추가할 칸
| 어디 | 칸 | 뜻 |
|---|---|---|
| 편 | `stage` | 속한 단계 id(`"s01"`). `levels.json` 과 둘 중 하나만 진실이면 되므로 **levels.json 이 진실**, 편의 `stage` 는 검사기가 맞춰 준다 |
| 편 | `core` | 이 편의 턴이 그 단계 핵심 문장(외우는 50개)임을 표시(`true`). 핵심 1 : 변형 9 의 「1」 |
| 턴 | `ko_f` | 여성판 한국어가 다를 때만(A9) |
| 턴 | `morph` | spaCy 결과를 낱말마다 `[표면형, 레마, POS, "Gender=Masc\|Number=Plur\|Person=2\|Tense=Pres\|Mood=Ind"]` — `lemmas`(3칸) 는 그대로 두고 **별도 칸**(단어장 연결과 문법 자막은 쓰는 곳이 다름) |
| 턴 | `focus` | 그 단계가 가르치는 굴절 슬롯(`"Number=Sing\|Person=2"`). 「성·수」 자막이 강조할 낱말을 고르는 기준 |
| 턴 | `audio` | 없음 — 음성 유무는 D1 매니페스트가 진실(일본어앱과 같음) |

### 3-3. 변형 카드(말 조각) 파일 — 신규
`assets/data/variants/R<n>/s<k>.json`:
```json
{"level":"R1","stage":"s01","slot":"Gender|Number","cards":[
 {"id":"r1_s01_v001","core":"r1_love_a1:2","tl":"Es muy bonita.","tl_f":"","rd":"에스 무이 보니따.","ko":"되게 예뻐.",
  "morph":[["Es","ser","AUX","Mood=Ind|Number=Sing|Person=3|Tense=Pres"],["bonita","bonito","ADJ","Gender=Fem|Number=Sing"]],
  "focus":"Gender=Fem","emotion":"cheerful","src":"claude"}]}
```
- `core` = 어느 핵심 문장의 변형인지(`편id:턴`). 단계당 핵심 50 → 변형 450(A2, 스페인어 500 으로 시작).
- `src` = `claude`(자체 작문) 만 저장소에 둔다. 코퍼스 후보 풀·선별 점수표는 **저장소 밖**(`~/talkverse/_corpus/es/`, §5-3).
- 음성: 덱도 「편」처럼 다룬다 — `audio_lines.episode = "r1_s01_v"`, `turn` = 카드 번호. `ttslib.EP` 글롭에 `assets/data/variants/R*/*.json` 추가.

### 3-4. 로더·pubspec·버전
- pubspec 은 폴더의 하위 폴더를 묶지 않는다 → `tools/build_dialogue_index.py`(신규)가 ① `assets/data/dialogues/index.json`(편 id → 경로·레벨·단계) ② pubspec `assets:` 의 `assets/data/dialogues/R<n>/<주제>/`·`assets/data/variants/R<n>/` 줄을 생성·검사(빠진 폴더가 있으면 종료 코드 1). 편을 추가할 때마다 돌린다.
- `dialogue_service.dart`: `_files` 상수 → `index.json` 읽기, 편 형식 = 새 JSON(`region`·`island`·`speakers`·턴 `tl`). `Dialogue` 에 `stage`·`core`, `DialogueTurn` 에 `tlF rdF koF segs morph focus`. 옛 `L1.json` 변환 코드는 **지우지 않고 index 에 없으면 안 읽는다**(§7 결정 뒤 삭제).
- `Dialogue.view(turn)`(일본어앱 `dialogue_service.dart:138`): 음성 줄이 있으면 그 본문(`text`·`rd`·`ko`), 없으면 `LearnerPrefs.isFemale ? tlF : tl` — 듣는 말과 글이 같아야 한다. 모든 화면은 `turn` 대신 `d.view(turn)` 을 그린다.
- `assets/data/version.json`: `assets/data/` 안의 데이터가 하나라도 바뀌면 `db` +1 과 `log` 한 줄(지금 3 → R 폴더 첫 묶음 때 4). 음성·그림은 번호와 무관(서버 매니페스트가 버전).

## 4. 화면별 작업

### 4-1. 회화 리더 + 음성(일본어앱 이식)
- `lib/services/dialogue_audio.dart` 복사: `t.ja`→`t.tl`, `t.kana`→`t.rd`, `LearnerPrefs.voiceGender` 그대로, `covers(d)`(이름 자리 턴에 음성이 있으면 이름을 묻지 않음) 유지.
- `content_sync.dart`: `audioManifestUrl = 'https://auth.talkverse.uk/art/es/audio/manifest'`, `AudioLine`, `audioIndex`(편→턴→m|f), 음성 키도 `_wanted` 에 넣어 같은 폴더·같은 버전으로 받기, `estimate` 에 `audio/` 수. 매니페스트 실패 시 그림 동기화는 그대로(일본어앱 규칙).
- `episode_play_pane.dart` `_speakOne`·자동 재생 → `speakTurn(d, t, rate:)`(음성 우선, 없으면 `TtsService`). `dialogue_card_screen.dart` 「듣기」도 같은 함수. `audioplayers` 는 이미 pubspec 에 있다.
- 리더 자막 줄: `TapWords`(레마 탭 → `word_sheet`) 유지, 그 아래 **morph 칩**(§4-4) 한 줄 추가, `VerbChips` 는 그대로.

### 4-2. 레벨 길(`level_path_screen.dart`, 신규)
- `levels.json` 을 읽어 레벨 카드 6개 → 단계 줄. 단계 줄 = 핵심 편(`AchievementService.isDone` 체크) · 말 조각 덱(외운 n/450, `memorized_store.dart` 재사용) · 잠금(`LevelAccess`). 넓은 화면은 왼쪽 칸 목록 → 오른쪽 칸 상세(`openPane`), 재생은 `openFull`(지금 규칙).
- 레벨 머리줄에 「단어 상한: 단어 구간 R4(570위) 안」처럼 `vocab_cap` 을 보여 2-3 의 구분을 눈에 남긴다.

### 4-3. 말 조각 덱(`variant_deck_screen.dart` + `variant_service.dart`, 신규)
- 뺑뺑이: 덱의 카드를 섞어 앞면 `tl`(성별판) + 음성, 뒷면 `ko` + morph 칩 + 「원문」(core 턴으로 점프). 「외웠다/다시」 두 버튼 → `memorized_store.dart`. 레이아웃은 `dialogue_card_screen.dart` 의 `_CardArt`·`_CardText`·`_Btn` 재사용.
- 트랙 A/B(전달문 A-보): 규칙 카드와 불규칙 통문장 카드(8동사: ser·estar·ir·tener·hacer·poder·querer·decir)는 덱 안에서 `track: "irregular"` 로 구분하고 인칭표를 띄우지 않는다.

### 4-4. 「성·수」 자막(morph 칩, `lib/widgets/morph_chips.dart`, 신규)
- 턴 `morph` 중 `focus` 에 맞는 낱말만 칩: 성(남 파랑·여 빨강 — `docs/DIALOGUE.md` 색 규칙), 수(단·복), 인칭(1·2·3·usted). 전역 토글은 `KoReadingPrefs` 와 같은 틀로 `MorphCaptionPrefs`(프로필 설정 줄 + 리더 앱바 버튼). 레벨 1·2 는 단수만 나오므로 칩이 단순하고, 레벨 3 에서 복수·usted 칩이 처음 보인다(A3 체감).

### 4-5. 성별판
- `d.view(turn)` 이 `tl_f`·`rd_f`·`ko_f` 를 고르고, 장면 컷은 이미 `<편id>_f` 우선(`content_sync.sceneIndex`). 변형 카드도 `tl_f` 있으면 같은 규칙. 프로필에서 성별을 바꾸면 `LearnerPrefs.gender` 리스너로 즉시 다시 그림.

### 4-6. 절벽 단어 교차 링크
- `word_sheet.dart`(레마 탭)에 「이 레벨 상한 안/밖」 한 줄(`levels.json vocab_cap` 과 `cliff.dart regionOf`). `tools/conv_words.py` 는 편이 늘 때마다 다시 돌려 `conv_words_es.json` 갱신.
- 「나」(프로필) 성과 데스크(`achievement_desk.dart`)에 「레벨 n · 단계 k」 진행 한 줄.

## 5. 도구·파이프라인

### 5-1. 검사기 `tools/check_dialogues.py` 추가 규칙
- **레벨 어휘 상한**: 턴 `lemmas` 의 레마 순위(`lang_es_top.csv`) > 그 레벨 `vocab_cap` 이면 오류, 편당 1개까지 허용(`new` 에 있어야 함, B3). 표현 풀 낱말·`{name}` 등 변수·고유명사는 세지 않음.
- **단수만(R1·R2, A3)**: `morph` 에 `Number=Plur` 인 동사·2인칭 대명사(vosotros·os·vuestro)가 있으면 오류.
- **말투(A4)**: R1·R2 는 `register` 가 `casual`/`chat` 이어야 하고 usted 형(`usted`·`Perdone`·3인칭 명령형 -e/-a 에 2인칭 뜻)이 보이면 오류. **A4 답이 나오기 전에는 경고로만 출력**(가게 tú 장면 허용 여부 미정).
- **챗 실전(A5)**: R2 묶음에 `kind: chat` 비율 50% 이상(묶음이 생기면 적용).
- `levels.json` 대조: 편 id 가 어느 단계에도 없으면 오류, `stage` 칸 자동 보정(`--fix-stage`).
- 변형 덱 검사(`--decks`): 카드 수 = 핵심×9 ±10%, `core` 가 실제 턴을 가리키는지, 각 카드 `morph`·`focus` 비어 있지 않은지.

### 5-2. 형태 태깅 `tools/tag_morph.py`(신규, `add_lemmas.py` 와 한 venv)
- 입력 `assets/data/dialogues/R*/*/*.json` + `assets/data/variants/R*/*.json`(지금 `add_lemmas.py` 는 옛 `*.json` 만 봄 — 함께 고침). spaCy `es_core_news_md` 로 `lemmas`(3칸)·`morph`(4칸) 둘 다 채우고, 단계 `slot` 에 맞는 낱말로 `focus` 를 제안.
- 출력 검수표 `data/review/write/morph_review.csv`(편·턴·낱말·태그·의심 사유: 대문자 고유명사, clitic 붙은 동사 `dímelo`, `se` 다의성) → Claude 검수 뒤 `morph_manual: true` 로 고정(독음 `rd_manual` 과 같은 방식).

### 5-3. 변형 선별 `tools/select_variants.py`(신규)
- 입력: 후보 풀 CSV(**저장소 밖** `~/talkverse/_corpus/es/pool_R<n>.csv`, `.gitignore` 에 `_corpus/`) + 단계 `slot` + 레벨 어휘 상한.
- 점수(전달문 A-보): 레벨 1·4 = 빈도 20 · 격/활용 시연 35(`slot` 과 맞는 morph 가 몇 개) · 양태 15 · 시제 10 · 단순성 15(단어 수·절 수). 레벨 2·5 = 빈도 50 + 나머지 균등. 불규칙 동사는 트랙 B 로 따로.
- 출력: 상위 후보 `data/review/write/variants_R<n>_s<k>.csv` → Claude 가 **자체 문장으로 다시 써서** 덱 JSON 저장(원문은 저장소에 넣지 않음) → `tag_morph.py` → `check_dialogues.py --decks` → 리뷰 → 통과.

### 5-4. 음성(변형 포함)
- `tools/tts/make_plan.py`·`ttslib.py` 가 덱 JSON 도 읽게(`cards[]` 의 `tl`·`tl_f`·`emotion`, 편 id = 덱 id). 나머지(`make_jobs → qa → pack --upload`)는 그대로, 품질 기준은 `~/talkverse/ja/docs/DIALOGUE_AUDIO.md` §5(유사도 ≥0.90, 쉼 ≤0.25초, 참고 음성 ≤-60dB).
- 양 추정: 레벨당 500문장×m/f = 1,000줄, 5레벨 5,000줄 ≈ 일본어 215편(4,384줄, 약 9시간 3090) 수준 → 레벨 단위로 나눠 돌린다.

### 5-5. 리뷰 페이지·색인
- `tools/review_html.py` 에 덱 섹션(카드 = 한 줄 세 칸 + m/f 버튼). `data/tts/audio_es.json` 에 덱 줄도 들어가게.
- `tools/build_dialogue_index.py`(§3-4) → `index.json` + pubspec 검사. 편·덱을 더하면 순서: `tag_morph → check_dialogues → conv_words → build_dialogue_index → version.json db+1`.

## 6. 단계별 빌드 순서

| # | 단계 | 산출물 | 확인 | 배포 |
|---|---|---|---|---|
| **0** | **지금(콘텐츠 무관 코드)** | `levels.json`(R1 10단계 이름만, 편 자리 4편) · `build_dialogue_index.py` + pubspec 하위 폴더 · `dialogue_service.dart` 새 형식+`view()`+`tlF/rdF/koF/segs/morph/focus` · `dialogue_audio.dart` 이식 + `content_sync.dart` 음성 매니페스트 · 리더·카드의 `speakTurn` · `level_path_screen.dart`(잠금 꺼짐) · `morph_chips.dart`(데이터 없으면 숨김) · `about_screen.dart` 문구 · 사전 3개 | `flutter analyze` 0 · 시뮬레이터 복구 뒤 `integration_test/dialogue_pane_test.dart`(아이패드 두 칸·리더·음성 버튼, 넘침 0) · 디바이스에서 4편 음성 102줄 재생·성별 전환 | **초안 4편이 통과 전이라 보류** — 사용자가 「초안 그대로 올려도 됨」이라 하면 Zealot+TestFlight 함께(§7-4) |
| 1 | 지금(도구) | `check_dialogues.py` 새 규칙(상한·단수·말투 경고·levels 대조·`--decks`) · `tag_morph.py` · `add_lemmas.py` R 폴더 읽기 · `select_variants.py` 뼈대(풀 없어도 돌아감) · `review_html.py` 덱 섹션 · `make_plan.py` 덱 읽기 | 4편에 `tag_morph` 돌려 `morph_review.csv` 생성, 검사기 오류 0(A4 경고만) | 없음(도구) |
| 2 | 지금 가능한 콘텐츠(한도 안) | **R0 짧은 회화 1편**(레벨별 한 편 한도 안, 반말·단수) — 사용자 지시 뒤 착수 · `CHARACTERS.md` 조연은 Grok 뒤 | 검사기 0 · 리뷰 페이지 | 없음 |
| 3 | 사용자 통과(Grok 11/10 뒤, 지시 때) | Grok 재작성 → 리뷰 → `approved` → 장면 컷 → `version.json` db 4 | 리뷰 페이지 통과, `conv_words` 갱신 | **첫 릴리스**: 레벨 길 + 음성 리더 + 4~5편. Zealot `tools/zealot_push.sh` + `tools/ios_release.sh` 함께, 빌드 번호 규칙 CLAUDE.md §8 |
| 4 | 동결 해제 뒤 — A12 ①② | `data/levels/R1_vocab.csv`(코어 40, 기능어/내용어) · `skeleton_map_es.json`(매핑표) · `levels.json` 각 단계 `slot` 확정 | 사용자 통과 | 매핑표 화면 추가 시 함께 배포 |
| 5 | A12 ③ | R1 핵심 50(10단계 × 회화 편) · 라임 편(외계인 시트 뒤) | 검사기(단수·casual·상한) 0 → 리뷰 → 통과 | 잠금 켜기(`free_stages: 2`) + 페이월 문구 → **배포(결제 심사 문안 `docs/store/review_notes.md` 갱신)** |
| 6 | A12 ④ | R1 덱 10개(450) — 선별 → Claude 정제 → 태깅 → 음성 | `--decks` 0, 음성 QA, 리뷰 | 덱 화면 첫 배포 |
| 7 | A12 ⑤ | 기존 R1~R4 편 재태그·코어 밖 단어 교체·A4 결과 반영(C-2 표) | 검사기 0 | 데이터만 — db+1, 배포 |
| 8 | A12 ⑥ | R2 챗 실전(채팅 편 `ui: bubble`) → R3 그래머2(새 단어 0, R1 핵심을 복수·usted 로) → R4 → R5 | 레벨마다 핵심 통과 → 변형 | 레벨마다 한 번 |

각 배포 공통: `[skip ci]` 는 문서만 · APK 서명 SHA-1 `9C:C4:…:47:6B` 확인(`zealot_push.sh` 가 막음) · PC `D:\OneDrive\app project\` 백업 · HANDOFF 갱신.

## 7. 위험 · 결정 필요(사용자)

1. **레벨 어휘 상한 매핑** — 전달문 A1 은 「절벽 tier = 상한」이지만 R1 tier 45어로는 회화가 안 된다(`docs/DIALOGUE.md` 는 R1=570·R2=1,000·R3=2,000). 제안: 레벨 0·1 ≤570(R4 끝) · 레벨 2·3 ≤1,000 · 레벨 4 ≤2,000 · 레벨 5 = 571~2,000 완주. `levels.json vocab_cap` 값으로 결정만 받으면 된다.
2. **A4 가게 tú**(대기) — 허용이면 `r1_love_a1` 유지·검사기 usted 만 금지 / 원문대로면 R1·R2 편을 친구 장면으로 교체(단계 7) · 검사기 「낯선 사이」 금지로 강화.
3. **A6 어휘 완주 1,430**(대기) — 500 출시면 R5 = 571~1,070위 덱 1개 레벨 · 나머지 v2.0 「파생어」 메뉴 / 1,000 이상 B 면 R5 를 두 레벨(5-A·5-B)로 `levels.json` 에 추가.
4. **초안 4편을 통과 전에 앱에 넣어 배포할지** — 단계 0 코드가 끝나면 릴리스 가능하나 내용은 `draft: claude`. 안 올리면 첫 릴리스는 단계 3 뒤.
5. **옛 `L1.json`·`conversation_screen.dart`·`episode_screen.dart` 삭제** — 새 로더가 들어오면 안 읽히는 파일. 지우려면 지시.
6. **평생 이용권 범위** = A10(레벨 1 3단계부터) 로 확정할지(HANDOFF §3-1 「수요일」 건).
7. **외계인 캐릭터 시트** 위치·제작(uk 세션) — 라임 편·페이월 장면이 이것에 걸려 있음.
8. **R2 기존 편 처리**(C-2) — `r2_life_b1` 은 채팅 편이 아니고 vosotros·Perdone 사용 → 레벨 3 이동 또는 채팅 장면 재작성. `r3_friends_b1` 의 접속법은 씨앗으로 둘지.
9. **코퍼스 풀 위치** — 공개 저장소 밖 `~/talkverse/_corpus/es/` 제안(백업은 PC `D:\`), 저장소에는 자체 작문 결과만.
10. **매핑표·코어 40 이 「회화 밖 콘텐츠」동결에 걸리는지** — 걸리면 단계 4 는 해제 뒤, 아니면 지금 시작 가능.
11. 음성 분량(레벨당 1,000줄)이 PC 3090 시간을 레벨당 2시간쯤 쓴다 — 세무 학습 등 3090 우선 작업과 겹치면 순서 조정.
