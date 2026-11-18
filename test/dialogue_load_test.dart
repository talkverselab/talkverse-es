import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_universe/services/dialogue_service.dart';

/// 회화 편 JSON(R0~R5) 이 모두 읽히고, 여성 학습자판이 상대 이름·성별 줄을 바꾸는지(2026-11-18).
void main() {
  final files = Directory('assets/data/dialogues').listSync(recursive: true).whereType<File>().where((f) => RegExp(r'/R[0-5]/[^/]+/[^/]+\.json$').hasMatch(f.path)).toList();

  test('모든 편이 읽힌다', () {
    expect(files.length, greaterThanOrEqualTo(60));
    final ids = <String>{};
    for (final f in files) {
      final j = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
      final d = Dialogue.fromJson(j);
      expect(d.turns, isNotEmpty, reason: f.path);
      expect(DialogueService.levels, contains(d.region), reason: f.path);
      expect(DialogueService.islands, contains(d.island), reason: f.path);
      expect(ids.add(d.id), isTrue, reason: '같은 id ${d.id}');
    }
  });

  test('여성판: speakers_f 와 tl_f 를 쓴다', () {
    final j = json.decode(File('assets/data/dialogues/R0/love/r0_love_a1.json').readAsStringSync()) as Map<String, dynamic>;
    final m = Dialogue.fromJson(j), f = Dialogue.fromJson(j, female: true);
    expect(m.speakers['B'], 'Marta');
    expect(f.speakers['B'], 'Mateo');
    final n = (j['turns'] as List).firstWhere((t) => (t as Map).containsKey('tl_f'))['num'];
    expect(f.turns.firstWhere((t) => t.num == n).tl, isNot(m.turns.firstWhere((t) => t.num == n).tl));
    expect(f.scene, contains('Mateo'));
  });

  test('언어감각 과정: 급마다 외울 대화 + 참고, 문장마다 tl·rd·ko', () {
    final j = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (j['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels.length, 10);
    for (final lv in levels) {
      final kinds = [for (final l in (lv['lessons'] as List)) (l as Map)['kind']];
      expect(kinds, ['memorize', 'ref'], reason: '${lv['id']}');
      for (final s in ((lv['lessons'] as List).first['sentences'] as List).cast<Map>()) {
        for (final k in ['tl', 'rd', 'ko']) {
          expect('${s[k] ?? ''}', isNotEmpty, reason: '${lv['id']} $k');
        }
      }
    }
  });
}
