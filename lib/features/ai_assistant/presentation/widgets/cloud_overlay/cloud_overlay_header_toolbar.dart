import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../widgets/common/platform_adaptive_dropdown.dart';
import 'header_glass_button.dart';

/// Actions available in the assistant overlay header menu.
enum AssistantMenuAction { autoApprove, settings }

/// The expanded top toolbar for the draggable AI cloud overlay.
class CloudOverlayHeaderToolbar extends StatelessWidget {
  const CloudOverlayHeaderToolbar({
    super.key,
    required this.safeRect,
    required this.fullscreenProgress,
    required this.appearanceProgress,
    required this.surfaceColor,
    required this.foregroundColor,
    required this.controlFill,
    required this.isExpanded,
    required this.isFullscreen,
    required this.hasChatTurns,
    required this.activeConversationTitle,
    required this.autoApproveDataRequests,
    required this.useStaticGlass,
    required this.onToggleSidebar,
    required this.onToggleFullscreen,
    required this.onStartNewChat,
    required this.onToggleAutoApprove,
    required this.onOpenSettings,
    required this.onToggleExpanded,
    required this.onHeaderDragStart,
    required this.onHeaderDragUpdate,
    required this.onHeaderDragEnd,
  });

  final Rect safeRect;
  final double fullscreenProgress;
  final double appearanceProgress;
  final Color surfaceColor;
  final Color foregroundColor;
  final Color controlFill;
  final bool isExpanded;
  final bool isFullscreen;
  final bool hasChatTurns;
  final String activeConversationTitle;
  final bool autoApproveDataRequests;
  final bool useStaticGlass;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onStartNewChat;
  final VoidCallback onToggleAutoApprove;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleExpanded;
  final GestureDragStartCallback onHeaderDragStart;
  final GestureDragUpdateCallback onHeaderDragUpdate;
  final GestureDragEndCallback onHeaderDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final surfaceIsLight = surfaceColor.computeLuminance() >= 0.5;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final safeSpaceOutset = 44.0 * (1 - fullscreenProgress);
    final fullscreenInset = 12.0 * fullscreenProgress;
    final expandedToolbarTop = safeRect.top - 62;
    final fullscreenToolbarTop = MediaQuery.paddingOf(context).top + 10;
    final toolbarTop =
        expandedToolbarTop +
        (fullscreenToolbarTop - expandedToolbarTop) * fullscreenProgress;

    return Positioned(
      left: safeRect.left - safeSpaceOutset + fullscreenInset,
      right: viewportWidth - safeRect.right - safeSpaceOutset + fullscreenInset,
      top: toolbarTop,
      height: 52,
      child: IgnorePointer(
        ignoring: !isExpanded,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: HeaderGlassButton(
                icon: isFullscreen
                    ? LucideIcons.panel_left
                    : LucideIcons.maximize_2,
                tooltip: isFullscreen ? 'Seitenleiste' : 'Vollbild',
                isDarkSurface: !surfaceIsLight,
                foregroundColor: foregroundColor,
                backgroundColor: controlFill,
                useStaticGlass: useStaticGlass,
                onPressed: isFullscreen ? onToggleSidebar : onToggleFullscreen,
              ),
            ),
            if (hasChatTurns)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: HeaderGlassButton(
                  icon: LucideIcons.square_pen,
                  tooltip: l10n.aiOverlayNewChat,
                  isDarkSurface: !surfaceIsLight,
                  foregroundColor: foregroundColor,
                  backgroundColor: controlFill,
                  useStaticGlass: useStaticGlass,
                  onPressed: onStartNewChat,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, 0.78, 1],
                  ).createShader(bounds),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: onHeaderDragStart,
                    onVerticalDragUpdate: onHeaderDragUpdate,
                    onVerticalDragEnd: onHeaderDragEnd,
                    child: SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          activeConversationTitle,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: surfaceIsLight ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PlatformAdaptivePopupMenu<AssistantMenuAction>(
                icon: HeaderGlassButton(
                  icon: LucideIcons.ellipsis,
                  tooltip: 'Chat-Menü',
                  isDarkSurface: !surfaceIsLight,
                  foregroundColor: foregroundColor,
                  backgroundColor: controlFill,
                  useStaticGlass: useStaticGlass,
                ),
                menuWidth: 330,
                hideGlobalAiCloud: false,
                items: [
                  PlatformAdaptivePopupMenuItem(
                    value: AssistantMenuAction.autoApprove,
                    label: l10n.aiOverlayAutoApprove,
                    icon: LucideIcons.shield_check,
                    customTrailing: autoApproveDataRequests
                        ? Icon(
                            LucideIcons.check,
                            color: foregroundColor,
                            size: 18,
                          )
                        : null,
                  ),
                  PlatformAdaptivePopupMenuItem(
                    value: AssistantMenuAction.settings,
                    label: l10n.settingsTitle,
                    icon: LucideIcons.settings,
                  ),
                ],
                onSelected: (action) {
                  switch (action) {
                    case AssistantMenuAction.autoApprove:
                      onToggleAutoApprove();
                    case AssistantMenuAction.settings:
                      onOpenSettings();
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8),
              child: HeaderGlassButton(
                icon: LucideIcons.x,
                tooltip: 'Schließen',
                isDarkSurface: !surfaceIsLight,
                foregroundColor: foregroundColor,
                backgroundColor: controlFill,
                useStaticGlass: useStaticGlass,
                onPressed: onToggleExpanded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
