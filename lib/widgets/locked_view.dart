import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';

/// 이용권이 필요한 화면 — 숨기지 않고 무엇이 잠겼는지 보여 주고 결제 화면으로(PAYWALL_SPEC §3).
class LockedView extends StatelessWidget {
  final String title;
  const LockedView({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text(title, style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 44, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(tr('이용권으로 열리는 내용이에요'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Entitlement.showPaywall(context), child: Text(tr('이용권 보기'))),
            ]),
          ),
        ),
      );
}
