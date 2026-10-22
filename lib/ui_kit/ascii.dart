import 'package:flutter/material.dart';

import '../domain/call_status.dart';

/// A 1px box with its title set into the top border: `┌─ TITLE ───┐`.
class AsciiBox extends StatelessWidget {
  const AsciiBox({
    super.key,
    required this.title,
    required this.child,
    this.fill = false,
  });

  final String title;
  final Widget child;

  /// Stretch to the height the parent gives, e.g. to fill the screen.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      fit: fill ? StackFit.expand : StackFit.loose,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: colors.onSurface),
          ),
          child: fill
              ? Align(alignment: Alignment.topLeft, child: child)
              : child,
        ),
        Positioned(
          left: 10,
          top: 0,
          child: Container(
            color: colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '─ ${title.toUpperCase()} ─',
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1.1),
            ),
          ),
        ),
      ],
    );
  }
}

/// A solid square button with a short text label, e.g. the `<` back button.
class SquareButton extends StatelessWidget {
  const SquareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.size = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = Material(
      color: colors.onSurface,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: colors.surface,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// A text progress bar: `[██████····]`.
String asciiBar(double progress, {int width = 10}) {
  final filled = (progress.clamp(0.0, 1.0) * width).round();
  return '[${'█' * filled}${'·' * (width - filled)}]';
}

/// Short marker for the friend list.
String callMarker(CallState state) => switch (state) {
  CallState.never => '--',
  CallState.ok => 'ok',
  CallState.due => '! ',
  CallState.overdue => '!!',
};

String callLabel(CallState state) => switch (state) {
  CallState.never => 'NEVER CALLED',
  CallState.ok => 'OK',
  CallState.due => 'DUE',
  CallState.overdue => 'OVERDUE',
};

/// `0d`, `18d`, or `—` when never called.
String daysLabel(int? days) => days == null ? '—' : '${days}d';
