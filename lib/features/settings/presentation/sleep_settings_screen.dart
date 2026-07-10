import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';

import '../../sleep/platform/permissions/sleep_permission_controller.dart';
import '../../sleep/platform/permissions/sleep_permission_models.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SleepSettingsScreen extends StatefulWidget {
  const SleepSettingsScreen({
    super.key,
    SleepSettingsService? sleepSyncService,
    SleepPermissionController? sleepPermissionController,
  })  : _sleepSyncService = sleepSyncService,
        _sleepPermissionController = sleepPermissionController;

  final SleepSettingsService? _sleepSyncService;
  final SleepPermissionController? _sleepPermissionController;

  @override
  State<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends State<SleepSettingsScreen> {
  late final SleepSettingsService _sleepSyncService;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;

  bool _sleepTrackingEnabled = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();
    _loadSleepSettings();
  }

  @override
  void dispose() {
    if (_ownsSleepPermissionController) {
      _sleepPermissionController.state.dispose();
    }
    if (_ownsSleepSyncService) {
      unawaited(_sleepSyncService.dispose());
    }
    super.dispose();
  }

  Future<void> _loadSleepSettings() async {
    final enabled = await _sleepSyncService.isTrackingEnabled();
    if (!mounted) return;
    setState(() => _sleepTrackingEnabled = enabled);
    await _sleepPermissionController.refresh();
  }



  String _sleepStatusSubtitle(
    SleepPermissionStatus status,
    AppLocalizations l10n,
  ) {
    final custom = status.message;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (status.state) {
      SleepPermissionState.loading => l10n.sleepStatusChecking,
      SleepPermissionState.ready => l10n.sleepStatusReady,
      SleepPermissionState.denied => l10n.sleepStatusDenied,
      SleepPermissionState.partial => l10n.sleepStatusPartial,
      SleepPermissionState.unavailable => l10n.sleepStatusUnavailable,
      SleepPermissionState.notInstalled => l10n.sleepStatusNotInstalled,
      SleepPermissionState.technicalError => l10n.sleepStatusTechnicalError,
    };
  }

  IconData _sleepStatusIcon(SleepPermissionState state) {
    return switch (state) {
      SleepPermissionState.ready => LucideIcons.circle_check,
      SleepPermissionState.loading => LucideIcons.hourglass,
      SleepPermissionState.denied => LucideIcons.ban,
      SleepPermissionState.partial => LucideIcons.triangle_alert,
      SleepPermissionState.unavailable => LucideIcons.signal_zero,
      SleepPermissionState.notInstalled => LucideIcons.download,
      SleepPermissionState.technicalError => LucideIcons.triangle_alert,
    };
  }

  Color _sleepStatusColor(BuildContext context, SleepPermissionState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      SleepPermissionState.ready => Colors.green,
      SleepPermissionState.loading => scheme.outline,
      SleepPermissionState.denied => scheme.error,
      SleepPermissionState.partial => Colors.orange,
      SleepPermissionState.unavailable => scheme.outline,
      SleepPermissionState.notInstalled => scheme.secondary,
      SleepPermissionState.technicalError => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.sleepSettingsSectionTitle,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: l10n.sleepSettingsSectionTitle),
          ValueListenableBuilder<SleepPermissionStatus>(
            valueListenable: _sleepPermissionController.state,
            builder: (context, permission, _) {
              return SummaryCard(
                child: Column(
                  children: [
                    PlatformAdaptiveSwitchListTile(
                      secondary: const Icon(LucideIcons.moon),
                      title: Text(
                        l10n.sleepEnableTrackingTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.sleepEnableTrackingSubtitle),
                      value: _sleepTrackingEnabled,
                      onChanged: (value) async {
                        final wasEnabled = _sleepTrackingEnabled;
                        await _sleepSyncService.setTrackingEnabled(value);
                        if (value && !wasEnabled) {
                          await _sleepPermissionController
                              // ignore: use_build_context_synchronously
                              .requestAccess(context);
                        }
                        await _sleepPermissionController.refresh();
                        if (!mounted) return;
                        setState(() {
                          _sleepTrackingEnabled = value;
                          _hasChanges = true;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.shield_check),
                      title: Text(
                        l10n.sleepHealthConnectionStatusTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_sleepStatusSubtitle(permission, l10n)),
                          const SizedBox(height: 4),
                          Text(
                            permission.state == SleepPermissionState.ready
                                ? (Platform.isIOS ? l10n.sleepDataStatusSubtitleIos : l10n.sleepDataStatusSubtitle)
                                : (permission.state == SleepPermissionState.denied ||
                                        permission.state == SleepPermissionState.partial
                                    ? l10n.sleepNoPermissionSubtitle
                                    : l10n.sleepFeatureUnavailableSubtitle),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        permission.state == SleepPermissionState.ready
                            ? LucideIcons.circle_check
                            : (permission.state == SleepPermissionState.denied ||
                                    permission.state == SleepPermissionState.partial
                                ? LucideIcons.chevron_right
                                : _sleepStatusIcon(permission.state)),
                        color: _sleepStatusColor(context, permission.state),
                      ),
                      onTap: (permission.state == SleepPermissionState.denied ||
                              permission.state == SleepPermissionState.partial)
                          ? () async {
                              await _sleepPermissionController.requestAccess(context);
                              if (!mounted) return;
                              setState(() {});
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.refresh_cw),
                      title: Text(l10n.sleepImportNowTitle),
                      subtitle: Text(l10n.sleepImportNowSubtitle),
                      trailing: const Icon(LucideIcons.chevron_right),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final l10n = AppLocalizations.of(context)!;
                        SleepSyncResult? importResult;

                        final success = await LongRunningOperationOverlay.run(
                          context: context,
                          title: l10n.sleepSyncTitle,
                          initialStatus: l10n.sleepSyncTitle,
                          icon: LucideIcons.refresh_cw,
                          operation: (token, updateProgress) async {
                            importResult = await _sleepSyncService.importRecent(
                              lookbackDays: 365,
                              forceFullSync: true,
                              token: token,
                              onProgress: (index, total) {
                                final statusText = index == 0
                                    ? l10n.sleepSyncTitle
                                    : l10n.progressImportingNight(index, total);
                                final progressValue = index == 0
                                    ? -1.0
                                    : (total > 0 ? index / total : 0.0);
                                updateProgress(statusText, progressValue);
                              },
                            );
                          },
                        );

                        if (!mounted) return;
                        setState(() {
                          _hasChanges = true;
                        });

                        final res = importResult;
                        if (res != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                res.success
                                    ? l10n.sleepImportFinishedSessions(
                                        res.importedSessions)
                                    : (res.message ??
                                        l10n.sleepImportUnavailableCheckPermissions),
                              ),
                            ),
                          );
                        } else if (!success) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.snackbarImportError),
                            ),
                          );
                        }
                        await _sleepPermissionController.refresh();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
