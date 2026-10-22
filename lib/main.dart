import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'data/friend_repository.dart';
import 'data/vault_storage.dart';
import 'features/friend_list/friend_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final vault = Directory('${docs.path}/FriendBase');
  await vault.create(recursive: true);

  runApp(
    ProviderScope(
      overrides: [
        friendRepositoryProvider.overrideWithValue(
          FriendRepository(VaultStorage(vault)),
        ),
      ],
      child: const FriendBaseApp(),
    ),
  );
}

class FriendBaseApp extends StatelessWidget {
  const FriendBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FriendBase',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const FriendListScreen(),
    );
  }
}
