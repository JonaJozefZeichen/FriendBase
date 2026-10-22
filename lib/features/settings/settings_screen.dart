import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/app_settings.dart';
import '../../domain/date_format.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/ledger.dart';
import '../../ui_kit/widgets.dart';
import '../about/about_screen.dart';

/// App options, opened from the button on the friend list.
///
/// Layout like a notebook page (sections written straight onto the paper,
/// About at the bottom), controls from the glass toolkit: capsule segments,
/// paper dots, round ticks.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void update(AppSettings Function(AppSettings) change) =>
        notifier.update(change);
    final l10n = context.l10n;
    final tokens = LedgerTokens.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';

    const gap = SizedBox(height: 26);
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Room on the left for the pinned back button.
                  Padding(
                    padding: const EdgeInsets.only(left: 60, top: 4),
                    child: Text(
                      l10n.options,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Label(l10n.language),
                  SegmentedChoice<AppLanguage>(
                    options: [
                      (AppLanguage.system, l10n.languageSystem, null),
                      (AppLanguage.en, 'English', null),
                      (AppLanguage.de, 'Deutsch', null),
                    ],
                    selected: settings.language,
                    onSelected: (v) => update((s) => s.copyWith(language: v)),
                  ),
                  gap,
                  _Label(l10n.paper),
                  _PaperDots(
                    selected: settings.theme,
                    onSelected: (t) => update((s) => s.copyWith(theme: t)),
                  ),
                  gap,
                  _Label(l10n.display),
                  _Sub(l10n.font),
                  SegmentedChoice<AppFont>(
                    options: [
                      for (final (font, label) in [
                        (AppFont.ledger, 'Ledger'),
                        (AppFont.system, l10n.fontSystem),
                        (AppFont.serif, l10n.fontSerif),
                        (AppFont.readable, l10n.fontReadable),
                        (AppFont.mono, l10n.fontMono),
                      ])
                        (
                          font,
                          label,
                          TextStyle(fontFamily: fontFamilyFor(font)),
                        ),
                    ],
                    selected: settings.font,
                    onSelected: (f) => update((s) => s.copyWith(font: f)),
                  ),
                  const SizedBox(height: 14),
                  _Sub(l10n.textSize),
                  SegmentedChoice<double>(
                    options: [
                      for (final MapEntry(key: label, value: scale)
                          in kTextScales.entries)
                        (scale, label, null),
                    ],
                    selected: settings.textScale,
                    onSelected: (v) => update((s) => s.copyWith(textScale: v)),
                  ),
                  const SizedBox(height: 14),
                  _Sub(l10n.dateFormat),
                  SegmentedChoice<DateStyle>(
                    options: [
                      for (final style in DateStyle.values)
                        (
                          style,
                          formatDay(style, day: 29, month: 10, year: 1994),
                          tokens.data(),
                        ),
                    ],
                    selected: settings.dateStyle,
                    onSelected: (v) => update((s) => s.copyWith(dateStyle: v)),
                  ),
                  const SizedBox(height: 6),
                  ToggleRow(
                    label: l10n.compactList,
                    subtitle: l10n.compactListHint,
                    value: settings.compactList,
                    onChanged: (v) => update((s) => s.copyWith(compactList: v)),
                  ),
                  gap,
                  _Label(l10n.list),
                  _Sub(l10n.sortBy),
                  SegmentedChoice<ListSort>(
                    options: [
                      (ListSort.urgency, l10n.sortCallDue, null),
                      (ListSort.name, l10n.sortName, null),
                      (ListSort.birthday, l10n.birthday, null),
                    ],
                    selected: settings.sort,
                    onSelected: (v) => update((s) => s.copyWith(sort: v)),
                  ),
                  const SizedBox(height: 14),
                  _Sub(l10n.showInList),
                  SegmentedChoice<ListDetail>(
                    options: [
                      (ListDetail.lastCall, l10n.lastCall, null),
                      (ListDetail.birthday, l10n.birthday, null),
                      (ListDetail.none, l10n.nothing, null),
                    ],
                    selected: settings.listDetail,
                    onSelected: (v) => update((s) => s.copyWith(listDetail: v)),
                  ),
                  gap,
                  _Reminders(settings: settings, update: update),
                  const SizedBox(height: 30),
                  const _DashedRule(),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.aboutApp,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            version.isEmpty
                                ? '→'
                                : 'v${version.split(' ').first} →',
                            style: tokens.data(
                              size: 13,
                              color: tokens.paper.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Pinned, so it stays reachable while scrolling.
              const Positioned(left: 20, top: 8, child: BackRoundButton()),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section name written on the paper.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A smaller muted label for one control inside a section.
class _Sub extends StatelessWidget {
  const _Sub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Round paper samples with their names; System is half Cream, half Ink.
class _PaperDots extends StatelessWidget {
  const _PaperDots({required this.selected, required this.onSelected});

  final AppTheme selected;
  final ValueChanged<AppTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = LedgerTokens.of(context);
    final names = {
      AppTheme.system: l10n.paperSystem,
      AppTheme.cream: l10n.paperCream,
      AppTheme.kraft: l10n.paperKraft,
      AppTheme.blue: l10n.paperBlue,
      AppTheme.ink: l10n.paperInk,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final theme in AppTheme.values)
          Semantics(
            button: true,
            selected: theme == selected,
            label: names[theme],
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onSelected(theme),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme == selected
                            ? tokens.paper.ink
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(child: _swatch(theme, tokens.paper)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    names[theme]!,
                    style: tokens.data(
                      size: 11,
                      weight: theme == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _swatch(AppTheme theme, Paper current) {
    final rim = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: current.ink.withValues(alpha: 0.18)),
    );
    if (theme == AppTheme.system) {
      return DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: rim,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: kCream.paper)),
            Expanded(child: ColoredBox(color: kInk.paper)),
          ],
        ),
      );
    }
    final paper = kPapers[theme]!;
    return Container(
      decoration: rim.copyWith(color: paper.paper),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: paper.accent, shape: BoxShape.circle),
      ),
    );
  }
}

