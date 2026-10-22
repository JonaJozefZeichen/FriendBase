import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/app_settings.dart';
import '../../domain/date_format.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/widgets.dart';
import '../about/about_screen.dart';

/// App options, opened from the button on the friend list.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void update(AppSettings Function(AppSettings) change) =>
        notifier.update(change);

    final l10n = context.l10n;
    const gap = SizedBox(height: 24);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.options)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            title: l10n.language,
            child: SegmentedChoice<AppLanguage>(
              options: [
                (AppLanguage.system, l10n.languageSystem, null),
                (AppLanguage.en, 'English', null),
                (AppLanguage.de, 'Deutsch', null),
              ],
              selected: settings.language,
              onSelected: (v) => update((s) => s.copyWith(language: v)),
            ),
          ),
          gap,
          SectionCard(
            title: l10n.theme,
            child: _ThemeGrid(
              selected: settings.theme,
              onSelected: (t) => update((s) => s.copyWith(theme: t)),
            ),
          ),
          gap,
          SectionCard(
            title: l10n.display,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label(l10n.font),
                SegmentedChoice<AppFont>(
                  options: [
                    for (final (font, label) in [
                      (AppFont.system, l10n.fontSystem),
                      (AppFont.serif, l10n.fontSerif),
                      (AppFont.readable, l10n.fontReadable),
                      (AppFont.mono, l10n.fontMono),
                    ])
                      (font, label, TextStyle(fontFamily: fontFamilyFor(font))),
                  ],
                  selected: settings.font,
                  onSelected: (f) => update((s) => s.copyWith(font: f)),
                ),
                const SizedBox(height: 16),
                _Label(l10n.textSize),
                SegmentedChoice<double>(
                  options: [
                    for (final MapEntry(key: label, value: scale)
                        in kTextScales.entries)
                      (scale, label, null),
                  ],
                  selected: settings.textScale,
                  onSelected: (v) => update((s) => s.copyWith(textScale: v)),
                ),
                const SizedBox(height: 16),
                _Label(l10n.dateFormat),
                SegmentedChoice<DateStyle>(
                  options: [
                    for (final style in DateStyle.values)
                      (
                        style,
                        formatDay(style, day: 29, month: 10, year: 1994),
                        null,
                      ),
                  ],
                  selected: settings.dateStyle,
                  onSelected: (v) => update((s) => s.copyWith(dateStyle: v)),
                ),
                const SizedBox(height: 8),
                ToggleRow(
                  label: l10n.compactList,
                  subtitle: l10n.compactListHint,
                  value: settings.compactList,
                  onChanged: (v) => update((s) => s.copyWith(compactList: v)),
                ),
              ],
            ),
          ),
          gap,
          SectionCard(
            title: l10n.list,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label(l10n.sortBy),
                SegmentedChoice<ListSort>(
                  options: [
                    (ListSort.urgency, l10n.sortCallDue, null),
                    (ListSort.name, l10n.sortName, null),
                    (ListSort.birthday, l10n.birthday, null),
                  ],
                  selected: settings.sort,
                  onSelected: (v) => update((s) => s.copyWith(sort: v)),
                ),
                const SizedBox(height: 16),
                _Label(l10n.showInList),
                SegmentedChoice<ListDetail>(
                  options: [
                    (ListDetail.lastCall, l10n.lastCall, null),
                    (ListDetail.birthday, l10n.birthday, null),
                    (ListDetail.none, l10n.nothing, null),
                  ],
                  selected: settings.listDetail,
                  onSelected: (v) => update((s) => s.copyWith(listDetail: v)),
                ),
              ],
            ),
          ),
          gap,
          _RemindersCard(settings: settings, update: update),
          gap,
          SectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.aboutApp),
              subtitle: Text(l10n.aboutAppHint),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius),
              ),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One rounded tile per theme, painted in its own colours.
class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.selected, required this.onSelected});

  final AppTheme selected;
  final ValueChanged<AppTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final width = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final theme in AppTheme.values)
              Semantics(
                button: true,
                selected: theme == selected,
                child: GestureDetector(
                  onTap: () => onSelected(theme),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: width,
                    height: 60,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme == selected ? outline : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: theme == AppTheme.system
                          ? _systemSwatch(_themeName(context, theme))
                          : _swatch(
                              kPalettes[theme]!,
                              _themeName(context, theme),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _themeName(BuildContext context, AppTheme theme) {
    final l10n = context.l10n;
    return switch (theme) {
      AppTheme.system => l10n.themeSystem,
      AppTheme.light => l10n.themeLight,
      AppTheme.dark => l10n.themeDark,
      AppTheme.rose => l10n.themeRose,
      AppTheme.mint => l10n.themeMint,
      AppTheme.sky => l10n.themeSky,
      AppTheme.lavender => l10n.themeLavender,
    };
  }

  Widget _swatch(Palette p, String name) => Container(
    color: p.bg,
    alignment: Alignment.center,
    child: Text(
      name,
      style: TextStyle(color: p.fg, fontWeight: FontWeight.w600),
    ),
  );

  /// Half Light, half Dark: follows the phone.
  Widget _systemSwatch(String name) => Stack(
    fit: StackFit.expand,
    children: [
      Row(
        children: [
          Expanded(child: Container(color: kLight.bg)),
          Expanded(child: Container(color: kDark.bg)),
        ],
      ),
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: kLight.bg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            name,
            style: TextStyle(color: kLight.fg, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );
}

class _RemindersCard extends ConsumerWidget {
  const _RemindersCard({required this.settings, required this.update});

  final AppSettings settings;
  final void Function(AppSettings Function(AppSettings)) update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: context.l10n.reminders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleRow(
            label: context.l10n.birthdaysAhead,
            subtitle: context.l10n.birthdaysAheadHint,
            value: settings.remindBirthdays,
            onChanged: (v) =>
                _toggle(context, ref, v, (s) => s.copyWith(remindBirthdays: v)),
          ),
          if (settings.remindBirthdays) ...[
            const SizedBox(height: 4),
            _Label(context.l10n.daysBefore),
            SegmentedChoice<int>(
              options: [for (final d in kBirthdayDaysBefore) (d, '$d', null)],
              selected: settings.birthdayDaysBefore,
              onSelected: (d) =>
                  update((s) => s.copyWith(birthdayDaysBefore: d)),
            ),
            const SizedBox(height: 4),
          ],
          ToggleRow(
            label: context.l10n.birthdaysOnDay,
            subtitle: context.l10n.birthdaysOnDayHint,
            value: settings.remindBirthdayOnDay,
            onChanged: (v) => _toggle(
              context,
              ref,
              v,
              (s) => s.copyWith(remindBirthdayOnDay: v),
            ),
          ),
          ToggleRow(
            label: context.l10n.overdueCalls,
            subtitle: context.l10n.overdueCallsHint,
            value: settings.remindOverdueCalls,
            onChanged: (v) => _toggle(
              context,
              ref,
              v,
              (s) => s.copyWith(remindOverdueCalls: v),
            ),
          ),
          const Divider(height: 24),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickTime(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(context.l10n.timeOfDay)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      settings.reminderTimeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
