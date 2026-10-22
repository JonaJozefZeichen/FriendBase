import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/call_status.dart';
import '../../domain/date_format.dart';
import '../../domain/friend.dart';
import '../../domain/app_settings.dart';
import '../../l10n/l10n.dart';
import '../../app/theme.dart';
import '../../ui_kit/friend_avatar.dart';
import '../../ui_kit/ledger.dart';
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

    final tokens = LedgerTokens.of(context);
    final dark = tokens.paper.brightness == Brightness.dark;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            tokens.paper.ink,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/fb-logo.png',
                            width: 30,
                            height: 30,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.appTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        FloatingRoundButton(
                          icon: Icons.tune_rounded,
                          tooltip: context.l10n.options,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (problems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Text(
                        context.l10n.filesUnreadable(
                          problems.length,
                          problems.map((p) => p.folder).join(', '),
                        ),
                        style: TextStyle(color: tokens.paper.danger),
                      ),
                    ),
                  Expanded(
                    child: friends.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(context.l10n.somethingWentWrong('$e')),
                      ),
                      data: (all) {
                        if (all.isEmpty) return const _EmptyState();
                        final settings = ref.watch(settingsProvider);
                        final visible = sortFriends(
                          all.where(_matches),
                          settings.sort,
                        );
                        return RefreshIndicator(
                          onRefresh: () =>
                              ref.read(friendsProvider.notifier).reload(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                            children: [
                              if (visible.isNotEmpty)
                                SectionCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      for (final (i, friend)
                                          in visible.indexed) ...[
                                        if (i > 0)
                                          const Divider(
                                            indent: 64,
                                            endIndent: 10,
                                          ),
                                        _FriendRow(
                                          friend: friend,
                                          compact: settings.compactList,
                                          detail: settings.listDetail,
                                          dateStyle: settings.dateStyle,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: GlassSurface(
                        radius: 999,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: context.l10n.search,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      tooltip: context.l10n.addFriend,
                      elevation: dark ? 2 : 4,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FriendEditScreen(),
                        ),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          vertical: compact ? 6 : 10,
        ),
        child: Row(
          children: [
            FriendAvatar(friend: friend, size: compact ? 34 : 42, square: true),
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
    final tokens = LedgerTokens.of(context);
    final paper = tokens.paper;
    final status = CallStatus.of(friend);
    final overdue = status.state == CallState.overdue;
    final days = status.daysSince;
    final urgent =
        status.state == CallState.due || status.state == CallState.overdue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status.state == CallState.overdue)
          Semantics(
            label: context.l10n.overdue,
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: paper.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        Text(
          switch (days) {
            null => kNoValue,
            0 => context.l10n.lastCallAgo(0),
            _ => context.l10n.daysShort(days),
          },
          style: tokens.data(
            size: 14,
            weight: urgent ? FontWeight.w600 : FontWeight.w400,
            color: overdue
                ? paper.danger
                : urgent
                ? paper.accent
                : paper.muted,
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
    final tokens = LedgerTokens.of(context);
    final muted = tokens.paper.muted;
    final birthday = friend.birthday;
    if (birthday == null) {
      return Text(kNoValue, style: tokens.data(size: 14, color: muted));
    }
    final days = birthday.daysUntil(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatDay(dateStyle, day: birthday.day, month: birthday.month),
          style: tokens.data(size: 14, color: tokens.paper.ink),
        ),
        Text(
          context.l10n.inDaysShort(days),
          style: tokens.data(
            size: 11,
            color: days <= 1 ? tokens.paper.accent : muted,
            weight: days <= 1 ? FontWeight.w600 : null,
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
            Text(
              context.l10n.noFriendsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.noFriendsBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
