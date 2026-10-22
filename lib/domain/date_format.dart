import 'app_settings.dart';

/// Formats a date for display in the chosen [style]. Files always keep ISO
/// dates; this only changes what is shown.
///
/// | style    | with year    | without year |
/// |----------|--------------|--------------|
/// | european | `29.10.1994` | `29.10.`     |
/// | american | `10/29/1994` | `10/29`      |
/// | iso      | `1994-10-29` | `10-29`      |
String formatDay(
  DateStyle style, {
  required int day,
  required int month,
  int? year,
}) {
  final dd = day.toString().padLeft(2, '0');
  final mm = month.toString().padLeft(2, '0');
  final yyyy = year?.toString().padLeft(4, '0');
  return switch (style) {
    DateStyle.european => yyyy == null ? '$dd.$mm.' : '$dd.$mm.$yyyy',
    DateStyle.american => yyyy == null ? '$mm/$dd' : '$mm/$dd/$yyyy',
    DateStyle.iso => yyyy == null ? '$mm-$dd' : '$yyyy-$mm-$dd',
  };
}

/// [formatDay] for a [DateTime], leaving out the year when [withYear] is
/// false. (Not to be confused with `formatDate` in `friend.dart`, which
/// writes the ISO form used in files.)
String displayDate(DateStyle style, DateTime t, {bool withYear = true}) =>
    formatDay(
      style,
      day: t.day,
      month: t.month,
      year: withYear ? t.year : null,
    );
