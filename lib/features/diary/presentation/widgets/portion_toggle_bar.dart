import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Portion toggle bar — compact segmented control
// ═══════════════════════════════════════════════════════════════════════════

/// A compact two-chip glass segmented control for toggling between
/// per-portion and per-100g nutrition views.
///
/// The shared track uses the same restrained rounded-card language as the
/// nutrition cards, while each [_PortionChip] handles its own tap gesture and
/// animated selected-state highlight.
class PortionToggleBar extends StatelessWidget {
  final bool showPer100g;
  final ValueChanged<bool> onChanged;
  final String labelPortion;
  final String label100g;

  const PortionToggleBar({
    super.key,
    required this.showPer100g,
    required this.onChanged,
    required this.labelPortion,
    required this.label100g,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: showPer100g,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.46)
              : cs.surfaceContainerHighest.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: isDark ? 0.14 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: cs.shadow.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PortionChip(
              label: labelPortion,
              selected: !showPer100g,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 2),
            _PortionChip(
              label: label100g,
              selected: showPer100g,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable chip inside [PortionToggleBar].
///
/// Uses an [AnimatedContainer] to transition the selection highlight
/// (primary-tinted background + bold primary text) with a 180ms ease.
class _PortionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PortionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 58, minHeight: 30),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: isDark ? 0.34 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(
                  color: cs.primary.withValues(alpha: isDark ? 0.34 : 0.18),
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.88),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
