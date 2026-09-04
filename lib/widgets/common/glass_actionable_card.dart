import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../common/swipe_action_background.dart';
import '../common/summary_card.dart';
import '../common/glass_context_menu_overlay.dart';
import '../../features/app/presentation/widgets/glass_bottom_menu.dart';

/// A unified, highly accessible wrapper for summary cards and tiles.
///
/// Combines:
/// 1. **Swipe Actions**: Left-to-right (Edit) and Right-to-left (Delete) using [Dismissible].
/// 2. **iOS Liquid Glass Context Menu**: Triggered on long-press (or tap when configured).
/// 3. **Accessibility**: Adds semantic actions for VoiceOver/TalkBack.
class GlassActionableCard extends StatefulWidget {
  /// The card or tile child widget to wrap.
  final Widget child;

  /// Optional Key specifically for the internal [Dismissible] widget.
  final Key? dismissibleKey;

  /// Primary tap callback (e.g. opening detail view).
  final VoidCallback? onTap;

  /// Callback executed for Edit action (triggered via swipe right or context menu).
  final VoidCallback? onEdit;

  /// Callback executed for Delete action (triggered via swipe left or context menu).
  final VoidCallback? onDelete;

  /// Optional custom confirmation function before executing delete action.
  /// If omitted, defaults to [showDeleteConfirmation] dialog.
  final Future<bool?> Function()? confirmDelete;

  /// Custom edit label (defaults to [AppLocalizations.edit]).
  final String? editLabel;

  /// Custom delete label (defaults to [AppLocalizations.delete]).
  final String? deleteLabel;

  /// Additional custom actions to include in the context menu.
  final List<GlassContextAction> additionalActions;

  /// Whether swipe-to-edit and swipe-to-delete are enabled. Defaults to `true`.
  final bool enableSwipe;

  /// Whether long-press context menu is enabled. Defaults to `true`.
  final bool enableContextMenu;

  /// Optional custom corner radius. Defaults to [DesignConstants.borderRadiusL].
  final BorderRadius? borderRadius;

  /// Optional custom margin for swipe background. Defaults to 6.0 vertical for [SummaryCard] and zero otherwise.
  final EdgeInsetsGeometry? margin;

  const GlassActionableCard({
    super.key,
    required this.child,
    this.dismissibleKey,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.confirmDelete,
    this.editLabel,
    this.deleteLabel,
    this.additionalActions = const <GlassContextAction>[],
    this.enableSwipe = true,
    this.enableContextMenu = true,
    this.borderRadius,
    this.margin,
  });

  @override
  State<GlassActionableCard> createState() => _GlassActionableCardState();
}

class _GlassActionableCardState extends State<GlassActionableCard> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _triggerContextMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final actions = <GlassContextAction>[];

    // Edit Action
    if (widget.onEdit != null) {
      actions.add(
        GlassContextAction(
          label: widget.editLabel ?? l10n?.edit ?? 'Bearbeiten',
          icon: LucideIcons.pencil,
          onTap: widget.onEdit!,
        ),
      );
    }

    // Additional Actions
    actions.addAll(widget.additionalActions);

    // Delete Action
    if (widget.onDelete != null) {
      actions.add(
        GlassContextAction(
          label: widget.deleteLabel ?? l10n?.delete ?? 'Löschen',
          icon: LucideIcons.trash,
          isDestructive: true,
          onTap: () async {
            final confirmed = widget.confirmDelete != null
                ? await widget.confirmDelete!()
                : await showDeleteConfirmation(context);

            if (confirmed == true && widget.onDelete != null) {
              widget.onDelete!();
            }
          },
        ),
      );
    }

    if (actions.isEmpty) return;

    // Determine target global rect
    final renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final targetRect = offset & size;

    await showGlassContextMenu(
      context: context,
      targetRect: targetRect,
      targetWidget: widget.child,
      actions: actions,
      borderRadius: widget.borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveKey =
        widget.dismissibleKey ?? widget.key ?? ValueKey(_cardKey.hashCode);

    Widget content = KeyedSubtree(
      key: _cardKey,
      child: widget.child,
    );

    // Add GestureDetector for tap and long-press
    final bool hasActions = widget.onEdit != null ||
        widget.onDelete != null ||
        widget.additionalActions.isNotEmpty;
    if (widget.onTap != null || (widget.enableContextMenu && hasActions)) {
      content = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.enableContextMenu && hasActions
            ? () => _triggerContextMenu(context)
            : null,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    // Add Dismissible for swipe actions if enabled
    if (widget.enableSwipe &&
        (widget.onEdit != null || widget.onDelete != null)) {
      final effectiveRadius = widget.borderRadius ??
          BorderRadius.circular(DesignConstants.borderRadiusL);

      final bool isOpaqueCard = widget.child is SummaryCard;

      final EdgeInsetsGeometry effectiveMargin = widget.margin ??
          (isOpaqueCard
              ? const EdgeInsets.symmetric(vertical: 6.0)
              : EdgeInsets.zero);

      Future<bool?> handleConfirmDismiss(DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (widget.onEdit != null) {
            widget.onEdit!();
          }
          return false;
        } else {
          if (widget.confirmDelete != null) {
            return await widget.confirmDelete!();
          } else {
            return await showDeleteConfirmation(context);
          }
        }
      }

      void handleOnDismissed(DismissDirection direction) {
        if (direction == DismissDirection.endToStart &&
            widget.onDelete != null) {
          widget.onDelete!();
        }
      }

      // ClipRect prevents the card's BoxShadow from bleeding over the swipe
      // background and creating a dark-crescent artifact at the inner edge.
      final Widget clippedContent = ClipRect(child: content);

      content = Dismissible(
        key: effectiveKey,
        direction: (widget.onEdit != null && widget.onDelete != null)
            ? DismissDirection.horizontal
            : (widget.onEdit != null
                ? DismissDirection.startToEnd
                : DismissDirection.endToStart),
        background: widget.onEdit != null
            ? SwipeActionBackground(
                color: Colors.blueAccent,
                icon: LucideIcons.pencil,
                alignment: Alignment.centerLeft,
                borderRadius: effectiveRadius,
                margin: effectiveMargin,
              )
            : Container(),
        secondaryBackground: widget.onDelete != null
            ? SwipeActionBackground(
                color: DesignConstants.brandRedColor,
                icon: LucideIcons.trash,
                alignment: Alignment.centerRight,
                borderRadius: effectiveRadius,
                margin: effectiveMargin,
              )
            : Container(),
        confirmDismiss: handleConfirmDismiss,
        onDismissed: handleOnDismissed,
        child: clippedContent,
      );
    }

    // Wrap with Accessibility Semantics
    final customSemanticsActions = <CustomSemanticsAction, VoidCallback>{};
    if (widget.onEdit != null) {
      customSemanticsActions[CustomSemanticsAction(
              label: widget.editLabel ?? l10n?.edit ?? 'Bearbeiten')] =
          widget.onEdit!;
    }
    if (widget.onDelete != null) {
      customSemanticsActions[CustomSemanticsAction(
          label: widget.deleteLabel ?? l10n?.delete ?? 'Löschen')] = () async {
        final confirmed = widget.confirmDelete != null
            ? await widget.confirmDelete!()
            : await showDeleteConfirmation(context);
        if (confirmed == true && widget.onDelete != null) {
          widget.onDelete!();
        }
      };
    }

    if (customSemanticsActions.isNotEmpty) {
      content = Semantics(
        customSemanticsActions: customSemanticsActions,
        child: content,
      );
    }

    return content;
  }
}
