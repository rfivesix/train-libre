import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';

/// Represents a single action item inside a [showGlassContextMenu].
class GlassContextAction {
  /// Main label text (e.g., "Bearbeiten" or "Löschen").
  final String label;

  /// Icon representing the action.
  final IconData icon;

  /// Callback executed when the action item is selected.
  final VoidCallback onTap;

  /// If true, renders the action in a prominent destructive color (e.g., brand red).
  final bool isDestructive;

  /// Optional subtitle or secondary details.
  final String? subtitle;

  const GlassContextAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.subtitle,
  });
}

/// Displays an iOS / WhatsApp style context menu with a blurred background,
/// elevated target card, and floating Liquid Glass action menu.
Future<void> showGlassContextMenu({
  required BuildContext context,
  required Rect targetRect,
  required Widget targetWidget,
  required List<GlassContextAction> actions,
  BorderRadius? borderRadius,
}) async {
  if (actions.isEmpty) return;

  // Trigger haptic feedback asynchronously when opening context menu
  unawaited(HapticFeedbackService.mediumImpact());

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.55)
      : Colors.black.withValues(alpha: 0.32);

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Context Menu',
    barrierColor: barrierColor,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return _GlassContextMenuOverlay(
        targetRect: targetRect,
        targetWidget: targetWidget,
        actions: actions,
        borderRadius: borderRadius ??
            BorderRadius.circular(DesignConstants.borderRadiusL),
        animation: animation,
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
  );
}

class _GlassContextMenuOverlay extends StatelessWidget {
  final Rect targetRect;
  final Widget targetWidget;
  final List<GlassContextAction> actions;
  final BorderRadius borderRadius;
  final Animation<double> animation;

  const _GlassContextMenuOverlay({
    required this.targetRect,
    required this.targetWidget,
    required this.actions,
    required this.borderRadius,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    // Calculate vertical layout & bounds
    const double menuSpacing = 8.0;
    final double estimatedMenuHeight = (actions.length * 52.0) + 16.0;

    // Check if menu should be placed above or below target
    final double spaceBelow =
        screenSize.height - targetRect.bottom - bottomPadding;
    final bool showAbove = spaceBelow < (estimatedMenuHeight + 20) &&
        targetRect.top > estimatedMenuHeight;

    // Constrain card positioning to visible bounds
    final double cardTop = targetRect.top.clamp(
      topPadding + 10,
      screenSize.height - bottomPadding - targetRect.height - 10,
    );

    final double cardLeft = math.max(16.0, targetRect.left);
    final double cardWidth =
        math.min(targetRect.width, screenSize.width - 32.0);

    // Context menu position
    final double menuTop = showAbove
        ? math.max(topPadding + 10, cardTop - estimatedMenuHeight - menuSpacing)
        : math.min(screenSize.height - bottomPadding - estimatedMenuHeight - 10,
            cardTop + targetRect.height + menuSpacing);

    final CurvedAnimation easeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double progress = easeAnimation.value;
        final double cardScale = 1.0 + (0.025 * progress);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Blurry background barrier (native route barrier color + static backdrop blur)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12.0,
                    sigmaY: 12.0,
                  ),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

              // Elevated & Focused Target Card (Seamless 2.5% scale growth, no warping)
              Positioned(
                top: cardTop,
                left: cardLeft,
                width: cardWidth,
                height: targetRect.height,
                child: Transform.scale(
                  scale: cardScale,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8 * progress,
                    shadowColor: cs.shadow
                        .withValues(alpha: (isDark ? 0.4 : 0.2) * progress),
                    borderRadius: borderRadius,
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: IgnorePointer(
                        child: targetWidget,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Liquid Glass Action Menu
              Positioned(
                top: menuTop,
                left: cardLeft,
                width: math.min(cardWidth, 320.0),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1.0)
                      .animate(easeAnimation),
                  alignment:
                      showAbove ? Alignment.bottomLeft : Alignment.topLeft,
                  child: _buildGlassMenuCard(context, isDark, cs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassMenuCard(
      BuildContext context, bool isDark, ColorScheme cs) {
    final radius = BorderRadius.circular(DesignConstants.borderRadiusL);

    return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? DesignConstants.summaryCardDarkMode
                        .withValues(alpha: 0.88)
                    : cs.surface.withValues(alpha: 0.92),
                borderRadius: radius,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : cs.onSurface.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(actions.length, (index) {
                  final action = actions[index];
                  final isLast = index == actions.length - 1;
                  final Color actionColor = action.isDestructive
                      ? DesignConstants.brandRedColor
                      : cs.onSurface;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            unawaited(HapticFeedbackService.selectionClick());
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              action.onTap();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 14.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  action.icon,
                                  size: 20,
                                  color: actionColor,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        action.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: actionColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (action.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          action.subtitle!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (action.isDestructive)
                                  Icon(
                                    LucideIcons.chevron_right,
                                    size: 16,
                                    color: actionColor.withValues(alpha: 0.6),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ));
  }
}
