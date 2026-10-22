import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../domain/app_settings.dart';
import '../../domain/call_status.dart';
import '../../domain/date_format.dart';
import '../../domain/friend.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/caption_dialog.dart';
import '../../app/theme.dart';
import '../../ui_kit/friend_avatar.dart';
import '../../ui_kit/ledger.dart';
import '../../ui_kit/image_source_sheet.dart';
import '../../ui_kit/widgets.dart';
import '../friend_edit/friend_edit_screen.dart';
import '../image_view/image_view_screen.dart';

/// One friend, laid out top to bottom as (see the blockout):
///
/// ```
/// (<)╭─────────────────╮
///    │ friend info     │  name, contact, birthday, last call + Called
///    ╰─────────────────╯
///    ╭─────────────────╮
///    │ image refs      │  thumbnails, tap to open the ImageView
///    ╰─────────────────╯
///    ╭─────────────────╮
///    │ notes           │  fills the rest of the screen
///    ╰─────────────────╯
/// ```
class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider).value ?? const [];
    final friend = friends.where((f) => f.id == friendId).firstOrNull;
    if (friend == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(padding: EdgeInsets.all(12), child: BackRoundButton()),
        ),
      );
    }

    const gutter = EdgeInsets.fromLTRB(16, 20, 16, 0);
    // Its own messenger: the Undo snackbar belongs to this page and goes
    // away with it instead of following you back to the list.
    return ScaffoldMessenger(
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _InfoCard(friend: friend)),
                    SliverPadding(
                      padding: gutter,
                      sliver: SliverToBoxAdapter(
                        child: _ImageStrip(friend: friend),
                      ),
                    ),
                    SliverPadding(
                      padding: gutter.copyWith(bottom: 20),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: SectionCard(
                          fill: true,
                          padding: const EdgeInsets.all(10),
                          // The page fills the card, like a notebook page.
                          child: SizedBox.expand(
                            child: RuledPage(
                              fill: true,
                              child: friend.notes.trim().isEmpty
                                  ? Text(
                                      context.l10n.notesHint,
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                      ),
                                    )
                                  : SelectableText(friend.notes.trim()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Above the scroll view, so it stays put while scrolling.
                const Positioned(left: 8, top: 8, child: BackRoundButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The info card. Its top-left corner sits under the floating back button.
class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final birthday = friend.birthday;
    final today = DateTime.now();
    final dateStyle = ref.watch(settingsProvider.select((s) => s.dateStyle));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row clears the back button overlapping the corner.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 32),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FriendAvatar(friend: friend, size: 80, square: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    // As tall as the picture, with name + nickname centred.
                    constraints: const BoxConstraints(minHeight: 86),
                    padding: const EdgeInsets.only(top: 6),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (friend.nickname != null)
                          Text(
                            friend.nickname!,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendEditScreen(friend: friend),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final phone in friend.phones)
              _InfoRow(
                icon: Icons.phone_outlined,
                text: phone,
                onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
              ),
            for (final email in friend.emails)
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                text: email,
                onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
              ),
            if (friend.address != null)
              _InfoRow(icon: Icons.home_outlined, text: friend.address!),
            if (birthday != null)
              _InfoRow(
                icon: Icons.cake_outlined,
                data: true,
                text: formatDay(
                  dateStyle,
                  day: birthday.day,
                  month: birthday.month,
                  year: birthday.year,
                ),
                note: _birthdayHint(
                  context,
                  birthday.daysUntil(today),
                  birthday.turningAge(today),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CallSection(friend: friend),
            ),
          ],
        ),
      ),
    );
  }

  static String _birthdayHint(BuildContext context, int days, int? age) {
    final l10n = context.l10n;
    return [
      l10n.birthdayIn(days),
      if (age != null) l10n.turnsAge(age),
    ].join(' · ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.note,
    this.onTap,
    this.data = false,
  });

  final IconData icon;
  final String text;

  /// Show [text] in the data (monospace) font, e.g. for dates.
  final bool data;

  /// A smaller, paler side note under [text].
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: data
                        ? LedgerTokens.of(context).data(size: 15)
                        : onTap == null
                        ? null
                        : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (note != null)
                    Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallSection extends ConsumerWidget {
  const _CallSection({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = CallStatus.of(friend);
    final history = friend.callTimes.reversed.take(3).toList();
    final dateStyle = ref.watch(settingsProvider.select((s) => s.dateStyle));

    final tokens = LedgerTokens.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.lastCall,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      lastCallLabel(context, status.daysSince),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (history.isNotEmpty)
                      Text(
                        context.l10n.recentCalls(
                          history
                              .map((t) => _shortDate(dateStyle, t))
                              .join(', '),
                        ),
                        style: tokens.data(size: 12, color: tokens.paper.muted),
                      ),
                  ],
                ),
              ),
              LensButton(
                label: context.l10n.calledToday,
                hint: context.l10n.calledTodayHint,
                onTap: () => _logCall(context, ref, DateTime.now()),
                onLongPress: () => _logPastCall(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.callHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateStyle style, DateTime t) =>
      displayDate(style, t, withYear: t.year != DateTime.now().year);

  Future<void> _logCall(
    BuildContext context,
    WidgetRef ref,
    DateTime at,
  ) async {
    final notifier = ref.read(friendsProvider.notifier);
    final style = ref.read(settingsProvider).dateStyle;
    final updated = await notifier.logCall(friend, at);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.callLogged(
              '${displayDate(style, at)} ${formatCallTime(at).substring(11)}',
            ),
          ),
          duration: const Duration(seconds: 4),
          // With an action, snackbars stay until dismissed by default.
          persist: false,
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => notifier.undoLastCall(updated),
          ),
        ),
      );
  }

  Future<void> _logPastCall(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !context.mounted) return;
    await _logCall(
      context,
      ref,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

/// A row of thumbnails; the last tile adds a new image.
class _ImageStrip extends ConsumerWidget {
  const _ImageStrip({required this.friend});

  final Friend friend;

  static const _tile = 66.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(friendRepositoryProvider);

    // Polaroids lie straight on the paper; room around them for the tilt.
    return SizedBox(
      height: _tile + 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        itemCount: friend.images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == friend.images.length) {
            return _AddTile(size: _tile, onTap: () => _addImage(context, ref));
          }
          final file = repo.imageFile(friend, friend.images[i]);
          const broken = Center(child: Icon(Icons.broken_image_outlined));
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ImageViewScreen(friendId: friend.id, initialIndex: i),
              ),
            ),
            child: Polaroid(
              tilt: i.isEven ? -3 : 2,
              size: _tile,
              child: file == null
                  ? broken
                  : Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      errorBuilder: (_, _, _) => broken,
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final source = await showImageSourceSheet(context);
    if (source is! ImageSource) return;
    final notifier = ref.read(friendsProvider.notifier);
    try {
      final path = await ref.read(imagePickerProvider)(source);
      if (path == null) return;
      final updated = await notifier.addImage(friend, path);
      if (!context.mounted) return;
      final added = updated.images.last;
      final file = ref.read(friendRepositoryProvider).imageFile(updated, added);
      final caption = await showCaptionDialog(
        context,
        dismissLabel: context.l10n.skip,
        preview: file == null
            ? null
            : Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
      );
      if (caption != null && caption.trim().isNotEmpty) {
        await notifier.setCaption(updated, added, caption);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotAddImage('$e'))),
      );
    }
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n.addImage,
      child: GlassSurface(
        radius: 16,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size + 6,
            height: size + 14,
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
