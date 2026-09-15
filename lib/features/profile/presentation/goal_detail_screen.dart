// lib/features/profile/presentation/goal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/models/goal_model.dart';
import '../domain/models/goal_progress.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../data/goal_repository_impl.dart';
import '../domain/services/goal_notification_orchestrator.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'widgets/active_goal_dashboard_widget.dart';
import 'widgets/goal_adjustment_sheet.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  final IGoalRepository? repository;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.repository,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late final IGoalRepository _goalRepository;
  IProfileRepository? _profileRepo;
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.repository ?? GoalRepositoryImpl();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileRepo ??= context.read<IProfileRepository>();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchGoalDetailData();
    });
  }

  Future<Map<String, dynamic>> _fetchGoalDetailData() async {
    final goal = await _goalRepository.getGoalById(widget.goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    final progress = await _goalRepository.getGoalProgress(goal);

    // Fetch chart points for weight from goal start date up to now
    final profileRepo = _profileRepo;
    final startDate = goal.startDate.subtract(const Duration(days: 1));
    final endDate = DateTime.now().add(const Duration(days: 1));

    List<ChartDataPoint> chartPoints = [];
    if (profileRepo != null) {
      try {
        chartPoints = await profileRepo.getChartDataForTypeAndRange(
          'weight',
          DateTimeRange(start: startDate, end: endDate),
        );
      } catch (_) {
        chartPoints = [];
      }
    }

    // Ensure baseline is included at goal start date if missing
    final baseline = progress?.baselineValue;
    if (baseline != null) {
      if (chartPoints.isEmpty) {
        chartPoints = [
          ChartDataPoint(
            date: goal.startDate,
            value: baseline,
          ),
        ];
      } else if (chartPoints.first.date.isAfter(goal.startDate)) {
        chartPoints.insert(
          0,
          ChartDataPoint(
            date: goal.startDate,
            value: baseline,
          ),
        );
      }
    }

    return {
      'goal': goal,
      'progress': progress,
      'chartPoints': chartPoints,
    };
  }

  Future<void> _openAdjustmentSheet(Goal goal, GoalProgress? progress) async {
    final startWeight =
        progress?.currentValue ?? progress?.baselineValue ?? 75.0;
    final result = await GoalAdjustmentSheet.show(
      context,
      goal: goal,
      startWeightKg: startWeight,
      repository: _goalRepository,
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _retireGoal(Goal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.retireGoalDialogTitle,
      content: l10n.retireGoalDialogContent,
      confirmLabel: l10n.retireGoalConfirmButton,
    );

    if (confirmed == true && mounted) {
      await _goalRepository.retireGoal(goal.id,
          reason: 'Nutzer hat Ziel beendet');
      await GoalNotificationOrchestrator(goalRepository: _goalRepository)
          .goalBecameInactive(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goalRetiredSuccessSnack)),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _resumeGoal(Goal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassConfirmation(
      context: context,
      title: l10n.resumeGoalDialogTitle,
      content: l10n.resumeGoalDialogContent,
      confirmLabel: l10n.resumeGoalConfirmButton,
    );

    if (confirmed == true && mounted) {
      final previouslyActive = await _goalRepository.getActiveGoal();
      await _goalRepository.resumeGoal(goal.id);
      final notifications =
          GoalNotificationOrchestrator(goalRepository: _goalRepository);
      if (previouslyActive != null && previouslyActive.id != goal.id) {
        await notifications.goalBecameInactive(previouslyActive.id);
      }
      await notifications.synchronize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goalResumedSuccessSnack)),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.goalDetailScreenTitle,
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
          final goal = data['goal'] as Goal;
          final progress = data['progress'] as GoalProgress?;
          final chartPoints = data['chartPoints'] as List<ChartDataPoint>;

          final isActive = goal.status == GoalStatus.active;
          final isRetired = goal.status == GoalStatus.retired;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.screenPaddingHorizontal,
                vertical: DesignConstants.spacingM,
              ),
              children: [
                ActiveGoalDashboardWidget(
                  goal: goal,
                  progress: progress,
                  chartPoints: chartPoints,
                  onRefresh: _loadData,
                  bleedChartToEdges: true,
                  bottomActions: isActive
                      ? Row(
                          children: [
                            Expanded(
                              child: AppButton.secondary(
                                label: l10n.adjustGoalTitle,
                                onPressed: () =>
                                    _openAdjustmentSheet(goal, progress),
                              ),
                            ),
                            const SizedBox(width: DesignConstants.spacingM),
                            Expanded(
                              child: AppButton.secondary(
                                label: l10n.retireGoalButton,
                                onPressed: () => _retireGoal(goal),
                              ),
                            ),
                          ],
                        )
                      : (isRetired
                          ? SizedBox(
                              width: double.infinity,
                              child: AppButton.primary(
                                label: l10n.resumeGoalButton,
                                onPressed: () => _resumeGoal(goal),
                              ),
                            )
                          : null),
                ),
                const BottomContentSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
