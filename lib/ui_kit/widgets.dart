import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/call_status.dart';

/// A soft rounded card with an optional small heading above it.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.fill = false,
    this.padding = const EdgeInsets.all(16),
  });

  final String? title;
  final Widget child;

  /// Stretch to the height the parent gives, e.g. to fill the screen.
  final bool fill;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: fill ? Align(alignment: Alignment.topLeft, child: child) : child,
    );
    if (title == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        fill ? Expanded(child: card) : card,
      ],
    );
  }
}

/// A small round button floating over content, e.g. the back button.
class FloatingRoundButton extends StatelessWidget {
  const FloatingRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.onSurface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: colors.surface),
          ),
        ),
      ),
    );
  }
}

/// The standard floating back button.
class BackRoundButton extends StatelessWidget {
  const BackRoundButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingRoundButton(
    icon: Icons.arrow_back_ios_new_rounded,
    tooltip: 'Back',
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

/// A small rounded label for a friend's call status.
class StatusPill extends StatelessWidget {
  const StatusPill(this.state, {super.key});

  final CallState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strong = state == CallState.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: switch (state) {
          CallState.overdue => colors.onSurface,
          CallState.due => colors.surfaceContainerHigh,
          _ => Colors.transparent,
        },
        border: state == CallState.never || state == CallState.ok
            ? Border.all(color: colors.outline)
            : null,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        callLabel(state),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: strong ? colors.surface : colors.onSurface,
        ),
      ),
    );
  }
}

/// A row with a rounded tick box; the whole row is tappable.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyLarge),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A segmented control: equal-width options, the selected one slides into
/// a filled pill.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Value, label and an optional label style (e.g. to preview a font).
  final List<(T, String, TextStyle?)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label, style) in options)
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: value == selected ? colors.onSurface : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: (style ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w600,
                          color: value == selected
                              ? colors.surface
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String callLabel(CallState state) => switch (state) {
  CallState.never => 'New',
  CallState.ok => 'OK',
  CallState.due => 'Due',
  CallState.overdue => 'Overdue',
};

/// `Today`, `Yesterday`, `18 days ago`, or `Never called`.
String lastCallLabel(int? days) => switch (days) {
  null => 'Never called',
  0 => 'Today',
  1 => 'Yesterday',
  _ => '$days days ago',
};
