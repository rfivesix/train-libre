import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../ai_assistant/data/ai_overlay_demo_settings.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/platform_adaptive_switch_list_tile.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../data/whats_new_service.dart';
import '../data/ai_assistant_update_intro_service.dart';
import '../domain/whats_new_release.dart';

/// Shows the "What's New" bottom sheet for [releases] (newest first).
///
/// Does nothing when [releases] is empty. [markSeen] should stay `true` for the
/// automatic post-update presentation and `false` when the user opened the
/// history themselves from the About screen.
Future<void> showWhatsNewSheet(
  BuildContext context,
  List<WhatsNewRelease> releases, {
  bool markSeen = true,
}) async {
  if (releases.isEmpty) return;

  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;

  unawaited(
    TelemetryService.instance.trackScreenView(screenName: ScreenName.whatsNew),
  );
  if (markSeen) {
    unawaited(
      TelemetryService.instance.trackFeatureUsed(
        featureKey: FeatureKey.whatsNewViewed,
        extraProps: {'release_version': releases.first.version},
      ),
    );
  }

  await showGlassBottomMenu<void>(
    context: context,
    title: l10n.whatsNewTitle,
    contentBuilder: (ctx, close) => _WhatsNewContent(
      releases: releases,
      onClose: close,
      showSingleVersionHeader: releases.length == 1,
    ),
  );

  if (markSeen) {
    await WhatsNewService.instance.markSeen();
  }
}

/// Opens the AI chat introduction and marks the startup presentation as seen.
Future<void> showAiAssistantUpdateIntroSheet(
  BuildContext context, {
  bool markSeen = true,
}) async {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;
  unawaited(
    TelemetryService.instance.track(
      'ai_assistant_update_intro_viewed',
      properties: {'release_version': '1.7.0', 'source': 'standalone'},
    ),
  );
  await showGlassBottomMenu<void>(
    context: context,
    title: l10n.aiAssistantUpdateIntroTitle,
    expandToFullHeight: true,
    contentBuilder: (ctx, close) => Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Expanded(child: _AiAssistantUpdateIntro(fillAvailable: true)),
        const SizedBox(height: DesignConstants.spacingM),
        AppButton.primary(
          label: l10n.whatsNewCta,
          semanticsLabel: l10n.whatsNewCta,
          onPressed: close,
        ),
        const SizedBox(height: DesignConstants.spacingS),
      ],
    ),
  );
  if (markSeen) await AiAssistantUpdateIntroService.instance.markSeen();
}

class _WhatsNewContent extends StatelessWidget {
  const _WhatsNewContent({
    required this.releases,
    required this.onClose,
    required this.showSingleVersionHeader,
  });

  final List<WhatsNewRelease> releases;
  final VoidCallback onClose;

  /// A single release gets a compact subtitle instead of a section header, so
  /// the common case after an update does not read like a changelog archive.
  final bool showSingleVersionHeader;

  String _headerFor(BuildContext context, WhatsNewRelease release) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.whatsNewVersionHeader(release.version);
    final date = release.releaseDate;
    if (date == null) return label;
    final formatted = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    return '$label · $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignConstants.spacingS,
          0,
          DesignConstants.spacingS,
          DesignConstants.spacingM,
        ),
        child: Text(
          showSingleVersionHeader
              ? _headerFor(context, releases.first)
              : l10n.whatsNewSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    ];

    for (final release in releases) {
      if (!showSingleVersionHeader) {
        children.add(
          AppSectionHeader(
            title: _headerFor(context, release),
            isFirst: release == releases.first,
          ),
        );
      }
      for (final entry in release.entries) {
        children.add(_WhatsNewEntryTile(entry: entry));
      }
    }

    children.add(const SizedBox(height: DesignConstants.spacingL));
    children.add(
      AppButton.primary(
        label: l10n.whatsNewCta,
        semanticsLabel: l10n.whatsNewCta,
        onPressed: onClose,
      ),
    );
    children.add(const SizedBox(height: DesignConstants.spacingS));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// The floating chat preview and its two opt-in controls for existing users.
class _AiAssistantUpdateIntro extends StatelessWidget {
  const _AiAssistantUpdateIntro({this.fillAvailable = false});

