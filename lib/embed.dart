import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/embed_env.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/account.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'data/purchase.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/achievement_service.dart';
import 'services/content_sync.dart';
import 'services/ko_reading.dart';
import 'services/learner_prefs.dart';

export 'core/embed_env.dart' show Embed;

/// 통합 앱(Talkverse) 연결점 — EMBED_GUIDE.md(2026-11-09), ko·ja 와 같은 약속.
/// 단독 앱 `main()`: `await embedInit()` → `runApp(embedApp(onOrientation: …))`.
/// 통합 앱: `await embedInit(embedded: true)` → 이 언어 화면을 열 때 `embedApp(onSwitchLanguage: …)`.
late final AppDatabase appDb;
bool _inited = false;
bool _syncFirst = false;

/// 가격표 = ~/talkverse/PRICING.md(사용자 확정 2026-11-09) — 앱 할인가(30%)·앱 정가.
const plans = [
  Plan('lang_es_1m', 1, 3900, listKrw: 5500),
  Plan('lang_es_3m', 3, 9000, listKrw: 12900),
  Plan('lang_es_1y', 12, 19900, listKrw: 28500),
  Plan('lang_es_life', 0, 49000, listKrw: 69900),
  Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
  Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
];

/// 초기화 전부(화면 방향·runApp 제외). 여러 번 불러도 한 번만 한다.
Future<void> embedInit({bool embedded = false}) async {
  if (_inited) return;
  _inited = true;
  WidgetsFlutterBinding.ensureInitialized();
  Embed.embedded = embedded;
  if (!embedded) await migrateStorage(); // 옛 이름은 단독 앱에만 있다
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await LearnerPrefs.load();
  await AchievementService.instance.load();
  Account.load(); // Talkverse ID — 저장된 로그인 표시 + 뒤에서 토큰 갱신(기다리지 않음)
  Purchase.configure(Embed.code, plans);
  // 그림(장면 컷·단어 그림) 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(사용자 지시 2026-11-04)
  final v = WidgetsBinding.instance.platformDispatcher.views.first;
  final wide = v.physicalSize.shortestSide / v.devicePixelRatio >= 600;
  _syncFirst = await ContentSync.instance.init(large: wide);
}

/// runApp 에 넘기는 위젯. [onSwitchLanguage] 가 있으면 프로필 설정 맨 위에 「다른 언어 배우기」.
/// [onOrientation] = 단독 앱이 화면 방향을 다시 계산할 때(통합 앱은 넘기지 않는다).
Widget embedApp({VoidCallback? onSwitchLanguage, void Function(double shortest)? onOrientation}) {
  Embed.onSwitchLanguage = onSwitchLanguage;
  return SpanishUniverseApp(syncFirst: _syncFirst, onOrientation: onOrientation);
}

/// 옛 저장 이름(접두 없음) → `es_` 접두로 한 번 옮긴다(단독 앱만). 순서: DB 파일 → 키 → 그림 폴더.
/// DB 를 먼저 옮겨야, 실패했을 때 db_version 만 옮겨지고 새 DB 가 빈 채로 남는 일이 없다.
/// 학습자 이름·성별(learner_*)·표시 언어(app_lang)·로그인(보안 저장소 tv_*)은 언어 공통이라 그대로.
const migratedKeys = [
  'show_ko_reading_v2', 'memorized_words', 'achievements_v1', 'dialogue_last',
  'art_version_v1', 'art_scene_manifest_v1', 'art_manifest_es_v1', 'art_manifest_es_at', 'db_version',
  'iap_owned2', 'iap_owned', 'iap_pending',
];

Future<void> migrateStorage() async {
  final p = await SharedPreferences.getInstance();
  final done = pk('storage_migrated_v1');
  if (p.getBool(done) ?? false) return;
  // 1) DB 파일 — 옮기지 못하면 키도 그대로 두고 다음 실행에 다시 시도한다.
  try {
    final docs = (await getApplicationDocumentsDirectory()).path;
    for (final ext in ['', '-wal', '-shm']) {
      final old = File('$docs/$legacyDbName.sqlite$ext'), neu = File('$docs/$dbName.sqlite$ext');
      if (await old.exists() && !await neu.exists()) await old.rename(neu.path);
    }
  } catch (e) {
    debugPrint('migrateStorage db: $e');
    return;
  }
  // 2) 설정 키(memo:* 는 앞부분이 같은 것 전부)
  final keys = [...migratedKeys, ...p.getKeys().where((k) => k.startsWith('memo:'))];
  for (final k in keys) {
    final v = p.get(k);
    if (v == null || p.containsKey(pk(k))) continue;
    switch (v) {
      case String s: await p.setString(pk(k), s);
      case bool b: await p.setBool(pk(k), b);
      case int i: await p.setInt(pk(k), i);
      case double d: await p.setDouble(pk(k), d);
      case List l: await p.setStringList(pk(k), l.cast<String>());
    }
    await p.remove(k);
  }
  // 3) 그림 폴더 Support/art → Support/es/art (못 옮겨도 다시 받으면 되므로 계속)
  try {
    final sup = (await getApplicationSupportDirectory()).path;
    final art = Directory('$sup/art'), artn = Directory('$sup/${Embed.code}/art');
    if (await art.exists() && !await artn.exists()) {
      await artn.parent.create(recursive: true);
      await art.rename(artn.path);
    }
  } catch (e) {
    debugPrint('migrateStorage art: $e');
  }
  await p.setBool(done, true);
}

class SpanishUniverseApp extends StatelessWidget {
  final bool syncFirst;
  final void Function(double shortest)? onOrientation;
  const SpanishUniverseApp({super.key, this.syncFirst = false, this.onOrientation});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: tr('스페인어유니버스'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          if (onOrientation != null) WidgetsBinding.instance.addPostFrameCallback((_) => onOrientation!(mq.size.shortestSide));
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
      ),
    );
  }
}
