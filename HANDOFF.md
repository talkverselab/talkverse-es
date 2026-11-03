# HANDOFF — talkverse-es (스페인어유니버스)

_2026-11-03 새벽 전체 다시 씀. 규칙은 `CLAUDE.md`, 인물은 `CHARACTERS.md`, 회화 원칙 링크·특이점은 `docs/DIALOGUE.md`._

## 1. 지금 상태

| 항목 | 상태 |
|---|---|
| 저장소 | `master` = `af69ce3`. **2026-11-03 이력 정리 강제 푸시 완료**(시판 교재에서 뽑은 단어·표현 파일·파서·메모·커밋 메시지의 책 이름을 모든 이력에서 제거, 태그 4개도 다시 씀). 다른 기기·세션의 옛 복사본은 `git fetch && git reset --hard origin/master` 필요 |
| Android | CI 빌드 **9**(`latest`), Zealot 「스페인어유니버스」 https://apps.talkverse.uk/CFaiv/207 , PC `D:\OneDrive\app project\talkverse-es\talkverse-es-latest.apk` |
| iOS | TestFlight 업로드 **빌드 2611030107**(App Store Connect 앱 레코드 사용자 생성 완료). 번들 ID `com.talkverse.spanishUniverse`, IPA 백업 PC `D:\OneDrive\app project\spanish_universe\ios\` |
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
- 아이패드 스크린샷 테스트 `integration_test/dialogue_pane_test.dart` + `tools/pane_shots.py <UDID> <스크래치 폴더> integration_test/dialogue_pane_test.dart`(넘침 0, 통과). 이 세션 시뮬레이터 `es-shots-ipad`(7BE0AF82…).

## 3. 사용자 결정 / 기다리는 것

1. **평생 이용권이 열 기능** — 사용자 「수요일」(2026-11-03 답, 그날 정할 것으로 이해). 정해지기 전에는 잠그지 않는다. 아무것도 안 열면 App Store 심사(3.1.1)에 걸릴 수 있음.
2. **회화 작성 금지 중**(공통 프롬프터 §0-1) — 회화·예문 새로 쓰지 말 것. 풀리면 `docs/DIALOGUE.md` + 회화 공통 원칙대로 R1~R4 구조로 다시 쓰고(지금 L1 은 옛 인물 Minjun·Lucía, 20턴, 독음 없음), 장면 컷 요청(편당 4장, `CHARACTERS.md` 첨부).
3. 스토어 콘솔(사용자): App ID 에 Sign in with Apple capability, 인앱 상품 등록, Play 판이면 `REQUEST_INSTALL_PACKAGES`·「앱 업데이트」 타일 빼기.
4. 비어 있는 주제별 단어·표현(`assets/data/vocab/travel_*.json`) — 저작권 정리로 비움, 자체 제작으로 채울 것(콘텐츠 금지 풀린 뒤).

## 4. 다음 할 일(순서)

1. TestFlight 처리 확인 → 아이패드에서 두 화면·동사 칩·로그인(데모 계정)·구매 시트 확인. IPA 의 `applesignin` 확인: `codesign -d --entitlements :- Payload/Runner.app | grep applesignin` — 없으면 포털 capability(사용자).
2. 이용권 범위가 정해지면 `Entitlement.premium` 으로 잠금 + 잠금 시트 혜택 문구 + 심사 메모 갱신.
3. 성·수 / 발음 화면(「준비 중」), 성·수 일치 표시는 회화 데이터 `tags` 가 생긴 뒤.

## 5. 공통 절차(요약)

- 커밋은 경로 지정만(`git add -A` 금지). 빌드 뒤 잡음 되돌리기: `analysis_options.yaml`·`android/gradle.properties`·`ios/Flutter/*.xcconfig`·`project.pbxproj`(Pods 줄)·`Runner.xcscheme`·`Runner.xcworkspace/contents.xcworkspacedata`, untracked `ios/Podfile*`·`**/swiftpm/` 는 그대로 둔다.
- Android 배포: 코드 푸시 → CI(빌드 번호 = 실행 번호) → `gh release download latest -p app-latest.apk -O build/app/outputs/flutter-apk/app-release.apk` → `bash tools/zealot_push.sh "<변경>"`(서명 확인 포함) → PC 백업.
- iOS: `bash tools/ios_release.sh` 백그라운드(빌드 번호 = KST 시각). `[skip ci]` 커밋은 CI 를 건너뜀.
- Grok 그림은 한자 세션을 통해(글 시안은 이 세션이 직접). 사용자 결정이 필요하면 PushNotification.
- (2026-11-03 사용자 지시) 직접 Grok·Gemini 를 쓸 땐 M4 `~/chrome-grok` 쿠키를 **M4 안에서** `~/chrome-grok-es/` 로 복사 → M4 에서 자기 포트(`GROK_CHROME_PORTS.md`)로 띄우고 M6 에서 `ssh -fN -L` 터널, 첨부는 M4 `/tmp/grok_att/es/`. 사용자 지시 있을 때만 켜고, 탭은 건마다 닫고 끝나면 Chrome 도 끈다. 상세 M6 `~/talkverse/GROK_M4_LOGIN.md`.
- (같은 날) 회화가 풀리면 반전 비율: 카오스 30% 이상 · 연애·플러팅 편마다 심쿵 한 줄(여성 주도 편 더 많이) · 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore) · 새 편은 왕초보·초급 위주 · 장면 컷 = A·B 쌍 1컷, 글자·말풍선 없음, 인물 시트 첨부. https://talkverse.uk/talkverse/dialogue-rules/
- 로컬에 2026-11-03 이력 정리 전 잡음 stash 하나 있음(`git stash list`, 줄바꿈 차이뿐 — 버려도 됨).
