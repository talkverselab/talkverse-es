# 스페인어유니버스 (SpanishUniverse)

> 한국 화자 대상 스페인어 단일 앱. `talkverse/zh` (중국어유니버스) 구조를 그대로 계승.
> 앱 이름: **스페인어유니버스**
> Package: `com.talkverse.spanish_universe`
> Stack: **Flutter** (Material 3) + **Drift** (SQLite). Brand: `#AA151B` (rojo) + `#F1BF00` (gualda).
> Git: GitHub `talkverselab/spanish-universe` (master 푸시 → Actions 가 release APK 게시).

---

## 한 페이지 요약

es = 굴절어. 학습 3축 = **(1) 동사 활용 / (2) 성·수 일치 / (3) 발음 (rr·ñ·강세)**.

zh 의 "한자 cliff" 에 대응하는 es 차별화 IP 후보:
- **동사 cliff**: 핵심 동사 30 → 100 → 300 단계로 회화 커버리지 실측 (TBD)
- **단어 cliff**: R1/R2/R3/R4 region 분류 (zh 와 동일 스키마)

---

## 진입

```powershell
cd C:\Users\Johnjeon\talkverse\es
claude
```

빌드:
```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen
flutter run                                                # 개발 (실기기)
flutter build apk --release                                # release APK
```

---

## 폴더

| 위치 | 내용 |
|---|---|
| `lib/main.dart` | 앱 진입점 (`appDb` 전역 + SeedLoader) |
| `lib/core/theme.dart` | España 팔레트 (rojo·gualda·cal·tinta), `conjColor`, `genderColor` |
| `lib/data/db/` | **Drift** schema: Turns / Words / Verbs / UserProgress / VerbProgress / UserMemos |
| `lib/data/db/seed_loader.dart` | assets → DB 시딩 (`db_seeded_v1` 키) |
| `lib/screens/` | MainScreen(홈·학습·진행·프로필), ConversationScreen, EpisodeScreen, VerbScreen, WordFreqScreen, ProgressScreen, ProfileScreen |
| `lib/widgets/spanish_decor.dart` | TileBadge, BandPanel, BandDivider, AzulejoPattern, StreakChip, SolMark |
| `lib/services/` | TtsService(es-ES), AudioService(mp3 manifest), MemoService |
| `assets/data/dialogues/` | `_meta.json` + `L1.json` (JSON SOT) |
| `assets/data/grammar/verbs_core.json` | 핵심 동사 30 (현재·단순과거) |
| `assets/data/freq/lang_es_top.csv` | 빈도 단어 (rank,word,pos,gender,ko,freq,cum_pct,region,cefr) |
| `assets/audio/words/` | mp3 (.gitignore) |
| `.github/workflows/android-release.yml` | master 푸시 → 서명 release APK → GitHub Release |

---

## 콘텐츠 schema (v1)

```
L1: 5 ep × 40 turn = 200 turn   매칭 narrative (Minjun & Lucía)   — 현재 ep1 20 turn 샘플
L2: TBD (일상 챗)
L3: TBD (내러티브)
```

Turn JSON:
```json
{
  "num": 1, "speaker": "A",
  "es": "¡Hola! ¿Qué tal?",
  "ko": "안녕! 잘 지내?",
  "note": "¡ ¿ 역부호 / qué tal = 가벼운 인사",
  "tags": ["greeting"]
}
```

zh 와의 차이: `zh/pinyin/tones` → `es` 단일 필드. `dialect(north/south)` → `variety(es_ES/es_MX)`.

---

## zh → es 대응표

| zh | es |
|---|---|
| Hanzi / HanziProgress | Verbs / VerbProgress |
| toneColor(1~4·경성) | conjColor(ar/er/ir/irregular), genderColor(m/f) |
| SealStamp / CloudPattern / BrushDivider | TileBadge / AzulejoPattern / BandDivider |
| TTS zh-CN | TTS es-ES |
| 한자 209 / 발음부 / 성조 matrix | 동사 활용 / 성·수 / 발음(rr·ñ) — 뒤 둘은 placeholder |

---

## 미결

1. 변종 정책: es_ES(vosotros) 단일 vs es_MX 병행
2. L1 ep1 나머지 20 turn + ep2~5
3. 빈도 단어 실코퍼스 (현재 200 샘플, 수동 작성 — 실측 freq 아님)
4. 발음·성수 화면 설계
5. 앱 아이콘 (`assets/characters/icon_full.png` 미생성 — `flutter_launcher_icons` 실행 전 필요)
