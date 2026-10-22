import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/app_settings.dart';

/// A two-colour theme: everything is drawn in [fg] on [bg].
class Palette {
  const Palette(this.name, this.fg, this.bg, this.brightness);

  final String name;
  final Color fg;
  final Color bg;
  final Brightness brightness;
}

const kLight = Palette(
  'Light',
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Brightness.light,
);
const kDark = Palette(
  'Dark',
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Brightness.dark,
);

/// Every selectable palette. `AppTheme.system` switches between Light and
/// Dark with the phone.
const kPalettes = {
  AppTheme.light: kLight,
  AppTheme.dark: kDark,
  AppTheme.rose: Palette(
    'Rose',
    Color(0xFF3B1F27),
    Color(0xFFF9DDE3),
    Brightness.light,
  ),
  AppTheme.mint: Palette(
    'Mint',
    Color(0xFF1E3A2F),
    Color(0xFFD8F3E6),
    Brightness.light,
  ),
  AppTheme.sky: Palette(
    'Sky',
    Color(0xFF1C2E45),
    Color(0xFFD9EAF8),
    Brightness.light,
  ),
  AppTheme.lavender: Palette(
    'Lavender',
    Color(0xFF2E2645),
    Color(0xFFE6E0F7),
    Brightness.light,
  ),
};

/// The font family for [font]; null means the platform's own UI font
/// (SF Pro on iOS, Roboto on Android).
String? fontFamilyFor(AppFont font) => switch (font) {
  AppFont.system => null,
  AppFont.serif => 'SourceSerif4',
  AppFont.readable => 'AtkinsonHyperlegible',
  AppFont.mono =>
    defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? 'Menlo'
        : 'monospace',
};

/// Two colours, square corners, one font.
ThemeData buildTheme(Palette palette, {AppFont font = AppFont.system}) {
  final fg = palette.fg;
  final bg = palette.bg;
  final brightness = palette.brightness;
  final family = fontFamilyFor(font);
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final border = BorderSide(color: fg);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: family,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: fg,
      onPrimary: bg,
      secondary: fg,
      onSecondary: bg,
      error: fg,
      onError: bg,
      surface: bg,
      onSurface: fg,
    ),
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    hintColor: fg.withValues(alpha: 0.45),
    splashFactory: NoSplash.splashFactory,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: border),
      titleTextStyle: base.textTheme.titleMedium?.copyWith(
        color: fg,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    ),
    dividerTheme: DividerThemeData(color: fg, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: square,
        backgroundColor: fg,
        foregroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        // Spelled out: a button textStyle replaces the theme font entirely.
        textStyle: TextStyle(
          fontFamily: family,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: square,
        side: border,
        foregroundColor: fg,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: square, foregroundColor: fg),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: fg,
      foregroundColor: bg,
      elevation: 0,
      shape: square,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: border,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: border,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: border.copyWith(width: 2),
      ),
      floatingLabelStyle: TextStyle(color: fg),
      hintStyle: TextStyle(color: fg.withValues(alpha: 0.45)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: fg,
      contentTextStyle: TextStyle(color: bg, fontFamily: family),
      actionTextColor: bg,
      shape: square,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(side: border),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: bg),
    datePickerTheme: DatePickerThemeData(backgroundColor: bg),
    timePickerTheme: TimePickerThemeData(backgroundColor: bg),
    textSelectionTheme: TextSelectionThemeData(cursorColor: fg),
  );
}
