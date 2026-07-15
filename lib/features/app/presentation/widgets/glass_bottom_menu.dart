import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../util/design_constants.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/glass_border_painter.dart';
import '../../../../widgets/common/app_button.dart';

/// Represents an action item within a [showGlassBottomMenu].
class GlassMenuAction {
  /// Optional standard material icon.
  final IconData? icon; // Now nullable
  /// Optional custom widget for the icon area (e.g., initials or custom shape).
  final Widget? customIcon; // New: for custom letters
  /// The main text label for the action.
  final String label;

  /// Optional secondary text providing more context.
  final String? subtitle;

  /// Callback triggered when the action is selected.
  final VoidCallback onTap;

  GlassMenuAction({
    this.icon,
    this.customIcon, // New
    required this.label,
    this.subtitle,
    required this.onTap,
  }) : assert(
          icon != null || customIcon != null,
          'Icon or customIcon must be provided',
        );
}

/// Shows a premium glass-styled modal bottom sheet.
///
/// Can display either a list of [actions] or custom [contentBuilder] content.
Future<T?> showGlassBottomMenu<T>({
  required BuildContext context,
  String? title,
  List<GlassMenuAction>? actions,
  Widget Function(BuildContext, VoidCallback)? contentBuilder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool applySafeAreaBottom = true,
}) {
  assert(
    (actions != null && contentBuilder == null) ||
        (actions == null && contentBuilder != null),
    'Either actions OR contentBuilder must be provided',
  );

  final isDark = Theme.of(context).brightness == Brightness.dark;

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: _GlassBottomMenuSheet(
          title: title,
          actions: actions ?? const <GlassMenuAction>[],
          contentBuilder: contentBuilder,
          applySafeAreaBottom: applySafeAreaBottom,
        ),
      );
    },
  );
}

class _GlassBottomMenuSheet extends StatelessWidget {
  const _GlassBottomMenuSheet({
    this.title,
    this.contentBuilder,
    this.actions = const <GlassMenuAction>[],
    this.applySafeAreaBottom = true,
  });

  final String? title;
  final Widget Function(BuildContext, VoidCallback)? contentBuilder;
  final List<GlassMenuAction> actions;
  final bool applySafeAreaBottom;

  @override
  Widget build(BuildContext context) {
    // ... (this part stays exactly identical to the current file) ...
    // ...
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = media.viewPadding.bottom;

    final Color neutralTint = isDark
        ? DesignConstants.summaryCardDarkMode.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.82);
    final Color effectiveGlass = DesignConstants.glassColor(isDark);

    const double r = 24;
    const EdgeInsets outerMargin = EdgeInsets.zero;

    Widget contentColumn() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignConstants.spacingS),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingL),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (contentBuilder != null) ...[
            const SizedBox(height: DesignConstants.spacingS),
            Padding(
              padding: EdgeInsets.only(
                  left: DesignConstants.spacingM,
                  right: DesignConstants.spacingM,
                  bottom: applySafeAreaBottom ? bottomInset : 0),
              child: contentBuilder!(
                context,
                () => Navigator.of(context).maybePop(),
              ),
            ),
          ] else if (actions.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 12, 8, 8 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(actions.length, (i) {
                      final a = actions[i];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingS),
                        child: _GlassTile(
                          icon: a.icon,
                          customIcon: a.customIcon, // <--- Pass new value
                          title: a.label,
                          subtitle: a.subtitle,
                          onTap: () {
                            HapticFeedbackService.instance.selectionFeedback();
                            Navigator.of(context).maybePop();
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => a.onTap(),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // ... (liquidCard and plainCard stay identical, shortened here) ...
    Widget liquidCard() {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: AdaptiveGlass(
              settings: LiquidGlassSettings(
                thickness: 0,
                blur: 8,
                glassColor: effectiveGlass,
                lightIntensity: 0,
                saturation: 1.20,
              ),
              shape: const LiquidVerticalRoundedSuperellipse(
                topRadius: r,
                bottomRadius: 0,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: neutralTint,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(r)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GlassBorderPainter(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                        radius: r,
                        strokeWidth: 1.5,
                        bottomPadding: bottomInset,
                      ),
                    ),
                  ),
                  contentColumn(),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: outerMargin,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: liquidCard(),
          ),
        ),
      ),
    );
  }
}
// In lib/widgets/glass_bottom_menu.dart

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    this.icon,
    this.customIcon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    final Color neutralTint = DesignConstants.glassNeutralTint(isDark);
    final Color effectiveGlass = DesignConstants.glassColor(isDark);

    final Widget leadingWidget =
        customIcon != null ? customIcon! : Icon(icon, size: 22);

    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: DesignConstants.spacingM),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
                width: 1,
              ),
            ),
            child: Center(child: leadingWidget),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Icon(
            LucideIcons.chevron_right,
            size: 22,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: AdaptiveGlass(
        settings: LiquidGlassSettings(
          // Changed here: thickness 0 removes distortion/shift.
          thickness: 0,
          blur:
              2.0, // Restored blur for clear but properly diffused liquid-glass look
          glassColor: effectiveGlass,
          // Changed here: less light intensity reduces harsh edges.
          lightIntensity: 0.1,
          saturation: 1.20,
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    // BorderRadius also helps visual separation here.
                    decoration: BoxDecoration(
                      color: neutralTint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                tileContent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable delete confirmation in glass style.
/// Returns true when deletion should proceed.
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  String? title,
  String? content,
  String? confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final effectiveTitle = title ?? l10n.deleteConfirmTitle;
  final effectiveContent = content ?? l10n.deleteConfirmContent;
  final effectiveConfirmLabel = confirmLabel ?? l10n.delete;

  final result = await showGlassBottomMenu<bool>(
    context: context,
    title: effectiveTitle,
    contentBuilder: (ctx, close) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingS),
            child: Text(
              effectiveContent,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(false);
                  },
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(true);
                  },
                  label: effectiveConfirmLabel,
                  tooltip: effectiveConfirmLabel,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}

/// Represents the user's choice when there is an active workout conflict.
enum ActiveWorkoutConflictResult {
  resume,
  discard,
  cancel,
}

/// Shows a glass-styled modal bottom sheet when trying to start a new workout
/// while another workout is already in progress.
Future<ActiveWorkoutConflictResult> showActiveWorkoutConflictDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;

  final result = await showGlassBottomMenu<ActiveWorkoutConflictResult>(
    context: context,
    title: l10n.workoutConflictTitle,
    contentBuilder: (ctx, close) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingS),
            child: Text(
              l10n.workoutConflictContent,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(ActiveWorkoutConflictResult.cancel);
                  },
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(ActiveWorkoutConflictResult.discard);
                  },
                  label: l10n.discardButton,
                  tooltip: l10n.discardButton,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              onPressed: () {
                close();
                Navigator.of(ctx).pop(ActiveWorkoutConflictResult.resume);
              },
              label: l10n.resumeWorkoutButton,
              tooltip: l10n.resumeWorkoutButton,
            ),
          ),
        ],
      );
    },
  );

  return result ?? ActiveWorkoutConflictResult.cancel;
}
