import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/app_settings.dart';

/// One Ledger paper: the ground everything sits on, the ink written on it,
/// and the ballpoint accent. All text pairs are ≥ 4.5 : 1 on the paper and
/// on frosted glass over it (see `test/app/ledger_contrast_test.dart`).
class Paper {
  const Paper({
    required this.brightness,
    required this.paper,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.dot,
    required this.glassFill,
    required this.glassRim,
    required this.scrapA,
    required this.scrapB,
    required this.rule,
    required this.margin,
  });

  final Brightness brightness;
  final Color paper;
  final Color ink;
  final Color muted;

  /// Ballpoint blue: primary actions, selection, due friends.
  final Color accent;
  final Color onAccent;

  /// Red ink: overdue, allergies.
  final Color danger;
  final Color dot;
  final Color glassFill;
  final Color glassRim;

  /// Light paper (ruled notes page) and a second paper tone.
  final Color scrapA;
  final Color scrapB;

  /// Ruled lines and the red margin line of a notebook page.
  final Color rule;
  final Color margin;

  /// The glass as an opaque colour, for fills and high-contrast fallbacks.
  Color get card => Color.alphaBlend(glassFill, paper);
}

const kCream = Paper(
  brightness: Brightness.light,
  paper: Color(0xFFF3EFE6),
  ink: Color(0xFF2B2620),
  muted: Color(0xFF655C50),
  accent: Color(0xFF2F4BA8),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFA8352A),
  dot: Color(0x332F4BA8),
  glassFill: Color(0x80FFFFFF),
  glassRim: Color(0xCCFFFFFF),
  scrapA: Color(0xFFFBF8F1),
  scrapB: Color(0xFFDCC7A2),
  rule: Color(0xFFC9D4E6),
  margin: Color(0xFFD9604C),
);

const kKraft = Paper(
  brightness: Brightness.light,
  paper: Color(0xFFDCC7A2),
  ink: Color(0xFF2B2620),
  muted: Color(0xFF574C3C),
  accent: Color(0xFF243B8A),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFF8E2A20),
  dot: Color(0x332B2620),
  glassFill: Color(0x80FFFFFF),
  glassRim: Color(0xB3FFFFFF),
  scrapA: Color(0xFFFBF8F1),
  scrapB: Color(0xFFC9B184),
  rule: Color(0xFFB9C4D6),
  margin: Color(0xFFC0503E),
);

const kBlue = Paper(
  brightness: Brightness.light,
  paper: Color(0xFFE8EEF7),
  ink: Color(0xFF1E2E55),
  muted: Color(0xFF4E5A73),
  accent: Color(0xFF2F4BA8),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFA8352A),
  dot: Color(0x332F4BA8),
  glassFill: Color(0x80FFFFFF),
  glassRim: Color(0xCCFFFFFF),
  scrapA: Color(0xFFFFFFFF),
  scrapB: Color(0xFFD3DDEC),
  rule: Color(0xFFC3CFE3),
  margin: Color(0xFFD9604C),
);

const kInk = Paper(
  brightness: Brightness.dark,
  paper: Color(0xFF1F1D24),
  ink: Color(0xFFEDEAF5),
  muted: Color(0xFFABA6B8),
  accent: Color(0xFF8EA2F0),
  onAccent: Color(0xFF1F1D24),
  danger: Color(0xFFF08A7C),
  dot: Color(0x298EA2F0),
  glassFill: Color(0x12FFFFFF),
  glassRim: Color(0x24FFFFFF),
  scrapA: Color(0xFF2B2932),
  scrapB: Color(0xFF34302B),
  rule: Color(0xFF3A3846),
  margin: Color(0xFF8A3A2E),
);

/// Every selectable paper. `AppTheme.system` uses Cream by day and Ink at
/// night.
const kPapers = {
  AppTheme.cream: kCream,
  AppTheme.kraft: kKraft,
  AppTheme.blue: kBlue,
  AppTheme.ink: kInk,
};

