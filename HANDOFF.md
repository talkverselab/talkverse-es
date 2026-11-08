# HANDOFF — talkverse-es (스페인어유니버스)

_2026-11-03 새벽 전체 다시 씀. 규칙은 `CLAUDE.md`, 인물은 `CHARACTERS.md`, 회화 원칙 링크·특이점은 `docs/DIALOGUE.md`._

## 1. 지금 상태

| 항목 | 상태 |
|---|---|
| 저장소 | `master` 최신(2026-11-08 단어·메뉴 개편·회화 초안 58편·문법 배치). 아이패드 스크린샷 16장 넘침 0(2026-11-08). Grok 재개 11/9 13:30(사용자 지시). **2026-11-03 이력 정리 강제 푸시 완료**(시판 교재에서 뽑은 단어·표현 파일·파서·메모·커밋 메시지의 책 이름을 모든 이력에서 제거, 태그 4개도 다시 씀). 다른 기기·세션의 옛 복사본은 `git fetch && git reset --hard origin/master` 필요 |
| Android | CI 빌드 **13**(`latest`, 3120e1b), Zealot 「스페인어유니버스」 https://apps.talkverse.uk/CFaiv/369 , PC `D:\OneDrive\app project\talkverse-es\talkverse-es-latest.apk` |
| iOS | TestFlight 업로드 **빌드 2611081700**(이전 2611081628)(App Store Connect 앱 레코드 사용자 생성 완료). 번들 ID `com.talkverse.spanishUniverse`, IPA 백업 PC `D:\OneDrive\app project\spanish_universe\ios\` |
| 서명 | 기존 키 유지(SHA-1 `9C:C4:…:47:6B`), 백업 PC `D:\keys\talkverse-es\` + Doppler `SIGNKEY_*` — `CLAUDE.md` §1·§8 |
| Supabase | 앱은 처음부터 안 씀(`docs/CLOUDFLARE_MIGRATION.md`). 공용 `items` 에 옛 es 2,864행만 남음 — 삭제는 사용자 |

## 2. 만든 것(2026-11-02 ~ 03)

- **일본어앱 구조 옮기기**(공통 프롬프터 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`): 넓은 화면 = 레일 4탭(배우기·복습·탐색·나) + 왼쪽 칸 + 오른쪽 칸(`core/pane.dart`), 폰 = 하단 탭. 회화 리더(시안 02: 좌 스크립트·우 장면 컷·하단 컨트롤·완주 연출), 그림 카드, 「나」 성과 데스크, 프로필 「학습자 프로필」(이름·성별).
  - 회화 데이터는 바꾸지 않음 — `services/dialogue_service.dart` 가 옛 `L1.json` 을 읽어 변환(레벨 L1 「이야기」, 주제 love). 화자 목소리는 데이터 성별.
