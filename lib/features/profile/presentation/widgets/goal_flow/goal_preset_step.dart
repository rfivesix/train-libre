import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/app_segmented_control.dart';
import '../../../domain/models/goal_model.dart';
import 'goal_flow_state.dart';

class GoalPresetStep extends StatelessWidget {
  final GoalFlowState state;
  final EdgeInsetsGeometry padding;

  const GoalPresetStep({
    super.key,
    required this.state,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignConstants.spacingL,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStep1Question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStep1Description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
        _buildPresetTile(
          context,
          preset: GoalPreset.loseWeight,
          title: l10n.goalPresetLoseWeight,
          subtitle: l10n.goalPresetLoseWeightDescription,
          icon: LucideIcons.trending_down,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.gainWeight,
          title: l10n.goalPresetGainWeight,
          subtitle: l10n.goalPresetGainWeightDescription,
          icon: LucideIcons.trending_up,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.maintainWeight,
          title: l10n.goalPresetMaintainWeight,
          subtitle: l10n.goalPresetMaintainWeightDescription,
          icon: LucideIcons.scale,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.recomposition,
          title: l10n.goalPresetRecomposition,
          subtitle: l10n.goalPresetRecompositionDescription,
          icon: LucideIcons.refresh_cw,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.custom,
          title: l10n.goalPresetCustom,
          subtitle: l10n.goalPresetCustomDescription,
          icon: LucideIcons.target,
        ),
        if (state.preset == GoalPreset.custom) ...[
          const SizedBox(height: DesignConstants.spacingM),
          TextField(
            controller: state.customTitleController,
            decoration: InputDecoration(
              labelText: l10n.goalCustomTitleLabel,
              hintText: l10n.goalCustomTitleHint,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.goalCustomDirectionPrompt,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppSegmentedControl<String>(
            children: {
              'lose': l10n.goalPresetLoseWeight,
              'gain': l10n.goalPresetGainWeight,
              'maintain': l10n.goalPresetMaintainWeight,
            },
            groupValue: state.customDirection,
            onValueChanged: (val) {
              state.updateCustomDirection(val);
            },
          ),
        ],
      ],
    ),);
  }

  Widget _buildPresetTile(
    BuildContext context, {
    required GoalPreset preset,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = state.preset == preset;
    final animationDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 160);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          key: Key('goal_preset_${preset.name}'),
          onTap: () {
            state.updatePreset(preset);
          },
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
          child: AnimatedContainer(
            duration: animationDuration,
            padding: const EdgeInsets.all(DesignConstants.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.11)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.35),
              ),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                AnimatedContainer(
                  duration: animationDuration,
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
