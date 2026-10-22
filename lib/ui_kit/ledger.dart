import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The paper every screen sits on: the paper colour with a fine dot grid,
/// optionally with two paper scraps lying underneath the content.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.scraps = false});

  final Widget child;

  /// Decorative scraps (a ruled note and a kraft card with tape). Keep them
  /// to screens with little text over them.
  final bool scraps;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    return CustomPaint(
      painter: _DotGridPainter(paper.paper, paper.dot),
      child: Stack(
        fit: StackFit.expand,
        children: [if (scraps) ..._scraps(paper), child],
      ),
    );
  }

  static List<Widget> _scraps(Paper paper) => [
    Positioned(
      left: -24,
      top: 190,
      child: _Scrap(
        width: 210,
        height: 220,
        angle: -7,
        color: paper.scrapA,
        child: CustomPaint(
          painter: RuledPainter(
            rule: paper.rule,
            margin: paper.margin,
            lineHeight: 20,
            marginX: 22,
          ),
        ),
      ),
    ),
    Positioned(
      right: -34,
      top: 330,
      child: _Scrap(width: 190, height: 170, angle: 6, color: paper.scrapB),
    ),
    Positioned(
      right: 56,
      top: 318,
      child: _Scrap(
        width: 70,
        height: 20,
        angle: -4,
        color: const Color(0xCCECDCAA),
        shadow: false,
      ),
    ),
  ];
}

class _Scrap extends StatelessWidget {
  const _Scrap({
    required this.width,
    required this.height,
    required this.angle,
    required this.color,
    this.child,
    this.shadow = true,
  });

  final double width;
  final double height;
  final double angle;
  final Color color;
  final Widget? child;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              boxShadow: shadow
                  ? const [
                      BoxShadow(
                        color: Color(0x1F2B2620),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.paper, this.dot);

  final Color paper;
  final Color dot;

  static const _spacing = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final paint = Paint()..color = dot;
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.paper != paper || old.dot != dot;
}

/// Frosted glass: blur of whatever lies behind, a translucent fill and a
/// light rim. With "Increase contrast" it turns into an opaque card.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = kRadius,
    this.circle = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final bool circle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    final highContrast = MediaQuery.highContrastOf(context);
    final borderRadius = circle ? null : BorderRadius.circular(radius);
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: borderRadius,
        color: highContrast ? paper.card : paper.glassFill,
        border: Border.all(
          color: highContrast
              ? paper.ink.withValues(alpha: 0.5)
              : paper.glassRim,
        ),
      ),
      // Transparent Material so ripples of ListTiles/InkWells show.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
    final clipped = circle
        ? ClipOval(child: _blurred(content, highContrast))
        : ClipRRect(
            borderRadius: borderRadius!,
            child: _blurred(content, highContrast),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: paper.brightness == Brightness.dark ? 0.25 : 0.07,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: clipped,
    );
  }

  static Widget _blurred(Widget child, bool highContrast) => highContrast
      ? child
      : BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: child,
        );
}

/// Ruled notebook lines with a red margin line.
class RuledPainter extends CustomPainter {
  RuledPainter({
    required this.rule,
    required this.margin,
    this.lineHeight = 28,
    this.marginX = 40,
    this.offset = 0,
  });

  final Color rule;
  final Color margin;
  final double lineHeight;
  final double marginX;

  /// Where the first line sits, so text baselines can land on the lines.
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = rule
      ..strokeWidth = 1;
    for (var y = offset + lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(
      Offset(marginX, 0),
      Offset(marginX, size.height),
      Paint()
        ..color = margin
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(RuledPainter old) =>
      old.rule != rule ||
      old.margin != margin ||
      old.lineHeight != lineHeight ||
      old.marginX != marginX ||
      old.offset != offset;
}

/// A notebook page: ruled lines, margin line, text written on the lines.
class RuledPage extends StatelessWidget {
  const RuledPage({super.key, required this.child, this.fill = false});

  final Widget child;
  final bool fill;

  static const lineHeight = 28.0;
  static const _top = 8.0;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    final dark = paper.brightness == Brightness.dark;
    // Fill colour under the lines, lines under the text.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: dark ? paper.scrapA.withValues(alpha: 0.6) : paper.scrapA,
        child: CustomPaint(
          painter: RuledPainter(
            rule: paper.rule,
            margin: paper.margin,
            offset: _top,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: fill ? 0 : lineHeight * 4),
            padding: const EdgeInsets.fromLTRB(52, _top - 4, 14, 8),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 16, height: lineHeight / 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A photo in a white instant-camera frame, slightly tilted.
class Polaroid extends StatelessWidget {
  const Polaroid({
    super.key,
    required this.child,
    this.tilt = 0,
    this.size = 64,
  });

  final Widget child;

  /// Degrees; alternate the sign for a hand-placed look.
  final double tilt;
  final double size;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    final dark = paper.brightness == Brightness.dark;
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 13),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF2E2C34) : const Color(0xFFFFFDF7),
          boxShadow: const [
            BoxShadow(
              color: Color(0x262B2620),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

/// The round glass "lens" with an ink dot: tap after a call, hold for an
/// earlier date.
class LensButton extends StatelessWidget {
  const LensButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    final dark = paper.brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        hint: hint,
        excludeSemantics: true,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              colors: dark
                  ? [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.06),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.4),
                    ],
            ),
            border: Border.all(color: paper.glassRim),
            boxShadow: [
              BoxShadow(
                color: paper.accent.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: paper.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
