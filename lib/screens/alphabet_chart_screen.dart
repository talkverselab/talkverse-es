import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/alphabet_es.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/alphabet_sound_sheet.dart';

/// 알파벳과 발음 — 일본어앱 「50음도와 발음」 구조.
/// 묶음 칩(모음·자음·겹글자·스페인 소리·강세) + 글자 격자. 탭 → 발음 상세 시트.
/// 보조 표기 = 앱 전역 한글독음 토글(기본 숨김).
class AlphabetChartScreen extends StatefulWidget {
  const AlphabetChartScreen({super.key});

  @override
  State<AlphabetChartScreen> createState() => _AlphabetChartScreenState();
}

const _groups = ['vowel', 'cons', 'digraph', 'spain', 'stress'];

String _groupLabel(String g) => switch (g) {
      'vowel' => tr('모음'),
      'cons' => tr('자음'),
      'digraph' => tr('겹글자'),
      'spain' => tr('스페인 소리'),
      _ => tr('강세'),
    };

Color alphabetGroupColor(String g) => switch (g) {
      'vowel' => AppColors.beni,
      'cons' => AppColors.mar,
      'digraph' => AppColors.oliva,
      'spain' => AppColors.sakuraDeep,
      _ => AppColors.irregular,
    };

class _AlphabetChartScreenState extends State<AlphabetChartScreen> {
  String _group = 'vowel';
  List<AlphabetUnit>? _units;

  @override
  void initState() {
    super.initState();
    AlphabetData.load().then((u) {
      if (mounted) setState(() => _units = u);
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('알파벳과 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 2)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: _units == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              _chips(),
              Expanded(child: _grid()),
            ]),
    );
  }

  Widget _chips() {
    final units = _units!;
    return Container(
      width: double.infinity,
      color: AppColors.washiDeep,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final g in _groups)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(g, units.where((u) => u.group == g).length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String g, int n) {
    final selected = _group == g;
    final c = alphabetGroupColor(g);
    return GestureDetector(
      onTap: () => setState(() => _group = g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.washi,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c, width: selected ? 1.5 : 0.8),
        ),
        child: Text(
          '${_groupLabel(g)} $n',
          style: TextStyle(color: selected ? AppColors.washi : c, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }

  Widget _grid() {
    final list = _units!.where((u) => u.group == _group).toList();
    final color = alphabetGroupColor(_group);
    final wide = _group == 'digraph' || _group == 'spain' || _group == 'stress';
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, showKo, _) => GridView.builder(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: wide ? 190 : 100,
          mainAxisExtent: showKo ? 104 : 88,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) => _tile(list[i], color, showKo, wide),
      ),
    );
  }

  Widget _tile(AlphabetUnit u, Color color, bool showKo, bool wide) {
    return Material(
      color: AppColors.washi,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showAlphabetSoundSheet(context, unit: u, color: color),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 4, offset: const Offset(1, 2))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(u.letter,
                  maxLines: 1,
                  style: TextStyle(fontSize: wide ? 20 : 26, fontWeight: FontWeight.w900, color: AppColors.sumi, height: 1.1)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(wide ? u.name : '${u.name} · ${u.ipa}',
                  maxLines: 1, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
            ),
            if (showKo && u.rd.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(u.rd, maxLines: 1, style: const TextStyle(fontSize: 11, color: AppColors.sumiLight, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ),
    );
  }
}
