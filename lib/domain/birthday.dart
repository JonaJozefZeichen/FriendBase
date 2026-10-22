/// A birthday with an optional year, stored as `1994-03-12` or `--03-12`.
class Birthday {
  const Birthday({required this.month, required this.day, this.year});

  final int month;
  final int day;
  final int? year;

  static final _pattern = RegExp(r'^(?:(\d{4})-|--)(\d{2})-(\d{2})$');

  /// Returns null if [raw] is not a valid birthday.
  static Birthday? tryParse(String? raw) {
    final match = _pattern.firstMatch(raw?.trim() ?? '');
    if (match == null) return null;
    final year = match[1] == null ? null : int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(2000, month)) {
      return null;
    }
    return Birthday(month: month, day: day, year: year);
  }

  String format() {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '${year?.toString().padLeft(4, '0') ?? '-'}-$mm-$dd';
  }

  /// The next occurrence on or after [today]. A Feb 29 birthday falls on
  /// Feb 28 in non-leap years.
  DateTime nextOccurrence(DateTime today) {
    final date = DateTime(today.year, today.month, today.day);
    var next = _occurrenceIn(date.year);
    if (next.isBefore(date)) next = _occurrenceIn(date.year + 1);
    return next;
  }

  int daysUntil(DateTime today) =>
      calendarDaysBetween(today, nextOccurrence(today));

  /// Age reached on the next birthday, or null if the year is unknown.
  int? turningAge(DateTime today) =>
      year == null ? null : nextOccurrence(today).year - year!;

  DateTime _occurrenceIn(int y) {
    final d = day > _daysInMonth(y, month) ? _daysInMonth(y, month) : day;
    return DateTime(y, month, d);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;
}

/// Whole calendar days from [from] to [to], unaffected by DST changes.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
