import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/unit_service.dart';
import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/app_ruler_picker.dart';
import '../../../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../../../widgets/common/summary_card.dart';
import '../../../domain/repositories/goal_repository.dart';
import 'goal_flow_state.dart';

class GoalBaselineStep extends StatelessWidget {
  final GoalFlowState state;
  final IGoalRepository? repository;
  final EdgeInsetsGeometry padding;

  const GoalBaselineStep({
    super.key,
    required this.state,
    this.repository,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignConstants.spacingL,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final baselineKg = state.getBaselineKg(unitService);
    final double? baselineDisp = baselineKg != null
        ? unitService.convertDisplayValue(baselineKg, UnitDimension.weight)
        : null;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStepBaselineQuestion,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStepBaselineDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
        SummaryCard(
          key: const Key('goal_start_date_card'),
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () async {
              final picked = await showAdaptiveDatePicker(
                context: context,
                initialDate: state.startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                state.updateStartDate(picked);
                if (repository != null) {
                  state.detectBaseline(repository!, unitService);
                }
              }
            },
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignConstants.spacingXS,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.goalStartDateLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(state.startDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        SummaryCard(
          key: const Key('goal_baseline_card'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DesignConstants.spacingXS,
            ),
            child: Column(
              children: [
                Text(
                  l10n.goalBaselineHeader,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    InkWell(
                      onTap: () {
                        state.toggleEditingBaseline();
                      },
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.spacingS,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              baselineDisp?.toStringAsFixed(1) ?? '--',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: DesignConstants.spacingS),
                            Text(
                              unitStr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingXS),
                    IconButton(
                      key: const Key('goal_edit_baseline_button'),
                      tooltip: state.isEditingBaseline ? l10n.save : l10n.edit,
                      icon: Icon(
                        state.isEditingBaseline
                            ? LucideIcons.check
                            : LucideIcons.pencil,
                        size: 20,
                      ),
                      onPressed: () {
                        state.toggleEditingBaseline();
                      },
                    ),
                    if (state.isEditingBaseline)
                      IconButton(
                        icon: Icon(
                          state.showManualBaselineInput
                              ? LucideIcons.sliders_horizontal
                              : LucideIcons.keyboard,
                          size: 20,
                        ),
                        onPressed: () {
                          state.toggleManualBaselineInput();
                        },
                      ),
                  ],
                ),
                if (state.detectedBaselineDate != null &&
                    !state.isManualBaselineMode) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(state.detectedBaselineDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                if (state.isEditingBaseline) ...[
                  if (state.showManualBaselineInput) ...[
                    const SizedBox(height: DesignConstants.spacingM),
                    TextField(
                      key: const Key('goal_inline_baseline_input'),
                      controller: state.baselineWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (text) {
                        final parsed =
                            double.tryParse(text.replaceAll(',', '.'));
                        if (parsed != null && parsed > 0) {
                          final metric = unitService.convertToMetric(
                              parsed, UnitDimension.weight);
                          state.setBaselineManual(metric, unitService);
                        }
                      },
                      decoration: InputDecoration(
                        suffixText: unitStr,
                        hintText: '0.0',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignConstants.borderRadiusM),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignConstants.spacingM),
                  AppRulerPicker.weight(
                    value: baselineDisp ??
                        (unitService.isImperial ? 160.0 : 75.0),
                    imperial: unitService.isImperial,
                    onChanged: (newWeight) {
                      final metric = unitService.convertToMetric(
                          newWeight, UnitDimension.weight);
                      state.setBaselineManual(metric, unitService);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
