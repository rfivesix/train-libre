import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/unit_service.dart';
import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/app_ruler_picker.dart';
import '../../../../../widgets/common/summary_card.dart';
import '../../../../../widgets/common/value_summary_card.dart';
import 'goal_flow_state.dart';

class GoalTargetStep extends StatelessWidget {
  final GoalFlowState state;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  const GoalTargetStep({
    super.key,
    required this.state,
    this.horizontalPadding = DesignConstants.spacingL,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isMaintain) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding > 0 ? bottomPadding : horizontalPadding,
        ),
        child: _buildMaintainTarget(context),
      );
    } else {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding,
          bottom: bottomPadding > 0 ? bottomPadding : horizontalPadding,
        ),
        child: _buildChangeTarget(context),
      );
    }
  }

  Widget _buildMaintainTarget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);

    final baselineKg = state.getBaselineKg(unitService);
    final double? baselineDisp = baselineKg != null
        ? unitService.convertDisplayValue(baselineKg, UnitDimension.weight)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalPresetMaintainWeight,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalPresetMaintainWeightDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        SummaryCard(
          key: const Key('goal_baseline_card'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goalMaintainCorridor,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (baselineDisp != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${baselineDisp.toStringAsFixed(1)} $unitStr (± 1.0 $unitStr)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingM),
                const Divider(height: 1),
                const SizedBox(height: DesignConstants.spacingM),
                Text(
                  l10n.goalPaceFeedbackMaintain,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeTarget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);

    final baselineKg = state.getBaselineKg(unitService);
    final targetKg = state.getTargetKg(unitService);
    final double? baselineDisp = baselineKg != null
        ? unitService.convertDisplayValue(baselineKg, UnitDimension.weight)
        : null;
    final double? targetDisp = targetKg != null
        ? unitService.convertDisplayValue(targetKg, UnitDimension.weight)
        : null;
    final double? deltaDisp = (baselineDisp != null && targetDisp != null)
        ? (targetDisp - baselineDisp)
        : null;

    final isLosing = state.isLosing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.goalStepTargetWeightQuestion,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.goalStepTargetWeightDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingXL),

              // Target Weight Card
              SummaryCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    Text(
                      l10n.goalTargetWeightLabel(unitStr),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          targetDisp?.toStringAsFixed(1) ?? '--',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                        const SizedBox(width: DesignConstants.spacingS),
                        IconButton(
                          icon: Icon(
                            state.showManualTargetWeightInput
                                ? LucideIcons.sliders_horizontal
                                : LucideIcons.pencil,
                            size: 20,
                          ),
                          onPressed: () {
                            state.toggleManualTargetWeightInput();
                          },
                        ),
                      ],
                    ),
                    if (state.showManualTargetWeightInput) ...[
                      const SizedBox(height: DesignConstants.spacingM),
                      TextField(
                        key: const Key('goal_target_weight_input'),
                        controller: state.targetWeightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        onChanged: (_) {
                          final newTarget = state.getTargetKg(unitService);
                          if (newTarget != null && baselineKg != null) {
                            final delta = (newTarget - baselineKg).abs();
                            if (delta > 0 && state.weeklyRateKg > 0) {
                              final w = delta / state.weeklyRateKg;
                              final days = (w * 7).round();
                              state.onTargetDateChanged(
                                state.startDate
                                    .add(Duration(days: max(7, days))),
                                unitService,
                              );
                            }
                          }
                        },
                        decoration: InputDecoration(
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
                    if (targetDisp != null || baselineDisp != null)
                      AppRulerPicker.weight(
                        value: targetDisp ?? baselineDisp!,
                        imperial: unitService.isImperial,
                        onChanged: (newWeight) {
                          state.onTargetWeightChanged(newWeight, unitService);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),

        // Quick adjustment chips (scrollable edge-to-edge)
        if (baselineDisp != null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ),
            child: Row(
              children: (isLosing)
                  ? [2.0, 5.0, 10.0, 15.0].map((delta) {
                      final target = max(30.0, baselineDisp - delta);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '-$delta $unitStr (${target.toStringAsFixed(1)})',
                            style: theme.textTheme.labelMedium,
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.15),
                          ),
                          onPressed: () {
                            state.onTargetWeightChanged(target, unitService);
                          },
                        ),
                      );
                    }).toList()
                  : [2.0, 4.0, 6.0, 8.0].map((delta) {
                      final target = baselineDisp + delta;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '+$delta $unitStr (${target.toStringAsFixed(1)})',
                            style: theme.textTheme.labelMedium,
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.15),
                          ),
                          onPressed: () {
                            state.onTargetWeightChanged(target, unitService);
                          },
                        ),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
        ],

        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (baselineDisp != null && targetDisp != null) ...[
                if (isLosing && targetDisp >= baselineDisp)
                  _buildDirectionWarning(
                    context,
                    l10n.goalTargetDirectionLoseError,
                  ),
                if (!isLosing && targetDisp <= baselineDisp)
                  _buildDirectionWarning(
                    context,
                    l10n.goalTargetDirectionGainError,
                  ),
              ],

              // 3-Column Summary Cards: Baseline, Planned Delta, Target
              if (baselineDisp != null &&
                  targetDisp != null &&
                  deltaDisp != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('goal_baseline_card'),
                        onTap: () => state.toggleEditingBaseline(),
                        borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusM),
                        child: ValueSummaryCard(
                          label: l10n.goalBaselineHeader,
                          value: '${baselineDisp.toStringAsFixed(1)} $unitStr',
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.goalWeightDifferenceLabel,
                        value:
                            '${deltaDisp >= 0 ? '+' : ''}${deltaDisp.toStringAsFixed(1)} $unitStr',
                        valueColor: deltaDisp == 0
                            ? theme.colorScheme.primary
                            : (deltaDisp < 0 ? Colors.green : Colors.orange),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.goalTargetHeader,
                        value: '${targetDisp.toStringAsFixed(1)} $unitStr',
                        valueColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (state.isEditingBaseline) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  SummaryCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.goalBaselineHeader,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              key: const Key('goal_edit_baseline_button'),
                              tooltip: l10n.save,
                              icon: const Icon(LucideIcons.check, size: 20),
                              onPressed: () => state.toggleEditingBaseline(),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignConstants.spacingS),
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
                        const SizedBox(height: DesignConstants.spacingM),
                        AppRulerPicker.weight(
                          value: baselineDisp,
                          imperial: unitService.isImperial,
                          onChanged: (newWeight) {
                            final metric = unitService.convertToMetric(
                                newWeight, UnitDimension.weight);
                            state.setBaselineManual(metric, unitService);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: DesignConstants.spacingL),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionWarning(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      padding: const EdgeInsets.all(DesignConstants.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circle_alert,
              color: theme.colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: DesignConstants.spacingS),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