/// The body font family for [font]; null means the platform's UI font
/// (SF Pro on iOS, Roboto on Android).
String? fontFamilyFor(AppFont font) => switch (font) {
  AppFont.ledger || AppFont.serif => 'SourceSerif4',
  AppFont.system => null,
  AppFont.readable => 'AtkinsonHyperlegible',
  AppFont.mono => _platformMono,
};

/// The family for numbers, dates and small labels. Ledger pairs the serif
/// with IBM Plex Mono; every other choice uses its one family throughout.
String? dataFontFamilyFor(AppFont font) => switch (font) {
  AppFont.ledger => 'IBMPlexMono',
  _ => fontFamilyFor(font),
};

String get _platformMono =>
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS
    ? 'Menlo'
    : 'monospace';

/// Ledger design values for widgets that draw paper and glass themselves.
@immutable
class LedgerTokens extends ThemeExtension<LedgerTokens> {
  const LedgerTokens({required this.paper, required this.dataFamily});

  final Paper paper;
  final String? dataFamily;

  static LedgerTokens of(BuildContext context) =>
      Theme.of(context).extension<LedgerTokens>()!;

  /// Style for numbers, dates and small labels.
  TextStyle data({
    double? size,
    FontWeight? weight,
    Color? color,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: dataFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  @override
  LedgerTokens copyWith({Paper? paper, String? dataFamily}) => LedgerTokens(
    paper: paper ?? this.paper,
    dataFamily: dataFamily ?? this.dataFamily,
  );

  @override
  LedgerTokens lerp(LedgerTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Corner radius for glass cards.
const kRadius = 22.0;

/// Paper, ink and glass with one ballpoint accent.
ThemeData buildTheme(Paper paper, {AppFont font = AppFont.ledger}) {
  final fg = paper.ink;
  final bg = paper.paper;
  final brightness = paper.brightness;
  final family = fontFamilyFor(font);
  final muted = paper.muted;
  final card = paper.card;
  final cardHigh = Color.alphaBlend(fg.withValues(alpha: 0.08), card);
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: paper.glassRim),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: family,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: paper.accent,
      onPrimary: paper.onAccent,
      secondary: paper.accent,
      onSecondary: paper.onAccent,
      error: paper.danger,
      onError: paper.onAccent,
      surface: bg,
      onSurface: fg,
      onSurfaceVariant: muted,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: cardHigh,
      surfaceContainerHighest: cardHigh,
      outline: fg.withValues(alpha: 0.3),
      outlineVariant: fg.withValues(alpha: 0.14),
    ),
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    hintColor: muted,
    extensions: [
      LedgerTokens(paper: paper, dataFamily: dataFontFamilyFor(font)),
    ],
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      // Transparent so the paper's dot grid runs behind it.
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: fg,
        fontWeight: FontWeight.w700,
        fontFamily: family,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: fg.withValues(alpha: 0.14),
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        backgroundColor: paper.accent,
        foregroundColor: paper.onAccent,
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
        foregroundColor: paper.accent,
        textStyle: TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: fg),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: paper.accent,
      foregroundColor: paper.onAccent,
      elevation: 3,
      highlightElevation: 5,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: paper.accent, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: paper.danger, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: paper.danger, width: 1.5),
      ),
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: fg),
      hintStyle: TextStyle(color: muted),
      prefixIconColor: muted,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: BorderSide(color: fg.withValues(alpha: 0.4), width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? paper.accent : null,
      ),
      checkColor: WidgetStatePropertyAll(paper.onAccent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: fg,
      contentTextStyle: TextStyle(color: bg, fontFamily: family),
      actionTextColor: brightness == Brightness.dark
          ? const Color(0xFF2F4BA8)
          : const Color(0xFFB9C7FF),
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
    progressIndicatorTheme: ProgressIndicatorThemeData(color: paper.accent),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: paper.accent,
      selectionColor: paper.accent.withValues(alpha: 0.25),
      selectionHandleColor: paper.accent,
    ),
  );
}
