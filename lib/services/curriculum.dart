import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/embed_env.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22).
/// 회화 레벨에서 다이얼로그 3·5·10편을 골라 코스 → 편마다 연습(듣기 + 확인 문제) → 간격 반복 복습(1·3·7일)
/// → 코스 시험 80% 이상이면 통과 → 레벨 편을 다 통과하면 다음 레벨. 하루 목표 = 새 편 1·2·3 + 복습.
/// 저장 키 `curriculum_v1`(통합 앱에서는 언어 접두어 `pk()` 가 붙는다). 서버 동기화는 나중에 uk.

const kCurriculumPass = 80;
const kReviewSteps = [1, 3, 7]; // 일

/// 점수 = 정답 / 문제 × 100, 소수점 버림.
int curriculumScore(int right, int total) => total <= 0 ? 0 : (right * 100) ~/ total;
bool curriculumPassed(int right, int total) => curriculumScore(right, total) >= kCurriculumPass;

String dayKey(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

class ReviewItem {
  final String lineId; // "<편 id>#<턴 번호>"
  String due; // yyyy-mm-dd
  int step; // 0 = 1일, 1 = 3일, 2 = 7일
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  Course(this.id, this.dialogueIds, {List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map j) => Course('${j['id']}', [for (final x in (j['dialogueIds'] as List? ?? const [])) '$x'],
      practiced: [for (final x in (j['practiced'] as List? ?? const [])) '$x'],
      examScores: [for (final x in (j['examScores'] as List? ?? const [])) (x as num).toInt()],
      passedAt: j['passedAt'] as String?);
}

/// 저장되는 상태 전체(스펙 §7 형식 + 오늘 진행 `today`).
class CurriculumState {
  String? level;
  int dailyGoal; // 1 가볍게 · 2 보통 · 3 집중
  Course? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  String? todayDay;
  int todayNew;
  int todayReview;

  CurriculumState({this.level, this.dailyGoal = 2, this.course, List<String>? passedDialogues, List<ReviewItem>? review, this.streakCount = 0, this.streakLastDay, this.todayDay, this.todayNew = 0, this.todayReview = 0})
      : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: ((j['dailyGoal'] as num?)?.toInt() ?? 2).clamp(1, 3),
      course: j['course'] is Map ? Course.fromJson(j['course'] as Map) : null,
      passedDialogues: [for (final x in (j['passedDialogues'] as List? ?? const [])) '$x'],
      review: [for (final x in (j['review'] as List? ?? const [])) if (x is Map) ReviewItem.fromJson(x)],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: t['day'] as String?,
      todayNew: (t['new'] as num?)?.toInt() ?? 0,
      todayReview: (t['review'] as num?)?.toInt() ?? 0,
    );
  }

  /// 날이 바뀌었으면 오늘 칸을 비운다.
  void rollDay(DateTime now) {
    final k = dayKey(now);
    if (todayDay != k) {
      todayDay = k;
      todayNew = 0;
      todayReview = 0;
    }
  }

  List<ReviewItem> dueReview(DateTime now) {
    final k = dayKey(now);
    return review.where((r) => r.due.compareTo(k) <= 0).toList();
  }

  /// 간격 반복 — 맞히면 다음 간격(1 → 3 → 7일, 7일 뒤 또 맞히면 졸업), 틀리면 1일로.
  void grade(String lineId, bool ok, DateTime now) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    final cur = i < 0 ? null : review[i];
    if (ok) {
      final next = cur == null ? 1 : cur.step + 1;
      if (next >= kReviewSteps.length) {
        if (i >= 0) review.removeAt(i);
        return;
      }
      final due = dayKey(_day(now).add(Duration(days: kReviewSteps[next])));
      cur == null ? review.add(ReviewItem(lineId, due, next)) : (cur..step = next..due = due);
    } else {
      final due = dayKey(_day(now).add(Duration(days: kReviewSteps[0])));
      cur == null ? review.add(ReviewItem(lineId, due, 0)) : (cur..step = 0..due = due);
    }
  }

  int newLeft() => max(0, dailyGoal - todayNew);
  bool todayDone(DateTime now) => newLeft() == 0 && dueReview(now).isEmpty;

  /// 오늘 분량을 다 했으면 연속 일수 갱신(하루 한 번).
  void touchStreak(DateTime now) {
    if (!todayDone(now)) return;
    final k = dayKey(now);
    if (streakLastDay == k) return;
    final y = dayKey(_day(now).subtract(const Duration(days: 1)));
    streakCount = streakLastDay == y ? streakCount + 1 : 1;
    streakLastDay = k;
  }
}

