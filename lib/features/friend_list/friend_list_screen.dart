import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/call_status.dart';
import '../../domain/friend.dart';
import '../../ui_kit/ascii.dart';
import '../friend_detail/friend_detail_screen.dart';
import '../friend_edit/friend_edit_screen.dart';

/// All friends, most in need of a call first.
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
      ...f.tags,
      f.notes,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final problems = ref.watch(friendRepositoryProvider).problems;

    return Scaffold(
      appBar: AppBar(title: const Text('FRIENDBASE')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add friend',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const FriendEditScreen())),
        child: const Text('[+]', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('>'),
                  ),
                ),
                hintText: 'search_',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (problems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                '!! ${problems.length} file(s) could not be read: '
                '${problems.map((p) => p.folder).join(', ')}',
              ),
            ),
          const Divider(),
          Expanded(
            child: friends.when(
              loading: () => const Center(child: Text('loading...')),
              error: (e, _) => Center(child: Text('!! $e')),
              data: (all) {
                if (all.isEmpty) return const _EmptyState();
                final visible = sortByUrgency(all.where(_matches));
                return RefreshIndicator(
                  onRefresh: () => ref.read(friendsProvider.notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) => _FriendRow(friend: visible[i]),
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
  const _FriendRow({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final status = CallStatus.of(friend);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendDetailScreen(friendId: friend.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                friend.name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                daysLabel(status.daysSince),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            Text(callMarker(status.state)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '┌──────────────────────┐\n'
        '│   no friends yet.    │\n'
        '│   tap [+] to add.    │\n'
        '└──────────────────────┘',
        textAlign: TextAlign.center,
      ),
    );
  }
}
