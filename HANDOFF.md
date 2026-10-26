# HANDOFF — talkverse-es (스페인어 앱)

## 2026-10-26 — talkverse.uk 톤·아이콘, 빌드 5

- 아이콘 「Ñ」(메시 바탕·하늘색→인디고 강조선)과 화면 톤(흰 바탕·남색 글자·인디고 포인트)으로 바꿈 — `CLAUDE.md` §9.
- 서명 키는 기존 키 유지(SHA-1 `9C:C4:…`), PC `D:\keys\talkverse-es\` 에 백업. 로컬 빌드 번호 = 다음 CI 실행 번호로 맞추기로 정리(`CLAUDE.md` §8) — 아래 "확인 필요" 1·3번은 이것으로 정리됨.
- 남은 것: 작업 트리의 줄바꿈(CRLF) 잡음 35개 파일은 그대로(커밋하지 않음). `CLAUDE.md` 의 화면 표(문법·문장 카드·말하기·청크 검색·단어 카드)에 적힌 화면 파일이 `lib/screens/` 에 없다 — 공용 키트 이식이 이 저장소에 실제로 들어왔는지 확인 필요.

## Zealot 설정 — 확인 필요 (2026-10-11)

설정만 했다(빌드·업로드·커밋·푸시 없음). `CLAUDE.md` §8, `tools/zealot_push.sh` 참조. 사용자가 정할 것:

1. **로컬 빌드 번호 규칙** — CI 릴리스가 빌드 4인데 `pubspec.yaml` 은 `+1` 이다. 그대로 로컬 빌드해 Zealot 에 올리면 폰(빌드 4)에 덮어 설치가 안 된다(버전 낮춤). 반대로 번호를 크게 주면(예: 100) 앱 안 「앱 업데이트」가 CI 빌드를 새 빌드로 보지 않게 된다(CI 실행 번호가 그 수를 넘을 때까지). 방법 후보: ⓐ Zealot 에는 CI 가 만든 APK(`latest` 릴리스)를 내려받아 그대로 올린다 — 번호가 하나로 유지됨 ⓑ 로컬 빌드는 CI 번호 + 1 로 하고 곧바로 푸시해 CI 가 따라오게 한다.
2. **Zealot 앱이름** — 앱 표시 이름 「스페인어유니버스」로 정했다. 다른 언어 앱과 이름 규칙을 맞추려면(예: "Talkverse ES") 첫 업로드 전에 `CLAUDE.md` §8 과 스크립트의 `APP_NAME` 을 바꾼다.
3. **맥미니의 서명 키** — 이 폴더의 `android/app/signing-key.jks` 는 맞는 키(SHA-1 `9C:C4:…:47:6B`)지만, 맥미니의 `~/.android/debug.keystore` 는 다른 키(`BE:B3:…:0B:81`)다. 이 폴더의 jks 가 맥미니에 있는 유일한 사본일 수 있으니(git 에 없음) 지우지 말 것. 다른 언어 앱 폴더에 `key.properties` 가 없으면 §1 의 `cp` 대신 이 jks 를 복사해야 한다.
4. 맥미니에 `apksigner`(Android SDK build-tools)가 보이지 않는다 — 스크립트의 서명 확인은 건너뛰어지고, 로컬 빌드 환경(Android SDK)도 첫 빌드 전에 확인이 필요하다.

## 다음에 할 내용 (2026-10-11)

_세션 정리용 점검 메모. CLAUDE.md · CLAUDE_UPDATES.md · git 기록 · 작업 트리만 읽고 썼다(코드·빌드·커밋·푸시 없음)._

### 현재 상태

- 브랜치 `master`, 로컬 추적 정보 기준 `origin/master` 와 같은 커밋(`1512649`, 2026-09-12). 그 뒤 한 달간 커밋 없음. (`git fetch` 는 하지 않았다 — 원격에 새 커밋이 있는지는 미확인.)
- 마지막 작업 묶음(2026-09-10 ~ 09-12): 앱 안 업데이트(GitHub 릴리스) + CI 서명 고정 → 새 화면 6개(문법·문장 카드·말하기·청크 검색·단어 카드 등, 공용 키트 port6) → 표시 언어 4종 + 갤럭시·아이폰 공용 인터페이스 + iOS 빌드 초안.
- 작업 트리에 수정 표시 35개(`.gitignore`, `CLAUDE_UPDATES.md`, `analysis_options.yaml`, `android/**`, `ios/**`, `assets/data/vocab/travel_*.json`)가 있지만 **내용 변경은 없다** — 전부 줄바꿈(LF → CRLF) 차이뿐이다(`git diff -w --ignore-cr-at-eol` 결과 비어 있음, 13,800줄 추가 = 13,800줄 삭제). 윈도우에서 복사해 오면서 생긴 것으로 보인다(추정).
- `pubspec.yaml` 버전 `0.1.0+1`. 실제 빌드 번호는 CI 실행 번호가 쓴다.
- 이 파일(`HANDOFF.md`)은 새로 만든 것이라 아직 git 에 올라가 있지 않다.

### 남은 일 (순서대로)

1. **줄바꿈 차이 정리** — 35개 파일은 내용이 같으므로 되돌리는 것(`git checkout -- .` 또는 `git stash`)이 맞아 보인다. 되돌리기 전에 `git diff -w --ignore-cr-at-eol --stat` 가 여전히 비어 있는지 다시 확인. 재발 방지로 `.gitattributes`(`* text=auto eol=lf`) 추가를 검토.
2. **공개 저장소 출처 점검(CLAUDE.md §4)** — `CLAUDE_UPDATES.md` 11~12행과 커밋 `87062be` 제목, `tool/` 의 파서 파일 이름에 교재 이름과 OneDrive 경로가 그대로 남아 있다. `travel_words.json`(1,349개)·`travel_expressions.json`(796개)도 그 교재에서 뽑은 것으로 적혀 있어, CLAUDE.md 의 "자체 제작 초안, 단어 40개" 서술과 맞지 않는다. 어느 쪽이 현재 사실인지 확인하고, 문서·파일명 정리와 히스토리 처리 여부는 사용자가 결정.
3. **콘텐츠 확장** — 회화 5편 × 8턴, 문법 10패턴 × 예문 3은 초안이다. `_update_kit/content/es.py` 를 고치고 `build_content.py` 로 다시 만든다.
4. **준비중 메뉴** — 홈의 「성·수」, 「발음」 화면 구현.
5. **iOS** — Apple Developer Program 이 2026-10-10 에 가입됐으므로 TestFlight 경로가 열렸다. 전역 규칙대로 맥미니에서 빌드·서명·업로드(`~/interval-camera/tools/ios_release.sh` 를 복사해 씀). 번들 ID 가 `com.talkverse.<앱>` 규칙에 맞는지 확인, App Store Connect 앱 레코드 생성과 내부 테스트 그룹 추가는 사용자 몫. 리포의 `ios-testflight.yml`(CI 경로)을 계속 둘지도 그때 정리.
6. **Zealot** — 다음 APK 빌드 때 `~/bin/zealot-upload` 로 올리고, 쓴 앱이름을 CLAUDE.md 에 적는다(아직 이 앱의 이름이 정해져 있지 않다).
7. `CLAUDE_UPDATES.md` 는 2026-09-05 에서 멈춰 있다 — 2번을 정리할 때 CLAUDE.md 로 합치거나 갱신.

### 주의할 점

- **서명 키를 새로 만들지 말 것**(CLAUDE.md §1). 로컬 `~/.android/debug.keystore` 와 리포 시크릿이 같은 키다. 서명이 바뀌면 폰에서 앱을 지워야 하고 학습 기록이 사라진다. 맥미니에 이 키(SHA-1 `9C:C4:…:47:6B`)가 있는지는 확인하지 않았다 — 로컬 릴리스 빌드 전에 `keytool` 로 먼저 확인.
- `master` 푸시 = CI 가 릴리스를 올리고 폰에 업데이트 알림이 뜬다. `**.md` 만 바꾼 푸시는 빌드하지 않는다. 줄바꿈만 바뀐 `android/**`·`assets/**` 를 실수로 커밋하면 헛빌드가 돈다.
- 폰에 케이블로 설치할 때는 `adb install --user 0 -r`(듀얼 메신저 프로필에 복제 방지).
- 새 화면 6개와 l10n 사전은 **여러 언어 앱이 같은 코드**를 쓴다 — 고칠 때는 `talkverse/_update_kit/` 원본을 고치고 다시 배포. 이 앱은 fr·it·pt·de·tr·hu·hi·fa 의 템플릿이기도 하다.
- 공개 저장소다 — 이 파일을 포함해 새로 쓰는 문서에 교재·자막 출처 이름을 적지 말 것.
