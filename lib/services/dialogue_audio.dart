import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'content_sync.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';
import 'tts_service.dart';

/// 회화 턴 녹음(mp4) 우선 재생 — 일본어앱 dialogue_audio.dart 를 옮긴 것(2026-11-23).
///
/// 목록은 `ContentSync.audioIndex`(편 → 턴 → 학습자 성별판 m·f). 기기에 받아 둔 파일이 있으면 파일로, 없으면 주소로 재생한다.
/// 녹음이 없는 줄(합격 못 한 줄 등)이나 대사를 고친 뒤 옛 녹음만 남은 줄은 기기 음성(TTS)으로 읽는다.
class DialogueAudio {
  DialogueAudio._();
  static final DialogueAudio instance = DialogueAudio._();

  AudioPlayer? _player;
  Completer<void>? _wait;
  int _gen = 0;

  /// 이 턴에 쓸 녹음(없으면 null). [script] 를 주면 녹음 글이 지금 원고와 맞을 때만.
  AudioLine? line(String episodeId, int turn, {String? script}) {
    final l = ContentSync.instance.audioIndex[episodeId]?[turn]?[LearnerPrefs.isFemale ? 'f' : 'm'];
    if (l == null || script == null) return l;
    return audioFitsScript(l.text, script) ? l : null;
  }

  /// 녹음을 끝까지 재생한다. 녹음이 없거나 재생에 실패하면 false(부르는 쪽이 TTS 로 넘긴다).
  Future<bool> play(String episodeId, int turn, {double rate = 1.0, String? script}) async {
    final l = line(episodeId, turn, script: script);
    if (l == null) return false;
    final my = ++_gen;
    try {
      await TtsService.instance.stop();
      final p = _player ??= AudioPlayer();
      await p.stop();
      _wait?.complete();
      final done = _wait = Completer<void>();
      final sub = p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      try {
        final url = '${ContentSync.instance.base}/${l.key}';
        final f = ContentSync.instance.localFile(url);
        await p.setPlaybackRate(rate);
        await p.play(f != null ? DeviceFileSource(f.path) : UrlSource(url)).timeout(const Duration(seconds: 12));
        if (my != _gen) return true;
        await p.setPlaybackRate(rate); // 일부 기기는 재생을 시작한 뒤에야 속도가 먹는다
        await done.future.timeout(Duration(milliseconds: (l.ms / rate).round() + 6000), onTimeout: () {});
      } finally {
        await sub.cancel();
      }
      return true;
    } catch (e) {
      debugPrint('DialogueAudio: 재생 실패 $episodeId/$turn $e');
      return false;
    }
  }

  Future<void> stop() async {
    _gen++;
    final w = _wait;
    if (w != null && !w.isCompleted) w.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}

/// 턴 하나 읽기: 녹음이 있으면 그것, 없으면 기기 음성. 끝날 때까지 기다린다.
Future<void> speakTurn(Dialogue d, DialogueTurn t, {double rate = 1.0}) async {
  if (await DialogueAudio.instance.play(d.id, t.num, rate: rate, script: t.tl)) return;
  final s = LearnerPrefs.fill(t.tl).replaceAll(RegExp(r'[（(][^)）]*[)）]'), '').trim();
  await TtsService.instance.speakAs(s.isEmpty ? t.tl : s, gender: d.voiceGender(t.speaker), rate: rate * 0.45);
}

/// 녹음 글이 원고 줄과 같은 말인가. 자리 표시({name} …)는 아무 글이나, 대소문자·문장부호·괄호 속 지문은 보지 않는다.
bool audioFitsScript(String audio, String script) {
  String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[（(][^)）]*[)）]'), '')
      .replaceAll(RegExp(r'[\s¿¡!?.,;:…"“”«»\-—–~]'), '');
  final parts = script.split(RegExp(r'\{[a-z_]+\}')).map((p) => RegExp.escape(norm(p)));
  return RegExp('^${parts.join('.*?')}\$').hasMatch(norm(audio));
}
