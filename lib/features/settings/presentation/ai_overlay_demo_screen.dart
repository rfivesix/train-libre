import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_info_row.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/glass_progress_bar.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';

/// Scrollable sample content for exploring a future AI assistant surface.
///
/// All values are static examples. The approval controls only change their
/// local preview state and never read or modify app data.
class AiOverlayDemoScreen extends StatefulWidget {
  const AiOverlayDemoScreen({super.key});

  @override
  State<AiOverlayDemoScreen> createState() => _AiOverlayDemoScreenState();
}

class _AiOverlayDemoScreenState extends State<AiOverlayDemoScreen> {
  bool? _accessApproved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contentTop = MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        DesignConstants.spacingS;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiOverlayDemoScreenTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.spacingL,
          contentTop,
          DesignConstants.spacingL,
          DesignConstants.spacingXXL,
        ),
        children: [
          _buildIntroCard(context, l10n, theme),
          const SizedBox(height: DesignConstants.spacingM),
          AppSectionHeader(
            title: l10n.aiOverlayDemoTodaySection,
            isFirst: true,
          ),
          _buildWorkoutCard(context, l10n),
          AppSectionHeader(title: l10n.aiOverlayDemoNutritionSection),
          _buildNutritionCard(context, l10n, theme),
          AppSectionHeader(title: l10n.aiOverlayDemoActivitySection),
          _buildActivityCard(context, l10n, theme),
          AppSectionHeader(title: l10n.aiOverlayDemoAssistantSection),
          _buildAssistantPreviewCard(context, l10n, theme),
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

  Widget _buildWorkoutCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return SummaryCard(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(
            padding: EdgeInsets.zero,
            title: l10n.aiOverlayDemoWorkoutTitle,
            subtitle: l10n.aiOverlayDemoWorkoutSubtitle,
            leading: Icon(
              LucideIcons.dumbbell,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.aiOverlayDemoWorkoutMeta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _ExampleExerciseRow(
            name: l10n.aiOverlayDemoExerciseOne,
            details: '3 × 8',
          ),
          const Divider(height: DesignConstants.spacingXL),
          _ExampleExerciseRow(
            name: l10n.aiOverlayDemoExerciseTwo,
            details: '3 × 10',
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        children: [
          GlassProgressBar(
            label: l10n.calories,
            unit: 'kcal',
            value: 1620,
            target: 2100,
            color: theme.colorScheme.primary,
            height: 58,
            disableShadow: true,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: _MacroExample(
                  label: l10n.protein,
                  value: '112 g',
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _MacroExample(
                  label: l10n.carbs,
                  value: '165 g',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              Expanded(
                child: _MacroExample(
                  label: l10n.fat,
                  value: '48 g',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingL,
        vertical: DesignConstants.spacingS,
      ),
      child: Column(
        children: [
          AppInfoRow(
            title: l10n.steps,
            subtitle: l10n.aiOverlayDemoStepsValue,
            leading: Icon(
              LucideIcons.footprints,
              color: theme.colorScheme.primary,
            ),
          ),
          const Divider(height: 1),
          AppInfoRow(
            title: l10n.water,
            subtitle: l10n.aiOverlayDemoWaterValue,
            leading: Icon(
              LucideIcons.droplets,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantPreviewCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignConstants.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
            ),
            child: Text(
              l10n.aiOverlayDemoAssistantMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.aiOverlayDemoRequestLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          _PermissionScopeRow(
            icon: LucideIcons.calendar_days,
            label: l10n.aiOverlayDemoScope,
          ),
          const SizedBox(height: DesignConstants.spacingXS),
          _PermissionScopeRow(
            icon: LucideIcons.target,
            label: l10n.aiOverlayDemoPurpose,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Wrap(
            spacing: DesignConstants.spacingS,
            runSpacing: DesignConstants.spacingS,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _accessApproved = false),
                icon: const Icon(LucideIcons.x, size: 18),
                label: Text(l10n.aiOverlayDemoDeny),
              ),
              FilledButton.icon(
                onPressed: () => setState(() => _accessApproved = true),
                icon: const Icon(LucideIcons.check, size: 18),
                label: Text(l10n.aiOverlayDemoAllowOnce),
              ),
            ],
          ),
          if (_accessApproved != null) ...[
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              _accessApproved!
                  ? l10n.aiOverlayDemoApprovedFeedback
                  : l10n.aiOverlayDemoDeniedFeedback,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleExerciseRow extends StatelessWidget {
  final String name;
  final String details;

  const _ExampleExerciseRow({required this.name, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
        Text(
          details,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MacroExample extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroExample({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PermissionScopeRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PermissionScopeRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: DesignConstants.iconSizeS,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
