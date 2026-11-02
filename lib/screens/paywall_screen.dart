import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import 'login_screen.dart';

/// 평생 이용권 시트 — 가격 + 인앱 결제 + 구매 복원(한자 앱 paywall_screen.dart 와 같은 구성, 2026-11-02).
/// 사거나 복원되면 닫힌다. 로그인은 선택(기기 간 공유용).
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    Purchase.status.value = null;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cal,
      builder: (_) => const PaywallScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Purchase.status,
      builder: (c, st, _) {
        if (st == 'done' || st == 'restored') {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (Navigator.canPop(c)) Navigator.pop(c); });
        }
        final busy = st == 'pending';
        return ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: Purchase.products,
          builder: (c, _, _) {
            final price = Purchase.price(Entitlement.lang);
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 20 + bottomInset(context)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(tr('평생 이용권'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.tinta)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(color: AppColors.tinta, borderRadius: BorderRadius.circular(18)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(price ?? '—', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tr('한 번 결제 · 구독 아님 · 평생'), style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (st == 'error') Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(tr('결제를 마치지 못했습니다. 다시 시도해 주세요.'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600))),
                  if (st == 'nothing') Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(tr('복원할 구매가 없습니다.'), style: const TextStyle(color: AppColors.tintaLight, fontWeight: FontWeight.w600))),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, minimumSize: const Size.fromHeight(54), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    onPressed: busy || price == null || Entitlement.premium ? null : () => Purchase.buy(Entitlement.lang),
                    child: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(Entitlement.premium
                            ? tr('이용권이 있습니다')
                            : price == null ? tr('스토어에 연결하는 중…') : trf('평생 이용권 구매 · {0}', [price])),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: busy ? null : () => Purchase.restore(), child: Text(tr('이전 구매 복원'))),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: Account.user,
                    builder: (c, u, _) => u == null
                        ? TextButton(
                            onPressed: () => LoginScreen.open(context),
                            child: Text(tr('로그인하면 다른 기기에서도 이용권이 열립니다 (선택)'), style: const TextStyle(fontSize: 12.5)),
                          )
                        : Text(tr('로그인됨 — 구매는 Talkverse 계정에 기록되어 다른 기기에서도 열립니다.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
                  ),
                  Text(
                    tr('결제는 App Store / Google Play 에서 처리됩니다. 표시 가격은 스토어 가격을 따르며 세금이 포함될 수 있습니다.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.tintaLight, height: 1.4),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
