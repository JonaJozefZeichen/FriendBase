import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/friend_repository.dart';
import '../data/settings_storage.dart';
import '../domain/app_settings.dart';
import '../domain/friend.dart';

/// Overridden in `main()` once the vault directory is known.
final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => throw UnimplementedError('friendRepositoryProvider not overridden'),
);

/// Overridden in `main()` once the vault directory is known.
final settingsStorageProvider = Provider<SettingsStorage>(
  (ref) => throw UnimplementedError('settingsStorageProvider not overridden'),
);

/// Settings loaded before `runApp`, so the first frame has the right theme.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(settingsStorageProvider).save(state);
  }
}

/// Picks an image and returns its temporary path, or null if cancelled.
/// A provider so widget tests can fake picking.
final imagePickerProvider = Provider<Future<String?> Function(ImageSource)>(
  (ref) => (source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    return picked?.path;
  },
);

final friendsProvider = AsyncNotifierProvider<FriendsNotifier, List<Friend>>(
  FriendsNotifier.new,
);

/// The in-memory list of friends. Every change is written to disk first,
/// then reflected here.
class FriendsNotifier extends AsyncNotifier<List<Friend>> {
  FriendRepository get _repo => ref.read(friendRepositoryProvider);

  @override
  Future<List<Friend>> build() => _repo.loadAll();

  Future<Friend> save(Friend friend) async => _put(await _repo.save(friend));

  /// Replaces or adds [saved] in the in-memory list.
  Friend _put(Friend saved) {
    final current = state.value ?? const [];
    final exists = current.any((f) => f.id == saved.id);
    state = AsyncData(
      exists
          ? [for (final f in current) f.id == saved.id ? saved : f]
          : [...current, saved],
    );
    return saved;
  }

  Future<Friend> logCall(Friend friend, [DateTime? at]) =>
      save(friend.withCall(at ?? DateTime.now()));

  Future<Friend> undoLastCall(Friend friend) => save(friend.withoutLastCall());

  Future<Friend> addImage(Friend friend, String sourcePath) async =>
      _put(await _repo.addImage(friend, sourcePath));

  Future<Friend> removeImage(Friend friend, FriendImage image) async =>
      _put(await _repo.removeImage(friend, image));

  Future<Friend> setCaption(Friend friend, FriendImage image, String caption) =>
      save(
        friend.copyWith(
          images: [
            for (final i in friend.images)
              i.file == image.file ? i.copyWith(caption: caption.trim()) : i,
          ],
        ),
      );

  Future<void> delete(Friend friend) async {
    await _repo.delete(friend);
    state = AsyncData([
      for (final f in state.value ?? const <Friend>[])
        if (f.id != friend.id) f,
    ]);
  }

  Future<void> reload() async {
    state = AsyncData(await _repo.loadAll());
  }
}
