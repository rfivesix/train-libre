import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/unit_service.dart';
import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/app_ruler_picker.dart';
import '../../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../../../widgets/common/summary_card.dart';
import 'goal_flow_state.dart';

class GoalPaceTimelineStep extends StatelessWidget {
  final GoalFlowState state;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  const GoalPaceTimelineStep({
    super.key,
    required this.state,
    this.horizontalPadding = DesignConstants.spacingL,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isMaintain) {
      return _buildMaintainTimeline(context);
    }
    return _buildChangeTimeline(context);
  }

  Widget _buildMaintainTimeline(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding > 0 ? bottomPadding : horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStepTrajectoryQuestion,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStep4Description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
        Text(
          l10n.goalTargetDateLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        PlatformAdaptiveDropdownFormField<String>(
          key: ValueKey('maintain_duration_${state.selectedDurationPreset}'),
          value: state.selectedDurationPreset == '24'
              ? 'custom'
              : state.selectedDurationPreset,
          items: [
            DropdownMenuItem(
              value: 'ongoing',
              child: Text(l10n.goalNoDeadlineOption),
            ),
            DropdownMenuItem(
              value: '8',
              child: Text(l10n.goalEstimatedDuration(8)),
            ),
            DropdownMenuItem(
              value: '12',
              child: Text(l10n.goalEstimatedDuration(12)),
            ),
            DropdownMenuItem(
              value: '16',
              child: Text(l10n.goalEstimatedDuration(16)),
            ),
            DropdownMenuItem(
              value: 'custom',
              child: Text(l10n.goalDurationCustom),
            ),
          ],
          onChanged: (val) {
            if (val == null) return;
            state.setDurationPreset(val);
          },
        ),
        if (state.selectedDurationPreset == 'custom') ...[
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            child: ListTile(
              title: Text(
                state.targetDate != null
                    ? dateFormat.format(state.targetDate!)
                    : l10n.goalNoDeadlineOption,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(l10n.goalTargetDateLabel),
              onTap: () async {
                final picked = await showAdaptiveDatePicker(
                  context: context,
                  initialDate: state.targetDate ??
                      state.startDate.add(const Duration(days: 84)),
                  firstDate: state.startDate.add(const Duration(days: 7)),
                  lastDate: state.startDate.add(const Duration(days: 730)),
                );
                if (picked != null) {
                  state.setTargetDate(picked);
                }
              },
            ),
          ),
        ],
      ],
    ),);
  }

  Widget _buildChangeTimeline(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final isLosing = state.isLosing;
    final dailyCalorieImpact = (state.weeklyRateKg * 7700 / 7).round();
    final int weeks = state.targetDate != null
        ? max(1, (state.targetDate!.difference(state.startDate).inDays / 7).round())
        : 12;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding > 0 ? bottomPadding : horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStepTrajectoryQuestion,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStepTrajectoryDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

          // Hero Trajectory card
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.goalEstimatedDuration(weeks),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.targetDate != null)
                        Text(
                          dateFormat.format(state.targetDate!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.goalEstimatedDailyDelta,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Text(
                        '${isLosing ? '-' : '+'}$dailyCalorieImpact ${l10n.analyticsKcalPerDay}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLosing
                              ? Colors.orangeAccent
                              : Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    children: [
                      Icon(
                        state.weeklyRateKg > 1.0
                            ? LucideIcons.triangle_alert
                            : (state.weeklyRateKg < 0.3
                                ? LucideIcons.info
                                : LucideIcons.circle_check),
                        size: 18,
                        color: state.weeklyRateKg > 1.0
                            ? Colors.orange
                            : (state.weeklyRateKg < 0.3
                                ? Colors.blue
                                : Colors.green),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: Text(
                          state.weeklyRateKg > 1.0
                              ? l10n.goalPaceFeedbackAggressive
                              : (state.weeklyRateKg < 0.3
                                  ? l10n.goalPaceFeedbackGentle
                                  : l10n.goalPaceFeedbackSafe),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Pace Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.goalWeeklyRateLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.weeklyRateKg.toStringAsFixed(2)} $unitStr / ${l10n.weekShort}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          PlatformAdaptiveDropdownFormField<String>(
            key: ValueKey('rate_dropdown_${state.selectedRatePreset}'),
            value: state.selectedRatePreset,
            items: [
              DropdownMenuItem(
                value: 'gentle',
                child: Text(l10n.goalRateGentle),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text(l10n.goalRateModerate),
              ),
              DropdownMenuItem(
                value: 'athletic',
                child: Text(l10n.goalRateAthletic),
              ),
              DropdownMenuItem(
                value: 'aggressive',
                child: Text(l10n.goalRateAggressive),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(l10n.goalRateCustom),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              if (val == 'gentle') {
                state.onWeeklyRateChanged(0.25, unitService, ratePreset: 'gentle');
              } else if (val == 'moderate') {
                state.onWeeklyRateChanged(0.50, unitService, ratePreset: 'moderate');
              } else if (val == 'athletic') {
                state.onWeeklyRateChanged(0.75, unitService, ratePreset: 'athletic');
              } else if (val == 'aggressive') {
                state.onWeeklyRateChanged(1.00, unitService, ratePreset: 'aggressive');
              } else {
                state.setRatePresetCustom();
              }
            },
          ),
          if (state.selectedRatePreset == 'custom') ...[
            const SizedBox(height: DesignConstants.spacingM),
            AppRulerPicker.rate(
              value: state.weeklyRateKg,
              imperial: unitService.isImperial,
              onChanged: (val) => state.onWeeklyRateChanged(
                val,
                unitService,
                ratePreset: 'custom',
              ),
              unit: unitStr,
            ),
          ],
          const SizedBox(height: DesignConstants.spacingL),

          // Target Date / Duration Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.goalTargetDateLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.targetDate != null)
                Text(
                  dateFormat.format(state.targetDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          PlatformAdaptiveDropdownFormField<String>(
            key: ValueKey('duration_dropdown_${state.selectedDurationPreset}'),
            value: state.selectedDurationPreset,
            items: [
              DropdownMenuItem(
                value: '8',
                child: Text(l10n.goalEstimatedDuration(8)),
              ),
              DropdownMenuItem(
                value: '12',
                child: Text(l10n.goalEstimatedDuration(12)),
              ),
              DropdownMenuItem(
                value: '16',
                child: Text(l10n.goalEstimatedDuration(16)),
              ),
              DropdownMenuItem(
                value: '24',
                child: Text(l10n.goalEstimatedDuration(24)),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(l10n.goalDurationCustom),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              if (val == 'custom') {
                state.setDurationPresetCustom();
              } else {
                final w = int.tryParse(val) ?? 12;
                final newDate = state.startDate.add(Duration(days: w * 7));
                state.onTargetDateChanged(newDate, unitService, durationPreset: val);
              }
            },
          ),
          if (state.selectedDurationPreset == 'custom') ...[
            const SizedBox(height: DesignConstants.spacingM),
            SummaryCard(
              child: ListTile(
                title: Text(
                  state.targetDate != null
                      ? dateFormat.format(state.targetDate!)
                      : l10n.goalNoDeadlineOption,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(l10n.goalTargetDateLabel),
                onTap: () async {
                  final picked = await showAdaptiveDatePicker(
                    context: context,
                    initialDate: state.targetDate ??
                        state.startDate.add(const Duration(days: 84)),
                    firstDate: state.startDate.add(const Duration(days: 7)),
                    lastDate: state.startDate.add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    state.onTargetDateChanged(
                      picked,
                      unitService,
                      durationPreset: 'custom',
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
