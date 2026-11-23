import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_universe/services/curriculum_plan.dart';

/// 커리큘럼 단계 = 서버/앱 안 JSON(CURRICULUM_SPEC §12, 2026-11-23).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const app = {'a1', 'a2', 'b1', 'c1'};
  bool known(String id) => app.contains(id);

  String plan(int rev, List<List<String>> stages) => json.encode({
        'rev': rev,
        'stages': [
          for (var i = 0; i < stages.length; i++) {'n': i + 1, 'title': '${i + 1}단계', 'desc': '', 'dialogueIds': stages[i]},
        ],
        'prep': [],
      });

  test('앱에 없는 편 id 는 건너뛰고, 편이 0개인 단계는 숨긴다', () async {
    final p = CurriculumPlan.forTest(bundled: plan(1, [['a1', 'zz'], ['zz'], ['b1']]), fetch: (_) async => null);
    await p.init();
    final s = p.stages(known);
    expect(s.map((e) => e.n), [1, 3]);
    expect(s.first.dialogueIds, ['a1']);
  });

  test('서버 rev 가 크면 받아 바꾸고 기기에 둔다 — 다음 실행은 서버 없이도 그 판', () async {
    final p = CurriculumPlan.forTest(bundled: plan(1, [['a1']]), fetch: (_) async => plan(3, [['a1', 'a2'], ['b1'], ['c1']]));
    expect(await p.refresh(), isTrue);
    expect(p.rev, 3);
    expect(p.stages(known).length, 3);
    final again = CurriculumPlan.forTest(bundled: plan(1, [['a1']]), fetch: (_) async => null);
    await again.init();
    expect(again.rev, 3);
    expect(again.stages(known).first.dialogueIds, ['a1', 'a2']);
  });

  test('서버 rev 가 같거나 작으면 · 서버 실패면 · 깨진 판이면 앱 안 것', () async {
    for (final body in [plan(1, [['b1']]), null, '{"rev":9,"stages":[]}', 'not json']) {
      SharedPreferences.setMockInitialValues({});
      final p = CurriculumPlan.forTest(bundled: plan(1, [['a1']]), fetch: (_) async => body);
      expect(await p.refresh(), isFalse);
      expect(p.stages(known).single.dialogueIds, ['a1']);
    }
  });

  test('앱 안 기본값도 깨지면 단계 없음 → 회화 레벨 방식으로 돈다', () async {
    final p = CurriculumPlan.forTest(bundled: 'oops', fetch: (_) async => null);
    await p.init();
    expect(p.hasPlan, isFalse);
  });
}
