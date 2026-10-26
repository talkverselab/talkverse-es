# Supabase → Cloudflare 이관 — 스페인어앱 조사

2026-10-26 작성. 지침 `~/cloudflare-migration/GUIDE.md`, 설계 `talkverse/th/docs/CLOUDFLARE_MIGRATION.md` §2. **아무것도 만들거나 지우지 않았다**(D1·R2·Worker 생성, 코드 변경 없음).

## 결론 — 앱은 Supabase 를 쓰지 않는다 (확인 2026-10-26)

- `lib/`·`pubspec.yaml`·`android/`·`ios/`·`tool/`·`tools/`·CI 워크플로에 Supabase 주소·키·패키지·딥링크가 없다(git 기록에도 없음).
- 회화·문법·단어 콘텐츠는 앱 안 자산(`assets/data/`)과 기기 안 DB(drift/sqflite), 학습 기록은 기기 안(`shared_preferences`·로컬 DB), 앱 업데이트는 GitHub 릴리스. 바깥으로 부르는 곳은 GitHub 릴리스뿐이다.
- 로그인·계정·구독·코스 동기화·개발자 메모 기능 없음 → `talkverse-accounts`·`talkverse-auth`·`talkverse-db` 로 옮길 것 없음.

## 공용 Supabase 안의 스페인어 행 (SELECT 만, 2026-10-26)

| 표 | `es` 행 | 비고 |
|---|---|---|
| `public.items` (`language_code='es'`) | 2,864 (sentence·word, 약 0.6 MB) | 옛 공용 템플릿 시절 행. 지금 앱은 읽지 않는다 |
| `tv_course_answers` · `tv_course_progress` · `tv_dev_notes` (`app_lang='es'`) | 0 · 0 · 0 | |
| 저장소 버킷 | 스페인어 파일 0 | |

→ Cloudflare 로 옮길 데이터 없음. `items` 의 `es` 2,864행은 보관(내보내기)할지·삭제할지 사용자 결정 — 세션은 지우지 않는다. 내보내기는 402 제한이 풀린 뒤에 가능.

## 앞으로
- 콘텐츠를 서버로 옮기거나 로그인·동기화를 붙일 때는 공용 규칙을 따른다: 학습 데이터 → `talkverse-db`(`lang='es'`), 계정 → `talkverse-accounts` + `talkverse-auth`, 파일 → R2.
- 지금 할 일 없음. 대기: `items` es 행 처리(사용자).
