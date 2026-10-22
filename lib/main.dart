import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'data/friend_repository.dart';
import 'data/settings_storage.dart';
import 'data/vault_storage.dart';
import 'features/friend_list/friend_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final vault = Directory('${docs.path}/FriendBase');
  await vault.create(recursive: true);
  final settingsStorage = SettingsStorage(vault);
  final settings = await settingsStorage.load();

  runApp(
    ProviderScope(
      overrides: [
        friendRepositoryProvider.overrideWithValue(
          FriendRepository(VaultStorage(vault)),
        ),
        settingsStorageProvider.overrideWithValue(settingsStorage),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const FriendBaseApp(),
    ),
  );
}

class FriendBaseApp extends ConsumerWidget {
  const FriendBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      title: 'FriendBase',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const FriendListScreen(),
    );
  }
}
