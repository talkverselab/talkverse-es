import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/embed_env.dart';

/// 커리큘럼 단계 목록(CURRICULUM_SPEC §12, 사용자 지시 2026-11-23 「커리큘럼 내용도 모두 DB에서 · 5단계」).
///
/// 앱 안 기본값 `assets/curriculum_es.json` → 서버 `GET https://talkverse.uk/api/curriculum/es` 의 rev 가 더 크면 받아 기기에 두고 그것을 쓴다.
/// 형식 `{rev, stages:[{n, title, desc, dialogueIds, pick, pass, daily}], prep:[…]}`. 어느 편이 어느 단계인지는 이 파일이 정한다(코드에 없음).
/// 앱에 없는 편 id 는 건너뛰고, 편이 0개인 단계는 숨긴다. 읽기 실패면 [stages] 가 비어 회화 레벨(R) 방식으로 돈다.
class CurStage {
  final int n;
  final String title, desc;
  final List<String> dialogueIds;

  /// 고를 개수 · 통과 점수(%) · 하루 새 편 수[가볍게, 보통, 집중] — 서버 값, 없으면 기본(3·5·10 / 80 / 1·2·3).
  final List<int> pick;
  final int pass;
  final List<int> daily;

  /// 무료 단계인가(PAYWALL_SPEC §2 — 서버 `free`, 없으면 1단계만 무료).
  final bool free;
  const CurStage(this.n, this.title, this.desc, this.dialogueIds,
      {this.pick = kDefaultPick, this.pass = kDefaultPass, this.daily = kDefaultDaily, bool? free})
      : free = free ?? n == 1;
  String get key => '$n';
  CurStage withIds(List<String> ids) => CurStage(n, title, desc, ids, pick: pick, pass: pass, daily: daily, free: free);
}

const kDefaultPick = [3, 5, 10];
const kDefaultPass = 80;
const kDefaultDaily = [1, 2, 3];

class CurriculumPlan {
  CurriculumPlan._();
  static CurriculumPlan instance = CurriculumPlan._();

  @visibleForTesting
  CurriculumPlan.forTest({Future<String?> Function(String url)? fetch, String? bundled}) : _fetch = fetch, _bundled = bundled;

  static const url = 'https://talkverse.uk/api/curriculum/es';
  static const _asset = 'assets/curriculum_es.json';
  static final _prefKey = pk('curriculum_plan');

  Future<String?> Function(String url)? _fetch;
  String? _bundled;

  int rev = 0;
  List<CurStage> _all = [];

  /// 무료 한도(PAYWALL_SPEC §2) — 문법 스텝 수 · 언어감각 급 수. 서버 최상위 값, 없으면 2 · 1.
  int freeSteps = 2;
  int freeSenseLevels = 1;
  bool _ready = false;
  bool _checked = false;

  /// [known] = 앱에 있는 편 id. 그중 있는 편만 남기고 빈 단계는 뺀 목록.
  List<CurStage> stages(bool Function(String id) known) => [
        for (final s in _all)
          if (s.dialogueIds.any(known)) s.withIds(s.dialogueIds.where(known).toList()),
      ];

  bool get hasPlan => _all.isNotEmpty;

  /// 기기에 받아 둔 것 또는 앱 안 것을 읽는다(네트워크 없음).
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final b = _bundled ?? utf8.decode((await rootBundle.load(assetPath(_asset))).buffer.asUint8List());
      _apply(json.decode(b) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('CurriculumPlan: 앱 안 기본값 읽기 실패 $e');
    }
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_prefKey);
      if (saved != null) {
        final j = json.decode(saved) as Map<String, dynamic>;
        if (((j['rev'] as num?)?.toInt() ?? 0) > rev) _apply(j);
      }
    } catch (_) {}
  }

  /// 서버 판이 더 새것이면 받아 바꾼다. 바뀌었으면 true. 한 실행에 한 번만 묻는다.
  Future<bool> refresh() async {
    await init();
    if (_checked) return false;
    _checked = true;
    try {
      final body = await (_fetch ?? _get)(url);
      if (body == null) return false;
      final j = json.decode(body) as Map<String, dynamic>;
      if (((j['rev'] as num?)?.toInt() ?? 0) <= rev) return false;
      if (!_apply(j)) return false; // 단계가 없는 판은 쓰지 않는다
      await (await SharedPreferences.getInstance()).setString(_prefKey, body);
      return true;
    } catch (e) {
      debugPrint('CurriculumPlan: 서버 받기 실패 $e');
      return false;
    }
  }

  bool _apply(Map<String, dynamic> j) {
    final list = <CurStage>[];
    for (final s in ((j['stages'] as List?) ?? const []).cast<Map>()) {
      final n = (s['n'] as num?)?.toInt();
      if (n == null) continue;
      final pick = [for (final x in (s['pick'] as List?) ?? const []) if (x is num && x > 0) x.toInt()];
      final pass = (s['pass'] as num?)?.toInt();
      final d = s['daily'] is Map ? s['daily'] as Map : const {};
      int dn(String k, int def) => (d[k] as num?)?.toInt() ?? def;
      list.add(CurStage(n, '${s['title'] ?? '$n단계'}', '${s['desc'] ?? ''}', [for (final x in (s['dialogueIds'] as List?) ?? const []) '$x'],
          pick: pick.isEmpty ? kDefaultPick : pick,
          pass: pass != null && pass > 0 && pass <= 100 ? pass : kDefaultPass,
          daily: [dn('light', 1), dn('normal', 2), dn('focus', 3)],
          free: s['free'] is bool ? s['free'] as bool : null));
    }
    list.sort((a, b) => a.n.compareTo(b.n));
    if (list.isEmpty) return false;
    _all = list;
    rev = (j['rev'] as num?)?.toInt() ?? 0;
    freeSteps = (j['freeSteps'] as num?)?.toInt() ?? 2;
    freeSenseLevels = (j['freeSenseLevels'] as num?)?.toInt() ?? 1;
    return true;
  }

  Future<String?> _get(String u) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(Uri.parse(u));
      req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-es/0.1');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
