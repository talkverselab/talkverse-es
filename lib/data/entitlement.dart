import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 평생 이용권 — Talkverse 계정 이용권(lang 'es', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 이용권 (2026-11-02).
/// 지금은 잠근 기능이 없다(모든 기능 무료). 유료로 할 범위는 사용자가 정하면 [premium] 으로 잠근다.
class Entitlement {
  Entitlement._();
  static const lang = 'es';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