- **시안 ES-01 「동사 칩」**(사용자 통과 2026-11-03, `data/review/uxui/sian_es_01.*`): 캡션 아래 활용형 → 원형·인칭·시제, 누르면 현재·단순과거 시트, 「나」 탭 「만난 동사 n/30」. 데이터 = `assets/data/grammar/verbs_core.json`.
- **캐릭터 시트 v1**(통과 2026-11-03, `data/review/art/chars_es_v1.jpg`, `CHARACTERS.md`): Lucía·Marta·Javi·Diego·학습자 남/여, 마드리드.
- **Talkverse ID 로그인(선택) + 평생 이용권 인앱 결제**(한자 앱과 같은 구성, `data/account.dart`·`purchase.dart`·`entitlement.dart`, 로그인·결제 화면, 프로필 「계정」). client_id `es`, 딥링크 `talkverse.es://auth`, 상품 iOS `com.talkverse.spanishUniverse.lifetime` / Android `lang_es`. **지금 잠근 기능 없음.** 심사 문안 초안 `docs/store/`.
- **talkverse.uk 톤·아이콘**: 아이콘은 talkverse.uk 세션 담당(직접 고치지 말 것).
- **단어 그림 리스트**: `talkverselab/talkversehanja` `talkverse_art/words/es.csv`(2,500단어, R1 184·R2 157·R3 753·R4 1,406) · `es_food.csv`(50) → 그림 `GET https://auth.talkverse.uk/art/es/manifest`(앱이 자동 사용).
- **2026-11-04 공통 변경 8가지(일본어앱 9962316, 공통 프롬프터 §5-1)**: ① 장면 컷 말풍선 → 그림 **아래 띠**(`_LineStrip`), 재생 컷엔 말풍선 없음 ② 그림 카드 앞면에 한국어 뜻 ③ 턴 `lemmas`(`tools/add_lemmas.py`, spaCy) → 캡션·카드 뒷면 **레마 칩**(`lemma_chips.dart`, 단어장 = 빈도 단어표 `word_service.dart`·`word_sheet.dart`), 단어장에 없는 레마 `data/review/write/missing_lemmas.csv`(uk 세션에 전달) ④ 시작 때 그림 기기 내려받기 `content_sync.dart`·`sync_screen.dart`, 모든 그림 `artProvider()` ⑤ `assets/data/version.json` `db` 번호(지금 2) — 데이터 바꾸면 이 번호만 올림 ⑥ `{name}` 회화 열 때 이름 없으면 묻기(`learner_setup_dialog.dart`) ⑦ 여자 학습자면 `<편id>_f` 컷 먼저 ⑧ 조연 캐릭터 시트 — **Grok 대기 중이라 아직**(회화 작업이 풀리고 Grok 시작 지시가 오면 `CHARACTERS.md` 조연 정해서 시트 2장 요청).
- **2026-11-07 단어·메뉴 개편(일본어앱 `docs/MENU_WORDS_2026-11-07.md` §1·§3·§4·§6)**: 절벽 값 코드 한 곳 `lib/core/cliff.dart`(45·69·168·570 = R1~R4 끝 순위, R5 2,000위, 2,000위 누적 약 87.9% = 2,500위 88.9% 에서 2,001~2,500위 몫을 뺀 추정). 빈도 단어표 `assets/data/freq/lang_es_top.csv` 를 옛 200단어 → 레마 목록 2,506행(talkversehanja `words/es.csv` 그대로 — 새로 쓴 뜻 없음, 옛 표의 성·CEFR 만 같은 낱말에 붙임, `version.json` db 3). 레마는 러시아어 기준 그대로 둔다(사용자 2026-11-07). 절벽 단어 화면 = 20어 단원·타일·「회화 단어 포함」(`tools/conv_words.py` → `conv_words_es.json`), 앱 소개 `about_screen.dart`(레일 아래·프로필 정보), 배우기 순서 기초→문법→회화→단어, 탭 「나」 → 「프로필」, 「회화 노트」·앱 업데이트 타일·TTS·변종·테마·Stack 삭제(`conversation_screen.dart`·`update_screen.dart` 파일은 남음), 문장 레마 탭 → 단어창(`TapWords`), 한글독음 기본 미표시(`KoReadingPrefs.toggleFrom`; 지금 회화에 독음 데이터가 없어 앱바 버튼은 안 보이고 프로필 설정 줄만 있음). 문서 §2(문자 절벽) 해당 없음, §5(문장 말하기) 화면이 없어 해당 없음.
- **2026-11-08 기초 「알파벳과 발음」**(공통 프롬프터 §5-3, 일본어앱 50음도 구조): `alphabet_chart_screen.dart`·`widgets/alphabet_sound_sheet.dart`·`services/alphabet_es.dart`·`assets/data/grammar/alphabet_es.json`(41단위), 조음·모음 그림 `assets/images/ipa/`(임시 — 출시 전 Grok 그림으로 교체, 사용자 지시로 출처 표기 없음).
- 아이패드 스크린샷 테스트 `integration_test/dialogue_pane_test.dart` + `tools/pane_shots.py <UDID> <스크래치 폴더> integration_test/dialogue_pane_test.dart`(넘침 0, 통과). 이 세션 시뮬레이터 `es-shots-ipad`(7BE0AF82…).

