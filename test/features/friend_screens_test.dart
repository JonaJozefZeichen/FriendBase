import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/app/providers.dart';
import 'package:friendbase/app/theme.dart';
import 'package:friendbase/data/friend_repository.dart';
import 'package:friendbase/data/notification_service.dart';
import 'package:friendbase/data/settings_storage.dart';
import 'package:friendbase/domain/app_settings.dart';
import 'package:friendbase/data/vault_storage.dart';
import 'package:friendbase/domain/friend.dart';
import 'package:friendbase/domain/reminders.dart';
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
  Future<Friend> addImage(Friend friend, String sourcePath) => save(
    friend.copyWith(
      images: [
        ...friend.images,
        FriendImage(file: 'assets/$sourcePath'),
      ],
    ),
  );

  @override
  Future<void> delete(Friend friend) async =>
      friends.removeWhere((f) => f.id == friend.id);
}

/// Remembers the last saved settings instead of writing a file.
class _MemorySettings extends SettingsStorage {
  _MemorySettings() : super(Directory('/unused'));

  AppSettings? saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

/// Records what would be scheduled instead of talking to the OS.
class _FakeNotifications extends NotificationService {
  _FakeNotifications({this.allow = true});

  final bool allow;
  List<PlannedReminder> scheduled = const [];

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async =>
      scheduled = reminders;
}

Widget _app(
  _MemoryRepository repo, {
  _MemorySettings? settings,
  AppSettings initial = const AppSettings(),
  _FakeNotifications? notifications,
  String? pickedImage,
}) => ProviderScope(
  overrides: [
    friendRepositoryProvider.overrideWithValue(repo),
    settingsStorageProvider.overrideWithValue(settings ?? _MemorySettings()),
    initialSettingsProvider.overrideWithValue(initial),
    notificationServiceProvider.overrideWithValue(
      notifications ?? _FakeNotifications(),
    ),
    appVersionProvider.overrideWith((ref) async => '0.3.0 (3)'),
    imagePickerProvider.overrideWithValue((_) async => pickedImage),
  ],
  child: const FriendBaseApp(),
);

/// Opens Options and scrolls [target] into view.
Future<void> _openOptions(WidgetTester tester, [Finder? target]) async {
  await tester.tap(find.byTooltip('Options'));
  await tester.pumpAndSettle();
  if (target != null) {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  final today = DateTime.now();

  testWidgets('empty state', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('list sorts the most overdue first and filters by search', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(id: '1', name: 'Rita', calls: [formatCallTime(today)]),
          Friend(
            id: '2',
            name: 'Otto',
            calls: [formatCallTime(today.subtract(const Duration(days: 90)))],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final recentY = tester.getTopLeft(find.text('Rita')).dy;
    final overdueY = tester.getTopLeft(find.text('Otto')).dy;
    expect(overdueY, lessThan(recentY));
    expect(find.text('Overdue'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rit');
    await tester.pumpAndSettle();
    expect(find.text('Rita'), findsOneWidget);
    expect(find.text('Otto'), findsNothing);
  });

  testWidgets('add a friend, open them and log a call', (tester) async {
    final repo = _MemoryRepository([]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Marko');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.friends.single.name, 'Marko');
    expect(repo.friends.single.notes, isEmpty);

    await tester.tap(find.text('Marko'));
    await tester.pumpAndSettle();
    expect(find.text('Never called'), findsOneWidget);

    await tester.tap(find.text('Called today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(repo.friends.single.calls, hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.calls, isEmpty);
  });

  testWidgets('birthday validation', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'A');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Birthday'),
      '12.03.1994',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use 1994-03-12'), findsOneWidget);
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
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('+43 1'), findsOneWidget);
    expect(find.byTooltip('Add image'), findsOneWidget);
    expect(find.text('## Food\npho'), findsOneWidget);

    // Order top to bottom: info box, images, notes.
    final callY = tester.getTopLeft(find.text('Called today')).dy;
    final addY = tester.getTopLeft(find.byTooltip('Add image')).dy;
    final notesY = tester.getTopLeft(find.text('## Food\npho')).dy;
    expect(callY, lessThan(addY));
    expect(addY, lessThan(notesY));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsOneWidget);
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
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('cake'), findsOneWidget);
    expect(find.byTooltip('Previous image'), findsNothing);

    await tester.tap(find.byTooltip('Next image'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Tap to add context'), findsOneWidget);

    await tester.tap(find.text('Tap to add context'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'peonies for her birthday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('peonies for her birthday'), findsOneWidget);
    expect(repo.friends.single.images[1].caption, 'peonies for her birthday');

    await tester.tap(find.byTooltip('Delete image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
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
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Delete friend'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Delete friend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.friends, isEmpty);
    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('options: colour theme applies and is saved', (tester) async {
    final settings = _MemorySettings();
    await tester.pumpWidget(_app(_MemoryRepository([]), settings: settings));
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    await _openOptions(tester);
    await tester.tap(find.text('Rose'));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
    expect(app().theme!.scaffoldBackgroundColor, kPalettes[AppTheme.rose]!.bg);
    expect(settings.saved?.theme, AppTheme.rose);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(app().theme!.scaffoldBackgroundColor, kDark.bg);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('FriendBase'), findsOneWidget);
  });

  testWidgets('options: font and text size', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app().theme!.textTheme.bodyMedium!.fontFamily,
      isNot('SourceSerif4'),
    );

    await _openOptions(tester, find.text('Serif'));
    await tester.tap(find.text('Serif'));
    await tester.pumpAndSettle();
    expect(app().theme!.textTheme.bodyMedium!.fontFamily, 'SourceSerif4');

    await tester.tap(find.text('XL'));
    await tester.pumpAndSettle();
    final scale = MediaQuery.textScalerOf(tester.element(find.text('XL')))
        .scale(10);
    expect(scale, closeTo(13, 0.01));
  });

  testWidgets('options: sort, compact list, birthdays in list', (tester) async {
    final soon = DateTime.now().add(const Duration(days: 3));
    final mm = soon.month.toString().padLeft(2, '0');
    final dd = soon.day.toString().padLeft(2, '0');
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(id: '1', name: 'Zoe', birthdayRaw: '--$mm-$dd'),
          Friend(
            id: '2',
            name: 'Adam',
            calls: [formatCallTime(DateTime.now())],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    double y(String name) => tester.getTopLeft(find.text(name)).dy;

    // Default: never-called Zoe is most urgent.
    expect(y('Zoe'), lessThan(y('Adam')));
    expect(find.textContaining('Birthday in 3d'), findsOneWidget);
    final rowHeight = tester
        .getSize(
          find
              .ancestor(of: find.text('Adam'), matching: find.byType(InkWell))
              .first,
        )
        .height;

    await _openOptions(tester, find.text('Name'));
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Compact list'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Compact list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact list'));
    await tester.tap(find.text('Upcoming birthdays in list'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(y('Adam'), lessThan(y('Zoe')));
    expect(find.textContaining('Birthday in 3d'), findsNothing);
    expect(
      tester
          .getSize(
            find
                .ancestor(of: find.text('Adam'), matching: find.byType(InkWell))
                .first,
          )
          .height,
      lessThan(rowHeight),
    );
  });

  testWidgets('options: reminders ask permission and get scheduled', (
    tester,
  ) async {
    final notifications = _FakeNotifications();
    final settings = _MemorySettings();
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(
            id: '1',
            name: 'Marko',
            calls: [formatCallTime(DateTime(2026, 1, 1))],
          ),
        ]),
        settings: settings,
        notifications: notifications,
      ),
    );
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);

    await _openOptions(tester, find.text('Overdue calls'));
    await tester.tap(find.text('Overdue calls'));
    await tester.pumpAndSettle();
    expect(settings.saved?.remindOverdueCalls, isTrue);
    expect(notifications.scheduled.single.title, 'Time to call Marko');
    expect(
      find.byWidgetPredicate((w) => w is Checkbox && w.value == true),
      findsOneWidget,
    );
  });

  testWidgets('options: denied permission keeps the reminder off', (
    tester,
  ) async {
    final settings = _MemorySettings();
    await tester.pumpWidget(
      _app(
        _MemoryRepository([]),
        settings: settings,
        notifications: _FakeNotifications(allow: false),
      ),
    );
    await tester.pumpAndSettle();
    await _openOptions(tester, find.text('Birthdays ahead'));
    await tester.tap(find.text('Birthdays ahead'));
    await tester.pumpAndSettle();
    expect(settings.saved, isNull);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(find.text('Days before'), findsNothing);
  });

  testWidgets('options: about shows version, vault and counts', (tester) async {
    await tester.pumpWidget(
      _app(_MemoryRepository([const Friend(id: '1', name: 'Alice')])),
    );
    await tester.pumpAndSettle();
    await _openOptions(tester, find.text('Licences'));
    expect(find.text('FriendBase 0.3.0 (3)'), findsOneWidget);
    expect(find.text('/unused'), findsOneWidget);
    expect(find.text('1 friend'), findsOneWidget);
    expect(find.text('Made by Jona Jožef Zeichen'), findsOneWidget);

    await tester.tap(find.text('Licences'));
    await tester.pumpAndSettle();
    expect(find.textContaining('© 2026 Jona Jožef Zeichen'), findsOneWidget);
    expect(find.textContaining('MIT License'), findsOneWidget);
  });

  testWidgets('editor has no tags field', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('tags'), findsNothing);
  });

  testWidgets('empty notes show the grey hint in view and editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([const Friend(id: '1', name: 'Alice', folder: 'a')]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text(kNotesHint), findsOneWidget);
    expect(find.textContaining('## Food'), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text(kNotesHint),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text(kNotesHint), findsOneWidget);
  });

  testWidgets('back button stays on screen while scrolling', (tester) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(
            id: '1',
            name: 'Anna',
            folder: 'anna',
            notes: List.generate(80, (i) => 'line $i').join('\n'),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.byTooltip('Back'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsNothing, reason: 'info box scrolled away');
    expect(tester.getTopLeft(find.byTooltip('Back')), before);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('FriendBase'), findsOneWidget);
  });

  for (final save in [true, false]) {
    testWidgets(
      'adding an image asks for its context (${save ? 'save' : 'skip'})',
      (tester) async {
        final repo = _MemoryRepository([
          const Friend(id: '1', name: 'Anna', folder: 'anna'),
        ]);
        await tester.pumpWidget(_app(repo, pickedImage: 'new.jpg'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Anna'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add image'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Take a photo'));
        await tester.pumpAndSettle();
        expect(find.text('What is this image about?'), findsOneWidget);
        expect(repo.friends.single.images.single.file, 'assets/new.jpg');

        await tester.enterText(find.byType(TextField), 'her new bike');
        await tester.tap(find.text(save ? 'Save' : 'Skip'));
        await tester.pumpAndSettle();
        expect(find.text('What is this image about?'), findsNothing);
        expect(
          repo.friends.single.images.single.caption,
          save ? 'her new bike' : isEmpty,
        );
      },
    );
  }
}
