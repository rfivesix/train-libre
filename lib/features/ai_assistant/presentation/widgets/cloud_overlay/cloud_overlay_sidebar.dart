import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../../util/design_constants.dart';
import '../../../data/assistant_history_repository.dart';

/// The conversation history drawer for the AI overlay.
class CloudOverlaySidebar extends StatelessWidget {
  const CloudOverlaySidebar({
    super.key,
    required this.viewportWidth,
    required this.sidebarProgress,
    required this.sidebarWidth,
    required this.surfaceColor,
    required this.foregroundColor,
    required this.controlFill,
    required this.appearanceProgress,
    required this.useLiveAi,
    required this.conversations,
    required this.selectedIndex,
    required this.onSelectConversation,
    required this.onToggleSidebar,
  });

  final double viewportWidth;
  final double sidebarProgress;
  final double sidebarWidth;
  final Color surfaceColor;
  final Color foregroundColor;
  final Color controlFill;
  final double appearanceProgress;
  final bool useLiveAi;
  final List<AssistantConversation> conversations;
  final int selectedIndex;
  final ValueChanged<int> onSelectConversation;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceIsLight = surfaceColor.computeLuminance() >= 0.5;

    return Positioned(
      // Keep the drawer's trailing edge attached to the chat pane while the
      // user drags. At progress 0 it is fully offscreen; at 1 it is settled
      // against the translated chat surface.
      left: -sidebarWidth * (1 - sidebarProgress),
      top: 0,
      bottom: 0,
      width: sidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            right: BorderSide(
              color: foregroundColor.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chats',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: foregroundColor.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        MediaQuery.paddingOf(context).bottom + 84,
                      ),
                      itemCount: useLiveAi ? conversations.length : 16,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final selected = index == selectedIndex;
                        return Material(
                          color: selected
                              ? foregroundColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onSelectConversation(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      useLiveAi
                                          ? conversations[index].title
                                          : 'Example ${index + 1}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: foregroundColor,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 12,
                      bottom: MediaQuery.paddingOf(context).bottom + 12,
                      child: _buildSidebarChatButton(
                        theme: theme,
                        isDark: !surfaceIsLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarChatButton({
    required ThemeData theme,
    required bool isDark,
  }) {
    final glassTheme = theme.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    const radius = 24.0;
    final settings = DesignConstants.liquidGlassSettings(isDark);
    final button = Container(
      height: 48,
      decoration: BoxDecoration(
        color: controlFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(LucideIcons.square_pen, size: 19, color: foregroundColor),
          const SizedBox(width: 12),
          Text(
            'Chat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: DesignConstants.glassShadow(isDark),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleSidebar,
          child: Theme(
            data: glassTheme,
            child: GlassAdaptiveScope(
              maxQuality: DesignConstants.defaultGlassQuality,
              minQuality: DesignConstants.minGlassQuality,
              child: AdaptiveGlass(
                settings: settings,
                quality: DesignConstants.defaultGlassQuality,
                useOwnLayer: true,
                allowElevation: false,
                shape: const LiquidRoundedSuperellipse(borderRadius: radius),
                child: GlassGlow(
                  glowColor: Colors.white.withValues(
                    alpha: isDark ? 0.24 : 0.18,
                  ),
                  glowRadius: 1,
                  child: button,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
