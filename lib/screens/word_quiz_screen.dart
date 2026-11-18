import 'dart:math';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cliff.dart';
import '../core/embed_env.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../embed.dart' show appDb;
import '../services/tts_service.dart';

/// 단어 퀴즈 복습 — 일본어앱 「외국어 단어 퀴즈」(빌드 110) 꼴을 스페인어 빈도 단어에 씀(2026-11-18).
/// 3단계(핵심 → 중급까지 → 전체) 중 하나를 골라 10문제. 두 꼴을 번갈아 — 스페인어 → 뜻, 뜻 → 스페인어. 보기 1~4.
/// 틀린 단어는 다음 복습에 먼저 나온다.
const int kWordQuizSize = 10;
final String _kWrong = pk('word_quiz_wrong');

class QuizWord {
  final String es, ko;
  final int rank;
  const QuizWord(this.es, this.ko, this.rank);
}

/// 3단계 — 절벽 순위로 끊는다(`core/cliff.dart`).
class QuizStep {
  final String label;
  final int maxRank;
  const QuizStep(this.label, this.maxRank);
}

final kQuizSteps = [
  QuizStep('핵심', kWordCliffs[1]), // R1~R2 — 대화의 60%
  QuizStep('중급까지', kWordCliffs[3]), // R1~R4 — 80%
  const QuizStep('전체', kWordCap),
];

class WordQuizScreen extends StatefulWidget {
  final int? seed;
  const WordQuizScreen({super.key, this.seed});
  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _Q {
  final QuizWord w;
  final bool toEs; // true = 뜻 보고 스페인어 고르기
  final List<String> options;
  const _Q(this.w, this.toEs, this.options);
  String get answer => toEs ? w.es : w.ko;
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<QuizWord>? _all;
  int _step = 0;
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<QuizWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    final seen = <String>{};
    final out = <QuizWord>[];
    for (final r in rows) {
      final ko = (r.meaningKo ?? '').trim();
      if (ko.isEmpty || r.rank > kWordCap || !seen.add(r.word.toLowerCase())) continue;
      out.add(QuizWord(r.word, ko, r.rank));
    }
    if (mounted) setState(() => _all = out);
  }

  Future<void> _build() async {
    final p = await SharedPreferences.getInstance();
    final wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    final pool = _all!.where((w) => w.rank <= kQuizSteps[_step].maxRank).toList()..shuffle(_rnd);
    pool.sort((a, b) => (wrong.contains(b.es) ? 1 : 0) - (wrong.contains(a.es) ? 1 : 0));
    final picked = pool.take(kWordQuizSize).toList()..shuffle(_rnd);
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      final toEs = k.isOdd;
      final others = ({
        for (final o in pool)
          if (o.es != w.es && o.ko != w.ko) toEs ? o.es : o.ko
      }.toList()
            ..shuffle(_rnd))
          .take(3);
      qs.add(_Q(w, toEs, [toEs ? w.es : w.ko, ...others]..shuffle(_rnd)));
    }
    if (mounted) {
      setState(() {
        _qs = qs;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
      });
    }
  }

  Future<void> _record(String es, bool ok) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList(_kWrong) ?? const []).toSet();
    ok ? s.remove(es) : s.add(es);
    await p.setStringList(_kWrong, s.toList());
  }

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('단어 퀴즈'))),
      body: _all == null
          ? const Center(child: CircularProgressIndicator())
          : qs == null
              ? _chooser()
              : _i >= qs.length
                  ? _summary(qs.length)
                  : _question(qs[_i], qs.length),
    );
  }

  Widget _chooser() => ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
        Text(tr('범위를 고르면 10문제가 나와요. 틀린 단어는 다음에 먼저 나와요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 12),
        for (var k = 0; k < kQuizSteps.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-step-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                side: const BorderSide(color: AppColors.line, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _step = k;
                _build();
              },
              child: Row(children: [
                SizedBox(width: 30, child: Text('${k + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ai))),
                Expanded(child: Text(tr(kQuizSteps[k].label), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
                Text(trf('{0}위까지', [kQuizSteps[k].maxRank]), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ),
      ]);

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${w.es}  ${w.ko}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('wq-again'), onPressed: _build, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.sumi), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr(kQuizSteps[_step].label)} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(height: 14),
        Text(
          q.toEs ? w.ko : w.es,
          key: const ValueKey('wq-stem'),
          style: TextStyle(fontSize: q.toEs ? 22 : 30, fontWeight: FontWeight.w900, color: AppColors.sumi),
        ),
        const SizedBox(height: 8),
        Text(tr(q.toEs ? '스페인어로 맞는 것을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.es);
                      _record(w.es, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumiLight))),
                Expanded(child: Text(q.options[k], style: TextStyle(fontSize: q.toEs ? 20 : 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('wq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
