import 'package:flutter/material.dart';

/// App-wide options, stored in `<vault>/.friendbase/config.json`.
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});

  /// `system` until the user picks light or dark.
  final ThemeMode themeMode;

  AppSettings copyWith({ThemeMode? themeMode}) =>
      AppSettings(themeMode: themeMode ?? this.themeMode);

  Map<String, Object?> toJson() => {'theme': themeMode.name};

  /// Unknown or missing values fall back to defaults.
  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
    themeMode: ThemeMode.values.asNameMap()[json['theme']] ?? ThemeMode.system,
  );
}
