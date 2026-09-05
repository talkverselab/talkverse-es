# Claude 업데이트 메모 — spanish_universe (es)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- `87062be` (2026-09-02) co-Trip 주제별 단어·표현 메뉴 + 외우기 모드 + 독음 토글

## 변경 내용
### 콘텐츠 — co-Trip 여행 스페인어
- 원본: `OneDrive\전자책\01.06_로망스어계열(그리스어포함)\01.06.02.스페인어\co-Trip 여행 스페인어.md`
- 파서 `tool/parse_cotrip_generic.py`(신설, 범용): `##` 섹션 → 제목 키워드로 테마 자동 분류(+직전 테마 승계), 단어/표현 분리(WORDISH 제목 규칙 또는 문장부호<30% & 평균 3토큰 이하), ko 키워드 → 이모지 아이콘(섹션 내 중복 시 변형 풀). 권말 ㄱㄴㄷ/A–Z 사전은 DICT_SEC로 제외.
- 산출: `assets/data/vocab/travel_words.json`(12테마 1,349) · `travel_expressions.json`(10테마 796). pubspec assets 등록.

### 화면
- `screens/topic_vocab_screen.dart` 신설(zh 포팅): 테마 2열 그리드 → 단어는 3열 1×1 아이콘 타일(아이콘·스페인어·독음·뜻, 탭=TTS+상세 시트) / 표현은 목록.
- 홈 메뉴(`main_screen.dart`): `단어`=주제별(TopicVocabScreen), `표현` 신설(expressions 자산), 기존 빈도 단어는 `빈도 단어`로 분리.
### 외우기 모드 + 외움 체크
- `MemorizedStore`: 외운 항목을 원문 키로 SharedPreferences `memorized_words`에 저장. `version` ValueNotifier로 전 위젯 동기화.
- 모드 버튼: 전체 → 원문가림 → 뜻가림 순환. 가려진 항목은 `???`, 탭하면 공개+TTS.
- 외우기 모드에서 항목별 체크(외웠어요) 버튼, 외운 항목은 배경·테두리 강조.
- 모드 라벨: 전체 / 스페인어가림 / 뜻가림. 앱바에 'N항목 · 외움 n' 카운트.

### 한글독음 전역 토글 ([한] 버튼)
- 앱바 우측 `[한]` 버튼으로 독음 표시/숨김. SharedPreferences `show_ko_reading`에 영구 저장, 모든 화면이 즉시 동기화.
- 위젯: `KoReadingPrefs`(ValueNotifier) · `KoReadingToggleAction`(앱바 버튼) · `KoReadingText`(off면 빈 위젯).
- `services/ko_reading.dart`·`services/memorized_store.dart` 신설. `main.dart`에서 `KoReadingPrefs.load()`.
- 독음(rd)은 책의 한글독음 그대로 표시 (변환기 없음).

## 참고
- 이 앱이 fr/it/pt/de/tr/hu/hi/fa 8개 앱의 **템플릿**이 됨 — 여기 구조를 바꾸면 그 앱들도 같이 바꿔야 일관성 유지.
