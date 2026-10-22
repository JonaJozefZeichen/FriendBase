import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/data/settings_storage.dart';
import 'package:friendbase/domain/app_settings.dart';

void main() {
  late Directory root;
  late SettingsStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('friendbase_settings');
    storage = SettingsStorage(root);
  });

  tearDown(() => root.delete(recursive: true));

  test('defaults to following the phone when no config exists', () async {
    expect((await storage.load()).themeMode, ThemeMode.system);
  });

  test('saves to .friendbase/config.json and loads back', () async {
    await storage.save(const AppSettings(themeMode: ThemeMode.dark));
    final file = File('${root.path}/.friendbase/config.json');
    expect(file.readAsStringSync(), contains('"theme": "dark"'));
    expect((await storage.load()).themeMode, ThemeMode.dark);
  });

  test('broken or unknown values fall back to defaults', () async {
    final file = File('${root.path}/.friendbase/config.json')
      ..createSync(recursive: true);
    file.writeAsStringSync('{not json');
    expect((await storage.load()).themeMode, ThemeMode.system);
    file.writeAsStringSync('{"theme": "sepia"}');
    expect((await storage.load()).themeMode, ThemeMode.system);
  });
}
