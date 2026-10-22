import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app/theme.dart';

/// The paper every screen sits on: the paper colour with a fine dot grid.
///
/// The dots are anchored to the *screen*, not to the page: while a page
/// slides in or out (or follows the iOS back swipe) its paper stays put, so
/// only the content moves and no seam shows between the two pages.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final paper = LedgerTokens.of(context).paper;
    final route = ModalRoute.of(context);
    return _AnchoredPaper(
      paper: paper.paper,
      dot: paper.dot,
      // Repaint on every frame of this page's transitions.
      repaint: Listenable.merge([route?.animation, route?.secondaryAnimation]),
      child: child,
    );
  }
}

class _AnchoredPaper extends SingleChildRenderObjectWidget {
  const _AnchoredPaper({
    required this.paper,
    required this.dot,
    required this.repaint,
    super.child,
  });

  final Color paper;
  final Color dot;
  final Listenable repaint;

  @override
  RenderAnchoredPaper createRenderObject(BuildContext context) =>
      RenderAnchoredPaper(paper: paper, dot: dot, repaint: repaint);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAnchoredPaper renderObject,
  ) {
    renderObject
      ..paper = paper
      ..dot = dot
      ..repaint = repaint;
  }
}

/// Paints the paper and a dot grid aligned to global (screen) coordinates.
class RenderAnchoredPaper extends RenderProxyBox {
  RenderAnchoredPaper({
    required this._paper,
    required this._dot,
    required this._repaint,
  });

  static const spacing = 16.0;

  Color _paper;
  set paper(Color value) {
    if (value == _paper) return;
    _paper = value;
    markNeedsPaint();
  }

  Color _dot;
  set dot(Color value) {
    if (value == _dot) return;
    _dot = value;
    markNeedsPaint();
  }

  Listenable _repaint;
  set repaint(Listenable value) {
    if (identical(value, _repaint)) return;
    if (attached) {
      _repaint.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _repaint = value;
  }

  /// Where the first dot was drawn, in screen coordinates (for tests).
  @visibleForTesting
  Offset? debugFirstDotGlobal;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.drawRect(offset & size, Paint()..color = _paper);
    // Our top-left corner on screen, including any transition transform.
    final origin = localToGlobal(Offset.zero);
    const half = spacing / 2;
    final x0 = (half - origin.dx) % spacing;
    final y0 = (half - origin.dy) % spacing;
    debugFirstDotGlobal = origin + Offset(x0, y0);
    final paint = Paint()..color = _dot;
    for (var y = y0; y < size.height; y += spacing) {
      for (var x = x0; x < size.width; x += spacing) {
        canvas.drawCircle(offset + Offset(x, y), 1.1, paint);
      }
    }
    super.paint(context, offset);
  }
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

/// The round glass "lens" for logging a call: a chat bubble with a check
/// ("we talked"). Once today is logged it turns solid ([done]). Tap after a
/// call, hold for an earlier date.
class LensButton extends StatelessWidget {
  const LensButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    required this.onLongPress,
    this.done = false,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Today's call is already logged.
  final bool done;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? paper.accent : null,
            gradient: done
                ? null
                : RadialGradient(
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
            border: Border.all(color: done ? paper.accent : paper.glassRim),
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
              child: Icon(
                done
                    ? Icons.mark_chat_read_rounded
                    : Icons.mark_chat_read_outlined,
                size: 26,
                color: done ? paper.onAccent : paper.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
