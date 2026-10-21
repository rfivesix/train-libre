import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../data/assistant_history_repository.dart';
import 'ai_chat_turn.dart';
import 'cloud_chat_turn_view.dart';
import 'cloud_overlay_permission_card.dart';

/// Renders the scrollable list of chat turns with gradient edge fading and permission card.
class CloudChatTurnListView extends StatelessWidget {
  static const permissionCardKey = ValueKey<String>('ai-overlay-permission-card');

  final ScrollController scrollController;
  final List<AiChatTurn> chatTurns;
  final bool permissionPending;
  final bool? permissionApproved;
  final AssistantAccessRecord? pendingAccess;
  final bool isGenerating;
  final bool isLoadingCloudVisible;
  final Animation<double> loadingCloudAnimation;
  final AiChatTurn? copiedTurn;
  final bool useLiveAi;
  final ThemeData theme;
  final Color contrastColor;
  final Color surfaceColor;
  final Color softColor;
  final double chatTop;
  final double topFadeStart;
  final double topFadeEnd;
  final double topFadeHoldStop;
  final double chatBottom;
  final double bottomFadeHeight;
  final double fullscreenProgress;
  final ValueChanged<bool> onResolvePermission;
  final ValueChanged<AiChatTurn> onCopyResponse;
  final VoidCallback onCopyFullChat;
  final ValueChanged<AiChatTurn> onRetryPrompt;
  final ValueChanged<AssistantAccessRecord> onShowAccessAudit;
  final VoidCallback onIncrementUserScrollRevision;
  final VoidCallback onPermissionCardSizeEnd;

  const CloudChatTurnListView({
    super.key,
    required this.scrollController,
    required this.chatTurns,
    required this.permissionPending,
    required this.permissionApproved,
    required this.pendingAccess,
    required this.isGenerating,
    required this.isLoadingCloudVisible,
    required this.loadingCloudAnimation,
    required this.copiedTurn,
    required this.useLiveAi,
    required this.theme,
    required this.contrastColor,
    required this.surfaceColor,
    required this.softColor,
    required this.chatTop,
    required this.topFadeStart,
    required this.topFadeEnd,
    required this.topFadeHoldStop,
    required this.chatBottom,
    required this.bottomFadeHeight,
    required this.fullscreenProgress,
    required this.onResolvePermission,
    required this.onCopyResponse,
    required this.onCopyFullChat,
    required this.onRetryPrompt,
    required this.onShowAccessAudit,
    required this.onIncrementUserScrollRevision,
    required this.onPermissionCardSizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final topFadeEndStop =
            ((topFadeEnd - topFadeStart) / bounds.height).clamp(0.0, 1.0).toDouble();
        final topFadeOpaqueStartStop =
            (topFadeEndStop * topFadeHoldStop).clamp(0.0, topFadeEndStop).toDouble();
        final bottomFadeStartStop =
            ((chatBottom - bottomFadeHeight - topFadeStart) / bounds.height)
                .clamp(topFadeEndStop, 1.0)
                .toDouble();
        if (fullscreenProgress >= 0.999) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Colors.transparent,
              Colors.transparent,
              Colors.white,
              Colors.white,
            ],
            stops: [
              0,
              topFadeOpaqueStartStop,
              topFadeEndStop,
              1,
            ],
          ).createShader(bounds);
        }
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [
            0,
            topFadeOpaqueStartStop,
            topFadeEndStop,
            bottomFadeStartStop,
            1,
          ],
        ).createShader(bounds);
      },
      child: chatTurns.isEmpty
          ? const SizedBox.shrink()
          : NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction != ScrollDirection.idle) {
                  onIncrementUserScrollRevision();
                }
                return false;
              },
              child: ListView.builder(
                key: const PageStorageKey<String>('ai-overlay-chat-history'),
                controller: scrollController,
                findChildIndexCallback: (key) {
                  if (key == permissionCardKey) {
                    return chatTurns.length + 1;
                  }
                  if (key is ValueKey<AiChatTurn>) {
                    final turnIndex = chatTurns.indexOf(key.value);
                    return turnIndex < 0 ? null : turnIndex + 1;
                  }
                  return null;
                },
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: chatTurns.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return SizedBox(
                      height: math.max(0.0, chatTop - topFadeStart + 16),
                    );
                  }
                  if (index == chatTurns.length + 1) {
                    return KeyedSubtree(
                      key: permissionCardKey,
                      child: CloudOverlayPermissionCard(
                        theme: theme,
                        contrastColor: contrastColor,
                        surfaceColor: surfaceColor,
                        isVisible: (permissionPending || permissionApproved != null),
                        pendingAccess: pendingAccess,
                        permissionPending: permissionPending,
                        permissionApproved: permissionApproved,
                        useLiveAi: useLiveAi,
                        onResolvePermission: onResolvePermission,
                        onAnimatedSizeEnd: onPermissionCardSizeEnd,
                      ),
                    );
                  }
                  final turn = chatTurns[index - 1];
                  final isLastTurn = index == chatTurns.length;
                  return KeyedSubtree(
                    key: ValueKey<AiChatTurn>(turn),
                    child: CloudChatTurnView(
                      turn: turn,
                      contrastColor: contrastColor,
                      softColor: softColor,
                      isStreaming: isGenerating && isLastTurn,
                      showLoadingCloud: isLastTurn &&
                          isLoadingCloudVisible &&
                          turn.response.isEmpty,
                      loadingCloudAnimation: loadingCloudAnimation,
                      isCopied: copiedTurn == turn,
                      isGenerating: isGenerating,
                      useLiveAi: useLiveAi,
                      onCopyResponse: () => onCopyResponse(turn),
                      onCopyFullChat: onCopyFullChat,
                      onRetryPrompt: () => onRetryPrompt(turn),
                      onShowAccessAudit: onShowAccessAudit,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
