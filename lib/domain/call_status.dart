import 'birthday.dart';
import 'friend.dart';

/// Reminder interval used when a friend has no `call_interval_days`.
const kDefaultCallIntervalDays = 30;

enum CallState { never, ok, due, overdue }

/// How long it has been since the last call, relative to the interval.
/// Always derived at runtime, never stored.
class CallStatus {
  const CallStatus({required this.daysSince, required this.intervalDays});

  /// Null if there has never been a call.
  final int? daysSince;
  final int intervalDays;

  factory CallStatus.of(
    Friend friend, {
    DateTime? now,
    int defaultIntervalDays = kDefaultCallIntervalDays,
  }) {
    final last = friend.lastCall;
    final interval = friend.callIntervalDays ?? defaultIntervalDays;
    return CallStatus(
      daysSince: last == null
          ? null
          : calendarDaysBetween(last, now ?? DateTime.now()),
      intervalDays: interval < 1 ? 1 : interval,
    );
  }

  CallState get state {
    final days = daysSince;
    if (days == null) return CallState.never;
    if (days >= intervalDays * 2) return CallState.overdue;
    if (days >= intervalDays) return CallState.due;
    return CallState.ok;
  }

  /// Share of the interval used up, 0.0 to 1.0.
  double get progress =>
      daysSince == null ? 1 : (daysSince! / intervalDays).clamp(0.0, 1.0);

  /// Sort key: higher means more in need of a call. Never-called first.
  double get urgency =>
      daysSince == null ? double.infinity : daysSince! / intervalDays;
}

/// Most urgent first, then alphabetically.
List<Friend> sortByUrgency(Iterable<Friend> friends, {DateTime? now}) {
  final list = friends.toList();
  list.sort((a, b) {
    final byUrgency = CallStatus.of(
      b,
      now: now,
    ).urgency.compareTo(CallStatus.of(a, now: now).urgency);
    return byUrgency != 0
        ? byUrgency
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}
