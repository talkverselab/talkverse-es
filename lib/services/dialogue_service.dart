import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_prefs.dart';
import 'script_sync.dart';
import '../core/embed_env.dart';

/// 회화 로더 — 편 JSON `assets/data/dialogues/R<0~5>/<주제>/<편id>.json`(2026-11-18, 일본어앱 구조).
///
/// 각 파일은 서버 판이 있으면 그것([ScriptSync], 사용자 지시 2026-11-18 「다이얼로그까지 모두 DB에서」).
/// 여성 학습자: 편 `speakers_f`(상대 이름 교체)·턴 `tl_f`/`rd_f`/`ko_f`(성이 드러나는 줄)를 쓴다.
/// 옛 `L1.json`(편 1개)은 더 읽지 않는다.
/// 문장 내용어 한 개: 표면형(문장 속 모양)·기본형(사전형)·읽기(스페인어는 비움).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl; // 목표어(스페인어)
  final String reading; // 보조 줄 — 스페인어는 없음
  final String rd; // 한글 독음(지금 데이터에 없으면 빈 값)
  final String ko;
  final String note;
  final List<String> tags;
  final List<String> newWords;
  final String? art; // 턴 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형) — 단어장 연결(2026-11-04, tools/add_lemmas.py)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.reading,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    required this.newWords,
    this.art,
    this.lemmas = const [],
  });
  /// [female] = 여성 학습자판(`tl_f`·`rd_f`·`ko_f` 가 있으면 그것).
  factory DialogueTurn.fromJson(Map<String, dynamic> j, {bool female = false}) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: ((female ? j['tl_f'] : null) ?? j['tl'] ?? j['es']) as String? ?? '',
        reading: j['reading'] as String? ?? '',
        rd: ((female ? j['rd_f'] : null) ?? j['rd']) as String? ?? '',
        ko: ((female ? j['ko_f'] : null) ?? j['ko']) as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 단어 후보: new → 없음(문장 안 단어는 ArtService.urlInText 가 찾는다).
  List<String> get pictureWords => newWords;
}

class Dialogue {
  final String id;
  final String region; // R0..R5
  final String island; // survival friends love life travel culture work study
  final String kind;
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers; // A → 이름
  final Map<String, String> genders; // A → male|female (데이터에 정해진 성별)
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.turns,
    this.art,
  });
  factory Dialogue.fromJson(Map<String, dynamic> j, {bool female = false}) {
    final sp = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    if (female) ((j['speakers_f'] as Map?) ?? const {}).forEach((k, v) => sp['$k'] = '$v');
    final g = <String, String>{};
    ((j['genders'] as Map?) ?? const {}).forEach((k, v) => g['$k'] = '$v');
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? '',
      kind: j['kind'] as String? ?? 'long',
      title: j['title'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '💬',
      scene: _sceneFor(j['scene'] as String? ?? '', j, female),
      speakers: sp,
      genders: g,
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>, female: female)).toList(),
      art: j['art'] as String?,
    );
  }

  /// 여성판 장면 설명: `scene_f` 가 있으면 그것, 없으면 바뀐 상대 이름만 갈아 끼운다.
  static String _sceneFor(String scene, Map<String, dynamic> j, bool female) {
    if (!female) return scene;
    if (j['scene_f'] is String) return j['scene_f'] as String;
    var s = scene;
    final base = (j['speakers'] as Map?) ?? const {};
    ((j['speakers_f'] as Map?) ?? const {}).forEach((k, v) {
      final old = '${base[k] ?? ''}';
      if (old.isNotEmpty && !old.contains('{')) s = s.replaceAll(old, '$v');
    });
    return s;
  }

  bool get isChat => kind == 'chat';

  /// 화면에 보일 장면 설명 — 원고의 「A」(학습자)를 이름(없으면 「나」)으로(일본어앱 111).
  String get sceneShown => scene.replaceAllMapped(RegExp(r'(?<![A-Za-z])A(?![A-Za-z]) ?(?=[가-힣])'), (_) => speakerName('A'));

  /// 화자 표시 이름: `{name}`(학습자 자리) → 프로필 이름, 없으면 「나」.
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별: 이야기에 성별이 정해진 화자는 데이터 성별, 학습자 자리(`{name}`)면 프로필 성별.
  String voiceGender(String sp) {
    if ((speakers[sp] ?? '').contains('{name}')) return LearnerPrefs.gender.value;
    return genders[sp] ?? LearnerPrefs.voiceGender(sp);
  }

  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcst])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3, 't': 4};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌', 'friends': '친구', 'love': '사랑', 'life': '생활',
    'travel': '여행', 'culture': '문화', 'work': '직장', 'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘', 'friends': '🤝', 'love': '💘', 'life': '🏠',
    'travel': '✈️', 'culture': '🎬', 'work': '💼', 'study': '🎓',
  };
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4', 'R5'];
  static const levelKo = {'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급', 'R5': '어휘 완주'};
  static final _prefLast = pk('dialogue_last');

  final Map<String, Dialogue> _byId = {};
  Future<void>? _loading;
  String? _lastOpened;
  bool? _female; // 읽을 때의 학습자 성별 — 바뀌면 다시 읽는다

  /// 원고가 서버 판으로 바뀌거나 학습자 성별이 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// 마지막으로 연 편(홈 「이어서 읽기」).
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await SharedPreferences.getInstance()).setString(_prefLast, id);
  }

  /// 넓은 화면에서 탭이 동시에 떠 두 번 불릴 수 있어 Future 하나를 같이 기다린다.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    _lastOpened = (await SharedPreferences.getInstance()).getString(_prefLast);
    await _readAll();
    LearnerPrefs.gender.addListener(() async {
      if (_female == LearnerPrefs.isFemale) return;
      await _readAll();
      revision.value++;
    });
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  static final _pat = RegExp(r'^assets/data/dialogues/R[0-5]/[^/]+/[^/]+\.json$');

  /// 앱 안 편 + 서버에서 받은 새 편 − 서버에서 뺀 편. 각 파일은 덮어쓴 판이 있으면 그것.
  Future<void> _readAll() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final female = LearnerPrefs.isFemale;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final rels = <String>{
      for (final k in manifest.listAssets())
        if (unpackAsset(k) case final p? when _pat.hasMatch(p)) p.substring('assets/data/'.length),
      ...sync.added.where((p) => _pat.hasMatch('assets/data/$p')),
    }..removeAll(sync.removed);
    final next = <String, Dialogue>{};
    for (final rel in rels) {
      try {
        final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>, female: female);
        if (d.turns.isNotEmpty) next[d.id] = d;
      } catch (e) {
        debugPrint('DialogueService: $rel 읽기 실패 $e');
      }
    }
    _female = female;
    _byId
      ..clear()
      ..addAll(next);
  }

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList();

  List<Dialogue> list({String? region, String? island}) {
    final out = _byId.values.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();
    out.sort((a, b) => a.region != b.region ? a.region.compareTo(b.region) : a.orderKey.compareTo(b.orderKey));
    return out;
  }

  /// 편이 있는 레벨(고정 순서).
  List<String> get regions => levels.where((r) => _byId.values.any((d) => d.region == r)).toList();

  List<String> islandsOf(String region) {
    final has = _byId.values.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _byId.values.where((d) => d.region == region).length;
}