  final bool fillAvailable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fillAvailable)
              Expanded(
                child: _AssistantPreviewChat(
                  question: l10n.aiAssistantUpdateIntroExampleQuestion,
                  answer: l10n.aiAssistantUpdateIntroExampleAnswer,
                  expand: true,
                ),
              )
            else
              _AssistantPreviewChat(
                question: l10n.aiAssistantUpdateIntroExampleQuestion,
                answer: l10n.aiAssistantUpdateIntroExampleAnswer,
              ),
            const SizedBox(height: DesignConstants.spacingS),
            Consumer<ThemeService>(
              builder: (context, settings, _) => PlatformAdaptiveSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.aiAssistantUpdateIntroAiEnabled),
                subtitle: Text(l10n.aiAssistantUpdateIntroAiEnabledHint),
                value: settings.isAiEnabled,
                onChanged: (enabled) {
                  unawaited(settings.setAiEnabled(enabled));
                  if (!enabled) {
                    unawaited(AiOverlayDemoSettings.update(enabled: false));
                  }
                  unawaited(
                    TelemetryService.instance.track(
                      'ai_assistant_update_intro_choice',
                      properties: {'ai_enabled': enabled},
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<AiOverlayDemoConfiguration>(
              valueListenable: AiOverlayDemoSettings.configuration,
              builder: (context, settings, _) {
                final aiEnabled = context.watch<ThemeService>().isAiEnabled;
                return PlatformAdaptiveSwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.aiAssistantUpdateIntroLauncherEnabled),
                  subtitle: Text(
                    l10n.aiAssistantUpdateIntroLauncherEnabledHint,
                  ),
                  value: settings.enabled,
                  onChanged: aiEnabled
                      ? (enabled) {
                          unawaited(
                            AiOverlayDemoSettings.update(enabled: enabled),
                          );
                          unawaited(
                            TelemetryService.instance.track(
                              'ai_assistant_update_intro_choice',
                              properties: {
                                'floating_assistant_enabled': enabled,
                              },
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantPreviewChat extends StatelessWidget {
  const _AssistantPreviewChat({
    required this.question,
    required this.answer,
    this.expand = false,
  });

  final String question;
  final String answer;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cloudColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final cloudTextColor = theme.brightness == Brightness.dark
        ? Colors.black
        : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(
          constraints.maxWidth,
          expand ? constraints.maxHeight * 0.56 : 350,
        );
        final cloudSize = canvas.width * 0.8 < canvas.height * 0.75
            ? canvas.width * 0.8
            : canvas.height * 0.75;
        return Center(
          child: SizedBox(
            width: canvas.width,
            height: canvas.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: AiNeuralCloudOrbWidget(
                    size: cloudSize,
                    canvasSize: canvas,
                    cloudCenter: Offset(canvas.width / 2, canvas.height / 2),
                    frameRect: Rect.fromLTWH(
                      60,
                      canvas.height * 0.18,
                      canvas.width - 120,
                      canvas.height * 0.64,
                    ),
                    frameMorph: 1,
                    baseColor: cloudColor,
                    accentColor: colors.primary,
                    morph: 1,
                    flowSpeed: 0.15,
                    edgeBlurSigma: 1.5,
                    showAmbientGlow: false,
                    showDetachedSatellite: false,
                    enableInteraction: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _AssistantPreviewQuestion(text: question),
                      ),
                      const SizedBox(height: DesignConstants.spacingM),
                      Text(
                        answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cloudTextColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssistantPreviewQuestion extends StatelessWidget {
  const _AssistantPreviewQuestion({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Color.lerp(Colors.black, colors.primary, 0.42)!
        : colors.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: isDark ? Colors.white : colors.onPrimary),
      ),
    );
  }
}

/// One highlight row: icon, headline, description.
///
/// Deliberately not a glass card — the surrounding sheet already pushes a
/// backdrop filter, and one per row would cost a full framebuffer round trip
/// each on a tile-based GPU.
class _WhatsNewEntryTile extends StatelessWidget {
  const _WhatsNewEntryTile({required this.entry});

  final WhatsNewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: DesignConstants.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
            ),
            child: Icon(entry.icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
