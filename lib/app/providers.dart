import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/friend_repository.dart';
import '../domain/friend.dart';

/// Overridden in `main()` once the vault directory is known.
final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => throw UnimplementedError('friendRepositoryProvider not overridden'),
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