class _Reminders extends ConsumerWidget {
  const _Reminders({required this.settings, required this.update});

  final AppSettings settings;
  final void Function(AppSettings Function(AppSettings)) update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = LedgerTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(l10n.reminders),
        ToggleRow(
          label: l10n.birthdaysAhead,
          subtitle: l10n.birthdaysAheadHint,
          value: settings.remindBirthdays,
          onChanged: (v) =>
              _toggle(context, ref, v, (s) => s.copyWith(remindBirthdays: v)),
        ),
        if (settings.remindBirthdays) ...[
          const SizedBox(height: 4),
          _Sub(l10n.daysBefore),
          SegmentedChoice<int>(
            options: [
              for (final d in kBirthdayDaysBefore) (d, '$d', tokens.data()),
            ],
            selected: settings.birthdayDaysBefore,
            onSelected: (d) => update((s) => s.copyWith(birthdayDaysBefore: d)),
          ),
          const SizedBox(height: 6),
        ],
        ToggleRow(
          label: l10n.birthdaysOnDay,
          subtitle: l10n.birthdaysOnDayHint,
          value: settings.remindBirthdayOnDay,
          onChanged: (v) => _toggle(
            context,
            ref,
            v,
            (s) => s.copyWith(remindBirthdayOnDay: v),
          ),
        ),
        ToggleRow(
          label: l10n.overdueCalls,
          subtitle: l10n.overdueCallsHint,
          value: settings.remindOverdueCalls,
          onChanged: (v) => _toggle(
            context,
            ref,
            v,
            (s) => s.copyWith(remindOverdueCalls: v),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickTime(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.timeOfDay,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                GlassSurface(
                  radius: 999,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Text(
                    settings.reminderTimeLabel,
                    style: tokens.data(size: 15, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Switching a reminder on first asks the phone for permission.
  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool on,
    AppSettings Function(AppSettings) change,
  ) async {
    if (on) {
      bool granted;
      try {
        granted = await ref
            .read(notificationServiceProvider)
            .requestPermission();
      } catch (_) {
        granted = false;
      }
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.notificationsOff)),
          );
        }
        return;
      }
    }
    update(change);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null) return;
    update(
      (s) =>
          s.copyWith(reminderHour: picked.hour, reminderMinute: picked.minute),
    );
  }
}

/// A dashed line across the page, like a tear-off mark.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    final color = LedgerTokens.of(context).paper.ink.withValues(alpha: 0.25);
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DashPainter(color),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 1), Offset(x + 5, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
