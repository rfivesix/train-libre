import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import 'cloud_voice_controller.dart';
import 'cloud_voice_waveform.dart';
import 'header_glass_button.dart';

/// The expandable text input bar and voice dictation surface for the AI cloud overlay.
class CloudOverlayComposer extends StatelessWidget {
  final TextEditingController chatInputController;
  final FocusNode chatFocusNode;
  final ScrollController chatInputScrollController;
  final CloudVoiceController voiceController;
  final bool isGenerating;
  final bool isGlassTransitioning;
  final bool cloudSurfaceDark;
  final bool surfaceIsLight;
  final Color contrastColor;
  final Color composerFillColor;
  final Color controlFillColor;
  final Color sendButtonBackground;
  final Color sendButtonForeground;
  final Color selectionBlue;
  final String? askModelHint;
  final VoidCallback onSendPrompt;
  final VoidCallback onStopGeneration;

  const CloudOverlayComposer({
    super.key,
    required this.chatInputController,
    required this.chatFocusNode,
    required this.chatInputScrollController,
    required this.voiceController,
    required this.isGenerating,
    required this.isGlassTransitioning,
    required this.cloudSurfaceDark,
    required this.surfaceIsLight,
    required this.contrastColor,
    required this.composerFillColor,
    required this.controlFillColor,
    required this.sendButtonBackground,
    required this.sendButtonForeground,
    required this.selectionBlue,
    required this.askModelHint,
    required this.onSendPrompt,
    required this.onStopGeneration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final composerGlassSettings =
        DesignConstants.liquidGlassSettings(cloudSurfaceDark);
    final glassTheme = theme.copyWith(
      brightness: cloudSurfaceDark ? Brightness.dark : Brightness.light,
    );

    final surface = AnimatedBuilder(
      animation: Listenable.merge([
        chatInputController,
        chatFocusNode,
        chatInputScrollController,
        voiceController,
      ]),
      builder: (context, _) {
        final inputValue = chatInputController.value;
        final hasText = inputValue.text.trim().isNotEmpty;
        final inputIsScrolled = chatInputScrollController.hasClients &&
            chatInputScrollController.offset > 0.5;
        final recording = voiceController.isActive;
        final expandedInput = hasText || chatFocusNode.hasFocus;

        Widget voiceButton({bool filled = false}) => HeaderGlassButton(
              icon: recording ? LucideIcons.x : LucideIcons.mic,
              tooltip: recording
                  ? AppLocalizations.of(context)!.cancel
                  : AppLocalizations.of(context)!.voiceTapToRecord,
              isDarkSurface: !surfaceIsLight,
              foregroundColor: filled ? sendButtonForeground : contrastColor,
              backgroundColor: filled ? sendButtonBackground : controlFillColor,
              showBorder: recording || filled,
              useStaticGlass: isGlassTransitioning,
              onPressed: recording
                  ? voiceController.cancel
                  : () => unawaited(voiceController.start(context)),
            );

        Widget sendButton() {
          final hasDraft = inputValue.text.trim().isNotEmpty;
          final isStopAction = isGenerating && !hasDraft;
          return HeaderGlassButton(
            icon: isStopAction ? LucideIcons.square : LucideIcons.arrow_up,
            tooltip: isStopAction ? 'Stopp' : 'Senden',
            isDarkSurface: !surfaceIsLight,
            backgroundColor: sendButtonBackground,
            foregroundColor: sendButtonForeground,
            useStaticGlass: isGlassTransitioning,
            onPressed: isStopAction ? onStopGeneration : onSendPrompt,
          );
        }

        Widget messageField({required bool compact}) => Scrollbar(
              key: const ValueKey('ai-composer-scrollbar'),
              controller: chatInputScrollController,
              thumbVisibility: !compact,
              thickness: 2,
              radius: const Radius.circular(2),
              child: TextSelectionTheme(
                data: TextSelectionThemeData(
                  cursorColor: selectionBlue,
                  selectionColor: selectionBlue.withValues(alpha: 0.32),
                  selectionHandleColor: selectionBlue,
                ),
                child: TextField(
                  key: const ValueKey('ai-composer-text-field'),
                  controller: chatInputController,
                  scrollController: chatInputScrollController,
                  focusNode: chatFocusNode,
                  keyboardType: TextInputType.text,
                  onTapOutside: (_) => chatFocusNode.unfocus(),
                  onTap: () {
                    if (!voiceController.isActive) {
                      chatFocusNode.requestFocus();
                      unawaited(
                        SystemChannels.textInput.invokeMethod<void>(
                          'TextInput.show',
                        ),
                      );
                    }
                  },
                  textAlign: TextAlign.start,
                  textAlignVertical: compact
                      ? TextAlignVertical.center
                      : TextAlignVertical.top,
                  minLines: 1,
                  maxLines: compact ? 1 : 6,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendPrompt(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contrastColor,
                  ),
                  cursorColor: selectionBlue,
                  decoration: InputDecoration(
                    hintText: askModelHint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: contrastColor.withValues(alpha: 0.52),
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      top: compact ? 0 : (inputIsScrolled ? 0 : 8),
                    ),
                  ),
                ),
              ),
            );

        return TextFieldTapRegion(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  color: composerFillColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: contrastColor.withValues(alpha: 0.14),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(recording ? 6 : 10, 6, 6, 6),
                  child: recording
                      ? Row(
                          children: [
                            voiceButton(),
                            const SizedBox(width: 6),
                            Expanded(
                              child: CloudVoiceRecordingContent(
                                voiceStarting: voiceController.isStarting,
                                voiceStopping: voiceController.isStopping,
                                voiceLevelHistory: voiceController.levelHistory,
                                voiceWaveOffset: voiceController.waveOffset,
                                foregroundColor: contrastColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            HeaderGlassButton(
                              icon: LucideIcons.square,
                              tooltip: AppLocalizations.of(context)!
                                  .voiceTapToFinish,
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: controlFillColor,
                              foregroundColor: contrastColor,
                              useStaticGlass: isGlassTransitioning,
                              onPressed: voiceController.isStopping
                                  ? null
                                  : voiceController.stop,
                            ),
                            const SizedBox(width: 6),
                            HeaderGlassButton(
                              icon: LucideIcons.arrow_up,
                              tooltip: 'Senden',
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: sendButtonBackground,
                              foregroundColor: sendButtonForeground,
                              useStaticGlass: isGlassTransitioning,
                              onPressed: voiceController.isStopping
                                  ? null
                                  : voiceController.send,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 156),
                                    child: messageField(
                                      compact: !expandedInput,
                                    ),
                                  ),
                                ),
                                if (!expandedInput) ...[
                                  const SizedBox(width: 6),
                                  if (isGenerating)
                                    sendButton()
                                  else
                                    voiceButton(filled: true),
                                ],
                              ],
                            ),
                            if (expandedInput)
                              Row(
                                children: [
                                  if (!isGenerating || expandedInput)
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          chatFocusNode.requestFocus();
                                          unawaited(
                                            SystemChannels.textInput
                                                .invokeMethod<void>(
                                              'TextInput.show',
                                            ),
                                          );
                                        },
                                        child: const SizedBox(height: 44),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (!isGenerating) ...[
                                    voiceButton(),
                                    const SizedBox(width: 6),
                                  ],
                                  sendButton(),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: DesignConstants.glassShadow(cloudSurfaceDark),
      ),
      child: Theme(
        data: glassTheme,
        child: GlassAdaptiveScope(
          maxQuality: DesignConstants.defaultGlassQuality,
          minQuality: DesignConstants.minGlassQuality,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: isGlassTransitioning ? 0 : 1,
              end: isGlassTransitioning ? 0 : 1,
            ),
            duration: isGlassTransitioning
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder: (context, visibility, _) => AdaptiveGlass(
              settings: composerGlassSettings.copyWith(
                visibility: visibility,
              ),
              quality: DesignConstants.defaultGlassQuality,
              useOwnLayer: true,
              allowElevation: false,
              shape: const LiquidRoundedSuperellipse(
                borderRadius: 28,
              ),
              child: GlassGlow(
                glowColor: contrastColor.withValues(
                  alpha: 0.12 * visibility,
                ),
                glowRadius: visibility,
                child: surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
