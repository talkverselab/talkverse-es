import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../services/word_service.dart';

/// 단어 시트 — 문장 레마 칩을 누르면 올라온다(2026-11-04). 표제어·뜻·품사·성·빈도 순위·구간·🔊.
Future<void> showWordSheet(BuildContext context, WordEntry word) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (_) => WordSheet(word: word),
    );

class WordSheet extends StatelessWidget {
  final WordEntry word;
  const WordSheet({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final w = word;
    final g = w.gender;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset(context)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (g == 'm' || g == 'f')
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: genderColor(g).withValues(alpha: 0.12), border: Border.all(color: genderColor(g)), borderRadius: BorderRadius.circular(8)),
                child: Text(g == 'm' ? 'el' : 'la', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: genderColor(g))),
              ),
            Text(w.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const Spacer(),
            IconButton(onPressed: () => TtsService.instance.speak(w.word), icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 28)),
          ]),
          const SizedBox(height: 6),
          Text(w.gloss, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.sumi, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (w.pos != null && w.pos!.isNotEmpty) _tag(w.pos!),
            if (w.rank <= 3000) _tag(trf('빈도 {0}위', [w.rank])), // 3001~ = 회화에서 추가된 단어(순위 없음)
            if (w.region != null && w.region!.isNotEmpty) _tag(w.region!),
          ]),
        ]),
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
      );
}
