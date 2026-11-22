import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_universe/services/dialogue_service.dart';
import 'package:spanish_universe/services/curriculum.dart';

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(curriculumScore(7, 9), 77);
      expect(curriculumScore(0, 0), 0);
    });
    test('80 이상 통과, 미만 탈락', () {
      expect(curriculumPassed(8, 10), isTrue); // 80
      expect(curriculumPassed(24, 30), isTrue); // 80
      expect(curriculumPassed(23, 30), isFalse); // 76.6 → 76
      expect(curriculumPassed(79, 100), isFalse);
      expect(curriculumPassed(11, 14), isFalse); // 78.5 → 78
    });
  });

  group('간격 반복 1·3·7일', () {
    final d0 = DateTime(2026, 11, 22, 21, 30);
    test('처음 틀리면 1일 뒤', () {
      final s = CurriculumState()..grade('a#1', false, d0);
      expect(s.review.single.due, '2026-11-23');
      expect(s.review.single.step, 0);
    });
    test('처음 맞히면 3일 뒤, 또 맞히면 7일 뒤, 또 맞히면 졸업', () {
      final s = CurriculumState()..grade('a#1', true, d0);
      expect(s.review.single.due, '2026-11-25');
      s.grade('a#1', true, DateTime(2026, 11, 25));
      expect(s.review.single.due, '2026-12-02');
      expect(s.review.single.step, 2);
      s.grade('a#1', true, DateTime(2026, 12, 2));
      expect(s.review, isEmpty);
    });
    test('틀리면 1일로 돌아감', () {
      final s = CurriculumState()
        ..grade('a#1', true, d0)
        ..grade('a#1', false, DateTime(2026, 11, 25));
      expect(s.review.single.due, '2026-11-26');
      expect(s.review.single.step, 0);
    });
    test('오늘 분량·연속 일수', () {
      final s = CurriculumState(dailyGoal: 1)..rollDay(d0);
      s.grade('a#1', false, d0); // 내일 복습
      s.todayNew = 1;
      expect(s.todayDone(d0), isTrue);
      s.touchStreak(d0);
      expect(s.streakCount, 1);
      final d1 = d0.add(const Duration(days: 1));
      s.rollDay(d1);
      expect(s.dueReview(d1).length, 1);
      expect(s.todayDone(d1), isFalse);
    });
    test('저장 형식 왕복', () {
      final s = CurriculumState(level: 'R1', course: Course('c', ['x', 'y'], practiced: ['x'], examScores: [70]))..grade('x#2', false, d0);
      final back = CurriculumState.fromJson(s.toJson());
      expect(back.level, 'R1');
      expect(back.course!.dialogueIds, ['x', 'y']);
      expect(back.course!.examScores, [70]);
      expect(back.review.single.lineId, 'x#2');
    });
  });

  test('실제 회화로 문제·시험 만들기', () {
    final files = Directory('assets/data/dialogues/R1').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList()..sort((a, b) => a.path.compareTo(b.path));
    final ds = [for (final f in files) Dialogue.fromJson(json.decode(f.readAsStringSync()) as Map<String, dynamic>, female: false)];
    expect(ds.length, greaterThan(3));
    final rnd = Random(1);
    for (final d in ds) {
      final qs = buildQuestions(d, ds, rnd);
      expect(qs, isNotEmpty);
      expect(qs.length, lessThanOrEqualTo(10));
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options, contains(q.answer));
        expect(q.options.toSet().length, 4);
      }
    }
    final exam = buildExam(ds.take(10).toList(), ds, rnd);
    expect(exam.length, lessThanOrEqualTo(30));
    expect(exam.length, greaterThanOrEqualTo(3 * min(ds.length, 10) - 3));
    final rec = recommend(ds, {}, {}, 5);
    expect(rec.length, 5);
  });
}
