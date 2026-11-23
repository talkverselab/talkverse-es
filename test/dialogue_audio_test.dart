import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_universe/services/dialogue_audio.dart';

void main() {
  test('녹음 글 ↔ 원고 대조 — 부호·대소문자·이름 자리 무시, 대사가 바뀌면 안 맞음', () {
    expect(audioFitsScript('Lucía, ¿a qué hora cenas?', 'Lucía, ¿a qué hora cenas?'), isTrue);
    expect(audioFitsScript('lucía a qué hora cenas', '¡Lucía! ¿A qué hora cenas?'), isTrue);
    expect(audioFitsScript('Hola, Ana, ¿qué tal?', 'Hola, {name}, ¿qué tal?'), isTrue);
    expect(audioFitsScript('Hola (sonríe), ¿qué tal?', 'Hola, ¿qué tal?'), isTrue);
    expect(audioFitsScript('¿A qué hora comes?', '¿A qué hora cenas?'), isFalse);
  });
}
