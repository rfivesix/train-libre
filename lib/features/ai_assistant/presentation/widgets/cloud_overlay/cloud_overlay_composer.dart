import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import 'cloud_voice_controller.dart';
import 'cloud_voice_waveform.dart';
import 'header_glass_button.dart';
import '../../../../../widgets/common/platform_adaptive_dropdown.dart';

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
  final List<File> imageAttachments;
  final void Function(String source, Rect? sourceRect)? onAddImages;
  final GlobalKey? addImagesButtonKey;
  final ValueChanged<File>? onRemoveImage;

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
    this.imageAttachments = const [],
    this.onAddImages,
    this.addImagesButtonKey,
    this.onRemoveImage,
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
        final expandedInput =
            hasText || chatFocusNode.hasFocus || imageAttachments.isNotEmpty;

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
          final hasDraft =
              inputValue.text.trim().isNotEmpty || imageAttachments.isNotEmpty;
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

        Widget addImagesButton() {
          final l10n = AppLocalizations.of(context)!;
          return PlatformAdaptivePopupMenu<String>(
            hideGlobalAiCloud: false,
            menuWidth: 250,
            icon: HeaderGlassButton(
              key: addImagesButtonKey,
              icon: Icons.add,
              tooltip: l10n.aiChatAddImage,
              isDarkSurface: !surfaceIsLight,
              foregroundColor: contrastColor,
              backgroundColor: controlFillColor,
              useStaticGlass: isGlassTransitioning,
            ),
            items: [
              PlatformAdaptivePopupMenuItem<String>(
                value: 'camera',
                label: l10n.aiChatTakePhoto,
                icon: Icons.camera_alt_outlined,
              ),
              PlatformAdaptivePopupMenuItem<String>(
                value: 'photos',
                label: l10n.aiChatChoosePhoto,
                icon: Icons.photo_library_outlined,
              ),
            ],
            onSelected: (value) {
              final renderObject =
                  addImagesButtonKey?.currentContext?.findRenderObject();
              final box = renderObject is RenderBox ? renderObject : null;
              final sourceRect = box != null && box.hasSize
                  ? box.localToGlobal(Offset.zero) & box.size
                  : null;
              onAddImages?.call(value, sourceRect);
            },
          );
        }

        Widget buildDraftAttachment(
          BuildContext context,
          File image,
          int index,
          double size,
        ) =>
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox.square(
                    dimension: size,
                    child: image.existsSync()
                        ? Image.file(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Colors.black12,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          )
                        : const ColoredBox(
                            color: Colors.black12,
                            child: Icon(Icons.image_outlined),
                          ),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Semantics(
                    button: true,
                    label: AppLocalizations.of(context)!.aiChatRemoveImage,
                    child: HeaderGlassButton(
                      key: ValueKey('remove-chat-image-$index'),
                      icon: Icons.close,
                      iconSize: 12,
                      dimension: 26,
                      tooltip: AppLocalizations.of(context)!.aiChatRemoveImage,
                      isDarkSurface: !surfaceIsLight,
                      foregroundColor: contrastColor,
                      backgroundColor: controlFillColor,
                      useStaticGlass: isGlassTransitioning,
                      onPressed: () => onRemoveImage?.call(image),
                    ),
                  ),
                ),
              ],
            );

        Widget attachmentPreview() {
          const thumbnailSize = 80.0;
          final rows = <Widget>[];
          for (var start = 0; start < imageAttachments.length; start += 2) {
            final end = (start + 2).clamp(0, imageAttachments.length);
            rows.add(
              Padding(
                padding: EdgeInsets.only(top: start == 0 ? 0 : 8),
                child: Row(
                  children: [
                    for (var index = start; index < end; index++) ...[
                      if (index > start) const SizedBox(width: 8),
                      buildDraftAttachment(
                        context,
                        imageAttachments[index],
                        index,
                        thumbnailSize,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          );
        }

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
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
                            if (imageAttachments.isNotEmpty)
                              attachmentPreview(),
                            Row(
                              children: [
                                if (onAddImages != null && !expandedInput) ...[
                                  addImagesButton(),
                                  const SizedBox(width: 6),
                                ],
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
                                  if (onAddImages != null) ...[
                                    addImagesButton(),
                                    const SizedBox(width: 6),
                                  ],
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
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
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              surface,
            ],
          ),
        ),
      ),
    );
  }
}
