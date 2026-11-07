# 회화 음성 감정 계획 작성법 (스페인어)

편마다 `data/tts/plan/<편id>.json`. 검사 `python3 tools/tts/check_plan.py`. 일본어앱·중국어앱 `data/tts/PLAN_GUIDE.md` 와 같은 틀, 칸만 다르다(text = `tl`, reading 없음, rd = 한글 독음, ko = 한국어 뜻).

- **segs** = 말하는 순서대로 나눈 조각 `[감정, 본문]` 또는 `[감정, 본문, 읽기]`. 이어 붙이면 그 턴의 `tl` 과 같아야 한다(공백·문장부호 무시). 감정이 바뀌는 곳에서만 나눈다.
- 감정: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. neutral 만 쓰지 말 것 — 심쿵 턴은 gentle·shy.
- **cast**: A 는 안 쓴다(자동 am/af). Lucía=lucia · Marta=marta · Javi=javi · Diego=diego · 그 밖은 나이·성별로 man_y/m/o·woman_y/m/o·announce. 조연 고정 목소리 directora·vecina.
- **자리**: `{name}` 남성판 Alex, 여성판 Emma · `{country}` Canadá · `{city}` Toronto · `{lang}` inglés.
- **남성판·여성판**: 턴에 `tl_f` 가 있으면 계획에 `f` 를 넣는다(`text`·`rd`·`ko`·`segs`).
