import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../ai_assistant/data/ai_overlay_demo_settings.dart';
import '../../../services/theme_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../ai_assistant/presentation/widgets/draggable_ai_cloud.dart';

/// Scrollable sample content for exploring a future AI assistant surface.
///
/// The cards provide static visual samples; the cloud controls are local demo
/// state and never read or modify app data.
class AiOverlayDemoScreen extends StatefulWidget {
  const AiOverlayDemoScreen({super.key});

  @override
  State<AiOverlayDemoScreen> createState() => _AiOverlayDemoScreenState();
}

class _AiOverlayDemoScreenState extends State<AiOverlayDemoScreen> {
  bool _cloudExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final contentTop = MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        DesignConstants.spacingS;

    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: 'AI Overlay',
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.spacingL,
          contentTop,
          DesignConstants.spacingL,
          MediaQuery.paddingOf(context).bottom + 176,
        ),
        children: [
          ValueListenableBuilder<AiOverlayDemoConfiguration>(
            valueListenable: AiOverlayDemoSettings.configuration,
            builder: (context, settings, _) =>
                _buildCloudSettingsCard(theme, l10n, settings),
          ),
          AppSectionHeader(
            title: l10n.aiOverlayDemoColorSectionTitle,
            isFirst: true,
          ),
          _buildColorCard(
              color: Colors.white, semanticLabel: l10n.aiOverlayDemoColorWhite),
          const SizedBox(height: DesignConstants.spacingM),
          _buildColorCard(
              color: Colors.black, semanticLabel: l10n.aiOverlayDemoColorBlack),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: theme.brightness,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        // Prevent the route underneath the overlay from claiming the iOS
        // edge-swipe while the cloud is open. The cloud keeps its own gestures.
        canPop: !_cloudExpanded,
        child: Stack(
          fit: StackFit.expand,
          children: [
            scaffold,
            ValueListenableBuilder<AiOverlayDemoConfiguration>(
              valueListenable: AiOverlayDemoSettings.configuration,
              builder: (context, settings, _) => (settings.enabled &&
                      context.watch<ThemeService>().isAiEnabled)
                  ? const SizedBox.shrink()
                  : Positioned.fill(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                      child: Material(
                        type: MaterialType.transparency,
                        child: DraggableAiCloud(
                          navigator: Navigator.of(context),
                          semanticLabel: 'AI Overlay',
                          semanticHint: l10n.aiOverlayDemoAssistantHint,
                          liveliness: settings.liveliness,
                          showResizeHandles: settings.showResizeHandles,
                          openDirectlyFullscreen:
                              settings.openDirectlyFullscreen,
                          useLiveAi: true,
                          onExpandedChanged: (value) =>
                              setState(() => _cloudExpanded = value),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard({
    required Color color,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: SummaryCard(
        backgroundColor: color,
        padding: EdgeInsets.zero,
        disableShadow: true,
        child: const SizedBox(height: 128),
      ),
    );
  }

  Widget _buildCloudSettingsCard(
    ThemeData theme,
    AppLocalizations l10n,
    AiOverlayDemoConfiguration settings,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingL,
        vertical: DesignConstants.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 18),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: Text(
                  l10n.aiOverlayDemoLivelinessTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('${(settings.liveliness * 100).round()}%'),
            ],
          ),
          Slider(
            value: settings.liveliness,
            onChanged: (value) =>
                unawaited(AiOverlayDemoSettings.update(liveliness: value)),
          ),
          Text(
            l10n.aiOverlayDemoLivelinessDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.aiOverlayDemoSafeSpaceTitle),
            subtitle: Text(l10n.aiOverlayDemoSafeSpaceSubtitle),
            value: settings.showResizeHandles,
            onChanged: (value) => unawaited(
              AiOverlayDemoSettings.update(showResizeHandles: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.aiOverlayDemoFullscreenTitle),
            subtitle: Text(l10n.aiOverlayDemoFullscreenSubtitle),
            value: settings.openDirectlyFullscreen,
            onChanged: (value) => unawaited(
              AiOverlayDemoSettings.update(openDirectlyFullscreen: value),
            ),
          ),
        ],
      ),
    );
  }
}
