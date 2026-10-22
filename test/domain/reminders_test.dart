import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/domain/app_settings.dart';
import 'package:friendbase/domain/call_status.dart';
import 'package:friendbase/domain/friend.dart';
import 'package:friendbase/domain/reminders.dart';
import 'package:friendbase/l10n/app_localizations.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  const both = AppSettings(remindBirthdays: true, remindOverdueCalls: true);

  Friend friend(
    String name, {
    String? birthday,
    DateTime? lastCall,
    int? interval,
  }) => Friend(
    id: name,
    name: name,
    birthdayRaw: birthday,
    callIntervalDays: interval,
    calls: lastCall == null ? const [] : [formatCallTime(lastCall)],
  );

  group('birthdays', () {
    test('N days before, at the reminder time', () {
      final r = planReminders(
        [friend('Anna', birthday: '1994-10-29')],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 10, 26, 9));
      expect(r.title, "Anna's birthday");
      expect(r.body, 'In 3 days (29.10.) — turns 32');
      final us = planReminders(
        [friend('Anna', birthday: '1994-10-29')],
        both.copyWith(dateStyle: DateStyle.american),
        now: now,
      ).single;
      expect(us.body, 'In 3 days (10/29) — turns 32');
    });

    test('German texts', () {
      final r = planReminders(
        [friend('Anna', birthday: '1994-10-29')],
        both,
        now: now,
        strings: lookupAppLocalizations(const Locale('de')),
      ).single;
      expect(r.title, 'Geburtstag von Anna');
      expect(r.body, 'In 3 Tagen (29.10.) — wird 32');
      final call = planReminders(
        [friend('Marko', lastCall: DateTime(2026, 10, 20, 19), interval: 10)],
        both,
        now: now,
        strings: lookupAppLocalizations(const Locale('de')),
      ).single;
      expect(call.title, 'Zeit, Marko anzurufen');
      expect(call.body, '10 Tage seit dem letzten Anruf (alle 10 Tage)');
    });

    test('1 day before says tomorrow; no age without a year', () {
      final r = planReminders(
        [friend('Lea', birthday: '--10-29')],
        both.copyWith(birthdayDaysBefore: 1),
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 10, 28, 9));
      expect(r.body, 'Tomorrow');
    });

    test('reminder day already passed → next year', () {
      // Birthday in 2 days, reminder 3 days before was yesterday.
      final r = planReminders(
        [friend('Anna', birthday: '1994-10-24')],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2027, 10, 21, 9));
      expect(r.body, contains('turns 33'));
    });

    test('reminder can fall in the previous month and year', () {
      final r = planReminders(
        [friend('Jan', birthday: '2000-01-02')],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 12, 30, 9));
    });

    test('on the day, alone or together with the early one', () {
      const onDay = AppSettings(remindBirthdayOnDay: true);
      final only = planReminders(
        [friend('Anna', birthday: '1994-10-29')],
        onDay,
        now: now,
      ).single;
      expect(only.when, DateTime(2026, 10, 29, 9));
      expect(only.body, 'Today — turns 32');

      final both = planReminders(
        [friend('Anna', birthday: '1994-10-29')],
        onDay.copyWith(remindBirthdays: true),
        now: now,
      );
      expect(both.map((r) => r.when), [
        DateTime(2026, 10, 26, 9),
        DateTime(2026, 10, 29, 9),
      ]);
    });

    test('on the day, after the reminder time → next year', () {
      final r = planReminders(
        [friend('Anna', birthday: '1994-10-22')],
        const AppSettings(remindBirthdayOnDay: true),
        now: now,
      ).single;
      expect(r.when, DateTime(2027, 10, 22, 9));
    });

    test('Feb 29 in a non-leap year uses Feb 28', () {
      final r = planReminders(
        [friend('Leap', birthday: '2000-02-29')],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2027, 2, 25, 9));
    });
  });

  group('overdue calls', () {
    test('scheduled for the day the interval runs out', () {
      final r = planReminders(
        [friend('Marko', lastCall: DateTime(2026, 10, 20, 19), interval: 10)],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 10, 30, 9));
      expect(r.title, 'Time to call Marko');
      expect(r.body, '10d since your last call (every 10d)');
    });

    test('already overdue → next reminder time (tomorrow if passed)', () {
      final r = planReminders(
        [friend('Marko', lastCall: DateTime(2026, 7, 1))],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 10, 23, 9));

      final early = planReminders(
        [friend('Marko', lastCall: DateTime(2026, 7, 1))],
        both,
        now: DateTime(2026, 10, 22, 8),
      ).single;
      expect(early.when, DateTime(2026, 10, 22, 9));
    });

    test('never called → no reminder; default interval applies', () {
      expect(planReminders([friend('New')], both, now: now), isEmpty);
      final r = planReminders(
        [friend('A', lastCall: DateTime(2026, 10, 20))],
        both,
        now: now,
      ).single;
      expect(r.when, DateTime(2026, 10, 20 + kDefaultCallIntervalDays, 9));
    });
  });

  test('toggles off → nothing', () {
    final f = friend(
      'A',
      birthday: '1994-10-29',
      lastCall: DateTime(2026, 1, 1),
    );
    expect(planReminders([f], const AppSettings(), now: now), isEmpty);
    expect(
      planReminders(
        [f],
        const AppSettings(remindBirthdays: true),
        now: now,
      ).single.title,
      contains('birthday'),
    );
  });

  test('sorted soonest first, ids sequential, capped', () {
    final many = [
      for (var i = 0; i < 80; i++)
        friend('F$i', lastCall: DateTime(2026, 10, 1 + i % 20), interval: 30),
    ];
    final plan = planReminders(many, both, now: now);
    expect(plan, hasLength(kMaxPlannedReminders));
    expect(
      plan.map((r) => r.id),
      List.generate(kMaxPlannedReminders, (i) => i),
    );
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].when.isBefore(plan[i - 1].when), isFalse);
    }
  });

  test('sortFriends: name and birthday orders', () {
    final friends = [
      friend('carla', birthday: '1990-12-01'),
      friend('Anna', birthday: '1994-10-29'),
      friend('Bob'),
    ];
    expect(sortFriends(friends, ListSort.name, now: now).map((f) => f.name), [
      'Anna',
      'Bob',
      'carla',
    ]);
    expect(
      sortFriends(friends, ListSort.birthday, now: now).map((f) => f.name),
      ['Anna', 'carla', 'Bob'],
    );
  });
}