/// 확인 문제 한 개.
class CurQuestion {
  final String lineId;
  final String kind; // meaning · blank
  final String prompt;
  final String? sub; // 보조(뜻)
  final List<String> options;
  final String answer;
  const CurQuestion(this.lineId, this.kind, this.prompt, this.sub, this.options, this.answer);
}

String lineIdOf(Dialogue d, DialogueTurn t) => '${d.id}#${t.num}';

/// 편의 줄로 문제를 만든다 — 뜻 고르기(4지선다)와 빈칸 낱말 고르기를 번갈아. 최대 [maxQ].
List<CurQuestion> buildQuestions(Dialogue d, List<Dialogue> pool, Random rnd, {int maxQ = 10, Set<int>? onlyTurns}) {
  final turns = d.turns.where((t) => t.tl.trim().isNotEmpty && t.ko.trim().isNotEmpty && (onlyTurns == null || onlyTurns.contains(t.num))).toList()..shuffle(rnd);
  final koPool = <String>{for (final x in pool) for (final t in x.turns) if (t.ko.trim().isNotEmpty) t.ko.trim()}.toList();
  final wordPool = <String>{for (final x in pool) for (final t in x.turns) for (final l in t.lemmas) if (l.surface.length > 1) l.surface}.toList();
  final out = <CurQuestion>[];
  for (final t in turns.take(maxQ)) {
    final id = lineIdOf(d, t);
    final words = t.lemmas.map((l) => l.surface).where((w) => w.length > 1 && RegExp('(^|[^\\p{L}])${RegExp.escape(w)}(?![\\p{L}])', unicode: true).hasMatch(t.tl)).toList();
    final blank = out.length.isOdd && words.isNotEmpty && wordPool.length >= 4;
    if (blank) {
      final w = words[rnd.nextInt(words.length)];
      final masked = t.tl.replaceFirst(RegExp('(?<![\\p{L}])${RegExp.escape(w)}(?![\\p{L}])', unicode: true), '____');
      final others = (wordPool.where((x) => x.toLowerCase() != w.toLowerCase()).toList()..shuffle(rnd)).take(3);
      out.add(CurQuestion(id, 'blank', masked, t.ko, [w, ...others]..shuffle(rnd), w));
    } else {
      final others = (koPool.where((x) => x != t.ko.trim()).toList()..shuffle(rnd)).take(3);
      if (others.length < 3) continue;
      out.add(CurQuestion(id, 'meaning', t.tl, null, [t.ko.trim(), ...others]..shuffle(rnd), t.ko.trim()));
    }
  }
  return out;
}

/// 코스 시험 — 편당 최소 3문제, 전체 최대 30문제.
List<CurQuestion> buildExam(List<Dialogue> ds, List<Dialogue> pool, Random rnd) {
  if (ds.isEmpty) return const [];
  final per = (30 ~/ ds.length).clamp(3, 10);
  final out = <CurQuestion>[for (final d in ds) ...buildQuestions(d, pool, rnd, maxQ: per)];
  out.shuffle(rnd);
  return out.take(30).toList();
}

/// 추천으로 채우기 — 아직 통과 안 한 편에서 주제(island)가 겹치지 않게.
List<String> recommend(List<Dialogue> level, Set<String> passed, Set<String> already, int n) {
  final left = level.where((d) => !passed.contains(d.id) && !already.contains(d.id)).toList();
  final out = <String>[...already];
  final used = <String>{for (final d in level) if (already.contains(d.id)) d.island};
  for (final pass in [true, false]) {
    for (final d in left) {
      if (out.length >= n) break;
      if (out.contains(d.id)) continue;
      if (pass && used.contains(d.island)) continue;
      out.add(d.id);
      used.add(d.island);
    }
  }
  return out.take(n).toList();
}

class CurriculumStore {
  CurriculumStore._();
  static final CurriculumStore instance = CurriculumStore._();
  static final String key = pk('curriculum_v1');

  CurriculumState state = CurriculumState();

  Future<CurriculumState> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      state = raw == null ? CurriculumState() : CurriculumState.fromJson(json.decode(raw) as Map);
    } catch (_) {
      state = CurriculumState();
    }
    state.rollDay(DateTime.now());
    return state;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, json.encode(state.toJson()));
  }
}
