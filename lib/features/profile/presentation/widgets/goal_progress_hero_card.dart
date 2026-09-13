// lib/features/profile/presentation/widgets/goal_progress_hero_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/models/goal_progress.dart';
import '../create_goal_flow.dart';
import '../goal_detail_screen.dart';

class GoalProgressHeroCard extends StatelessWidget {
  final Goal? goal;
  final GoalProgress? progress;
  final VoidCallback? onRefresh;

  const GoalProgressHeroCard({
    super.key,
    required this.goal,
    this.progress,
    this.onRefresh,
  });

  String _presetLabel(BuildContext context, GoalPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    switch (preset) {
      case GoalPreset.loseWeight:
        return l10n.goalPresetLoseWeight;
      case GoalPreset.gainWeight:
        return l10n.goalPresetGainWeight;
      case GoalPreset.maintainWeight:
        return l10n.goalPresetMaintainWeight;
      case GoalPreset.recomposition:
        return l10n.goalPresetRecomposition;
      case GoalPreset.custom:
        return l10n.goalPresetCustom;
    }
  }

  IconData _presetIcon(GoalPreset preset) {
    switch (preset) {
      case GoalPreset.loseWeight:
        return LucideIcons.trending_down;
      case GoalPreset.gainWeight:
        return LucideIcons.trending_up;
      case GoalPreset.maintainWeight:
        return LucideIcons.scale;
      case GoalPreset.recomposition:
        return LucideIcons.refresh_cw;
      case GoalPreset.custom:
        return LucideIcons.target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();

    if (goal == null) {
      return SummaryCard(
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusS),
                    ),
                    child: Icon(
                      LucideIcons.compass,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.noActiveGoalTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.noActiveGoalSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Text(
                l10n.noActiveGoalDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingL),
              AppButton.primary(
                label: l10n.createGoalButton,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateGoalFlow(),
                    ),
                  );
                  onRefresh?.call();
                },
              ),
            ],
          ),
        ),
      );
    }

    final currentGoal = goal!;
    final currentProgress = progress;

    String formatWeight(double? val) {
      if (val == null) return '--';
      final disp = unitService.convertDisplayValue(val, UnitDimension.weight);
      final unit = unitService.unitString(UnitDimension.weight);
      return '${disp.toStringAsFixed(1)} $unit';
    }

    final isWaiting =
        currentProgress?.state == GoalProgressState.waitingForBaseline;

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return SummaryCard(
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goalId: currentGoal.id),
            ),
          );
          onRefresh?.call();
        },
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Driver Pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusS),
                    ),
                    child: Icon(
                      _presetIcon(currentGoal.preset),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentGoal.title.isNotEmpty
                              ? currentGoal.title
                              : _presetLabel(context, currentGoal.preset),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _presetLabel(context, currentGoal.preset),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentGoal.isNutritionDriver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          DesignConstants.borderRadiusS,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.goalDrivesNutritionBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingL),

              // Dreiklang: Start / Aktuell / Ziel
              Container(
                padding: const EdgeInsets.all(DesignConstants.spacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusS),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Start
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.goalStartLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isWaiting
                                ? l10n.goalWaitingForMeasurementShort
                                : formatWeight(currentProgress?.baselineValue),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (currentProgress?.baselineDate != null)
                            Text(
                              dateFormat.format(currentProgress!.baselineDate!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    // Aktuell
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.goalCurrentHeader,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatWeight(currentProgress?.currentValue),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentProgress?.deltaSinceStart != null)
                              Text(
                                '${currentProgress!.deltaSinceStart! >= 0 ? '+' : ''}${unitService.convertDisplayValue(currentProgress.deltaSinceStart!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    // Ziel
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.goalTargetLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentGoal.hasNumericTarget
                                  ? formatWeight(currentGoal.targetValue)
                                  : (currentGoal.isMaintenanceOrRecomp
                                      ? l10n.goalMaintainCorridor
                                      : l10n.goalDirectionalOnly),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentGoal.targetDate != null)
                              Text(
                                dateFormat.format(currentGoal.targetDate!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Bar / Waiting indicator / Remaining Pill
              const SizedBox(height: DesignConstants.spacingM),
              if (isWaiting)
                Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.goalNeedsFirstMeasurementPrompt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                if (currentProgress?.progressPercentage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentProgress!.progressPercentage,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentProgress?.remainingDistance != null &&
                        currentGoal.hasNumericTarget)
                      Text(
                        l10n.goalRemainingDistanceText(
                          '${unitService.convertDisplayValue(currentProgress!.remainingDistance!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (currentGoal.isMaintenanceOrRecomp)
                      Text(
                        currentProgress?.isInToleranceBand == true
                            ? l10n.goalMaintenanceStable
                            : l10n.goalMaintenanceDrifting,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: currentProgress?.isInToleranceBand == true
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (currentGoal.desiredWeeklyRateKg != null)
                      Text(
                        '${currentGoal.desiredWeeklyRateKg! >= 0 ? '+' : ''}${unitService.convertDisplayValue(currentGoal.desiredWeeklyRateKg!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
