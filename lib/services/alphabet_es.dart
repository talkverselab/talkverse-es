import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 알파벳과 발음 — `assets/data/grammar/alphabet_es.json` (글자 27 + 겹글자 + 스페인 소리 + 강세).
/// 콘텐츠(설명·비교·뜻)는 번역 대상이 아니다(CLAUDE.md §5) — 화면 문구만 tr().
class AlphabetExample {
  final String es; // 예문 낱말
  final String rd; // 한글 독음(전역 독음 토글로 표시)
  final String ko; // 뜻
  final int? rank; // 빈도 순위(lang_es_top.csv), 없으면 null

  const AlphabetExample({required this.es, required this.rd, required this.ko, this.rank});

  factory AlphabetExample.fromJson(Map<String, dynamic> j) => AlphabetExample(
        es: j['es'] as String,
        rd: (j['rd'] ?? '') as String,
        ko: (j['ko'] ?? '') as String,
        rank: j['rank'] as int?,
      );
}

class AlphabetUnit {
  final String id;
  final String group; // vowel · cons · digraph · spain · stress
  final String letter; // 타일·헤더에 크게 쓰는 글자
  final String name; // 글자 이름(a, be, ce…) 또는 소리 이름
  final String ipa;
  final String rd; // 한글 근사(전역 독음 토글로 표시)
  final String say; // 시트가 열리면 읽을 말
  final List<String> place; // bilabial · labiodental · interdental · dental · alveolar · postalveolar · palatal · velar · none · vowel · stress
  final String korSim; // 비슷한 한국어 소리
  final String mouth; // 소리 내는 법
  final String compare; // 한국어 화자에게 비슷한/다른 점
  final List<AlphabetExample> examples;

  const AlphabetUnit({
    required this.id,
    required this.group,
    required this.letter,
    required this.name,
    required this.ipa,
    required this.rd,
    required this.say,
    required this.place,
    required this.korSim,
    required this.mouth,
    required this.compare,
    required this.examples,
  });

  bool get isVowel => place.contains('vowel');

  factory AlphabetUnit.fromJson(Map<String, dynamic> j) => AlphabetUnit(
        id: j['id'] as String,
        group: j['group'] as String,
        letter: j['letter'] as String,
        name: j['name'] as String,
        ipa: j['ipa'] as String,
        rd: (j['rd'] ?? '') as String,
        say: j['say'] as String,
        place: (j['place'] as List).cast<String>(),
        korSim: (j['korSim'] ?? '') as String,
        mouth: (j['mouth'] ?? '') as String,
        compare: (j['compare'] ?? '') as String,
        examples: ((j['examples'] ?? []) as List).map((e) => AlphabetExample.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class AlphabetData {
  AlphabetData._();

  static List<AlphabetUnit>? _cache;

  static Future<List<AlphabetUnit>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/grammar/alphabet_es.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (j['units'] as List).map((e) => AlphabetUnit.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}
