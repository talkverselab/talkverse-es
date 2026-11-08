import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../widgets/word_art_thumb.dart';

/// 절벽 단어 — 레마 빈도 1~2,000위를 절벽구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로 보여 준다(사용자 지시 2026-11-07, 일본어앱과 같은 구조).
/// 위 버튼 「절벽구간 단어만 / 회화 단어 포함」 — 포함이면 회화에 나오지만 2,000위 밖인 단어(assets/data/freq/conv_words_es.json)가
/// 「회화」 구간으로 뒤에 붙는다. 단어장은 그대로 두고 화면에서만 합친다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

const int kUnit = 20;

class _Tile {
  final int rank;
  final String word, ko, region; // region: R1~R5 · C(회화 단어)
  const _Tile(this.rank, this.word, this.ko, this.region);
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<_Tile> _words = [];
  List<_Tile> _conv = [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions {
    final c = kWordCliffs;
    return {
      'ALL': _Region(tr('전체'), AppColors.sumi),
      'R1': _Region('R1 · 1-${c[0]}', AppColors.beni),
      'R2': _Region('R2 · ${c[0] + 1}-${c[1]}', AppColors.beniLight),
      'R3': _Region('R3 · ${c[1] + 1}-${c[2]}', AppColors.kinDeep),
      'R4': _Region('R4 · ${c[2] + 1}-${c[3]}', AppColors.matcha),
      'R5': _Region('R5 · ${c[3] + 1}-$kWordCap', AppColors.muted),
      'C': _Region(tr('회화'), AppColors.ai),
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)
          ..where((w) => w.rank.isBetweenValues(1, kWordCap))
          ..orderBy([(w) => OrderingTerm.asc(w.rank)]))
        .get();
    final entries = [for (final w in rows) _Tile(w.rank, w.word, w.meaningKo ?? '', regionOf(w.rank))];
    final conv = <_Tile>[];
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/freq/conv_words_es.json')) as Map<String, dynamic>;
      var n = 0;
      for (final w in (j['words'] as List).cast<Map<String, dynamic>>()) {
        conv.add(_Tile(++n, w['word'] as String, (w['ko'] as String?) ?? '', 'C'));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _words = entries;
      _conv = conv;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<_Tile>>[];
    for (var i = 0; i < filtered.length; i += kUnit) {
      units.add(filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)));
    }
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(
              children: [
                Container(
                  color: AppColors.washiDeep,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ModeButton(
                            label: tr('절벽구간 단어만'),
                            selected: !_withConv,
                            onTap: () => setState(() {
                              _withConv = false;
                              if (_filter == 'C') _filter = 'ALL';
                            }),
                          ),
                          const SizedBox(width: 8),
                          _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: chips.map((e) {
                            final selected = _filter == e.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _filter = e.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? e.value.color : AppColors.washi,
                                    border: Border.all(color: e.value.color, width: selected ? 1.5 : 0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(e.value.label, style: TextStyle(color: selected ? AppColors.washi : e.value.color, fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                      itemCount: units.length,
                      itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions, width: c.maxWidth),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<_Tile> words;
  final Map<String, _Region> regions;
  final double width;
  const _UnitBlock({required this.index, required this.words, required this.regions, required this.width});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final last = words.last;
    final region = regions[first.region];
    final range = first.region == 'C' ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}';
    final cols = (width / 112).floor().clamp(3, 8); // 칸 너비 기준 — 넓은 화면의 오른쪽 칸에서도 맞게
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: Row(
              children: [
                Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(range, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
                const Spacer(),
                if (region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(4)),
                    child: Text(first.region == 'C' ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.86), // 그림+단어+뜻이 정사각형에 4~6px 넘침(아이패드 스크린샷) → 세로로 조금 길게
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: regions[words[i].region]?.color ?? AppColors.sumi),
          ),
        ],
      ),
    );
  }
}

/// 네모 타일 — 순위 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final _Tile w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => TtsService.instance.speak(w.word),
        child: Container(
          decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8), boxShadow: kCardShadow),
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, c) {
              final art = (c.maxHeight * 0.40).clamp(28.0, 72.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(w.region == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 2),
                  WordArtThumb(word: w.word, rank: w.region == 'C' ? null : w.rank, size: art),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.sumi))),
                  if (w.ko.isNotEmpty)
                    Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
                ],
              );
            },
          ),
        ),
      );
}
