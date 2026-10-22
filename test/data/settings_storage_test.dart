import 'dart:io';

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

  File config() => File('${root.path}/.friendbase/config.json');

  test('defaults when no config exists', () async {
    final s = await storage.load();
    expect(s.theme, AppTheme.system);
    expect(s.font, AppFont.ledger);
    expect(s.sort, ListSort.urgency);
    expect(s.anyReminders, isFalse);
    expect(s.reminderTimeLabel, '09:00');
  });

  test('every field round-trips through config.json', () async {
    const custom = AppSettings(
      theme: AppTheme.kraft,
      font: AppFont.serif,
      textScale: 1.3,
      compactList: true,
      listDetail: ListDetail.birthday,
      dateStyle: DateStyle.iso,
      language: AppLanguage.de,
      sort: ListSort.birthday,
      remindBirthdays: true,
      birthdayDaysBefore: 7,
      remindBirthdayOnDay: true,
      remindOverdueCalls: true,
      reminderHour: 18,
      reminderMinute: 5,
    );
    await storage.save(custom);
    expect(config().readAsStringSync(), contains('"reminder_time": "18:05"'));
    final loaded = await storage.load();
    expect(loaded.toJson(), custom.toJson());
  });

  test('a v0.2 config still loads', () async {
    config()
      ..createSync(recursive: true)
      ..writeAsStringSync('{"theme": "dark"}');
    final s = await storage.load();
    expect(s.theme, AppTheme.ink);
    expect(s.font, AppFont.ledger);
  });

  test('pre-Ledger themes map to papers, old default font to Ledger', () async {
    config().createSync(recursive: true);
    for (final (old, paper) in [
      ('light', AppTheme.cream),
      ('rose', AppTheme.cream),
      ('lavender', AppTheme.cream),
      ('dark', AppTheme.ink),
      ('mint', AppTheme.blue),
      ('sky', AppTheme.blue),
      ('system', AppTheme.system),
    ]) {
      config().writeAsStringSync('{"theme": "$old", "font": "system"}');
      final s = await storage.load();
      expect(s.theme, paper, reason: old);
      expect(s.font, AppFont.ledger, reason: 'v1.0 default font');
    }
    // A deliberate font choice survives the upgrade…
    config().writeAsStringSync('{"theme": "light", "font": "serif"}');
    expect((await storage.load()).font, AppFont.serif);
    // …and after v1.1 "system" means the system font.
    config().writeAsStringSync('{"design": "ledger", "font": "system"}');
    expect((await storage.load()).font, AppFont.system);
  });

  test('broken or unknown values fall back to defaults', () async {
    config()
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');
    expect((await storage.load()).theme, AppTheme.system);

    config().writeAsStringSync(
      '{"theme": "sepia", "text_scale": 7, "birthday_days_before": 5, '
      '"reminder_time": "25:99", "compact_list": "yes"}',
    );
    final s = await storage.load();
    expect(s.toJson(), const AppSettings().toJson());
  });
}
