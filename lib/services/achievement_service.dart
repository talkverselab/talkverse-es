import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dialogue_service.dart';
import '../core/embed_env.dart';

/// 성과 기록·집계 — 일본어앱 achievement_service.dart 를 옮긴 것(2026-11-02, 공통 프롬프터 §3).
///
/// **센다**: 편 완주(「모든 문장 듣기」 끝까지) · 그림 카드 결과 · 만난 동사(동사 칩 시트를 연 원형) · 일별 기록 · 주제별 진행.
/// 라이트너·빈도 커버율·본 문자 수는 그 엔진이 이 앱에 없어 뺐다.
/// **안 센다**: 앱 오픈·스트릭·포인트·순위. 저장은 SharedPreferences `achievements_v1`(JSON 하나).
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();
  static final _key = pk('achievements_v1');

  final Map<String, String> _episodes = {}; // 편 id → 완주 날짜(yyyy-mm-dd, 처음)
  final Map<String, List<int>> _cards = {}; // 편 id → [맞음, 전체] (마지막 세션)
  final Set<String> _verbs = {}; // 동사 칩 시트로 본 원형
  final Map<String, Map<String, int>> _daily = {}; // 날짜 → {episodes, cards}
  final ValueNotifier<int> changes = ValueNotifier(0);
  bool _loaded = false;

  String get today => _ymd(DateTime.now());
  static String _ymd(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        final j = json.decode(raw) as Map<String, dynamic>;
        (j['episodes'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _episodes[k] = v.toString());
        (j['cards'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _cards[k] = (v as List).cast<int>());
        _verbs.addAll((j['verbs'] as List? ?? const []).cast<String>());
        (j['daily'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _daily[k] = (v as Map).map((a, b) => MapEntry(a.toString(), (b as num).toInt())));
      }
    } catch (e) {
      debugPrint('Achievement: load 실패 $e');
    }
    _loaded = true;
  }

  Future<void> _save() async {
    changes.value++;
    final data = json.encode({'episodes': _episodes, 'cards': _cards, 'verbs': _verbs.toList(), 'daily': _daily});
    (await SharedPreferences.getInstance()).setString(_key, data);
  }

  void _bump(String what, [int n = 1]) {
    final d = _daily.putIfAbsent(today, () => {});
    d[what] = (d[what] ?? 0) + n;
  }

  /// 편을 끝까지 들었다. 처음 완주한 날만 기록(반복 횟수는 세지 않는다).
  Future<bool> markEpisodeDone(String id) async {
    await load();
    final first = !_episodes.containsKey(id);
    if (first) {
      _episodes[id] = today;
      _bump('episodes');
      await _save();
    }
    return first;
  }

  /// 그림 카드 세션 결과(편별 마지막 세션).
  Future<void> markCards(String episodeId, int right, int total) async {
    await load();
    _cards[episodeId] = [right, total];
    _bump('cards', right);
    await _save();
  }

  /// 동사 칩 시트를 열어 본 원형(시안 ES-01 「만난 동사」).
  Future<void> markVerbSeen(String inf) async {
    await load();
    if (_verbs.add(inf)) {
      _bump('verbs');
      await _save();
    }
  }

  Set<String> get verbsSeen => _verbs;
  bool isDone(String id) => _episodes.containsKey(id);
  int get episodesDone => _episodes.length;
  List<int>? cardsOf(String id) => _cards[id];

  /// 주제·레벨별 완주 수 / 전체 수.
  (int, int) progress({required String island, required String region}) {
    final all = DialogueService.instance.list(region: region, island: island);
    final done = all.where((d) => _episodes.containsKey(d.id)).length;
    return (done, all.length);
  }

  /// 최근 7일(오늘 포함, 오래된 날부터) 완주 편 수.
  List<(String, int)> week() {
    final now = DateTime.now();
    return [for (var i = 6; i >= 0; i--) (_ymd(now.subtract(Duration(days: i))), _daily[_ymd(now.subtract(Duration(days: i)))]?['episodes'] ?? 0)];
  }

  Map<String, int> get thisWeek {
    final out = {'episodes': 0, 'cards': 0};
    for (final (d, _) in week()) {
      final m = _daily[d];
      if (m == null) continue;
      for (final k in out.keys) {
        out[k] = out[k]! + (m[k] ?? 0);
      }
    }
    return out;
  }
}
