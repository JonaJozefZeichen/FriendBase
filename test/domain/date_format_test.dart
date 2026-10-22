import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/domain/app_settings.dart';
import 'package:friendbase/domain/date_format.dart';

void main() {
  test('every style, with and without year', () {
    String f(DateStyle s, [int? y]) => formatDay(s, day: 3, month: 9, year: y);
    expect(f(DateStyle.european, 1994), '03.09.1994');
    expect(f(DateStyle.european), '03.09.');
    expect(f(DateStyle.american, 1994), '09/03/1994');
    expect(f(DateStyle.american), '09/03');
    expect(f(DateStyle.iso, 1994), '1994-09-03');
    expect(f(DateStyle.iso), '09-03');
  });

  test('displayDate can drop the year', () {
    final t = DateTime(2026, 10, 4, 19, 40);
    expect(displayDate(DateStyle.european, t), '04.10.2026');
    expect(displayDate(DateStyle.american, t, withYear: false), '10/04');
  });
}
