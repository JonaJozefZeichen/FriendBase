import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/l10n.dart';
import 'ledger.dart';

/// A frosted glass card with an optional small heading above it.
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
    final card = SizedBox(
      width: double.infinity,
      child: GlassSurface(
        padding: padding,
        child: fill ? Align(alignment: Alignment.topLeft, child: child) : child,
      ),
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

/// A small round glass button floating over content, e.g. the back
/// button. [filled] makes it a solid ballpoint-blue action instead.
class FloatingRoundButton extends StatelessWidget {
  const FloatingRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.size = 46,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          icon,
          size: 20,
          color: filled ? colors.onPrimary : colors.onSurface,
        ),
      ),
    );
    return Tooltip(
      message: tooltip,
      child: filled
          ? Material(
              color: colors.primary,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: colors.primary.withValues(alpha: 0.5),
              child: button,
            )
          : GlassSurface(circle: true, child: button),
    );
  }
}

/// The standard floating back button.
class BackRoundButton extends StatelessWidget {
  const BackRoundButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingRoundButton(
    icon: Icons.arrow_back_ios_new_rounded,
    tooltip: context.l10n.back,
    onPressed: () => Navigator.of(context).maybePop(),
  );
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

/// A segmented control on a glass track; the selected option sits under a
/// white "lens" thumb.
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
    final paper = LedgerTokens.of(context).paper;
    final dark = paper.brightness == Brightness.dark;
    final thumb = dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.95);
    return GlassSurface(
      radius: 999,
      padding: const EdgeInsets.all(4),
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
                    duration: const Duration(milliseconds: 220),
                    // No overshooting curve: it would push the shadow's
                    // blur below zero mid-animation.
                    curve: Curves.easeOutCubic,
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: value == selected ? thumb : null,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: value == selected && !dark
                          ? const [
                              BoxShadow(
                                color: Color(0x262E2645),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: (style ?? const TextStyle()).copyWith(
                          fontWeight: value == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: colors.onSurface,
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

/// Shown where a date would be when there is none, e.g. never called.
const kNoValue = '– –';

/// `Today`, `Yesterday`, `18 days ago`, or `– –` if never called.
String lastCallLabel(BuildContext context, int? days) =>
    days == null ? kNoValue : context.l10n.lastCallAgo(days);
