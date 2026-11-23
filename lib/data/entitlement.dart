import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';
import '../services/curriculum_plan.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'es', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 이용권(lang_es_* · all_*).
/// 무료/유료 범위 = `~/talkverse/PAYWALL_SPEC.md` §2(2026-11-23): 무료 = 커리큘럼 1단계·회화 1단계(R0·R1)·글자/발음/단어 기본·언어감각 1급,
/// 유료 = 그 밖의 단계·편·급. 어디가 무료인지는 커리큘럼 JSON(서버) 의 `free`·`freeSenseLevels` 가 정한다.
/// 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면.
class Entitlement {
  Entitlement._();
  static const lang = 'es';

  /// 테스트에서 이용권 있음/없음을 정할 때.
  @visibleForTesting
  static bool? premiumOverride;

  static bool get premium => premiumOverride ?? (Account.has(lang) || Purchase.owns(lang));

  /// 이용권 상태가 바뀌면 알린다(자물쇠를 다시 그릴 때).
  static final Listenable changed = Listenable.merge([Purchase.owned, Account.user]);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);

  static CurriculumPlan get _plan => CurriculumService.instance.plan;

  /// 커리큘럼 단계(또는 단계 JSON 이 없을 때의 회화 레벨)가 잠겼나.
  static bool levelLocked(String lv) {
    if (premium) return false;
    final svc = CurriculumService.instance;
    if (svc.usesStages) return !(svc.stages.where((s) => s.key == lv).firstOrNull?.free ?? false);
    return !(lv == 'R0' || lv == 'R1');
  }

  /// 회화 편이 무료인가 — 무료 단계에 든 편(단계 JSON 이 없으면 R0·R1).
  static bool dialogueFree(Dialogue d) {
    final stages = CurriculumService.instance.stages;
    if (stages.isNotEmpty) return stages.any((s) => s.free && s.dialogueIds.contains(d.id));
    return d.region == 'R0' || d.region == 'R1';
  }

  static bool dialogueLocked(Dialogue d) => !premium && !dialogueFree(d);

  /// 언어감각 급(0부터 센 순번)이 잠겼나.
  static bool senseLevelLocked(int index) => !premium && index >= _plan.freeSenseLevels;
}
