// lib/features/settings/presentation/goal_notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../services/local_notification_service.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/domain/services/goal_notification_orchestrator.dart';
import '../../workout/data/manual_training_plan_repository.dart';
import '../../workout/domain/services/workout_plan_notification_orchestrator.dart';

class GoalNotificationSettingsScreen extends StatefulWidget {
  const GoalNotificationSettingsScreen({super.key});

  @override
  State<GoalNotificationSettingsScreen> createState() =>
      _GoalNotificationSettingsScreenState();
}

class _GoalNotificationSettingsScreenState
    extends State<GoalNotificationSettingsScreen> {
  bool _weeklyReviewEnabled = true;
  bool _recommendationDueEnabled = true;
  bool _targetDateReminderEnabled = false;
  bool _workoutPlanReminderEnabled = false;
  int _workoutPlanReminderHour =
      WorkoutPlanNotificationOrchestrator.defaultHour;
  int _workoutPlanReminderMinute =
      WorkoutPlanNotificationOrchestrator.defaultMinute;
  bool _hasActiveWorkoutPlan = false;
  bool? _systemNotificationsEnabled;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final activePlan = await ManualTrainingPlanRepository().activePlan();
    final notificationsEnabled =
        await LocalNotificationService.instance.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _weeklyReviewEnabled = prefs.getBool('notify_weekly_goal_review') ?? true;
      _recommendationDueEnabled =
          prefs.getBool('notify_adaptive_recommendation') ?? true;
      _targetDateReminderEnabled =
          prefs.getBool('notify_goal_target_date') ?? false;
      _workoutPlanReminderEnabled = prefs.getBool(
            WorkoutPlanNotificationOrchestrator.enabledPreference,
          ) ??
          false;
      _workoutPlanReminderHour = prefs.getInt(
            WorkoutPlanNotificationOrchestrator.hourPreference,
          ) ??
          WorkoutPlanNotificationOrchestrator.defaultHour;
      _workoutPlanReminderMinute = prefs.getInt(
            WorkoutPlanNotificationOrchestrator.minutePreference,
          ) ??
          WorkoutPlanNotificationOrchestrator.defaultMinute;
      _hasActiveWorkoutPlan = activePlan != null;
      _systemNotificationsEnabled = notificationsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _setWorkoutPlanReminder(bool value) async {
    var enabled = value;
    if (enabled) {
      enabled = await LocalNotificationService.instance
          .requestNotificationPermissions();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      WorkoutPlanNotificationOrchestrator.enabledPreference,
      enabled,
    );
    if (!mounted) return;
    setState(() {
      _workoutPlanReminderEnabled = enabled;
      if (!enabled && value) _systemNotificationsEnabled = false;
    });
    await WorkoutPlanNotificationOrchestrator().synchronize();
    if (!enabled && value && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.notificationPermissionDenied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _chooseWorkoutReminderTime() async {
    final picked = await showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _workoutPlanReminderHour,
        minute: _workoutPlanReminderMinute,
      ),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      WorkoutPlanNotificationOrchestrator.hourPreference,
      picked.hour,
    );
    await prefs.setInt(
      WorkoutPlanNotificationOrchestrator.minutePreference,
      picked.minute,
    );
    if (!mounted) return;
    setState(() {
      _workoutPlanReminderHour = picked.hour;
      _workoutPlanReminderMinute = picked.minute;
    });
    await WorkoutPlanNotificationOrchestrator().synchronize();
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    final repository = GoalRepositoryImpl();
    final activeGoal = await repository.getActiveGoal();
    if (key == 'notify_adaptive_recommendation' && !value) {
      await LocalNotificationService.instance
          .cancelAdaptiveRecommendationNotifications();
      return;
    }
    if (key == 'notify_weekly_goal_review' && !value && activeGoal != null) {
      await LocalNotificationService.instance
          .cancelWeeklyReviewNotifications(goalId: activeGoal.id);
      return;
    }
    if (activeGoal != null) {
      await GoalNotificationOrchestrator(goalRepository: repository)
          .synchronize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.notificationSettingsTitle,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.screenPadding,
              children: [
                AppSectionHeader(
                  title: l10n.notificationWorkoutSectionTitle,
                  isFirst: true,
                ),
                SummaryCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: Icon(
                          LucideIcons.dumbbell,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          l10n.workoutPlanNotifyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _hasActiveWorkoutPlan
                              ? l10n.workoutPlanNotifySubtitle
                              : l10n.workoutPlanNotifyNoActivePlan,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        value: _workoutPlanReminderEnabled,
                        onChanged: _setWorkoutPlanReminder,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _workoutPlanReminderEnabled
                            ? Column(
                                children: [
                                  const Divider(height: 1),
                                  AppLinkRow(
                                    title: l10n.workoutPlanNotifyTimeTitle,
                                    subtitle: MaterialLocalizations.of(context)
                                        .formatTimeOfDay(
                                      TimeOfDay(
                                        hour: _workoutPlanReminderHour,
                                        minute: _workoutPlanReminderMinute,
                                      ),
                                      alwaysUse24HourFormat:
                                          MediaQuery.alwaysUse24HourFormatOf(
                                              context),
                                    ),
                                    trailingIcon: LucideIcons.clock_3,
                                    onTap: _chooseWorkoutReminderTime,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                if (_systemNotificationsEnabled == false &&
                    _workoutPlanReminderEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignConstants.spacingM,
                      DesignConstants.spacingS,
                      DesignConstants.spacingM,
                      0,
                    ),
                    child: Text(
                      l10n.notificationPermissionDenied,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: DesignConstants.spacingL),
                AppSectionHeader(title: l10n.notificationGoalsSectionTitle),
                SummaryCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: Icon(
                          LucideIcons.calendar_check_2,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          l10n.goalNotifyWeeklyReviewTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.goalNotifyWeeklyReviewSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        value: _weeklyReviewEnabled,
                        onChanged: (val) {
                          setState(() => _weeklyReviewEnabled = val);
                          _saveSetting('notify_weekly_goal_review', val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: Icon(
                          LucideIcons.sparkles,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          l10n.goalNotifyRecommendationDueTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.goalNotifyRecommendationDueSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        value: _recommendationDueEnabled,
                        onChanged: (val) {
                          setState(() => _recommendationDueEnabled = val);
                          _saveSetting('notify_adaptive_recommendation', val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: Icon(
                          LucideIcons.flag,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          l10n.goalNotifyTargetDateTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.goalNotifyTargetDateSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        value: _targetDateReminderEnabled,
                        onChanged: (val) {
                          setState(() => _targetDateReminderEnabled = val);
                          _saveSetting('notify_goal_target_date', val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                SummaryCard(
                  child: Padding(
                    padding: DesignConstants.cardPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.shield_check,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.notificationPrivacyTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingXS),
                              Text(
                                l10n.notificationPrivacyBody,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
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
