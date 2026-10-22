import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../domain/birthday.dart';
import '../l10n/l10n.dart';
import 'widgets.dart';

/// Day · Month · Year wheels in a bottom sheet. The year wheel starts with
/// `– –` for "year unknown".
///
/// Returns the new birthday as stored in files (`1994-03-12` or `--03-12`),
/// an empty string if the user cleared it, or null if dismissed.
Future<String?> showBirthdayPicker(BuildContext context, {Birthday? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    // Size to the wheels instead of the default half-screen cap, which is
    // too short on small phones.
    isScrollControlled: true,
    builder: (_) => _BirthdaySheet(initial: initial),
  );
}

class _BirthdaySheet extends StatefulWidget {
  const _BirthdaySheet({required this.initial});

  final Birthday? initial;

  @override
  State<_BirthdaySheet> createState() => _BirthdaySheetState();
}

class _BirthdaySheetState extends State<_BirthdaySheet> {
  /// Index 0 is "unknown", then the current year down to 1900.
  late final List<int?> _years = [
    null,
    for (var y = DateTime.now().year; y >= 1900; y--) y,
  ];

  late int _day = widget.initial?.day ?? 1;
  late int _month = widget.initial?.month ?? 1;
  late int? _year = widget.initial?.year;

  late final _dayWheel = FixedExtentScrollController(initialItem: _day - 1);
  late final _monthWheel = FixedExtentScrollController(initialItem: _month - 1);
  late final _yearWheel = FixedExtentScrollController(
    initialItem: _years.indexOf(_year).clamp(0, _years.length - 1),
  );

  @override
  void dispose() {
    _dayWheel.dispose();
    _monthWheel.dispose();
    _yearWheel.dispose();
    super.dispose();
  }

  /// Without a year, Feb 29 is allowed (it may be a leap-day birthday).
  int get _daysInMonth => DateTime.utc(_year ?? 2000, _month + 1, 0).day;

  void _clampDay() {
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      _dayWheel.jumpToItem(_day - 1);
    }
  }

  String get _result {
    final mm = _month.toString().padLeft(2, '0');
    final dd = _day.toString().padLeft(2, '0');
    return '${_year?.toString() ?? '-'}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    // Month names in the app's language (loaded by the Material
    // localizations), e.g. "October" / "Oktober".
    final monthName = DateFormat.MMMM(
      Localizations.localeOf(context).toLanguageTag(),
    );
    Widget wheel({
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
    }) => CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: 40,
      childCount: count,
      onSelectedItemChanged: onChanged,
      itemBuilder: (_, i) => Center(child: Text(label(i))),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: Text(l10n.clear),
                ),
                Expanded(
                  child: Text(
                    l10n.birthday,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _result),
                  child: Text(l10n.done),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoTheme(
              data: CupertinoThemeData(
                brightness: theme.brightness,
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                  ),
                ),
              ),
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: wheel(
                        controller: _dayWheel,
                        count: _daysInMonth,
                        label: (i) => '${i + 1}',
                        onChanged: (i) => setState(() => _day = i + 1),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: wheel(
                        controller: _monthWheel,
                        count: 12,
                        label: (i) => monthName.format(DateTime(2000, i + 1)),
                        onChanged: (i) => setState(() {
                          _month = i + 1;
                          _clampDay();
                        }),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: wheel(
                        controller: _yearWheel,
                        count: _years.length,
                        label: (i) => _years[i]?.toString() ?? kNoValue,
                        onChanged: (i) => setState(() {
                          _year = _years[i];
                          _clampDay();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.yearUnknownHint(kNoValue),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
