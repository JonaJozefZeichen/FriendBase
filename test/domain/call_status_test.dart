import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/domain/birthday.dart';
import 'package:friendbase/domain/call_status.dart';
import 'package:friendbase/domain/friend.dart';

Friend _calledOn(String name, DateTime? at, {int? interval}) => Friend(
  id: name,
  name: name,
  callIntervalDays: interval,
  calls: at == null ? const [] : [formatCallTime(at)],
);

void main() {
  final now = DateTime(2026, 10, 22, 12);

  group('CallStatus', () {
    test('never called', () {
      final s = CallStatus.of(_calledOn('a', null), now: now);
      expect(s.daysSince, isNull);
      expect(s.state, CallState.never);
    });

    test('ok / due / overdue thresholds', () {
      CallState at(int daysAgo) => CallStatus.of(
        _calledOn('a', now.subtract(Duration(days: daysAgo)), interval: 10),
        now: now,
      ).state;
      expect(at(0), CallState.ok);
      expect(at(9), CallState.ok);
      expect(at(10), CallState.due);
      expect(at(19), CallState.due);
      expect(at(20), CallState.overdue);
    });

    test('counts calendar days, not 24h periods', () {
      final lateYesterday = DateTime(2026, 10, 21, 23, 59);
      final s = CallStatus.of(
        _calledOn('a', lateYesterday),
        now: DateTime(2026, 10, 22, 0, 1),
      );
      expect(s.daysSince, 1);
    });

    test('is not thrown off by a DST change', () {
      // Europe switches clocks on 2026-10-25.
      final s = CallStatus.of(
        _calledOn('a', DateTime(2026, 10, 24, 12)),
        now: DateTime(2026, 10, 26, 12),
      );
      expect(s.daysSince, 2);
    });

    test('uses the default interval when none is set', () {
      final s = CallStatus.of(_calledOn('a', now), now: now);
      expect(s.intervalDays, kDefaultCallIntervalDays);
    });

    test('sortByUrgency: never called, then most overdue, then by name', () {
      final friends = [
        _calledOn('Ok', now.subtract(const Duration(days: 1))),
        _calledOn('Overdue', now.subtract(const Duration(days: 90))),
        _calledOn('Never', null),
        _calledOn('Bea', now.subtract(const Duration(days: 1))),
      ];
      expect(sortByUrgency(friends, now: now).map((f) => f.name), [
        'Never',
        'Overdue',
        'Bea',
        'Ok',
      ]);
    });
  });

  group('Birthday', () {
    test('parses with and without year', () {
      expect(Birthday.tryParse('1994-03-12')!.year, 1994);
      expect(Birthday.tryParse('--03-12')!.year, isNull);
      expect(Birthday.tryParse('--03-12')!.format(), '--03-12');
      expect(Birthday.tryParse('1994-13-01'), isNull);
      expect(Birthday.tryParse('1994-02-30'), isNull);
      expect(Birthday.tryParse('12.03.1994'), isNull);
    });

    test('days until and turning age', () {
      final b = Birthday.tryParse('1994-10-25')!;
      expect(b.daysUntil(now), 3);
      expect(b.turningAge(now), 32);
      expect(Birthday.tryParse('1994-10-22')!.daysUntil(now), 0);
      expect(
        Birthday.tryParse('1994-10-21')!.nextOccurrence(now),
        DateTime(2027, 10, 21),
      );
    });

    test('Feb 29 falls on Feb 28 in non-leap years', () {
      final b = Birthday.tryParse('2000-02-29')!;
      expect(b.nextOccurrence(DateTime(2027, 1, 1)), DateTime(2027, 2, 28));
      expect(b.nextOccurrence(DateTime(2028, 1, 1)), DateTime(2028, 2, 29));
    });
  });
}
