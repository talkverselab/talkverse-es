import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_universe/data/entitlement.dart';
import 'package:spanish_universe/services/curriculum_plan.dart';
import 'package:spanish_universe/services/curriculum_service.dart';
import 'package:spanish_universe/services/dialogue_service.dart';

/// 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    CurriculumService.instance.plan = CurriculumPlan.forTest(fetch: (_) async => null); // 앱 안 커리큘럼 rev 2
    await CurriculumService.instance.ensureLoaded();
  });
  tearDown(() => Entitlement.premiumOverride = null);

  test('앱 안 커리큘럼은 rev 2 — 1단계만 free, 언어감각 무료 1급', () {
    final p = CurriculumService.instance.plan;
    expect(p.rev, 2);
    expect(CurriculumService.instance.stages.map((s) => s.free), [true, false, false, false, false]);
    expect(p.freeSenseLevels, 1);
  });

  test('이용권 없음: 1단계 열림 · 2단계 이상 잠김 · 1단계 편 열림 · 2단계 편 잠김 · 언어감각 1급만 열림', () {
    Entitlement.premiumOverride = false;
    expect(Entitlement.levelLocked('1'), isFalse);
    for (final lv in ['2', '3', '4', '5']) {
      expect(Entitlement.levelLocked(lv), isTrue, reason: lv);
    }
    final ds = DialogueService.instance;
    final s1 = CurriculumService.instance.stages.first.dialogueIds.map(ds.byId).whereType<Dialogue>();
    final s2 = CurriculumService.instance.stages[1].dialogueIds.map(ds.byId).whereType<Dialogue>();
    expect(s1, isNotEmpty);
    expect(s1.every((d) => !Entitlement.dialogueLocked(d)), isTrue);
    expect(s2.every(Entitlement.dialogueLocked), isTrue);
    expect(Entitlement.senseLevelLocked(0), isFalse);
    expect(Entitlement.senseLevelLocked(1), isTrue);
  });

  test('이용권 있음: 모두 열림', () {
    Entitlement.premiumOverride = true;
    expect(['1', '2', '5'].any(Entitlement.levelLocked), isFalse);
    final all = DialogueService.instance.list();
    expect(all.any(Entitlement.dialogueLocked), isFalse);
    expect(Entitlement.senseLevelLocked(9), isFalse);
  });
}
