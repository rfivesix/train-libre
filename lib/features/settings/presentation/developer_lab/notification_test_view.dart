// lib/features/settings/presentation/developer_lab/notification_test_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../services/local_notification_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';

class NotificationTestView extends StatefulWidget {
  const NotificationTestView({super.key});

  @override
  State<NotificationTestView> createState() => _NotificationTestViewState();
}

class _NotificationTestViewState extends State<NotificationTestView> {
  String _statusMessage = 'Bereit zum Testen';
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final enabled =
        await LocalNotificationService.instance.areNotificationsEnabled();
    if (mounted) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  Future<void> _requestPermissions() async {
    final granted =
        await LocalNotificationService.instance.requestNotificationPermissions();
    await _checkPermissionStatus();
    _setMessage(granted
        ? 'Berechtigung erteilt oder aktiv'
        : 'Berechtigung nicht erteilt');
  }

  void _setMessage(String msg) {
    if (mounted) {
      setState(() => _statusMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _triggerWeeklyReviewNow() async {
    final success = await LocalNotificationService.instance
        .showWeeklyGoalReviewNotification(
      goalId: 'sandbox-goal-id',
      reviewId: 'test-weekly-review-${DateTime.now().millisecondsSinceEpoch}',
      ignorePreferences: true,
    );
    _setMessage(success
        ? 'Wochen-Review Benachrichtigung gesendet'
        : 'Senden fehlgeschlagen (Berechtigung im System prüfen)');
  }

  Future<void> _triggerWeeklyReviewIn5Seconds() async {
    _setMessage('Wochen-Review in 5 Sekunden im System geplant... (App jetzt minimieren)');
    final success = await LocalNotificationService.instance
        .showWeeklyGoalReviewNotification(
      goalId: 'sandbox-goal-id',
      reviewId: 'test-weekly-review-${DateTime.now().millisecondsSinceEpoch}',
      ignorePreferences: true,
      delay: const Duration(seconds: 5),
    );
    if (!success) {
      _setMessage('Planung fehlgeschlagen (Berechtigung im System prüfen)');
    }
  }

  Future<void> _triggerRecommendationDueNow() async {
    final success = await LocalNotificationService.instance
        .showAdaptiveRecommendationDueNotification(ignorePreferences: true);
    _setMessage(success
        ? 'Adaptive Empfehlungs-Benachrichtigung gesendet'
        : 'Senden fehlgeschlagen (Berechtigung im System prüfen)');
  }

  Future<void> _triggerRecommendationDueIn5Seconds() async {
    _setMessage('Empfehlung in 5 Sekunden im System geplant... (App jetzt minimieren)');
    final success = await LocalNotificationService.instance
        .showAdaptiveRecommendationDueNotification(
      ignorePreferences: true,
      delay: const Duration(seconds: 5),
    );
    if (!success) {
      _setMessage('Planung fehlgeschlagen (Berechtigung im System prüfen)');
    }
  }

  Future<void> _triggerTargetDateReminderNow() async {
    final success = await LocalNotificationService.instance
        .showGoalTargetDateReminderNotification(
      goalId: 'sandbox-goal-id',
      goalTitle: '78.0 kg erreichen',
      isDueToday: true,
      ignorePreferences: true,
    );
    _setMessage(success
        ? 'Zieldatum-Erinnerung gesendet'
        : 'Senden fehlgeschlagen (Berechtigung im System prüfen)');
  }

  Future<void> _cancelAllGoalNotifications() async {
    await LocalNotificationService.instance
        .cancelGoalNotifications(goalId: 'sandbox-goal-id');
    _setMessage('Alle Ziel-Benachrichtigungen für Sandbox abgebrochen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bell_ring, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: DesignConstants.spacingS),
                Text(
                  'Lokale Benachrichtigungen testen',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: _notificationsEnabled == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    _notificationsEnabled == true
                        ? LucideIcons.circle_check
                        : LucideIcons.circle_alert,
                    color: _notificationsEnabled == true
                        ? Colors.green
                        : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: Text(
                      _notificationsEnabled == null
                          ? 'Berechtigungsstatus wird geprüft...'
                          : _notificationsEnabled == true
                              ? 'System-Benachrichtigungen sind aktiv'
                              : 'System-Benachrichtigungen nicht erteilt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_notificationsEnabled != true)
                    TextButton(
                      onPressed: _requestPermissions,
                      child: const Text('Erteilen'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              'Status: $_statusMessage',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const Divider(height: DesignConstants.spacingL),
            Text(
              '1. Wöchentlicher Ziel-Review',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Jetzt senden',
                    onPressed: _triggerWeeklyReviewNow,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.secondary(
                    label: 'In 5s senden',
                    tooltip: 'In 5 Sekunden senden (zum Testen im Hintergrund)',
                    onPressed: _triggerWeeklyReviewIn5Seconds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              '2. Neue adaptive Empfehlung fällig',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Jetzt senden',
                    onPressed: _triggerRecommendationDueNow,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.secondary(
                    label: 'In 5s senden',
                    onPressed: _triggerRecommendationDueIn5Seconds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              '3. Zieldatum-Erinnerung',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            AppButton.secondary(
              label: 'Zieldatum erreicht (Heute)',
              onPressed: _triggerTargetDateReminderNow,
            ),
            const Divider(height: DesignConstants.spacingL),
            AppButton.secondary(
              label: 'Alle Ziel-Benachrichtigungen stornieren',
              onPressed: _cancelAllGoalNotifications,
            ),
          ],
        ),
      ),
    );
  }
}
