import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 통합 앱(Talkverse, `~/talkverse/talkverse-app`) 임베드 환경 — EMBED_GUIDE.md(2026-11-09).
/// 단독 앱이면 [Embed.embedded] = false 로 지금과 똑같이 돈다.
class Embed {
  Embed._();
  static bool embedded = false;
  static VoidCallback? onSwitchLanguage; // 있으면 프로필 설정 맨 위에 「다른 언어 배우기」
  static const package = 'spanish_universe';
  static const code = 'es';
}

/// 에셋 경로 — 통합 앱이 패키지로 부르면 `packages/spanish_universe/assets/…`.
String assetPath(String p) => Embed.embedded && !p.startsWith('packages/') ? 'packages/${Embed.package}/$p' : p;

/// 에셋 목록(AssetManifest) 키를 앱 기준 `assets/…` 로 되돌린다(통합 앱에서는 `packages/spanish_universe/` 가 붙어 온다).
String? unpackAsset(String key) {
  const pre = 'packages/${Embed.package}/';
  if (key.startsWith(pre)) return key.substring(pre.length);
  return Embed.embedded ? null : key; // 통합 앱에서 다른 패키지 에셋은 무시
}

/// 이 언어 전용 저장 이름(SharedPreferences 키) — `es_` 접두. 학습자 이름·성별·표시 언어·로그인은 접두 없이 공유.
String pk(String key) => '${Embed.code}_$key';

/// 이 언어 전용 기기 폴더 — ApplicationSupport/es/(통합 앱에서 다른 언어 패키지와 겹치지 않게).
Future<String> esDataDir() async {
  final d = Directory('${(await getApplicationSupportDirectory()).path}/${Embed.code}');
  if (!await d.exists()) await d.create(recursive: true);
  return d.path;
}

/// drift DB 이름 — 파일은 ApplicationDocuments/es_spanish_universe.sqlite. 옛 이름 spanish_universe 는 단독 앱만 한 번 옮긴다.
const dbName = '${Embed.code}_spanish_universe';
const legacyDbName = 'spanish_universe';
