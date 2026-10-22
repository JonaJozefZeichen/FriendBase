import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../domain/call_status.dart';
import '../../domain/friend.dart';
import '../../ui_kit/ascii.dart';
import '../friend_edit/friend_edit_screen.dart';
import '../image_view/image_view_screen.dart';

/// One friend, laid out top to bottom as:
///
/// ```
/// [<]┌─────────────────┐
///    │ friend info     │  name, contact, birthday, last call + CALLED
///    └─────────────────┘
///    ┌─────────────────┐
///    │ image refs      │  thumbnails, tap to open the ImageView
///    └─────────────────┘
///    ┌─────────────────┐
///    │ notes           │  fills the rest of the screen
///    └─────────────────┘
/// ```
class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider).value ?? const [];
    final friend = friends.where((f) => f.id == friendId).firstOrNull;
    if (friend == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SquareButton(
              label: '<',
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    const gutter = EdgeInsets.fromLTRB(20, 16, 20, 0);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _InfoBox(friend: friend)),
            SliverPadding(
              padding: gutter,
              sliver: SliverToBoxAdapter(child: _ImageStrip(friend: friend)),
            ),
            SliverPadding(
              padding: gutter.copyWith(bottom: 20),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: AsciiBox(
                  title: 'notes',
                  fill: true,
                  child: friend.notes.trim().isEmpty
                      ? const Text('—')
                      : SelectableText(friend.notes.trim()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The info box, with the back button sitting on its top-left corner.
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final birthday = friend.birthday;
    final today = DateTime.now();

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.onSurface),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row clears the back button overlapping the corner.
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        friend.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FriendEditScreen(friend: friend),
                      ),
                    ),
                    child: const Text('[EDIT]'),
                  ),
                ],
              ),
              if (friend.nickname != null || friend.tags.isNotEmpty)
                Text(
                  [
                    if (friend.nickname != null) 'aka ${friend.nickname}',
                    if (friend.tags.isNotEmpty)
                      friend.tags.map((t) => '#$t').join(' '),
                  ].join('  ·  '),
                ),
              const SizedBox(height: 8),
              for (final phone in friend.phones)
                _LinkLine(
                  label: 'tel',
                  value: phone,
                  uri: Uri(scheme: 'tel', path: phone),
                ),
              for (final email in friend.emails)
                _LinkLine(
                  label: 'mail',
                  value: email,
                  uri: Uri(scheme: 'mailto', path: email),
                ),
              if (friend.address != null) _InfoLine('addr', friend.address!),
              if (birthday != null)
                _InfoLine(
                  'bday',
                  '${birthday.format()}  ·  '
                      '${_birthdayHint(birthday.daysUntil(today), birthday.turningAge(today))}',
                ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _CallSection(friend: friend),
            ],
          ),
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
    );
  }

  static String _birthdayHint(int days, int? age) {
    final turns = age == null ? '' : ', turns $age';
    return days == 0 ? 'TODAY$turns' : 'in ${days}d$turns';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LinkLine extends StatelessWidget {
  const _LinkLine({
    required this.label,
    required this.value,
    required this.uri,
  });

  final String label;
  final String value;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text(label)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(decoration: TextDecoration.underline),
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
    final status = CallStatus.of(friend);
    final history = friend.callTimes.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'last call ${asciiBar(status.progress)} '
          '${daysLabel(status.daysSince)} / ${status.intervalDays}d',
        ),
        const SizedBox(height: 4),
        Text('status ${callLabel(status.state)}'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _logCall(context, ref, DateTime.now()),
          onLongPress: () => _logPastCall(context, ref),
          child: const Text('[ CALLED TODAY ]'),
        ),
        const SizedBox(height: 4),
        const Text(
          'long-press to log an earlier call',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            history
                .map((t) => '· ${formatCallTime(t).replaceFirst('T', ' ')}')
                .join('\n'),
          ),
        ],
      ],
    );
  }

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
            'call logged: ${formatCallTime(at).replaceFirst('T', ' ')}',
          ),
          action: SnackBarAction(
            label: 'UNDO',
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

  static const _tile = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(friendRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return AsciiBox(
      title: 'images',
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
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ImageViewScreen(friendId: friend.id, initialIndex: i),
                ),
              ),
              child: Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.onSurface),
                ),
                child: file == null
                    ? const Center(child: Text('?'))
                    : ColorFiltered(
                        colorFilter: kGreyscale,
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 216,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('?')),
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('[ FROM GALLERY ]'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('[ TAKE PHOTO ]'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return;
      await ref.read(friendsProvider.notifier).addImage(friend, picked.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('!! could not add image: $e')));
    }
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add image',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.onSurface),
          ),
          child: const Center(child: Text('[+]')),
        ),
      ),
    );
  }
}
