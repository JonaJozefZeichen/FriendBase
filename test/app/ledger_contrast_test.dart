import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/app/theme.dart';
import 'package:friendbase/ui_kit/ledger.dart';

/// WCAG relative luminance contrast between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, paper) in [
    ('Cream', kCream),
    ('Kraft', kKraft),
    ('Blue', kBlue),
    ('Ink', kInk),
  ]) {
    test('$name: every text colour ≥ 4.5 : 1 on paper and on glass', () {
      for (final ground in [paper.paper, paper.card]) {
        for (final (role, text) in [
          ('ink', paper.ink),
          ('muted', paper.muted),
          ('accent', paper.accent),
          ('danger', paper.danger),
        ]) {
          expect(
            contrast(text, ground),
            greaterThanOrEqualTo(4.5),
            reason: '$role on $ground',
          );
        }
      }
      expect(contrast(paper.onAccent, paper.accent), greaterThanOrEqualTo(4.5));
    });
  }

  testWidgets('glass turns into an opaque card with Increase contrast', (
    tester,
  ) async {
    Widget app({required bool highContrast}) => MaterialApp(
      theme: buildTheme(kCream),
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: const GlassSurface(child: SizedBox(width: 50, height: 50)),
      ),
    );

    await tester.pumpWidget(app(highContrast: false));
    expect(find.byType(BackdropFilter), findsOneWidget);
    BoxDecoration fill() => tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.color != null);
    expect(fill().color, kCream.glassFill);

    await tester.pumpWidget(app(highContrast: true));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(fill().color, kCream.card);
  });

  test('no ASCII box-drawing or bracket decorations in the UI', () {
    final ascii = RegExp(r'[┤├┌┐└┘─]|\[x\]|\[ \]|> search');
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('l10n/app_localizations')) continue;
      final lines = file.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        expect(
          ascii.hasMatch(line),
          isFalse,
          reason: '${file.path}:${i + 1}: $line',
        );
      }
    }
  });

  testWidgets('paper dots stay on the screen grid when the page moves', (
    tester,
  ) async {
    for (final shift in [
      Offset.zero,
      const Offset(37.5, 11),
      const Offset(-123, 0),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(kCream),
          home: Transform.translate(
            offset: shift,
            child: const PaperBackground(child: SizedBox.expand()),
          ),
        ),
      );
      final paper = tester.renderObject<RenderAnchoredPaper>(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_AnchoredPaper',
        ),
      );
      final dot = paper.debugFirstDotGlobal!;
      // Always on the same screen grid, wherever the page currently is.
      expect(
        dot.dx % RenderAnchoredPaper.spacing,
        closeTo(8, 0.001),
        reason: '$shift',
      );
      expect(
        dot.dy % RenderAnchoredPaper.spacing,
        closeTo(8, 0.001),
        reason: '$shift',
      );
    }
  });
}
