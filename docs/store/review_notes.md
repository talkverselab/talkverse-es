# 심사 메모(App Review Notes) 초안 · 개인정보처리방침 추가 문안 — 2026-11-02

> 기준: 한자 앱 `docs/store/review_notes.md`(talkverse-hanja) 를 스페인어유니버스에 맞춘 것. 공통 가이드 M6 `~/talkverse/TALKVERSE_ID_APP_GUIDE.md`.
> **2026-11-09**: 출시는 Talkverse 통합 앱 하나(언어앱 개별 출시 없음). 상품은 6개로 바뀜(`docs/STORE_PRODUCTS.md`) — 아래 [인앱 구입] 문장은 옛 평생 이용권 기준이라 통합 앱 심사 메모를 쓸 때 6개 기준으로 다시 쓴다. 4.3 문단은 위 첫 블록.

## App Store Connect "심사 정보 → 메모"

```
[Language-specific app — Guideline 4.3]
This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Spanish app has its own script & pronunciation module (27 letters incl. ñ, digraphs ch/ll/rr/qu/gu, Castilian sounds θ (ce/ci/z), x (j/ge/gi), tap r vs trilled rr and stress marks — 41 units with IPA, articulation and a Korean-vowel comparison), its own grammar tools (verb chips that turn any conjugated form in a dialogue line into infinitive · person · tense with a conjugation table for 30 core verbs; a grammar-stage path from article/gender agreement and ser/estar to the subjunctive; male/female learner versions of lines where Spanish agreement changes), [N] original conversation episodes with [M] recorded audio lines written for this language, and a vocabulary list measured from a Spanish conversation corpus (45 lemmas = 55% and 570 lemmas = 80% of dialogue). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.
([N]·[M] = 출시 때 실측으로 채움 — docs/store/listing.md §3)

[로그인] 로그인은 선택입니다. 모든 학습 기능은 로그인 없이 사용할 수 있고, 로그인은 구매 복원과 기기 간 이용권 공유에만 쓰입니다.
- 로그인 화면: 오른쪽 위 프로필 → 계정 → 로그인. Apple로 로그인 + 이메일 로그인(심사·테스트용).
- 데모 계정(이메일 로그인): review@talkverse.uk / 비밀번호: <Doppler keys/prd TALKVERSE_REVIEW_ACCOUNT 에서 복사해 여기 입력>
- 계정 삭제: 프로필 → 계정 → 계정 삭제(확인 창) → 서버에서 개인정보가 삭제되고 모든 기기에서 로그아웃됩니다.
[인앱 구입] 비소모성 "평생 이용권"(com.talkverse.spanishUniverse.lifetime) 1개. 프로필 → 계정 → 평생 이용권 → [평생 이용권 구매 ₩…], 복원은 [이전 구매 복원] 또는 프로필 → 구매 복원. Sandbox 계정으로 시험할 수 있습니다. 로그인 없이도 구매·복원이 됩니다.

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for restoring purchases across devices.
- Where: Profile (top right) → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler>
- Account deletion: Profile → Account → Delete account (confirmation) → personal data is deleted server-side and all sessions are revoked.
[IAP] One non-consumable "Lifetime Pass" (com.talkverse.spanishUniverse.lifetime). Profile → Account → Lifetime Pass → [Buy Lifetime Pass ₩…]; restore with [Restore purchases]. Works with a Sandbox account; sign-in is not required to buy or restore.
```

## 개인정보처리방침에 추가할 문안 (스페인어유니버스 방침 페이지 — talkverse.uk 세션 반영)
```
계정(선택)
스페인어유니버스는 로그인 없이 쓸 수 있습니다. Talkverse 계정으로 로그인하면 다음을 처리합니다.
- 수집 항목: 이메일 주소, 이름(Apple·Google 등 로그인 제공자가 전달하는 범위), 계정 ID, 로그인 시각·기기 식별 토큰.
- 목적: 로그인 유지, 구매(평생 이용권) 복원과 기기 간 공유, 고객 문의 응대.
- 보관: 계정 삭제 시 즉시 삭제(구매·주문 기록은 관계 법령에 따라 회계 목적으로 사용자 ID 만 남깁니다).
- 삭제 방법: 앱 → 프로필 → 계정 → 계정 삭제, 또는 https://talkverse.uk/account/delete
- 처리 위탁·국외 이전: 계정 서버는 Cloudflare(미국 등 글로벌 리전)에서 운영됩니다.

결제
평생 이용권 결제는 Apple App Store 또는 Google Play 가 처리하며, 앱은 카드 정보를 받지 않습니다. 앱은 구매 영수증(거래 번호·상품 ID)만 확인해 이용권을 적용합니다.
```

## IAP 상품 심사 스크린샷
- 평생 이용권 시트(프로필 → 평생 이용권) 캡처를 `docs/store/screenshots/iap_paywall.png` 로 두고 상품 등록 화면에 올린다(아직 없음).
