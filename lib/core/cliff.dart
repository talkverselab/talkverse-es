/// 스페인어 절벽 값 — 코드 한 곳(HANDOFF §5, 사용자 결정 2026-11-03). 누적 55/60/70/80% 에 처음 닿는 순위가 R1~R4 의 끝, 그 밖은 R5.
/// R5 는 2,000위에서 끊는다(사용자 지시 2026-11-07). 2,000위 누적 = 2,500위 88.9% 에서 2,001~2,500위 몫(약 1.0%)을 뺀 값.
const List<int> kWordCliffs = [45, 69, 168, 570];
const int kWordCap = 2000;
const double kWordCapPct = 87.9;

String regionOf(int rank) {
  for (var i = 0; i < kWordCliffs.length; i++) {
    if (rank <= kWordCliffs[i]) return 'R${i + 1}';
  }
  return 'R5';
}
