import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_prefs.dart';

/// 회화 로더 — 일본어앱 모델(`Dialogue`·`DialogueTurn`)로 읽어 새 리더에 넘긴다(2026-11-02, 공통 프롬프터 §4).
///
/// 데이터는 바꾸지 않는다: 지금 회화는 옛 형식 `assets/data/dialogues/L1.json`(편 배열, 턴 {num, speaker, es, ko, note, tags})
/// 하나뿐이라 그대로 읽어 변환한다. 새 구조(R0~R4·주제별 편 JSON)로 다시 쓰는 것은 회화 작업이 풀린 뒤.
/// 레벨은 R 로 재태그하지 않고 `L1`(「이야기」), 주제는 연애 서사라 `love`.
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
  });
  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['tl'] ?? j['es']) as String? ?? '',
        reading: j['reading'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
      );

  /// 그림 조회용 단어 후보: new → 없음(문장 안 단어는 ArtService.urlInText 가 찾는다).
  List<String> get pictureWords => newWords;
}

class Dialogue {
  final String id;
  final String region; // 지금은 L1(이야기)
  final String island; // 주제 — 지금은 love
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
  bool get isChat => kind == 'chat';

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

  String get orderKey => id;
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['love'];
  static const islandKo = {'love': '사랑'};
  static const islandEmoji = {'love': '💘'};
  static const levels = ['L1'];
  static const levelKo = {'L1': '이야기'};
  static const _prefLast = 'dialogue_last';
  static const _files = ['assets/data/dialogues/L1.json'];

  final Map<String, Dialogue> _byId = {};
  Future<void>? _loading;
  String? _lastOpened;

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
    for (final path in _files) {
      try {
        final j = json.decode(await rootBundle.loadString(path)) as Map<String, dynamic>;
        final level = j['level'] as String? ?? 'L1';
        final chars = (j['characters'] as Map?) ?? const {};
        final speakers = <String, String>{}, genders = <String, String>{};
        chars.forEach((k, v) {
          final m = v as Map;
          speakers['$k'] = '${m['name'] ?? k}';
          if (m['gender'] != null) genders['$k'] = '${m['gender']}';
        });
        for (final e in (j['episodes'] as List? ?? const [])) {
          final ep = e as Map<String, dynamic>;
          final turns = ((ep['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>)).toList();
          if (turns.isEmpty) continue;
          final id = '${level}_${ep['id']}';
          _byId[id] = Dialogue(
            id: id,
            region: level,
            island: 'love',
            kind: 'long',
            title: ep['title'] as String? ?? '',
            emoji: ep['emoji'] as String? ?? '💬',
            scene: ep['scenario'] as String? ?? '',
            speakers: speakers,
            genders: genders,
            turns: turns,
            art: ep['art'] as String?,
          );
        }
      } catch (_) {}
    }
  }

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList();

  List<Dialogue> list({String? region, String? island}) {
    final out = _byId.values.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();
    out.sort((a, b) => a.orderKey.compareTo(b.orderKey));
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