## 3. 사용자 결정 / 기다리는 것

1. **평생 이용권이 열 기능** — 사용자 「수요일」(2026-11-03 답, 그날 정할 것으로 이해). 정해지기 전에는 잠그지 않는다. 아무것도 안 열면 App Store 심사(3.1.1)에 걸릴 수 있음.
2. **회화 초안 전편(2026-11-08, 제한·동결 둘 다 해제)** — 레벨 = 문법 단계(굴절어 전략 A1, `docs/DIALOGUE_RULES_es.md`·`tools/prompts/dialogue_es.md` 레벨 표): R0 8 · R1 10 · R2 10(채팅) · R3 10(R1 의 복수·존댓말판) · R4 10(문법 10) · R5 10(주제 10) = **58편**(`stage` 칸 있음), 옛 번호 4편(`stage` 없음, 음성 있음)은 별도. 검사기 오류 0, 리뷰 `data/review/REVIEW_es.html`. 다음 = Grok 완전 재작성(11/10 뒤) → DB 반영(로더·pubspec·`levels.json`, 빌드 전략 `docs/APP_BUILD_STRATEGY_es.md`). 옛 메모:  — 굴절어는 **레벨별 한 편씩만** 쓰고 멈춤. R1~R4 각 1편 작성 완료(`assets/data/dialogues/R<n>/<주제>/`, `draft: claude`, `tools/check_dialogues.py` 통과, 규칙 `tools/prompts/dialogue_es.md`, 독음 `tools/rd_es.py`, 표현 풀 `data/expressions/top_expressions_es.csv`). **앱에는 아직 안 들어감**(pubspec 은 하위 폴더를 안 묶고 `dialogue_service.dart` 는 L1 만 읽음). 음성 4편 102줄 R2·D1 업로드(MOSS, `tools/tts/`, 감정은 회화 파일 `emotion`·`segs` → `make_plan.py`, 작업 폴더 M6 `~/tts_work/es`, 기준 미달 2조각 `r3_friends_b1` 15턴 Claro · `r4_work_b1` 5턴 Somos cuatrocientos), 리뷰 `data/review/REVIEW_es.html`. 다음 = Grok 재작성(11/10 뒤, 사용자 지시 있을 때) → `tools/add_lemmas.py` 를 편 JSON 형식에 맞춤 → 로더·pubspec → 리뷰 → 장면 컷. 단어·문법 동결은 그대로.
3. Play 프로텍트 「피싱」 경고(스토어 밖 설치 + 개발 키 + 로그인 화면 조합이면 뜸, 앱은 안전) — 근본 해결은 이메일 칸 숨기기 또는 Play 내부 테스트 배포, 사용자 결정.
3-1. 스토어 콘솔(사용자): App ID 에 Sign in with Apple capability, 인앱 상품 등록, Play 판이면 `REQUEST_INSTALL_PACKAGES`·「앱 업데이트」 타일 빼기.
4. 조연 캐릭터 시트(§5-1 ⑧) — Grok 대기 해제 뒤. 회화 금지가 풀려 새 편을 쓰면 `tools/add_lemmas.py` 를 다시 돌려 `lemmas` 를 채우고 `version.json` 번호를 올린다.
5. 비어 있는 주제별 단어·표현(`assets/data/vocab/travel_*.json`) — 저작권 정리로 비움, 자체 제작으로 채울 것(콘텐츠 금지 풀린 뒤).

## 4. 다음 할 일(순서)

1. TestFlight 처리 확인 → 아이패드에서 두 화면·동사 칩·로그인(데모 계정)·구매 시트 확인. IPA 의 `applesignin` 확인: `codesign -d --entitlements :- Payload/Runner.app | grep applesignin` — 없으면 포털 capability(사용자).
2. 이용권 범위가 정해지면 `Entitlement.premium` 으로 잠금 + 잠금 시트 혜택 문구 + 심사 메모 갱신.
3. 성·수 / 발음 화면(「준비 중」), 성·수 일치 표시는 회화 데이터 `tags` 가 생긴 뒤.

