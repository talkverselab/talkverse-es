import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../core/embed_env.dart';

/// 핵심 동사 30개(`assets/data/grammar/verbs_core.json`)의 활용형 역색인 — 시안 ES-01 「동사 칩」(2026-11-03).
/// 회화 문장을 낱말로 나눠 활용형(`soy`·`tengo`·`hablas`)을 찾고 원형·인칭·시제를 돌려준다. 새 콘텐츠는 만들지 않는다.
class VerbInfo {
  final String inf;
  final String ko;
  final String group; // ar | er | ir | irregular
  final List<String> present;
  final List<String> preterite;
  const VerbInfo({required this.inf, required this.ko, required this.group, required this.present, required this.preterite});
}

/// 문장 속 활용형 하나: 그 형이 될 수 있는 (동사, 인칭, 시제) 후보들.
class VerbHit {
  final String form;
  final List<(VerbInfo, int, String)> matches; // (동사, 인칭 0~5, 'present'|'preterite')
  const VerbHit(this.form, this.matches);
}

class VerbIndex {
  VerbIndex._();
  static final VerbIndex instance = VerbIndex._();

  final List<VerbInfo> verbs = [];
  List<String> persons = const ['yo', 'tú', 'él/ella', 'nosotros', 'vosotros', 'ellos'];
  final Map<String, List<(VerbInfo, int, String)>> _byForm = {};
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/grammar/verbs_core.json'))) as Map<String, dynamic>;
      persons = (j['persons'] as List?)?.cast<String>() ?? persons;
      for (final v in (j['verbs'] as List? ?? const [])) {
        final m = v as Map<String, dynamic>;
        final info = VerbInfo(
          inf: m['inf'] as String,
          ko: m['ko'] as String? ?? '',
          group: m['group'] as String? ?? '',
          present: (m['present'] as List?)?.cast<String>() ?? const [],
          preterite: (m['preterite'] as List?)?.cast<String>() ?? const [],
        );
        verbs.add(info);
        for (var i = 0; i < info.present.length; i++) {
          _byForm.putIfAbsent(info.present[i].toLowerCase(), () => []).add((info, i, 'present'));
        }
        for (var i = 0; i < info.preterite.length; i++) {
          _byForm.putIfAbsent(info.preterite[i].toLowerCase(), () => []).add((info, i, 'preterite'));
        }
      }
    } catch (_) {}
  }

  /// 문장 속 활용형(나온 순서, 같은 형은 한 번). 낱말 단위로만 맞춘다(`es` 가 `eres` 에 걸리지 않게).
  List<VerbHit> hitsIn(String text) {
    final out = <VerbHit>[];
    final seen = <String>{};
    for (final m in RegExp(r'[\p{L}]+', unicode: true).allMatches(text)) {
      final w = m.group(0)!.toLowerCase();
      final hits = _byForm[w];
      if (hits == null || !seen.add(w)) continue;
      out.add(VerbHit(m.group(0)!, hits));
    }
    return out;
  }

  static String tenseKo(String tense) => tense == 'present' ? '현재' : '단순과거';
}
