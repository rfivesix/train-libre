import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../../data/assistant_history_repository.dart';
import 'ai_chat_turn.dart';
import 'cloud_overlay_markdown.dart';

/// Formats generation duration into localized seconds.
String formatGenerationDuration(Duration duration) {
  final seconds = duration.inMilliseconds / 1000.0;
  if (seconds < 10) {
    return '${seconds.toStringAsFixed(1).replaceAll('.', ',')} s';
  } else {
    return '${seconds.toStringAsFixed(0)} s';
  }
}

/// Renders a single conversation turn in the AI overlay.
class CloudChatTurnView extends StatelessWidget {
  const CloudChatTurnView({
    super.key,
    required this.turn,
    required this.contrastColor,
    required this.softColor,
    required this.isStreaming,
    required this.showLoadingCloud,
    required this.loadingCloudAnimation,
    required this.isCopied,
    required this.isGenerating,
    required this.useLiveAi,
    required this.onCopyResponse,
    required this.onCopyFullChat,
    required this.onRetryPrompt,
    required this.onShowAccessAudit,
  });

  final AiChatTurn turn;
  final Color contrastColor;
  final Color softColor;
  final bool isStreaming;
  final bool showLoadingCloud;
  final Animation<double> loadingCloudAnimation;
  final bool isCopied;
  final bool isGenerating;
  final bool useLiveAi;
  final VoidCallback onCopyResponse;
  final VoidCallback onCopyFullChat;
  final VoidCallback onRetryPrompt;
  final ValueChanged<AssistantAccessRecord> onShowAccessAudit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompactPrompt = turn.prompt.trim().runes.length <= 2;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final userBubbleColor =
        isDark ? Color.lerp(Colors.black, primary, 0.42)! : primary;
    final userBubbleTextColor =
        isDark ? Colors.white : theme.colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                minWidth: isCompactPrompt ? 56 : 0,
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: userBubbleColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isCompactPrompt
                  ? Center(
                      widthFactor: 1,
                      child: Text(
                        turn.prompt,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: userBubbleTextColor,
                        ),
                      ),
                    )
                  : Text(
                      turn.prompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: userBubbleTextColor,
                      ),
                    ),
            ),
          ),
          if (showLoadingCloud)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: AnimatedBuilder(
                animation: loadingCloudAnimation,
                builder: (context, _) {
                  // 0.0 -> 0.44: nichts -> Kreis (sizeFactor 0 -> 1, morph 0)
                  // 0.44 -> 1.0: Kreis -> Wolke (sizeFactor 1, morph 0 -> 1)
                  // Reverse runs Wolke -> Kreis -> nichts.
                  const split = 0.44;
                  final progress =
                      loadingCloudAnimation.value.clamp(0.0, 1.0);
                  final circleScale = progress <= split
                      ? Curves.easeInOutCubic.transform(
                          (progress / split).clamp(0.0, 1.0),
                        )
                      : 1.0;
                  final cloudMorph = progress <= split
                      ? 0.0
                      : Curves.easeInOutCubic.transform(
                          ((progress - split) / (1.0 - split)).clamp(0.0, 1.0),
                        );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AiNeuralCloudOrbWidget(
                      size: 68,
                      canvasSize: const Size(42, 42),
                      cloudCenter: const Offset(21, 21),
                      sizeFactor: circleScale,
                      morph: 0,
                      instantaneousMorph: cloudMorph,
                      baseColor: contrastColor,
                      showAmbientGlow: false,
                      enableInteraction: false,
                    ),
                  );
                },
              ),
            )
          else if (turn.response.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: CloudOverlayMarkdown(
                rawResponse: turn.response,
                contrastColor: contrastColor,
                softColor: softColor,
                isStreaming: isStreaming,
              ),
            ),
            if (!isStreaming)
              _buildActionBar(theme, context),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, BuildContext context) {
    final subtleColor = contrastColor.withValues(alpha: 0.52);
    final modelLabel = turn.modelName;
    final durationLabel = turn.duration != null
        ? formatGenerationDuration(turn.duration!)
        : null;

    final metaText = [
      if (modelLabel != null && modelLabel.isNotEmpty) modelLabel,
      if (durationLabel != null) durationLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIconButton(
            icon: isCopied ? LucideIcons.check : LucideIcons.copy,
            tooltip: 'Antwort kopieren (Lange drücken: Gesamten Chat kopieren)',
            onTap: onCopyResponse,
            onLongPress: onCopyFullChat,
            foregroundColor: isCopied
                ? (theme.brightness == Brightness.dark
                    ? Colors.greenAccent
                    : Colors.green.shade700)
                : subtleColor,
          ),
          const SizedBox(width: 4),
          _buildActionIconButton(
            icon: LucideIcons.rotate_cw,
            tooltip: 'Erneut versuchen',
            onTap: isGenerating ? null : onRetryPrompt,
            foregroundColor: subtleColor,
          ),
          if (useLiveAi && turn.access != null) ...[
            const SizedBox(width: 4),
            PlatformAdaptivePopupMenu<String>(
              icon: Semantics(
                button: true,
                label: Localizations.localeOf(context).languageCode == 'de'
                    ? 'Weitere Optionen'
                    : 'More options',
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Icon(
                      LucideIcons.ellipsis,
                      size: 18,
                      color: subtleColor,
                    ),
                  ),
                ),
              ),
              menuWidth: 220,
              items: [
                PlatformAdaptivePopupMenuItem(
                  value: 'dataAccess',
                  label: Localizations.localeOf(context).languageCode == 'de'
                      ? 'Datenzugriff'
                      : 'Data access',
                ),
              ],
              onSelected: (_) => onShowAccessAudit(turn.access!),
            ),
          ],
          if (metaText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              metaText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: subtleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    required Color foregroundColor,
  }) {
    return Semantics(
      button: onTap != null,
      label: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
