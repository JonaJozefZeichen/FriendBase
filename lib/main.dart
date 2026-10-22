import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'data/friend_repository.dart';
import 'data/settings_storage.dart';
import 'domain/app_settings.dart';
import 'data/vault_storage.dart';
import 'features/friend_list/friend_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicences();
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

/// Bundled fonts are SIL OFL; show their licences on the licences page.
void _registerFontLicences() {
  for (final (font, file) in [
    ('Source Serif 4', 'SourceSerif4-OFL.txt'),
    ('Atkinson Hyperlegible', 'AtkinsonHyperlegible-OFL.txt'),
  ]) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$file'));
    });
  }
}

class FriendBaseApp extends ConsumerWidget {
  const FriendBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    ref.watch(reminderSyncProvider);

    return MaterialApp(
      // `system` follows the phone: Light theme, Dark as its dark variant.
      // Any other choice is used as-is.
      theme: buildTheme(
        kPalettes[settings.theme] ?? kLight,
        font: settings.font,
      ),
      darkTheme: buildTheme(kDark, font: settings.font),
      themeMode: settings.theme == AppTheme.system
          ? ThemeMode.system
          : ThemeMode.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              media.textScaler.scale(1) * settings.textScale,
            ),
          ),
          child: child!,
        );
      },
      title: 'FriendBase',
      debugShowCheckedModeBanner: false,
      home: const FriendListScreen(),
    );
  }
}
