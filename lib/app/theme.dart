import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Monochrome, monospace, square. Dark mode simply inverts.
ThemeData buildTheme(Brightness brightness) {
  final fg = brightness == Brightness.light ? Colors.black : Colors.white;
  final bg = brightness == Brightness.light ? Colors.white : Colors.black;
  final mono =
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS
      ? 'Menlo'
      : 'monospace';
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final border = BorderSide(color: fg);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: mono,
    fontFamilyFallback: const ['Menlo', 'Courier New', 'Courier', 'monospace'],
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
          fontFamily: mono,
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
      contentTextStyle: TextStyle(color: bg, fontFamily: mono),
      actionTextColor: bg,
      shape: square,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(side: border),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: fg),
  );
}
