import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/app_settings.dart';
import '../../ui_kit/ascii.dart';

const _repoUrl = 'https://github.com/JonaJozefZeichen/FriendBase';

/// App options, opened from the `[≡]` button on the friend list.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void update(AppSettings Function(AppSettings) change) =>
        notifier.update(change);

    const gap = SizedBox(height: 16);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(60, 14, 0, 24),
                  child: Text(
                    'OPTIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                AsciiBox(
                  title: 'theme',
                  child: _ThemeGrid(
                    selected: settings.theme,
                    onSelected: (t) => update((s) => s.copyWith(theme: t)),
                  ),
                ),
                gap,
                AsciiBox(
                  title: 'display',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Label('font'),
                      ChoiceRow<AppFont>(
                        options: [
                          for (final (font, label) in [
                            (AppFont.system, 'System'),
                            (AppFont.serif, 'Serif'),
                            (AppFont.readable, 'Readable'),
                            (AppFont.mono, 'Mono'),
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
                      const SizedBox(height: 12),
                      const _Label('text size'),
                      ChoiceRow<double>(
                        options: [
                          for (final MapEntry(key: label, value: scale)
                              in kTextScales.entries)
                            (scale, label, null),
                        ],
                        selected: settings.textScale,
                        onSelected: (v) =>
                            update((s) => s.copyWith(textScale: v)),
                      ),
                      const SizedBox(height: 8),
                      AsciiToggle(
                        label: 'compact list',
                        value: settings.compactList,
                        onChanged: (v) =>
                            update((s) => s.copyWith(compactList: v)),
                      ),
                      AsciiToggle(
                        label: 'show upcoming birthdays in list',
                        value: settings.birthdaysInList,
                        onChanged: (v) =>
                            update((s) => s.copyWith(birthdaysInList: v)),
                      ),
                    ],
                  ),
                ),
                gap,
                AsciiBox(
                  title: 'list',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Label('sort by'),
                      ChoiceRow<ListSort>(
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
                _RemindersBox(settings: settings, update: update),
                gap,
                const _AboutBox(),
              ],
            ),
            Positioned(
              left: 8,
              top: 8,
              child: SquareButton(
                label: '<',
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      ),
    );
  }
}

/// One tile per theme, painted in its own colours.
class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.selected, required this.onSelected});

  final AppTheme selected;
  final ValueChanged<AppTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
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
                  child: Container(
                    width: width,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: outline,
                        width: theme == selected ? 3 : 1,
                      ),
                    ),
                    child: theme == AppTheme.system
                        ? _systemSwatch()
                        : _swatch(kPalettes[theme]!),
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
      style: TextStyle(color: p.fg, fontWeight: FontWeight.bold),
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
          color: kLight.bg,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'System',
            style: TextStyle(color: kLight.fg, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}

class _RemindersBox extends ConsumerWidget {
  const _RemindersBox({required this.settings, required this.update});

  final AppSettings settings;
  final void Function(AppSettings Function(AppSettings)) update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsciiBox(
      title: 'reminders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsciiToggle(
            label: 'upcoming birthdays',
            value: settings.remindBirthdays,
            onChanged: (v) =>
                _toggle(context, ref, v, (s) => s.copyWith(remindBirthdays: v)),
          ),
          if (settings.remindBirthdays) ...[
            const _Label('days before'),
            ChoiceRow<int>(
              options: [for (final d in kBirthdayDaysBefore) (d, '$d', null)],
              selected: settings.birthdayDaysBefore,
              onSelected: (d) =>
                  update((s) => s.copyWith(birthdayDaysBefore: d)),
            ),
            const SizedBox(height: 4),
          ],
          AsciiToggle(
            label: 'overdue calls',
            value: settings.remindOverdueCalls,
            onChanged: (v) => _toggle(
              context,
              ref,
              v,
              (s) => s.copyWith(remindOverdueCalls: v),
            ),
          ),
          InkWell(
            onTap: () => _pickTime(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Expanded(child: Text('time of day')),
                  Text(
                    '[ ${settings.reminderTimeLabel} ]',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                'notifications are off for FriendBase. '
                'allow them in your phone settings.',
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

class _AboutBox extends ConsumerWidget {
  const _AboutBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value ?? '…';
    final repo = ref.watch(friendRepositoryProvider);
    final count = ref.watch(friendsProvider).value?.length ?? 0;
    final problems = repo.problems;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return AsciiBox(
      title: 'about',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FriendBase $version',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Everything stays on this phone. Each friend is a plain Markdown '
            'file (friends/<name>/friend.md) with their images next to it, '
            'readable in Obsidian or any text editor.',
          ),
          const SizedBox(height: 12),
          const _Label('vault'),
          SelectableText(
            repo.storage.root.path,
            style: const TextStyle(fontSize: 12),
          ),
          if (isIOS) ...[
            const SizedBox(height: 4),
            const Text(
              'Files app → On My iPhone → FriendBase',
              style: TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Text('$count friend${count == 1 ? '' : 's'}'),
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('!! ${problems.length} file(s) could not be read:'),
            for (final p in problems)
              Text(
                '· ${p.folder}: ${p.message}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => launchUrl(
              Uri.parse(_repoUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('[ SOURCE CODE ]'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'FriendBase',
              applicationVersion: version,
            ),
            child: const Text('[ LICENCES ]'),
          ),
        ],
      ),
    );
  }
}
