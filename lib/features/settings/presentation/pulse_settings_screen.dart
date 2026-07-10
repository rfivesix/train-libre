import 'package:flutter/material.dart';

import '../../pulse/application/pulse_tracking_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../util/permission_dialogs.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../sleep/platform/permissions/sleep_permission_controller.dart';
import '../../sleep/platform/permissions/sleep_permission_models.dart';
import '../../sleep/platform/permissions/healthkit_sleep_permissions_service.dart';
import '../../sleep/platform/permissions/health_connect_sleep_permissions_service.dart';
import '../../sleep/platform/sleep_platform_channel.dart';
import 'dart:io';

class PulseSettingsScreen extends StatefulWidget {
  const PulseSettingsScreen({
    super.key,
    PulseTrackingSettingsService? trackingService,
  }) : _trackingService = trackingService;

  final PulseTrackingSettingsService? _trackingService;

  @override
  State<PulseSettingsScreen> createState() => _PulseSettingsScreenState();
}

class _PulseSettingsScreenState extends State<PulseSettingsScreen> {
  late final PulseTrackingSettingsService _trackingService;
  late final SleepPermissionController _permissionController;
  bool _enabled = false;
  bool _requesting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _trackingService = widget._trackingService ?? PulseTrackingService();
    _permissionController = SleepPermissionController(
      Platform.isIOS
          ? const HealthKitSleepPermissionsService(HealthKitSleepMethodChannelBridge())
          : const HealthConnectSleepPermissionsService(HealthConnectSleepMethodChannelBridge())
    );
    _load();
  }

  @override
  void dispose() {
    _permissionController.state.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final enabled = await _trackingService.isTrackingEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
    await _permissionController.refresh();
  }

  String _statusSubtitle(SleepPermissionStatus status, AppLocalizations l10n) {
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

  IconData _statusIcon(SleepPermissionState state) {
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

  Color _statusColor(BuildContext context, SleepPermissionState state) {
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
    final copy = _PulseSettingsCopy(context);
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: copy.title,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: copy.title),
          ValueListenableBuilder<SleepPermissionStatus>(
            valueListenable: _permissionController.state,
            builder: (context, permission, _) {
              return SummaryCard(
                child: Column(
                  children: [
                    PlatformAdaptiveSwitchListTile(
                      key: const Key('pulse_tracking_toggle'),
                      secondary: const Icon(LucideIcons.heart),
                      title: Text(
                        copy.enableTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(copy.enableSubtitle),
                      value: _enabled,
                      onChanged: _requesting ? null : _setEnabled,
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
                          Text(_statusSubtitle(permission, l10n)),
                          const SizedBox(height: 4),
                          Text(
                            permission.state == SleepPermissionState.ready
                                ? l10n.sleepDataStatusSubtitle
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
                      trailing: _requesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              permission.state == SleepPermissionState.ready
                                  ? LucideIcons.circle_check
                                  : (permission.state == SleepPermissionState.denied ||
                                          permission.state == SleepPermissionState.partial
                                      ? LucideIcons.chevron_right
                                      : _statusIcon(permission.state)),
                              color: _statusColor(context, permission.state),
                            ),
                      onTap: (_requesting ||
                              permission.state == SleepPermissionState.ready)
                          ? null
                          : _requestAccess,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.info),
                      title: Text(copy.honestTitle),
                      subtitle: Text(copy.honestSubtitle),
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

  Future<void> _setEnabled(bool value) async {
    setState(() => _requesting = value);
    await _trackingService.setTrackingEnabled(value);
    if (!mounted) return;
    var granted = true;
    if (value) {
      final currentL10n = AppLocalizations.of(context)!;
      final confirmed = await showPrePermissionDialog(
        context: context,
        title: currentL10n.pulseSettingsPermissionTitle,
        body: currentL10n.pulseSettingsPermissionSubtitle,
        continueLabel: currentL10n.health_permission_continue,
        cancelLabel: '',
      );
      if (!mounted) return;
      if (confirmed) {
        granted = await _trackingService.requestPermissions();
        await _permissionController.refresh();
      } else {
        await _trackingService.setTrackingEnabled(false);
        granted = false;
        value = false;
      }
    } else {
      await _permissionController.refresh();
    }
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _requesting = false;
      _hasChanges = true;
    });
    if (value && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_PulseSettingsCopy(context).permissionFailed)),
      );
    }
  }

  Future<void> _requestAccess() async {
    final currentL10n = AppLocalizations.of(context)!;
    final confirmed = await showPrePermissionDialog(
      context: context,
      title: currentL10n.pulseSettingsPermissionTitle,
      body: currentL10n.pulseSettingsPermissionSubtitle,
      continueLabel: currentL10n.health_permission_continue,
      cancelLabel: '',
    );
    if (!mounted || !confirmed) return;

    setState(() => _requesting = true);
    final granted = await _trackingService.requestPermissions();
    await _permissionController.refresh();
    if (!mounted) return;
    setState(() => _requesting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? _PulseSettingsCopy(context).permissionGranted
              : _PulseSettingsCopy(context).permissionFailed,
        ),
      ),
    );
  }
}

class _PulseSettingsCopy {
  _PulseSettingsCopy(BuildContext context)
      : l10n = AppLocalizations.of(context)!;

  final AppLocalizations l10n;

  String get title => l10n.pulseTitle;
  String get enableTitle => l10n.pulseSettingsEnableTitle;
  String get enableSubtitle => l10n.pulseSettingsEnableSubtitle;
  String get permissionTitle => l10n.pulseSettingsPermissionTitle;
  String get permissionSubtitle => l10n.pulseSettingsPermissionSubtitle;
  String get honestTitle => l10n.analysis;
  String get honestSubtitle => l10n.pulseSettingsAnalysisSubtitle;
  String get permissionGranted => l10n.pulseSettingsPermissionGranted;
  String get permissionFailed => l10n.pulseSettingsPermissionFailed;
}
