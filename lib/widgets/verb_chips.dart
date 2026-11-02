import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../screens/verb_screen.dart';
import '../services/achievement_service.dart';
import '../services/tts_service.dart';
import '../services/verb_index.dart';

/// 캡션 아래 「동사 칩」 줄 — 시안 ES-01(사용자 통과 2026-11-03). 칩 하나 = 「● soy  ser · yo · 현재」.
/// 누르면 그 동사의 현재·단순과거 6인칭 시트. [onOpen] 은 시트를 열기 전에 부른다(재생 일시정지용).
class VerbChips extends StatelessWidget {
  final String text;
  final VoidCallback? onOpen;
  const VerbChips({super.key, required this.text, this.onOpen});

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: VerbIndex.instance.ensureLoaded(),
        builder: (context, _) {
          final hits = VerbIndex.instance.hitsIn(text);
          if (hits.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final h in hits)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      hit: h,
                      onTap: () {
                        onOpen?.call();
                        showVerbSheet(context, h);
                      },
                    ),
                  ),
              ]),
            ),
          );
        },
      );
}

class _Chip extends StatelessWidget {
  final VerbHit hit;
  final VoidCallback onTap;
  const _Chip({required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (v, p, tense) = hit.matches.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.beni, width: 1.2), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: conjColor(v.group), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(hit.form, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(width: 8),
          Text('${v.inf} · ${VerbIndex.instance.persons[p]} · ${tr(VerbIndex.tenseKo(tense))}${hit.matches.length > 1 ? ' …' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// 동사 활용 시트. 같은 형이 여러 동사에 해당하면(예: fue = ser/ir) 위에서 고른다.
Future<void> showVerbSheet(BuildContext context, VerbHit hit) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (_) => _VerbSheet(hit: hit),
    );

class _VerbSheet extends StatefulWidget {
  final VerbHit hit;
  const _VerbSheet({required this.hit});
  @override
  State<_VerbSheet> createState() => _VerbSheetState();
}

class _VerbSheetState extends State<_VerbSheet> {
  int _pick = 0;

  @override
  void initState() {
    super.initState();
    AchievementService.instance.markVerbSeen(widget.hit.matches.first.$1.inf);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.hit.matches;
    final (v, person, tense) = m[_pick];
    final persons = VerbIndex.instance.persons;
    Widget cell(String s, bool on) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: on ? AppColors.beni.withValues(alpha: 0.12) : null, border: Border.all(color: on ? AppColors.beni : Colors.transparent), borderRadius: BorderRadius.circular(8)),
          child: Text(s, style: TextStyle(fontSize: 15, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: AppColors.sumi)),
        );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (m.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(spacing: 8, children: [
                for (var i = 0; i < m.length; i++)
                  ChoiceChip(label: Text(m[i].$1.inf), selected: i == _pick, onSelected: (_) {
                    setState(() => _pick = i);
                    AchievementService.instance.markVerbSeen(m[i].$1.inf);
                  }),
              ]),
            ),
          Row(children: [
            Text(v.inf, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const SizedBox(width: 10),
            Expanded(child: Text(v.ko, style: const TextStyle(fontSize: 15, color: AppColors.sumiLight))),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: conjColor(v.group), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(v.group == 'irregular' ? tr('불규칙') : '-${v.group}', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
            IconButton(onPressed: () => TtsService.instance.speak(v.inf), icon: const Icon(Icons.volume_up, color: AppColors.beni)),
          ]),
          const Divider(height: 18),
          Table(
            columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: FlexColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                const SizedBox(),
                Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text(tr('현재'), style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700))),
                Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text(tr('단순과거'), style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700))),
              ]),
              for (var i = 0; i < persons.length; i++)
                TableRow(children: [
                  Padding(padding: const EdgeInsets.only(right: 12), child: Text(persons[i], style: const TextStyle(fontSize: 13, color: AppColors.muted))),
                  cell(i < v.present.length ? v.present[i] : '', i == person && tense == 'present'),
                  cell(i < v.preterite.length ? v.preterite[i] : '', i == person && tense == 'preterite'),
                ]),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const VerbScreen()));
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(tr('동사 활용 전체 보기')),
            ),
          ),
        ]),
      ),
    );
  }
}
