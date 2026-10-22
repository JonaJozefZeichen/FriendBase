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
  Future<Friend> setAvatar(Friend friend, String sourcePath) =>
      save(friend.copyWith(avatar: () => 'assets/$sourcePath'));

  @override
  Future<Friend> removeAvatar(Friend friend) =>
      save(friend.copyWith(avatar: () => null));

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
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Overdue',
      ),
      findsOneWidget,
    );
    expect(find.text('Today'), findsOneWidget);

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
    expect(find.text('– –'), findsOneWidget);

    await tester.tap(find.byTooltip('Called today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(repo.friends.single.calls, hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.calls, isEmpty);
  });

  testWidgets('birthday picker: unknown year, with year, clear', (
    tester,
  ) async {
    final repo = _MemoryRepository([]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mia');

    Future<void> openPicker() async {
      // The label is drawn by the field's decoration; the tap still lands
      // on the field around it.
      await tester.tap(find.text('Birthday'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    Future<void> spin(String from, double rows) async {
      await tester.drag(find.text(from).last, Offset(0, -40 * rows));
      await tester.pumpAndSettle();
    }

    // Defaults: 1 January, year unknown. Pick 12 March.
    await openPicker();
    await spin('1', 11);
    await spin('January', 2);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('12.03.'), findsOneWidget);

    // Now add a year: the first year after "unknown" is the current year.
    await openPicker();
    await spin('– –', 1);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final year = DateTime.now().year;
    expect(find.text('12.03.$year'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.birthdayRaw, '$year-03-12');

    // Clearing from the editor removes it again.
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear birthday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.birthdayRaw, isNull);
  });

  testWidgets('date format applies to the friend view', (tester) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          const Friend(
            id: '1',
            name: 'Anna',
            folder: 'a',
            birthdayRaw: '1994-10-29',
          ),
        ]),
        initial: const AppSettings(dateStyle: DateStyle.american),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    expect(find.text('10/29/1994'), findsOneWidget);
    expect(find.textContaining('turns'), findsOneWidget);
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
    final callY = tester.getTopLeft(find.byTooltip('Called today')).dy;
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

  testWidgets('options: paper applies and is saved', (tester) async {
    final settings = _MemorySettings();
    await tester.pumpWidget(_app(_MemoryRepository([]), settings: settings));
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);
    expect(app().theme!.scaffoldBackgroundColor, kCream.paper);
    expect(app().darkTheme!.scaffoldBackgroundColor, kInk.paper);

    await _openOptions(tester, find.text('Kraft'));
    await tester.tap(find.text('Kraft'));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
    expect(app().theme!.scaffoldBackgroundColor, kKraft.paper);
    expect(settings.saved?.theme, AppTheme.kraft);

    await tester.tap(find.text('Ink'));
    await tester.pumpAndSettle();
    expect(app().theme!.scaffoldBackgroundColor, kInk.paper);
    expect(app().theme!.brightness, Brightness.dark);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('FriendBase'), findsOneWidget);
  });

  testWidgets('options: font and text size', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepository([])));
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    LedgerTokens tokens() => app().theme!.extension<LedgerTokens>()!;
    // Ledger default: serif text, mono data.
    expect(app().theme!.textTheme.bodyMedium!.fontFamily, 'SourceSerif4');
    expect(tokens().dataFamily, 'IBMPlexMono');

    await _openOptions(tester, find.text('Readable'));
    await tester.tap(find.text('Readable'));
    await tester.pumpAndSettle();
    expect(
      app().theme!.textTheme.bodyMedium!.fontFamily,
      'AtkinsonHyperlegible',
    );
    expect(tokens().dataFamily, 'AtkinsonHyperlegible');

    await tester.tap(find.text('XL'));
    await tester.pumpAndSettle();
    final scale = MediaQuery.textScalerOf(tester.element(find.text('XL')))
        .scale(10);
    expect(scale, closeTo(13, 0.01));
  });

  testWidgets('options: sort, compact list, detail under each name', (
    tester,
  ) async {
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
    double rowHeight() => tester
        .getSize(
          find
              .ancestor(of: find.text('Adam'), matching: find.byType(InkWell))
              .first,
        )
        .height;

    // Default: urgency order (never-called Zoe first), last call shown,
    // with dashes for never called.
    expect(y('Zoe'), lessThan(y('Adam')));
    expect(find.text('– –'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    final normalHeight = rowHeight();

    Future<void> pick(String label, {bool last = false}) async {
      final f = last ? find.text(label).last : find.text(label);
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await _openOptions(tester);
    await pick('Compact list');
    await pick('Name');
    // 'Birthday' is both a sort option and a detail option; the detail
    // row comes second.
    await pick('Birthday', last: true);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(y('Adam'), lessThan(y('Zoe')));
    expect(find.text('in 3d'), findsOneWidget);
    expect(find.text('– –'), findsOneWidget, reason: 'Adam has no birthday');
    expect(rowHeight(), lessThan(normalHeight));

    await _openOptions(tester);
    await pick('Nothing');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('in 3d'), findsNothing);
    expect(find.text('– –'), findsNothing);
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

  testWidgets('about page: version, data, privacy policy, licences', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_MemoryRepository([const Friend(id: '1', name: 'Alice')])),
    );
    await tester.pumpAndSettle();
    await _openOptions(tester, find.text('About FriendBase'));
    await tester.tap(find.text('About FriendBase'));
    await tester.pumpAndSettle();

    expect(find.text('Version 0.3.0 (3)'), findsOneWidget);
    expect(find.text('Made by Jona Jožef Zeichen'), findsOneWidget);
    expect(find.text('/unused'), findsOneWidget);
    expect(find.text('1 friend'), findsOneWidget);

    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();
    expect(find.text('In short'), findsOneWidget);
    expect(find.textContaining('does not collect'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

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
    expect(find.text('Facts, Favourites, etc..'), findsOneWidget);
    expect(find.textContaining('## Food'), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Facts, Favourites, etc..'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Facts, Favourites, etc..'), findsOneWidget);
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

  testWidgets('profile picture: pick when creating, remove when editing', (
    tester,
  ) async {
    final repo = _MemoryRepository([]);
    await tester.pumpWidget(_app(repo, pickedImage: 'me.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mia');
    await tester.tap(find.bySemanticsLabel('Profile picture'));
    await tester.pumpAndSettle();
    expect(find.text('Remove picture'), findsNothing);
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.avatar, 'assets/me.jpg');

    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Profile picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.friends.single.avatar, isNull);
  });

  testWidgets('Undo disappears after 4 seconds and when leaving', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([const Friend(id: '1', name: 'Anna', folder: 'a')]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Called today'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);

    await tester.tap(find.byTooltip('Called today'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('FriendBase'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('friend view picture is 80px; settings says Show in list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          const Friend(id: '1', name: 'Anna', folder: 'a', nickname: 'Anni'),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    final picture = find.ancestor(
      of: find.text('A'),
      matching: find.byType(Container),
    );
    expect(tester.getSize(picture.first), const Size(80, 80));
    expect(find.textContaining('Every'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await _openOptions(tester, find.text('Show in list'));
    expect(find.text('Show in list'), findsOneWidget);
  });

  testWidgets('switching to German translates the app live', (tester) async {
    final settings = _MemorySettings();
    final days18 = DateTime.now().subtract(const Duration(days: 18));
    await tester.pumpWidget(
      _app(
        _MemoryRepository([
          Friend(
            id: '1',
            name: 'Anna',
            folder: 'a',
            birthdayRaw: '1994-10-29',
            calls: [formatCallTime(days18)],
          ),
        ]),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add friend'), findsOneWidget);

    await _openOptions(tester);
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(settings.saved?.language, AppLanguage.de);
    expect(find.text('Optionen'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('Papier'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Person hinzufügen'), findsOneWidget);
    expect(find.text('18 T'), findsOneWidget);

    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    expect(find.text('Letzter Anruf'), findsOneWidget);
    expect(find.text('vor 18 Tagen'), findsOneWidget);
    expect(find.textContaining('wird 32'), findsOneWidget);
    // No section titles in the Ledger design; the hint says it all.
    expect(find.text('Notizen'), findsNothing);
    expect(find.text('Fakten, Lieblingsdinge usw.'), findsOneWidget);

    // Built-in Flutter widgets follow too, e.g. the birthday wheels.
    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Person bearbeiten'), findsOneWidget);
    await tester.tap(find.text('Geburtstag'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Oktober'), findsOneWidget);
    expect(find.text('Fertig'), findsOneWidget);
  });

  testWidgets('German privacy policy', (tester) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepository([]),
        initial: const AppSettings(language: AppLanguage.de),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Noch niemand hier'), findsOneWidget);
    await tester.tap(find.byTooltip('Optionen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Über FriendBase'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Über FriendBase'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über FriendBase'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datenschutzerklärung'));
    await tester.pumpAndSettle();
    expect(find.text('Kurz gesagt'), findsOneWidget);
    expect(find.text('Gültig ab 22. Oktober 2026'), findsOneWidget);
  });
}
