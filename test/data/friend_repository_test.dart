import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/data/friend_repository.dart';
import 'package:friendbase/data/vault_storage.dart';
import 'package:friendbase/domain/friend.dart';

void main() {
  late Directory root;
  late FriendRepository repo;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('friendbase_test');
    repo = FriendRepository(VaultStorage(root));
  });

  tearDown(() => root.delete(recursive: true));

  test('save creates a folder per friend and loads back', () async {
    final saved = await repo.save(const Friend(id: 'x1', name: 'Anna Müller'));
    expect(saved.folder, 'anna-mueller');
    expect(saved.created, isNotNull);
    expect(
      File('${root.path}/friends/anna-mueller/friend.md').existsSync(),
      isTrue,
    );

    final loaded = await repo.loadAll();
    expect(loaded.single.id, 'x1');
    expect(loaded.single.name, 'Anna Müller');
  });

  test('same name gets a unique folder', () async {
    final a = await repo.save(const Friend(id: '1', name: 'Anna'));
    final b = await repo.save(const Friend(id: '2', name: 'Anna'));
    expect(a.folder, 'anna');
    expect(b.folder, 'anna-2');
  });

  test('saving again updates the file and leaves no temp file', () async {
    final saved = await repo.save(const Friend(id: '1', name: 'Anna'));
    await repo.save(saved.withCall(DateTime(2026, 10, 22, 18, 0)));
    final dir = Directory('${root.path}/friends/anna');
    expect(dir.listSync().map((e) => e.uri.pathSegments.last), ['friend.md']);
    expect((await repo.loadAll()).single.calls, ['2026-10-22T18:00']);
  });

  test('a broken file is reported, the rest still loads', () async {
    await repo.save(const Friend(id: '1', name: 'Good'));
    final bad = Directory('${root.path}/friends/bad')..createSync();
    File('${bad.path}/friend.md').writeAsStringSync('---\nname: [oops\n---\n');

    final loaded = await repo.loadAll();
    expect(loaded.map((f) => f.name), ['Good']);
    expect(repo.problems.single.folder, 'bad');
  });

  test('delete removes the folder', () async {
    final saved = await repo.save(const Friend(id: '1', name: 'Anna'));
    await repo.delete(saved);
    expect(await repo.loadAll(), isEmpty);
  });

  test('addImage copies into assets, removeImage deletes it', () async {
    final source = File('${root.path}/picked.JPG')..writeAsBytesSync([1, 2, 3]);
    var friend = await repo.save(const Friend(id: '1', name: 'Anna'));

    friend = await repo.addImage(friend, source.path);
    final image = friend.images.single;
    expect(image.file, matches(RegExp(r'^assets/\d{8}-\d{6}\.jpg$')));
    final copied = repo.imageFile(friend, image)!;
    expect(copied.readAsBytesSync(), [1, 2, 3]);
    expect(source.existsSync(), isTrue, reason: 'original is left alone');

    friend = await repo.addImage(friend, source.path);
    expect(friend.images, hasLength(2));
    expect(friend.images[1].file, isNot(image.file), reason: 'unique names');
    expect((await repo.loadAll()).single.images, hasLength(2));

    friend = await repo.removeImage(friend, image);
    expect(friend.images, hasLength(1));
    expect(copied.existsSync(), isFalse);
  });

  test('image paths cannot leave the friend folder', () {
    const friend = Friend(id: '1', name: 'A', folder: 'a');
    for (final unsafe in ['../b/friend.md', '/etc/passwd', 'assets//x']) {
      expect(repo.imageFile(friend, FriendImage(file: unsafe)), isNull);
    }
    expect(
      repo.imageFile(friend, const FriendImage(file: 'assets/x.jpg')),
      isNotNull,
    );
  });

  test('slugify', () {
    expect(slugify('  Đorđe Šimić '), 'djordje-simic');
    expect(slugify('!!!'), 'friend');
  });
}
