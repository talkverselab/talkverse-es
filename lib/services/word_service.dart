import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../main.dart';

/// 단어장 항목 — 빈도 단어표(`Words`) 한 행을 감싼다. 문장 레마 칩·단어 시트가 쓴다(2026-11-04).
class WordEntry {
  final WordRow row;
  const WordEntry(this.row);
  String get word => row.word;
  String get gloss => row.meaningKo ?? '';
  String? get pos => row.pos;
  String? get gender => row.gender;
  int get rank => row.rank;
  String? get region => row.region;
}

/// 단어장 조회 — 일본어앱 `WordService.byLemmas` 에 맞춘 것. 스페인어 단어장은 빈도 단어표 하나(기본형이 곧 표제어).
class WordService {
  WordService._();
  static final WordService instance = WordService._();

  /// 기본형으로 단어장 항목 찾기 — 문장 레마 칩용. 반환: 기본형 → 단어(같은 표제어가 여럿이면 순위 높은 것).
  Future<Map<String, WordEntry>> byLemmas(Iterable<String> bases, {Map<String, String> readings = const {}}) async {
    final keys = bases.map((b) => b.toLowerCase()).toSet().where((b) => b.isNotEmpty).toList();
    if (keys.isEmpty) return const {};
    final rows = await (appDb.select(appDb.words)..where((w) => w.word.lower().isIn(keys))).get();
    final out = <String, WordEntry>{};
    for (final b in bases) {
      final hits = rows.where((r) => r.word.toLowerCase() == b.toLowerCase()).toList()..sort((a, c) => a.rank.compareTo(c.rank));
      if (hits.isNotEmpty) out[b] = WordEntry(hits.first);
    }
    return out;
  }

  Future<WordEntry?> byWord(String word) async {
    final r = await (appDb.select(appDb.words)
          ..where((w) => w.word.lower().equals(word.toLowerCase()))
          ..orderBy([(w) => OrderingTerm.asc(w.rank)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : WordEntry(r);
  }
}
