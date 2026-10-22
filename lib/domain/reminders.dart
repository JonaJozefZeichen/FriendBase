import 'dart:ui';

import '../l10n/app_localizations.dart';
import 'app_settings.dart';
import 'birthday.dart';
import 'call_status.dart';
import 'date_format.dart';
import 'friend.dart';

/// iOS keeps at most 64 pending notifications per app; leave some headroom.
const kMaxPlannedReminders = 60;

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// Works out which reminders should be pending right now. Pure, so it can
/// be re-run after every change: the caller cancels everything and
/// schedules exactly this list.
List<PlannedReminder> planReminders(
  Iterable<Friend> friends,
  AppSettings settings, {
  DateTime? now,
  AppLocalizations? strings,
}) {
  final at = now ?? DateTime.now();
  final t = strings ?? lookupAppLocalizations(const Locale('en'));
  final planned = <({DateTime when, String title, String body})>[];

  // Calendar arithmetic (day ± n), so DST changes never shift the date.
  DateTime atReminderTime(DateTime day, [int plusDays = 0]) => DateTime(
    day.year,
    day.month,
    day.day + plusDays,
    settings.reminderHour,
    settings.reminderMinute,
  );

  for (final friend in friends) {
    final birthday = friend.birthday;
    if (birthday != null) {
      // One reminder [daysBefore] days ahead and/or one on the day (0).
      for (final days in [
        if (settings.remindBirthdays) settings.birthdayDaysBefore,
        if (settings.remindBirthdayOnDay) 0,
      ]) {
        var occurrence = birthday.nextOccurrence(at);
        var when = atReminderTime(occurrence, -days);
        if (!when.isAfter(at)) {
          // This year's reminder has passed; plan next year's.
          occurrence = birthday.nextOccurrence(
            DateTime(occurrence.year, occurrence.month, occurrence.day + 1),
          );
          when = atReminderTime(occurrence, -days);
        }
        final age = birthday.year == null
            ? ''
            : t.reminderTurns(occurrence.year - birthday.year!);
        planned.add((
          when: when,
          title: t.reminderBirthdayTitle(friend.name),
          body: switch (days) {
            0 => '${t.reminderToday}$age',
            1 => '${t.reminderTomorrow}$age',
            _ =>
              t.reminderInDays(
                    days,
                    displayDate(
                      settings.dateStyle,
                      occurrence,
                      withYear: false,
                    ),
                  ) +
                  age,
          },
        ));
      }
    }

    final lastCall = friend.lastCall;
    if (settings.remindOverdueCalls && lastCall != null) {
      final interval = CallStatus.of(friend, now: at).intervalDays;
      var when = atReminderTime(lastCall, interval);
      if (!when.isAfter(at)) {
        // Already overdue: remind at the next reminder time.
        when = atReminderTime(at);
        if (!when.isAfter(at)) {
          when = atReminderTime(at, 1);
        }
      }
      planned.add((
        when: when,
        title: t.reminderCallTitle(friend.name),
        body: t.reminderCallBody(calendarDaysBetween(lastCall, when), interval),
      ));
    }
  }

  planned.sort((a, b) => a.when.compareTo(b.when));
  return [
    for (final (i, p) in planned.take(kMaxPlannedReminders).indexed)
      PlannedReminder(id: i, when: p.when, title: p.title, body: p.body),
  ];
}
