import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_universe/screens/sense_course_screen.dart';
import 'package:spanish_universe/services/script_sync.dart';

/// 문법(언어감각) 스텝 = 서버 원고에서 받고, 빈 스텝은 숨긴다(사용자 지시 2026-11-23).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const rel = 'grammar/sense_course.json';
  late Directory dir;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('sense_sync');
    SenseCourse.clearCache();
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Map<String, dynamic> lesson(String id, {int n = 1, String kind = 'memorize'}) => {
        'id': id,
        'kind': kind,
        'title': id,
        'sentences': [for (var i = 0; i < n; i++) {'tl': 'Hola $i.', 'rd': '올라', 'ko': '안녕'}],
      };

  test('빈 회차·빈 급(참고만 있는 급 포함)은 빠진다', () {
    final v = SenseCourse.visible({
      'title': 't',
      'levels': [
        {'id': 'L1', 'title': 'a', 'lessons': [lesson('L1-1'), lesson('L1-x', n: 0)]},
        {'id': 'L2', 'title': 'b', 'lessons': []},
        {'id': 'L3', 'title': 'c', 'lessons': [lesson('L3-ref', n: 0, kind: 'ref')..['points'] = [{'head': 'h'}]]},
        {'id': 'L4', 'title': 'd'},
      ],
    });
    final lv = (v['levels'] as List).cast<Map<String, dynamic>>();
    expect(lv.map((e) => e['id']), ['L1']);
    expect((lv.first['lessons'] as List).length, 1);
  });

  test('서버 원고가 없으면 앱 안 것 — 10급 모두 보인다', () async {
    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 1, 'files': {}});
    final d = await SenseCourse.load();
    expect((d['levels'] as List).length, 10);
  });

  test('서버 원고가 있으면 그것으로 덮어쓴다 — 서버에서 빠진 스텝은 안 보임·더한 스텝은 보임·순서도 서버 것, 빈 스텝은 숨김', () async {
    final server = json.encode({
      'title': 'srv',
      'levels': [
        {'id': 'L2', 'title': '둘', 'lessons': [lesson('L2-1', n: 3)]},
        {'id': 'L1', 'title': '하나', 'lessons': [lesson('L1-1')]},
        {'id': 'L3', 'title': '셋(준비 중)', 'lessons': []},
        {'id': 'L16', 'title': '새 스텝', 'lessons': [lesson('L16-1')]},
      ],
    });
    final sha = sha1.convert(utf8.encode(server)).toString().substring(0, 12);
    final s = ScriptSync.forTest(
        dir: dir,
        baseline: {'rev': 1, 'files': {rel: 'old'}},
        fetch: (url) async => url.endsWith('/index.json')
            ? json.encode({'rev': 2, 'files': {rel: sha}})
            : (url.contains(rel) ? server : null));
    ScriptSync.instance = s;
    expect(await s.refresh(), isTrue);
    final d = await SenseCourse.load();
    final lv = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(d['title'], 'srv');
    expect(lv.map((e) => e['id']), ['L2', 'L1', 'L16']); // 묶음의 L3~L10 은 서버 목록에 없어 빠짐
  });
}