## 5. 공통 절차(요약)

- 커밋은 경로 지정만(`git add -A` 금지). 빌드 뒤 잡음 되돌리기: `analysis_options.yaml`·`android/gradle.properties`·`ios/Flutter/*.xcconfig`·`project.pbxproj`(Pods 줄)·`Runner.xcscheme`·`Runner.xcworkspace/contents.xcworkspacedata`, untracked `ios/Podfile*`·`**/swiftpm/` 는 그대로 둔다.
- (사용자 지시 2026-11-07) 앱을 고치면 Android(Zealot)·iOS(TestFlight)를 항상 함께 올린다.
- Android 배포: 코드 푸시 → CI(빌드 번호 = 실행 번호) → `gh release download latest -p app-latest.apk -O build/app/outputs/flutter-apk/app-release.apk` → `bash tools/zealot_push.sh "<변경>"`(서명 확인 포함) → PC 백업.
- iOS: `bash tools/ios_release.sh` 백그라운드(빌드 번호 = KST 시각). `[skip ci]` 커밋은 CI 를 건너뜀.
- Grok 그림은 한자 세션을 통해(글 시안은 이 세션이 직접). 사용자 결정이 필요하면 PushNotification.
- (2026-11-03 사용자 지시) 직접 Grok·Gemini 를 쓸 땐 M4 `~/chrome-grok` 쿠키를 **M4 안에서** `~/chrome-grok-es/` 로 복사 → M4 에서 자기 포트(`GROK_CHROME_PORTS.md`)로 띄우고 M6 에서 `ssh -fN -L` 터널, 첨부는 M4 `/tmp/grok_att/es/`. 사용자 지시 있을 때만 켜고, 탭은 건마다 닫고 끝나면 Chrome 도 끈다. 상세 M6 `~/talkverse/GROK_M4_LOGIN.md`.
- (2026-11-03 사용자 지시) **Grok 작업은 사용자가 따로 지시할 때까지 시작하지 않는다.** M4 Grok 은 새 계정(원본 `~/chrome-grok`, 9222; 옛 계정은 11/9 까지 한도, 새 계정엔 프로젝트·챗·GitHub 커넥터 없음). 시작할 땐 ① M4 안에서 `~/chrome-grok` 쿠키 다시 복사 ② 샘플 1~2개 먼저 ③ PushNotification 으로 사용자 통과 요청 ④ 통과 뒤 본작업.
- Grok 회화 재작성·장면 컷 요청문 작성법(실제 통과 방식): M6 `~/talkverse/GROK_PROMPT_GUIDE.md`, 틀 파일 `~/talkverse/zh/tools/`(prompts/rewrite_grok.md·rewrite_request.py·scene_prompts.py·grok_*.py) 복사해 코드만 바꿈. 편마다 새 대화방, 받은 재작성은 그대로 쓰지 말고 리뷰.
- 스페인어 절벽 = 자국 영화·드라마 대사 레마 기준 **R1 45 · R2 69 · R3 168 · R4 570(상위 2,500 레마 88.9%)** — 사용자 결정 2026-11-03. 단어 그림 리스트 talkversehanja `talkverse_art/words/es.csv`(42c80fc)도 이 순위. 앱 단어표는 2026-11-07 이 목록으로 바꿈.
- (같은 날) 회화가 풀리면 반전 비율: 카오스 30% 이상 · 연애·플러팅 편마다 심쿵 한 줄(여성 주도 편 더 많이) · 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore) · 새 편은 왕초보·초급 위주 · 장면 컷 = A·B 쌍 1컷, 글자·말풍선 없음, 인물 시트 첨부. https://talkverse.uk/talkverse/dialogue-rules/
- 로컬에 2026-11-03 이력 정리 전 잡음 stash 하나 있음(`git stash list`, 줄바꿈 차이뿐 — 버려도 됨).
