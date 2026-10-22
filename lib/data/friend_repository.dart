import 'dart:io';

import '../domain/friend.dart';
import 'frontmatter_codec.dart';
import 'vault_storage.dart';

/// A file that could not be read, reported instead of crashing the app.
class VaultProblem {
  const VaultProblem(this.folder, this.message);

  final String folder;
  final String message;
}

/// Loads and saves friends as Markdown files in the vault.
class FriendRepository {
  FriendRepository(this.storage);

  final VaultStorage storage;

  /// Problems found during the last [loadAll].
  List<VaultProblem> problems = const [];

  Future<List<Friend>> loadAll() async {
    final friends = <Friend>[];
    final found = <VaultProblem>[];
    for (final file in await storage.readAll()) {
      try {
        friends.add(decodeFriend(file.text, folder: file.folder));
      } on FormatException catch (e) {
        found.add(VaultProblem(file.folder, e.message));
      }
    }
    problems = found;
    return friends;
  }

  /// Saves [friend], creating their folder on first save. Returns the
  /// friend with its folder set.
  Future<Friend> save(Friend friend) async {
    var saved = friend;
    if (saved.folder.isEmpty) {
      saved = saved.copyWith(
        folder: await storage.uniqueFolderFor(saved.name),
        created: saved.created ?? formatDate(DateTime.now()),
      );
    }
    await storage.write(saved.folder, encodeFriend(saved));
    return saved;
  }

  /// Copies the image at [sourcePath] into the friend's assets and adds it
  /// to the end of their image list.
  Future<Friend> addImage(Friend friend, String sourcePath) async {
    final saved = friend.folder.isEmpty ? await save(friend) : friend;
    final file = await storage.importAsset(saved.folder, File(sourcePath));
    return save(
      saved.copyWith(
        images: [
          ...saved.images,
          FriendImage(file: file),
        ],
      ),
    );
  }

  /// Removes the image from the list and deletes its file.
  Future<Friend> removeImage(Friend friend, FriendImage image) async {
    final updated = await save(
      friend.copyWith(
        images: [
          for (final i in friend.images)
            if (i.file != image.file) i,
        ],
      ),
    );
    await storage.deleteAsset(friend.folder, image.file);
    return updated;
  }

  /// The image's file on disk, or null if its path is unsafe.
  File? imageFile(Friend friend, FriendImage image) =>
      storage.resolve(friend.folder, image.file);

  Future<void> delete(Friend friend) async {
    if (friend.folder.isNotEmpty) await storage.delete(friend.folder);
  }
}
