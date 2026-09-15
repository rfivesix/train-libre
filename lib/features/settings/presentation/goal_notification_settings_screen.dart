// lib/features/settings/presentation/goal_notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../services/local_notification_service.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/domain/services/goal_notification_orchestrator.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _weeklyReviewEnabled = prefs.getBool('notify_weekly_goal_review') ?? true;
      _recommendationDueEnabled =
          prefs.getBool('notify_adaptive_recommendation') ?? true;
      _targetDateReminderEnabled =
          prefs.getBool('notify_goal_target_date') ?? false;
      _isLoading = false;
    });
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
        title: l10n.goalNotificationSettingsTitle,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.screenPadding,
              children: [
                SummaryCard(
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
                                l10n.goalNotifyPrivacyTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingXS),
                              Text(
                                l10n.goalNotifyPrivacyBody,
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
