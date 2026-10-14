import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
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
  final _cloudKey = GlobalKey<DraggableAiCloudState>();
  bool _cloudFullscreen = false;
  bool _showCloudResizeHandles = false;
  bool _cloudIsGenerating = false;
  double _cloudLiveliness = 0.10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contentTop = MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        DesignConstants.spacingS;

    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.aiOverlayDemoScreenTitle,
        hidden: _cloudFullscreen,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              DesignConstants.spacingL,
              contentTop,
              DesignConstants.spacingL,
              MediaQuery.paddingOf(context).bottom + 176,
            ),
            children: [
              _buildIntroCard(context, l10n, theme),
              const SizedBox(height: DesignConstants.spacingM),
              _buildCloudSettingsCard(theme),
              AppSectionHeader(
                title: 'Schwarz und Weiß',
                isFirst: true,
              ),
              _buildColorCard(color: Colors.white, semanticLabel: 'Weiß'),
              const SizedBox(height: DesignConstants.spacingM),
              _buildColorCard(color: Colors.black, semanticLabel: 'Schwarz'),
            ],
          ),
          DraggableAiCloud(
            key: _cloudKey,
            semanticLabel: l10n.developerAiOverlayDemoTitle,
            semanticHint: l10n.aiOverlayDemoCloudHint,
            liveliness: _cloudLiveliness,
            showResizeHandles: _showCloudResizeHandles,
            onGenerationChanged: (value) =>
                setState(() => _cloudIsGenerating = value),
            onFullscreenChanged: (value) =>
                setState(() => _cloudFullscreen = value),
          ),
        ],
      ),
    );

    final cloudIsLight = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _cloudFullscreen
          ? SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness:
                  cloudIsLight ? Brightness.light : Brightness.dark,
              statusBarIconBrightness:
                  cloudIsLight ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  cloudIsLight ? Brightness.dark : Brightness.light,
            )
          : const SystemUiOverlayStyle(),
      child: scaffold,
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

  Widget _buildCloudSettingsCard(ThemeData theme) {
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
                  'Wolken-Lebhaftigkeit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('${(_cloudLiveliness * 100).round()}%'),
            ],
          ),
          Slider(
            value: _cloudLiveliness,
            onChanged: (value) => setState(() => _cloudLiveliness = value),
          ),
          Text(
            'Steuert die Bewegung der erweiterten KI-Wolke.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Safe-Space-Punkte anzeigen'),
            subtitle: const Text('Ecken zum Verändern des Bereichs einblenden'),
            value: _showCloudResizeHandles,
            onChanged: (value) =>
                setState(() => _showCloudResizeHandles = value),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _cloudIsGenerating
                  ? _cloudKey.currentState?.finishDemoGeneration
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Demo-Antwort abschließen'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    DesignConstants.borderRadiusM,
                  ),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiOverlayDemoIntroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingXS),
                    Text(
                      l10n.aiOverlayDemoIntroBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingM),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusS,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingM,
                vertical: DesignConstants.spacingS,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: DesignConstants.iconSizeS,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: Text(
                      l10n.aiOverlayDemoPreviewNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
