// 아이패드 두 화면·회화 리더 확인 스크린샷 흐름 — 일본어앱 dialogue_pane_test.dart 를 옮긴 것(2026-11-02).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <스크래치 폴더> integration_test/dialogue_pane_test.dart
import 'package:flutter/material.dart' show ListView, NavigationRail;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spanish_universe/core/l10n.dart';
import 'package:spanish_universe/data/db/app_database.dart';
import 'package:spanish_universe/data/db/seed_loader.dart';
import 'package:spanish_universe/main.dart';
import 'package:spanish_universe/services/achievement_service.dart';
import 'package:spanish_universe/services/ko_reading.dart';
import 'package:spanish_universe/services/learner_prefs.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  Finder rail(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

  testWidgets('dialogue pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    // 앱 시작 순서를 main() 과 똑같이
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const SpanishUniverseApp());
    await wait(t, 1500);
    await shot(t, '10_home_learn');

    // 기초 첫 줄 「알파벳과 발음」 → 격자 → 글자 Ñ 시트(1초 뒤 자동 재생)
    await t.tap(find.text('알파벳과 발음'));
    await wait(t, 2000);
    await shot(t, '10b_alphabet');
    await t.tapAt(const Offset(445, 248)); // 격자 첫 타일(A a) — 모음 묶음이 기본
    await wait(t, 2500);
    await shot(t, '10c_alphabet_sheet');
    await t.tapAt(const Offset(600, 160));
    await wait(t, 1000);

    await t.tap(find.text('장면 컷과 함께 읽고 듣기'));
    await wait(t, 2500);
    await shot(t, '11_dialogue_home');

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await shot(t, '12_topic_list');

    await t.tap(find.text('매칭').last);
    await wait(t, 1500);
    await shot(t, '13_reader_before_play');

    // 시안 ES-01 동사 칩: 4번 턴(Yo soy Lucía) → 캡션 아래 「soy」 칩 → 활용표 시트
    await t.tap(find.textContaining('Yo soy Lucía').first);
    await wait(t, 1500);
    await t.tap(find.text('soy').first);
    await wait(t, 1500);
    await shot(t, '13b_verb_sheet');
    await t.tapAt(const Offset(600, 160)); // 시트는 오른쪽 칸 안에서 열린다 — 칸 위쪽 막(barrier)을 눌러 닫기
    await wait(t, 1000);

    // 문장 레마 탭 → 단어창(4번 턴 스크립트 줄의 soy → ser)
    await t.tapOnText(find.textRange.ofSubstring('soy').first);
    await wait(t, 1500);
    await shot(t, '13c_word_sheet');
    await t.tapAt(const Offset(600, 160));
    await wait(t, 1000);

    await t.tap(find.text('재생').first);
    await wait(t, 6000);
    await shot(t, '14_reader_playing');

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '15_card_front');
    await t.tap(find.text('탭해서 확인'));
    await wait(t, 800);
    await shot(t, '16_card_back');
    await t.pageBack();
    await wait(t, 1200);

    await t.tap(rail('복습'));
    await wait(t, 1200);
    await shot(t, '17_review_tab');

    await t.tap(rail('프로필'));
    await wait(t, 2000);
    await shot(t, '18_me_desk');

    await t.tap(find.text('프로필 · 설정'));
    await wait(t, 1500);
    await shot(t, '19_profile');

    await t.tap(find.text('앱 소개').first);
    await wait(t, 1500);
    await shot(t, '20_about');

    await t.tap(rail('배우기'));
    await wait(t, 1000);
    await shot(t, '21_home_menu');
    final cliffTile = find.text('R1~R5').first;
    await t.dragUntilVisible(cliffTile, find.byType(ListView).first, const Offset(0, -200));
    await wait(t, 800);
    await t.tap(cliffTile);
    await wait(t, 2500);
    await shot(t, '22_cliff_words');
    await t.tap(find.textContaining('회화 단어 포함'));
    await wait(t, 800);
    await t.tap(find.text('회화').last);
    await wait(t, 1200);
    await shot(t, '23_cliff_conv');
  });
}
