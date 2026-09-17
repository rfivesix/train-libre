// lib/features/profile/presentation/my_goals_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../domain/models/goal_model.dart';
import '../domain/models/goal_progress.dart';
import '../domain/repositories/goal_repository.dart';
import '../data/goal_repository_impl.dart';
import 'create_goal_flow.dart';
import 'goal_detail_screen.dart';
import 'goals_screen.dart';
import 'widgets/goal_adjustment_sheet.dart';
import 'widgets/goal_progress_hero_card.dart';

class MyGoalsScreen extends StatefulWidget {
  final IGoalRepository? repository;

  const MyGoalsScreen({super.key, this.repository});

  @override
  State<MyGoalsScreen> createState() => _MyGoalsScreenState();
}

class _MyGoalsScreenState extends State<MyGoalsScreen> {
  late final IGoalRepository _goalRepository;
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.repository ?? GoalRepositoryImpl();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchGoalsData();
    });
  }

  Future<Map<String, dynamic>> _fetchGoalsData() async {
    final activeGoal = await _goalRepository.getActiveNutritionGoal();
    GoalProgress? activeProgress;
    if (activeGoal != null) {
      activeProgress = await _goalRepository.getGoalProgress(activeGoal);
    }
    final retiredGoals = await _goalRepository.getRetiredGoals();

    return {
      'activeGoal': activeGoal,
      'activeProgress': activeProgress,
      'retiredGoals': retiredGoals,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.my_goals,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: l10n.createGoalButton,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateGoalFlow(),
                ),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.error),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label: l10n.retry,
                    onPressed: _loadData,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final activeGoal = data['activeGoal'] as Goal?;
          final activeProgress = data['activeProgress'] as GoalProgress?;
          final retiredGoals = data['retiredGoals'] as List<Goal>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: DesignConstants.cardPadding,
              children: [
                // Top banner pointing to operative daily targets
                InkWell(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyTargetsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingM,
                      vertical: DesignConstants.spacingS + 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.sliders_horizontal,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        Expanded(
                          child: Text(
                            l10n.myGoalsOperativeTargetsBanner,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Section Header: Aktives Ziel
                Text(
                  l10n.myGoalsActiveGoalSectionHeader.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),

                // Active Goal Card (Hero card or empty state)
                GoalProgressHeroCard(
                  goal: activeGoal,
                  progress: activeProgress,
                  onRefresh: _loadData,
                ),

                if (activeGoal != null) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.goalDetailScreenTitle,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    GoalDetailScreen(goalId: activeGoal.id),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingM),
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.adjustGoalTitle,
                          onPressed: (activeProgress?.currentValue ??
                                      activeProgress?.baselineValue) ==
                                  null
                              ? null
                              : () async {
                                  final startWeight =
                                      activeProgress!.currentValue ??
                                          activeProgress.baselineValue!;
                                  final result = await GoalAdjustmentSheet.show(
                                    context,
                                    goal: activeGoal,
                                    startWeightKg: startWeight,
                                    repository: _goalRepository,
                                  );
                                  if (result == true && mounted) {
                                    _loadData();
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: DesignConstants.spacingXL),

                // Section Header & Collapsible Accordion: Ziel-Historie
                if (retiredGoals.isNotEmpty) ...[
                  SummaryCard(
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: const PageStorageKey('my_goals_history_expansion'),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.spacingM,
                          vertical: 4,
                        ),
                        leading: Icon(
                          LucideIcons.rotate_ccw,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        title: Text(
                          '${l10n.myGoalsHistorySectionHeader} (${retiredGoals.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: retiredGoals.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = retiredGoals[index];
                              final isSuperseded =
                                  item.status == GoalStatus.superseded;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacingM,
                                  vertical: 4,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSuperseded
                                            ? theme.colorScheme
                                                .surfaceContainerHighest
                                            : Colors.orange
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          DesignConstants.borderRadiusS,
                                        ),
                                      ),
                                      child: Text(
                                        isSuperseded
                                            ? l10n.goalStatusSuperseded
                                            : l10n.goalStatusRetired,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: isSuperseded
                                              ? theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7)
                                              : Colors.orange.shade800,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dateFormat.format(item.startDate)}${item.retiredAt != null ? " – ${dateFormat.format(item.retiredAt!)}" : ""}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    if (item.targetValue != null)
                                      Text(
                                        '${l10n.goalTargetHeader}: ${unitService.convertDisplayValue(item.targetValue!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: const Icon(LucideIcons.chevron_right,
                                    size: 18),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GoalDetailScreen(goalId: item.id),
                                    ),
                                  );
                                  _loadData();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const BottomContentSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
