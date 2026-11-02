# 데이터 안전 / 앱 개인정보 보호 답안 (2026-11-02 — 로그인·인앱 구입 포함)

근거(앱 사실): **Talkverse 계정 로그인은 선택**(Google·네이버·카카오·Apple, 이메일(데모) 로그인; 서버 auth.talkverse.uk = Cloudflare). 로그인하면 이메일·이름(제공자가 주는 범위)·계정 ID·세션 토큰을 서버에 저장. **인앱 구입** 1개(비소모성 평생 이용권) — 결제는 App Store/Google Play 가 처리, 앱·서버는 영수증(거래 번호·상품 ID)만 확인. 학습 기록·설정은 기기 안(SQLite·shared_preferences)에만. 앱 업데이트 확인은 GitHub 릴리스(Android 만). 광고·분석·크래시 SDK 없음. 추적 없음.
기준: 한자 앱 `docs/store/data_safety.md`.

## App Store — 앱 개인정보 보호(App Privacy)
| 질문 | 답 |
|---|---|
| 데이터를 수집하나요? | **예** |
| 연락처 정보 → 이메일 주소 | 앱 기능(계정 로그인·구매 복원) · 사용자와 연결됨 · 추적 아님 |
| 연락처 정보 → 이름 | 로그인 제공자가 넘기는 경우만 · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 식별자 → 사용자 ID | Talkverse 계정 ID · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 구매 → 구매 내역 | 이용권 복원·기기 간 공유 · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 그 밖(사용 데이터·진단·위치·오디오 등) | **수집 안 함** |
| 추적(ATT) | **아니요** |
| 개인정보처리방침 URL | 스페인어유니버스 방침 페이지(talkverse.uk 세션에 계정·결제 절 추가 요청) |

### Privacy Manifest(PrivacyInfo.xcprivacy) — 아직 없음, 한자 앱처럼 추가 필요
- `NSPrivacyTracking` = false, `NSPrivacyCollectedDataTypes`: EmailAddress·Name·UserID·PurchaseHistory(linked, not tracking, AppFunctionality). 필수 사유 API: UserDefaults `CA92.1`.

## Google Play — 데이터 보안(Data safety)
| 질문 | 답 |
|---|---|
| 수집·공유 | **예(수집)**, 공유 없음 |
| 수집 항목 | 이메일 주소·이름(선택, 계정 관리) · 사용자 ID(계정 관리) · 구매 내역(이용권 복원) |
| 전송 중 암호화 | 예(HTTPS) |
| 삭제 요청 | 예 — 앱 안 "프로필 → 계정 → 계정 삭제" + https://talkverse.uk/account/delete |
| 광고 / 광고 ID | 아니요 / 아니요 |
| 디지털 구매 | 예 — 인앱 구입 |

## 스토어 내기 전에 걸리는 것 (es 고유)
- **Android `REQUEST_INSTALL_PACKAGES` 권한**(앱 안 GitHub 업데이트용)은 Google Play 정책상 허용되지 않는 용도다 → Play 판에서는 이 권한과 「앱 업데이트」 타일을 빼야 한다.
- iOS `Info.plist` 의 마이크·음성 인식 권한 문구는 쓰는 화면(말하기 연습)이 이 저장소에 아직 없다 → 그대로 두면 심사에서 "쓰지 않는 권한" 질문을 받을 수 있다.
