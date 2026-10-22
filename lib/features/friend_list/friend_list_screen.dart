import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/call_status.dart';
import '../../domain/date_format.dart';
import '../../domain/friend.dart';
import '../../domain/app_settings.dart';
import '../../ui_kit/friend_avatar.dart';
import '../../ui_kit/widgets.dart';
import '../friend_detail/friend_detail_screen.dart';
import '../friend_edit/friend_edit_screen.dart';
import '../settings/settings_screen.dart';

/// All friends, sorted as chosen in Options.
class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  String _query = '';

  bool _matches(Friend f) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      f.name,
      f.nickname ?? '',
      f.notes,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final problems = ref.watch(friendRepositoryProvider).problems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FriendBase'),
        actions: [
          IconButton(
            tooltip: 'Options',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add friend',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const FriendEditScreen())),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (problems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${problems.length} file(s) could not be read: '
                '${problems.map((p) => p.folder).join(', ')}',
              ),
            ),
          Expanded(
            child: friends.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
              data: (all) {
                if (all.isEmpty) return const _EmptyState();
                final settings = ref.watch(settingsProvider);
                final visible = sortFriends(all.where(_matches), settings.sort);
                return RefreshIndicator(
                  onRefresh: () => ref.read(friendsProvider.notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const Divider(indent: 72, endIndent: 12),
                    itemBuilder: (_, i) => _FriendRow(
                      friend: visible[i],
                      compact: settings.compactList,
                      detail: settings.listDetail,
                      dateStyle: settings.dateStyle,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.compact,
    required this.detail,
    required this.dateStyle,
  });

  final Friend friend;
  final bool compact;
  final ListDetail detail;
  final DateStyle dateStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendDetailScreen(friendId: friend.id),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 6 : 12,
        ),
        child: Row(
          children: [
            FriendAvatar(friend: friend, size: compact ? 36 : 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            switch (detail) {
              ListDetail.none => const SizedBox.shrink(),
              ListDetail.lastCall => _LastCallTrailing(friend: friend),
              ListDetail.birthday => _BirthdayTrailing(
                friend: friend,
                dateStyle: dateStyle,
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// `18d`, `Today` or `– –`. Bold when due; overdue also gets a dot, so
/// urgency stays visible without a status pill.
class _LastCallTrailing extends StatelessWidget {
  const _LastCallTrailing({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = CallStatus.of(friend);
    final days = status.daysSince;
    final urgent =
        status.state == CallState.due || status.state == CallState.overdue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status.state == CallState.overdue)
          Semantics(
            label: 'Overdue',
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: colors.onSurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        Text(
          switch (days) {
            null => kNoValue,
            0 => 'Today',
            _ => '${days}d',
          },
          style: TextStyle(
            fontWeight: urgent ? FontWeight.w700 : FontWeight.w400,
            color: urgent ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The next birthday's date, with `in 7d` underneath; `– –` if unknown.
class _BirthdayTrailing extends StatelessWidget {
  const _BirthdayTrailing({required this.friend, required this.dateStyle});

  final Friend friend;
  final DateStyle dateStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final birthday = friend.birthday;
    if (birthday == null) {
      return Text(kNoValue, style: TextStyle(color: muted));
    }
    final days = birthday.daysUntil(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatDay(dateStyle, day: birthday.day, month: birthday.month),
          style: TextStyle(color: muted),
        ),
        Text(
          switch (days) {
            0 => 'today',
            1 => 'tomorrow',
            _ => 'in ${days}d',
          },
          style: theme.textTheme.bodySmall?.copyWith(
            color: muted.withValues(alpha: 0.75),
            fontWeight: days <= 1 ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No friends yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tap the button below to add someone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
