import 'dart:convert';
import 'dart:io';

import '../domain/app_settings.dart';

/// Reads and writes `<vault>/.friendbase/config.json`.
class SettingsStorage {
  SettingsStorage(this.root);

  final Directory root;

  File get _file => File('${root.path}/.friendbase/config.json');

  /// Defaults if the file is missing or unreadable.
  Future<AppSettings> load() async {
    try {
      final json = jsonDecode(await _file.readAsString());
      if (json is Map<String, Object?>) return AppSettings.fromJson(json);
    } on FileSystemException {
      // No config yet.
    } on FormatException {
      // Broken by hand-editing; start from defaults, next save repairs it.
    }
    return const AppSettings();
  }

  /// Atomic, like `VaultStorage.write`.
  Future<void> save(AppSettings settings) async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      flush: true,
    );
    await tmp.rename(_file.path);
  }
}
