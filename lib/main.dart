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
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicences();
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

/// Adds what Flutter can't find on its own to the licences page: the app's
/// own MIT licence and the bundled fonts' SIL OFL texts. Dart/Flutter
/// package licences are collected automatically at build time.
void _registerLicences() {
  for (final (name, asset) in [
    ('FriendBase', 'assets/LICENSE.txt'),
    ('Source Serif 4', 'assets/fonts/SourceSerif4-OFL.txt'),
    ('Atkinson Hyperlegible', 'assets/fonts/AtkinsonHyperlegible-OFL.txt'),
    ('IBM Plex Mono', 'assets/fonts/IBMPlexMono-OFL.txt'),
  ]) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(asset));
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
      locale: localeFor(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // `system` follows the phone: Cream paper by day, Ink at night.
      // Any other paper is used as-is.
      theme: buildTheme(kPapers[settings.theme] ?? kCream, font: settings.font),
      darkTheme: buildTheme(kInk, font: settings.font),
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
