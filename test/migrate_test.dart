import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_universe/embed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('옛 저장 이름 → es_ 접두로 한 번 이전(DB 파일 → 키 → 그림 폴더)', () async {
    final dir = Directory.systemTemp.createTempSync('esmig');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => dir.path);
    File('${dir.path}/spanish_universe.sqlite').writeAsStringSync('db');
    File('${dir.path}/spanish_universe.sqlite-wal').writeAsStringSync('wal');
    Directory('${dir.path}/art').createSync();
    File('${dir.path}/art/a.webp').writeAsStringSync('x');
    SharedPreferences.setMockInitialValues({
      'memorized_words': ['hola', 'adiós'],
      'achievements_v1': '{"x":1}',
      'show_ko_reading_v2': true,
      'db_version': 3,
      'iap_owned2': '{"lang_es_life":0}',
      'memo:hola': 'note',
      'learner_name': 'Mina',
      'app_lang': 'ko',
    });
    await migrateStorage();
    final p = await SharedPreferences.getInstance();
    expect(p.getStringList('es_memorized_words'), ['hola', 'adiós']);
    expect(p.getString('es_achievements_v1'), '{"x":1}');
    expect(p.getBool('es_show_ko_reading_v2'), true);
    expect(p.getInt('es_db_version'), 3);
    expect(p.getString('es_iap_owned2'), '{"lang_es_life":0}');
    expect(p.getString('es_memo:hola'), 'note');
    expect(p.containsKey('memorized_words'), false);
    expect(p.containsKey('memo:hola'), false);
    expect(p.getString('learner_name'), 'Mina'); // 공유 값은 그대로
    expect(p.getString('app_lang'), 'ko');
    expect(File('${dir.path}/es_spanish_universe.sqlite').readAsStringSync(), 'db');
    expect(File('${dir.path}/es_spanish_universe.sqlite-wal').existsSync(), true);
    expect(File('${dir.path}/spanish_universe.sqlite').existsSync(), false);
    expect(File('${dir.path}/es/art/a.webp').existsSync(), true);
    // 두 번째는 아무것도 안 한다
    await p.setString('dialogue_last', 'new');
    await migrateStorage();
    expect(p.getString('dialogue_last'), 'new');
    dir.deleteSync(recursive: true);
  });
}
