import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/alphabet_es.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../core/embed_env.dart';

/// 글자 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 구조).
/// 열리면 1초 뒤 자동 재생 · 다시 듣기 · IPA · 조음 위치 그림 · 모음 위치 · 예시 낱말 · 한국어와 비교.
Future<void> showAlphabetSoundSheet(BuildContext context, {required AlphabetUnit unit, required Color color}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.washi,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _AlphabetSoundSheet(unit: unit, color: color),
  );
}

/// 조음 위치 이름(화면 문구).
String placeLabel(String key) => switch (key) {
      'bilabial' => tr('두 입술 (양순음)'),
      'labiodental' => tr('윗니 + 아랫입술 (순치음)'),
      'interdental' => tr('이 사이 (치간음)'),
      'dental' => tr('윗니 뒤 (치음)'),
      'alveolar' => tr('윗잇몸 (치경음)'),
      'postalveolar' => tr('잇몸 뒤 (후치경음)'),
      'palatal' => tr('센입천장 (경구개음)'),
      'velar' => tr('여린입천장 (연구개음)'),
      'none' => tr('소리 없음'),
      'vowel' => tr('모음'),
      'stress' => tr('강세'),
      _ => key,
    };

// 조음 위치 그림(places_of_articulation.png, 960×1200) 위에 표시할 점 — 그림 안 비율 좌표.
const _placePoints = <String, List<Offset>>{
  'bilabial': [Offset(125 / 960, 480 / 1200), Offset(85 / 960, 850 / 1200)],
  'labiodental': [Offset(205 / 960, 470 / 1200), Offset(85 / 960, 850 / 1200)],
  'interdental': [Offset(190 / 960, 500 / 1200), Offset(155 / 960, 730 / 1200)],
  'dental': [Offset(228 / 960, 462 / 1200)],
  'alveolar': [Offset(268 / 960, 455 / 1200)],
  'postalveolar': [Offset(318 / 960, 430 / 1200)],
  'palatal': [Offset(497 / 960, 412 / 1200)],
  'velar': [Offset(623 / 960, 435 / 1200)],
};

// 모음 사다리꼴(ipa_vowel_chart.png, 960×778) 위 위치 — 스페인어 5모음 / 비슷한 한국어 모음.
const _esVowel = <String, Offset>{
  'a': Offset(697 / 960, 658 / 778),
  'e': Offset(375 / 960, 416 / 778),
  'i': Offset(216 / 960, 175 / 778),
  'o': Offset(858 / 960, 416 / 778),
  'u': Offset(858 / 960, 175 / 778),
};
const _koVowel = <String, Offset>{
  'a': Offset(671 / 960, 577 / 778), // 아 [ɐ]
  'e': Offset(345 / 960, 380 / 778), // 에
  'i': Offset(216 / 960, 175 / 778), // 이
  'o': Offset(858 / 960, 335 / 778), // 오 [o]
  'u': Offset(858 / 960, 175 / 778), // 우
};

class _AlphabetSoundSheet extends StatefulWidget {
  final AlphabetUnit unit;
  final Color color;
  const _AlphabetSoundSheet({required this.unit, required this.color});

  @override
  State<_AlphabetSoundSheet> createState() => _AlphabetSoundSheetState();
}

class _AlphabetSoundSheetState extends State<_AlphabetSoundSheet> {
  Timer? _autoPlay;

