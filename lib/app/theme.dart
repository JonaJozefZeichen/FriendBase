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

/// Corner radius for cards, fields and buttons.
const kRadius = 16.0;

/// Two colours, soft cards, rounded corners, one font.
///
/// Cards and fields are a light tint of [Palette.fg] over [Palette.bg]
/// (`colorScheme.surfaceContainer`), so every palette stays two-colour.
ThemeData buildTheme(Palette palette, {AppFont font = AppFont.system}) {
  final fg = palette.fg;
  final bg = palette.bg;
  final brightness = palette.brightness;
  final dark = brightness == Brightness.dark;
  final family = fontFamilyFor(font);
  Color tint(double light, double darkAlpha) =>
      Color.alphaBlend(fg.withValues(alpha: dark ? darkAlpha : light), bg);
  final card = tint(0.06, 0.12);
  final cardHigh = tint(0.11, 0.2);
  final muted = fg.withValues(alpha: 0.55);
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kRadius),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadius),
    borderSide: BorderSide.none,
  );

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
      onSurfaceVariant: muted,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: cardHigh,
      surfaceContainerHighest: cardHigh,
      outline: fg.withValues(alpha: 0.3),
      outlineVariant: fg.withValues(alpha: 0.12),
    ),
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    hintColor: fg.withValues(alpha: 0.45),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: fg,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: fg.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        backgroundColor: fg,
        foregroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // Spelled out: a button textStyle replaces the theme font entirely.
        textStyle: TextStyle(
          fontFamily: family,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: rounded,
        side: BorderSide(color: fg.withValues(alpha: 0.3)),
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: fg,
        textStyle: TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: fg),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: fg,
      foregroundColor: bg,
      elevation: 2,
      highlightElevation: 4,
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: fg.withValues(alpha: 0.5), width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: fg, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: fg, width: 1.5),
      ),
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: fg),
      hintStyle: TextStyle(color: fg.withValues(alpha: 0.45)),
      prefixIconColor: muted,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: fg.withValues(alpha: 0.4), width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? fg : null,
      ),
      checkColor: WidgetStatePropertyAll(bg),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: fg,
      contentTextStyle: TextStyle(color: bg, fontFamily: family),
      actionTextColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: fg.withValues(alpha: 0.3),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: bg),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: fg),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: fg,
      selectionColor: fg.withValues(alpha: 0.2),
      selectionHandleColor: fg,
    ),
  );
}
