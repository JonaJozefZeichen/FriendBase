import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/app/providers.dart';
import 'package:friendbase/data/friend_repository.dart';
import 'package:friendbase/data/vault_storage.dart';
import 'package:friendbase/domain/friend.dart';
import 'package:friendbase/main.dart';

import 'dart:io';

/// Keeps friends in memory so widget tests don't touch the file system.
class _MemoryRepository extends FriendRepository {
  _MemoryRepository(this.friends) : super(VaultStorage(Directory('/unused')));

  final List<Friend> friends;

  @override
  Future<List<Friend>> loadAll() async => [...friends];

  @override
  Future<Friend> save(Friend friend) async {
    final saved = friend.folder.isEmpty
        ? friend.copyWith(folder: friend.id)
        : friend;
    friends.removeWhere((f) => f.id == saved.id);
    friends.add(saved);
    return saved;
  }

  @override
  Future<Friend> removeImage(Friend friend, FriendImage image) => save(
    friend.copyWith(
      images: [
        for (final i in friend.images)
          if (i.file != image.file) i,
      ],
    ),
  );

  @override
  Future<void> delete(Friend friend) async =>
      friends.removeWhere((f) => f.id == friend.id);
}

Widget _app(_MemoryRepository repo) => ProviderScope(
  overrides: [friendRepositoryProvider.overrideWithValue(repo)],
  child: const FriendBaseApp(),
);

void main() {
  final today = DateTime.now();

  testWidgets('empty state', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    expect(find.textContaining('no friends yet'), findsOneWidget);
  });

  testWidgets('list sorts the most overdue first and filters by search', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(id: '1', name: 'Recent', calls: [formatCallTime(today)]),
          Friend(
            id: '2',
            name: 'Overdue',
            calls: [formatCallTime(today.subtract(const Duration(days: 90)))],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final recentY = tester.getTopLeft(find.text('RECENT')).dy;
    final overdueY = tester.getTopLeft(find.text('OVERDUE')).dy;
    expect(overdueY, lessThan(recentY));
    expect(find.text('!!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rec');
    await tester.pumpAndSettle();
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('OVERDUE'), findsNothing);
  });

  testWidgets('add a friend, open them and log a call', (tester) async {
    final repo = _MemoryRepository([]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'name *'),
      'Marko',
    );
    await tester.tap(find.text('[SAVE]'));
    await tester.pumpAndSettle();

    expect(repo.friends.single.name, 'Marko');
    expect(repo.friends.single.notes, kNotesTemplate);

    await tester.tap(find.text('MARKO'));
    await tester.pumpAndSettle();
    expect(find.text('status NEVER CALLED'), findsOneWidget);

    await tester.tap(find.text('[ CALLED TODAY ]'));
    await tester.pumpAndSettle();
    expect(find.text('status OK'), findsOneWidget);
    expect(repo.friends.single.calls, hasLength(1));

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.calls, isEmpty);
  });

  testWidgets('birthday validation', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'name *'), 'A');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'birthday (YYYY-MM-DD or --MM-DD)'),
      '12.03.1994',
    );
    await tester.tap(find.text('[SAVE]'));
    await tester.pumpAndSettle();
    expect(find.textContaining('use 1994-03-12'), findsOneWidget);
  });

  testWidgets('friend view: back button, info, images and notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          const Friend(
            id: '1',
            name: 'Anna',
            folder: 'anna',
            phones: ['+43 1'],
            notes: '## Food\npho',
            images: [FriendImage(file: 'assets/a.jpg', caption: 'cake')],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANNA'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('+43 1'), findsOneWidget);
    expect(find.text('[+]'), findsOneWidget);
    expect(find.text('## Food\npho'), findsOneWidget);

    // Order top to bottom: info box, images, notes.
    final callY = tester.getTopLeft(find.text('[ CALLED TODAY ]')).dy;
    final addY = tester.getTopLeft(find.text('[+]')).dy;
    final notesY = tester.getTopLeft(find.text('## Food\npho')).dy;
    expect(callY, lessThan(addY));
    expect(addY, lessThan(notesY));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('ANNA'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('image view: arrows, caption editing and delete', (tester) async {
    final repo = _MemoryRepository([
      const Friend(
        id: '1',
        name: 'Anna',
        folder: 'anna',
        images: [
          FriendImage(file: 'assets/a.jpg', caption: 'cake'),
          FriendImage(file: 'assets/b.jpg'),
        ],
      ),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANNA'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('cake'), findsOneWidget);
    expect(find.text('<'), findsOneWidget, reason: 'only the back button');

    await tester.tap(find.text('>'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('tap to add context_'), findsOneWidget);

    await tester.tap(find.text('tap to add context_'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'peonies for her birthday');
    await tester.tap(find.text('[SAVE]'));
    await tester.pumpAndSettle();
    expect(find.text('peonies for her birthday'), findsOneWidget);
    expect(repo.friends.single.images[1].caption, 'peonies for her birthday');

    await tester.tap(find.text('[DELETE]'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[DELETE]').last);
    await tester.pumpAndSettle();
    expect(repo.friends.single.images.map((i) => i.file), ['assets/a.jpg']);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('delete friend lives on the edit screen', (tester) async {
    final repo = _MemoryRepository([
      const Friend(id: '1', name: 'Anna', folder: 'anna'),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANNA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[EDIT]'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('[ DELETE FRIEND ]'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('[ DELETE FRIEND ]'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[DELETE]'));
    await tester.pumpAndSettle();

    expect(repo.friends, isEmpty);
    expect(find.textContaining('no friends yet'), findsOneWidget);
  });
}