  @override
  void initState() {
    super.initState();
    _autoPlay = Timer(const Duration(seconds: 1), () => TtsService.instance.speak(widget.unit.say));
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final color = widget.color;
    final places = u.place.where(_placePoints.containsKey).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.sumiLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            _header(u, color),
            const SizedBox(height: 18),
            _section(tr('👄 소리 내는 법'), color, [
              if (u.place.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(spacing: 6, runSpacing: 4, children: [for (final p in u.place) _chip(placeLabel(p), color)]),
                ),
              Text(u.mouth, style: _body),
            ]),
            if (places.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(tr('📍 조음 위치'), color, [_ArticulationPicture(places: places, color: color)]),
            ],
            if (u.isVowel && _esVowel.containsKey(u.id)) ...[
              const SizedBox(height: 14),
              _section(tr('📍 모음 위치 — 스페인어 vs 한국어'), color, [_VowelPicture(vowel: u.id, color: color)]),
            ],
            const SizedBox(height: 14),
            _section(tr('🔊 예시 낱말'), color, [for (final e in u.examples) _exampleRow(e, color)]),
            const SizedBox(height: 14),
            _section(tr('🇰🇷 한국어와 비교'), color, [
              Text(trf('비슷한 소리: {0}', [u.korSim]), style: _body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(u.compare, style: _body),
            ]),
          ],
        ),
      ),
    );
  }

  static const _body = TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi);

  Widget _header(AlphabetUnit u, Color color) => Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 84),
            height: 84,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(u.letter, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.washi)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text('IPA [${u.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
              if (u.rd.isNotEmpty) KoReadingText(u.rd, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w600)),
            ]),
          ),
          IconButton(
            iconSize: 44,
            color: color,
            tooltip: tr('다시 듣기'),
            icon: const Icon(Icons.play_circle_fill),
            onPressed: () => TtsService.instance.speak(u.say),
          ),
        ],
      );

  Widget _exampleRow(AlphabetExample e, Color color) => InkWell(
        onTap: () => TtsService.instance.speak(e.es),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(Icons.volume_up_rounded, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.es, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                KoReadingText(e.rd, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                Text(e.ko, style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight)),
              ]),
            ),
            if (e.rank != null)
              Text(trf('빈도 {0}위', [e.rank!]), style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _section(String title, Color color, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.washiDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          ...children,
        ]),
      );
}

/// 조음 위치 그림 + 해당 자리에 동그라미.
class _ArticulationPicture extends StatelessWidget {
  final List<String> places;
  final Color color;
  const _ArticulationPicture({required this.places, required this.color});

  @override
  Widget build(BuildContext context) {
    final pts = [for (final p in places) ..._placePoints[p]!];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(6),
            child: AspectRatio(
              aspectRatio: 960 / 1200,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(assetPath('assets/images/ipa/places_of_articulation.png'), fit: BoxFit.fill),
                CustomPaint(painter: _DotsPainter(filled: pts, color: color)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 모음 사다리꼴 — 스페인어 5모음(작은 점), 지금 모음(큰 점), 비슷한 한국어 모음(빈 원).
class _VowelPicture extends StatelessWidget {
  final String vowel;
  final Color color;
  const _VowelPicture({required this.vowel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(6),
          child: AspectRatio(
            aspectRatio: 960 / 778,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(assetPath('assets/images/ipa/ipa_vowel_chart.png'), fit: BoxFit.fill),
              CustomPaint(
                painter: _DotsPainter(
                  faint: [for (final e in _esVowel.entries) if (e.key != vowel) e.value],
                  filled: [_esVowel[vowel]!],
                  ring: _koVowel[vowel],
                  color: color,
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        _legend(Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.75), shape: BoxShape.circle)), tr('스페인어'), color),
        const SizedBox(width: 14),
        _legend(
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.ai, width: 2))),
          tr('한국어'),
          AppColors.ai,
        ),
      ]),
    ]);
  }

  Widget _legend(Widget dot, String label, Color c) => Row(children: [
        dot,
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ]);
}

class _DotsPainter extends CustomPainter {
  final List<Offset> filled;
  final List<Offset> faint;
  final Offset? ring;
  final Color color;
  _DotsPainter({required this.filled, this.faint = const [], this.ring, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.045;
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    final faintPaint = Paint()..color = color.withValues(alpha: 0.25);
    for (final f in faint) {
      canvas.drawCircle(at(f), r * 0.55, faintPaint);
    }
    final fill = Paint()..color = color.withValues(alpha: 0.45);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final f in filled) {
      canvas.drawCircle(at(f), r, fill);
      canvas.drawCircle(at(f), r, stroke);
    }
    if (ring != null) {
      canvas.drawCircle(
        at(ring!),
        r * 1.35,
        Paint()
          ..color = AppColors.ai
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.filled != filled || old.ring != ring || old.color != color;
}
