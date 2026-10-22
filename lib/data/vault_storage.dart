import 'dart:io';

/// The raw contents of one friend's file.
class StoredFile {
  const StoredFile({required this.folder, required this.text});

  final String folder;
  final String text;
}

/// Reads and writes the vault on disk:
///
/// ```
/// <root>/friends/<folder>/friend.md
/// <root>/friends/<folder>/assets/...
/// ```
///
/// The files are the source of truth, like an Obsidian vault.
class VaultStorage {
  VaultStorage(this.root);

  final Directory root;

  static const fileName = 'friend.md';

  Directory get friendsDir => Directory('${root.path}/friends');

  Directory folderDir(String folder) => Directory('${friendsDir.path}/$folder');

  File _file(String folder) => File('${folderDir(folder).path}/$fileName');

  /// Every `friends/*/friend.md` in the vault.
  Future<List<StoredFile>> readAll() async {
    if (!await friendsDir.exists()) return const [];
    final result = <StoredFile>[];
    await for (final entity in friendsDir.list()) {
      if (entity is! Directory) continue;
      final folder = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      final file = _file(folder);
      if (folder.startsWith('.') || !await file.exists()) continue;
      result.add(StoredFile(folder: folder, text: await file.readAsString()));
    }
    return result;
  }

  /// Writes atomically: a temp file is renamed over the old one, so a crash
  /// mid-write never leaves a half-written `friend.md`.
  Future<void> write(String folder, String text) async {
    final dir = folderDir(folder);
    await dir.create(recursive: true);
    final tmp = File('${dir.path}/$fileName.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(_file(folder).path);
  }

  /// Picks an unused folder name derived from [name], e.g. `anna-muller-2`.
  Future<String> uniqueFolderFor(String name) async {
    final base = slugify(name);
    var candidate = base;
    for (var i = 2; await folderDir(candidate).exists(); i++) {
      candidate = '$base-$i';
    }
    return candidate;
  }

  /// The file at [relativePath] inside the friend's folder, or null if the
  /// path tries to leave the folder (a hand-edited `../` or absolute path).
  File? resolve(String folder, String relativePath) {
    final segments = relativePath.split('/');
    if (relativePath.startsWith('/') ||
        segments.any((s) => s == '..' || s.isEmpty)) {
      return null;
    }
    return File('${folderDir(folder).path}/$relativePath');
  }

  /// Copies [source] into the friend's `assets/` folder under a fresh,
  /// time-based name. Returns the path relative to the friend's folder.
  Future<String> importAsset(String folder, File source) async {
    final dot = source.path.lastIndexOf('.');
    final ext = dot == -1 ? '' : source.path.substring(dot).toLowerCase();
    final assets = Directory('${folderDir(folder).path}/assets');
    await assets.create(recursive: true);
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}-'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    var name = '$stamp$ext';
    for (var i = 2; await File('${assets.path}/$name').exists(); i++) {
      name = '$stamp-$i$ext';
    }
    await source.copy('${assets.path}/$name');
    return 'assets/$name';
  }

  Future<void> deleteAsset(String folder, String relativePath) async {
    final file = resolve(folder, relativePath);
    if (file != null && await file.exists()) await file.delete();
  }

  /// Deletes the friend's folder, including their assets.
  Future<void> delete(String folder) async {
    final dir = folderDir(folder);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

const _transliterations = {
  'ä': 'ae',
  'ö': 'oe',
  'ü': 'ue',
  'ß': 'ss',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'ú': 'u',
  'č': 'c',
  'ć': 'c',
  'š': 's',
  'ž': 'z',
  'đ': 'dj',
  'ñ': 'n',
  'ç': 'c',
};

/// Turns a name into a safe folder name: `Anna Müller` → `anna-mueller`.
String slugify(String name) {
  final lower = name
      .toLowerCase()
      .split('')
      .map((c) => _transliterations[c] ?? c)
      .join();
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'friend' : slug;
}
