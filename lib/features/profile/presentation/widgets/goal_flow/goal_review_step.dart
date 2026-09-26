import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/unit_service.dart';
import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/platform_adaptive_switch_list_tile.dart';
import '../../../../../widgets/common/summary_card.dart';
import 'goal_flow_state.dart';

class GoalReviewStep extends StatelessWidget {
  final GoalFlowState state;
  final EdgeInsetsGeometry padding;

  const GoalReviewStep({
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
    final unitService = context.watch<UnitService>();
    final unit = unitService.unitString(UnitDimension.weight);
    final baseline = state.getBaselineKg(unitService);
    final target = state.getTargetKg(unitService);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final isMaintain = state.isMaintain;

    String formatWeight(double? value) => value == null
        ? '--'
        : '${unitService.convertDisplayValue(value, UnitDimension.weight).toStringAsFixed(1)} $unit';

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStep7Question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStep7Description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
        SummaryCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPreviewMetric(
                      context,
                      l10n.goalBaselineHeader,
                      formatWeight(baseline),
                    ),
                  ),
                  Text(
                    '→',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: _buildPreviewMetric(
                      context,
                      l10n.goalTargetHeader,
                      isMaintain
                          ? '${formatWeight(baseline)} (± 1.0 $unit)'
                          : formatWeight(target),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const Divider(height: DesignConstants.spacingXL),
              _buildReviewRow(
                context,
                label: l10n.goalWeeklyRateLabel,
                value: isMaintain
                    ? '0.00 $unit / ${l10n.weekShort} (${l10n.goalPresetMaintainWeight})'
                    : '${state.weeklyRateKg.toStringAsFixed(2)} $unit / ${l10n.weekShort}',
              ),
              const SizedBox(height: DesignConstants.spacingM),
              _buildReviewRow(
                context,
                label: l10n.goalTargetDateLabel,
                value: state.targetDate == null
                    ? l10n.goalNoDeadlineOption
                    : dateFormat.format(state.targetDate!),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        SummaryCard(
          margin: EdgeInsets.zero,
          child: PlatformAdaptiveSwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.goalDriverSettingLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              l10n.goalDriverSettingDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            value: state.isNutritionDriver,
            onChanged: (value) {
              state.setNutritionDriver(value);
            },
          ),
        ),
      ],
    ),);
  }

  Widget _buildPreviewMetric(
    BuildContext context,
    String label,
    String value, {
    bool alignEnd = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: alignEnd ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
