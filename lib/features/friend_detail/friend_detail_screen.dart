import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../domain/call_status.dart';
import '../../domain/friend.dart';
import '../../ui_kit/caption_dialog.dart';
import '../../ui_kit/friend_avatar.dart';
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
    return Scaffold(
      body: SafeArea(
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
                      title: 'Notes',
                      fill: true,
                      child: friend.notes.trim().isEmpty
                          ? Text(
                              kNotesHint,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            )
                          : SelectableText(
                              friend.notes.trim(),
                              style: const TextStyle(height: 1.45),
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
    );
  }
}

/// The info card. Its top-left corner sits under the floating back button.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthday = friend.birthday;
    final today = DateTime.now();

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
                  child: FriendAvatar(friend: friend, size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
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
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
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
                text:
                    '${shortDate(birthday.day, birthday.month, birthday.year)}'
                    '  ·  ${_birthdayHint(birthday.daysUntil(today), birthday.turningAge(today))}',
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

  static String _birthdayHint(int days, int? age) {
    final turns = age == null ? '' : ', turns $age';
    return switch (days) {
      0 => 'today$turns',
      1 => 'tomorrow$turns',
      _ => 'in $days days$turns',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
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
              child: Text(
                text,
                style: onTap == null
                    ? null
                    : const TextStyle(fontWeight: FontWeight.w500),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
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
                      'Last call',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      lastCallLabel(status.daysSince),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Every ${status.intervalDays} days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(status.state),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _logCall(context, ref, DateTime.now()),
            onLongPress: () => _logPastCall(context, ref),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Called today'),
          ),
          const SizedBox(height: 6),
          Text(
            'Long-press to log an earlier call',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Recent: ${history.map(_shortDate).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  static String _shortDate(DateTime t) =>
      shortDate(t.day, t.month, t.year == DateTime.now().year ? null : t.year);

  Future<void> _logCall(
    BuildContext context,
    WidgetRef ref,
    DateTime at,
  ) async {
    final notifier = ref.read(friendsProvider.notifier);
    final updated = await notifier.logCall(friend, at);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Call logged: ${formatCallTime(at).replaceFirst('T', ' ')}',
          ),
          action: SnackBarAction(
            label: 'Undo',
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

  static const _tile = 76.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(friendRepositoryProvider);

    return SectionCard(
      title: 'Images',
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: _tile,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: friend.images.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            if (i == friend.images.length) {
              return _AddTile(
                size: _tile,
                onTap: () => _addImage(context, ref),
              );
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: _tile,
                  child: file == null
                      ? broken
                      : Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 228,
                          errorBuilder: (_, _, _) => broken,
                        ),
                ),
              ),
            );
          },
        ),
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
        dismissLabel: 'Skip',
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add image: $e')));
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
      message: 'Add image',
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
