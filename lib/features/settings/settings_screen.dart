import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/app_settings.dart';
import '../../ui_kit/widgets.dart';

const _repoUrl = 'https://github.com/JonaJozefZeichen/FriendBase';
const _author = 'Jona Jožef Zeichen';
const _legalese =
    '© 2026 $_author\n'
    'Released under the MIT License.';

/// App options, opened from the button on the friend list.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void update(AppSettings Function(AppSettings) change) =>
        notifier.update(change);

    const gap = SizedBox(height: 24);
    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            title: 'Theme',
            child: _ThemeGrid(
              selected: settings.theme,
              onSelected: (t) => update((s) => s.copyWith(theme: t)),
            ),
          ),
          gap,
          SectionCard(
            title: 'Display',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Label('Font'),
                SegmentedChoice<AppFont>(
                  options: [
                    for (final (font, label) in [
                      (AppFont.system, 'System'),
                      (AppFont.serif, 'Serif'),
                      (AppFont.readable, 'Readable'),
                      (AppFont.mono, 'Mono'),
                    ])
                      (font, label, TextStyle(fontFamily: fontFamilyFor(font))),
                  ],
                  selected: settings.font,
                  onSelected: (f) => update((s) => s.copyWith(font: f)),
                ),
                const SizedBox(height: 16),
                const _Label('Text size'),
                SegmentedChoice<double>(
                  options: [
                    for (final MapEntry(key: label, value: scale)
                        in kTextScales.entries)
                      (scale, label, null),
                  ],
                  selected: settings.textScale,
                  onSelected: (v) => update((s) => s.copyWith(textScale: v)),
                ),
                const SizedBox(height: 8),
                ToggleRow(
                  label: 'Compact list',
                  subtitle: 'Smaller rows, fewer details',
                  value: settings.compactList,
                  onChanged: (v) => update((s) => s.copyWith(compactList: v)),
                ),
                ToggleRow(
                  label: 'Upcoming birthdays in list',
                  subtitle: 'Within the next 14 days',
                  value: settings.birthdaysInList,
                  onChanged: (v) =>
                      update((s) => s.copyWith(birthdaysInList: v)),
                ),
              ],
            ),
          ),
          gap,
          SectionCard(
            title: 'List',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Label('Sort by'),
                SegmentedChoice<ListSort>(
                  options: const [
                    (ListSort.urgency, 'Call due', null),
                    (ListSort.name, 'Name', null),
                    (ListSort.birthday, 'Birthday', null),
                  ],
                  selected: settings.sort,
                  onSelected: (v) => update((s) => s.copyWith(sort: v)),
                ),
              ],
            ),
          ),
          gap,
          _RemindersCard(settings: settings, update: update),
          gap,
          const _AboutCard(),
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
                          ? _systemSwatch()
                          : _swatch(kPalettes[theme]!),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _swatch(Palette p) => Container(
    color: p.bg,
    alignment: Alignment.center,
    child: Text(
      p.name,
      style: TextStyle(color: p.fg, fontWeight: FontWeight.w600),
    ),
  );

  /// Half Light, half Dark: follows the phone.
  Widget _systemSwatch() => Stack(
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
            'System',
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
      title: 'Reminders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleRow(
            label: 'Birthdays ahead',
            subtitle: 'A few days before, to plan something',
            value: settings.remindBirthdays,
            onChanged: (v) =>
                _toggle(context, ref, v, (s) => s.copyWith(remindBirthdays: v)),
          ),
          if (settings.remindBirthdays) ...[
            const SizedBox(height: 4),
            const _Label('Days before'),
            SegmentedChoice<int>(
              options: [for (final d in kBirthdayDaysBefore) (d, '$d', null)],
              selected: settings.birthdayDaysBefore,
              onSelected: (d) =>
                  update((s) => s.copyWith(birthdayDaysBefore: d)),
            ),
            const SizedBox(height: 4),
          ],
          ToggleRow(
            label: 'Birthdays on the day',
            subtitle: 'A nudge to send your wishes',
            value: settings.remindBirthdayOnDay,
            onChanged: (v) => _toggle(
              context,
              ref,
              v,
              (s) => s.copyWith(remindBirthdayOnDay: v),
            ),
          ),
          ToggleRow(
            label: 'Overdue calls',
            subtitle: 'When a friend passes their call interval',
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
                  const Expanded(child: Text('Time of day')),
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
            const SnackBar(
              content: Text(
                'Notifications are off for FriendBase. '
                'You can allow them in your phone settings.',
              ),
            ),
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

class _AboutCard extends ConsumerWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final version = ref.watch(appVersionProvider).value ?? '…';
    final repo = ref.watch(friendRepositoryProvider);
    final count = ref.watch(friendsProvider).value?.length ?? 0;
    final problems = repo.problems;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return SectionCard(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FriendBase $version',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('Made by $_author', style: muted),
          const SizedBox(height: 12),
          const Text(
            'Everything stays on this phone. Each friend is a plain Markdown '
            'file (friends/<name>/friend.md) with their images next to it, '
            'readable in Obsidian or any text editor.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          const _Label('Vault'),
          SelectableText(repo.storage.root.path, style: muted),
          if (isIOS) ...[
            const SizedBox(height: 4),
            Text('Files app → On My iPhone → FriendBase', style: muted),
          ],
          const SizedBox(height: 12),
          Text('$count friend${count == 1 ? '' : 's'}'),
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${problems.length} file(s) could not be read:'),
            for (final p in problems)
              Text('· ${p.folder}: ${p.message}', style: muted),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(_repoUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.code_rounded),
            label: const Text('Source code'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'FriendBase',
              applicationVersion: version,
              applicationLegalese: _legalese,
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Licences'),
          ),
        ],
      ),
    );
  }
}
