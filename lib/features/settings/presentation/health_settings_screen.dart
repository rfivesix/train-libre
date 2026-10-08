import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../features/health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../../../features/health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../../../features/health_export/export_service.dart';
import '../../../features/health_export/models/export_models.dart';
import '../../../features/pulse/application/pulse_tracking_service.dart';
import '../../../features/sleep/platform/permissions/health_connect_sleep_permissions_service.dart';
import '../../../features/sleep/platform/permissions/healthkit_sleep_permissions_service.dart';
import '../../../features/sleep/platform/permissions/sleep_permission_controller.dart';
import '../../../features/sleep/platform/permissions/sleep_permission_models.dart';
import '../../../features/sleep/platform/sleep_platform_channel.dart';
import '../../../features/sleep/platform/sleep_sync_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/health/apple_health_weight_import.dart';
import '../../../services/health/health_connect_weight_import.dart';
import '../../../services/health/health_models.dart';
import '../../../services/health/health_platform_steps.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../util/design_constants.dart';
import '../../../util/permission_dialogs.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';

class HealthSettingsScreen extends StatefulWidget {
  const HealthSettingsScreen({
    super.key,
    required this.sleepSyncService,
    required this.sleepPermissionController,
  });

  final SleepSettingsService sleepSyncService;
  final SleepPermissionController sleepPermissionController;

  @override
  State<HealthSettingsScreen> createState() => _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends State<HealthSettingsScreen> {
  late final StepsSyncService _steps = StepsSyncService();
  late final PulseTrackingService _pulse = PulseTrackingService();
  late final WeightImportService _measurement = Platform.isIOS
      ? AppleHealthWeightImportService()
      : HealthConnectWeightImportService();
  late final HealthExportService _export = HealthExportService(
    adapters: [AppleHealthExportAdapter(), HealthConnectExportAdapter()],
  );
  late final SleepPermissionController _pulsePermissions =
      SleepPermissionController(Platform.isIOS
          ? const HealthKitSleepPermissionsService(
              HealthKitSleepMethodChannelBridge(),
            )
          : const HealthConnectSleepPermissionsService(
              HealthConnectSleepMethodChannelBridge(),
            ));

  bool _stepsEnabled = false;
  bool _sleepEnabled = false;
  bool _pulseEnabled = false;
  bool _measurementEnabled = false;
  bool _exportEnabled = false;
  bool _busy = false;
  bool _changed = false;
  StepsAvailability _stepsAvailability = StepsAvailability.notAvailable;
  HealthConnectWeightImportStatus? _measurementStatus;
  Map<HealthExportPlatform, HealthExportPlatformStatus> _exportStatuses = {};

  HealthExportPlatform get _platform => Platform.isIOS
      ? HealthExportPlatform.appleHealth
      : HealthExportPlatform.healthConnect;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pulsePermissions.state.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        _steps.isTrackingEnabled(),
        widget.sleepSyncService.isTrackingEnabled(),
        _pulse.isTrackingEnabled(),
        _measurement.isEnabled(),
        _export.isPlatformEnabled(_platform),
        const HealthPlatformSteps().getAvailability(),
        _measurement.getStatus(),
        _export.getStatuses(),
      ]);
      if (!mounted) return;
      setState(() {
        _stepsEnabled = values[0] as bool;
        _sleepEnabled = values[1] as bool;
        _pulseEnabled = values[2] as bool;
        _measurementEnabled = values[3] as bool;
        _exportEnabled = values[4] as bool;
        _stepsAvailability = values[5] as StepsAvailability;
        _measurementStatus = values[6] as HealthConnectWeightImportStatus;
        _exportStatuses =
            values[7] as Map<HealthExportPlatform, HealthExportPlatformStatus>;
      });
      await Future.wait([
        widget.sleepPermissionController.refresh(),
        _pulsePermissions.refresh(),
      ]);
    } on MissingPluginException {
      // Native health channels may be absent during a hot restart.
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _setSteps(bool enabled) async {
    if (!enabled) {
      await _steps.setTrackingEnabled(false);
      _markChanged();
      await _load();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final availability = await _steps.getAvailability();
      if (availability != StepsAvailability.available) {
        _message(l10n.healthConnectWeightImportUnavailable);
        return;
      }
      if (!mounted) return;
      final confirmed = await showPrePermissionDialog(
        context: context,
        title: l10n.health_permission_dialog_title,
        body: l10n.health_permission_dialog_body,
        continueLabel: l10n.health_permission_continue,
        cancelLabel: l10n.health_permission_not_now,
      );
      if (!confirmed || !mounted) return;
      final granted = await _steps.requestPermissions();
      await _steps.setTrackingEnabled(granted);
      if (!granted) _message(l10n.sleepStatusDenied);
      _markChanged();
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setSleep(bool enabled) async {
    if (!enabled) {
      await widget.sleepSyncService.setTrackingEnabled(false);
      _markChanged();
      await _load();
      return;
    }
    await widget.sleepSyncService.setTrackingEnabled(enabled);
    if (!mounted) return;
    await widget.sleepPermissionController.requestAccess(context);
    _markChanged();
    await _load();
  }

  Future<void> _setPulse(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    if (!enabled) {
      await _pulse.setTrackingEnabled(false);
      _markChanged();
      await _load();
      return;
    }
    final confirmed = await showPrePermissionDialog(
      context: context,
      title: l10n.pulseSettingsPermissionTitle,
      body: l10n.pulseSettingsPermissionSubtitle,
      continueLabel: l10n.health_permission_continue,
      cancelLabel: '',
    );
    if (!mounted || !confirmed) return;
    final granted = await _pulse.requestPermissions();
    await _pulse.setTrackingEnabled(granted);
    if (!granted) _message(l10n.pulseSettingsPermissionFailed);
    _markChanged();
    await _load();
  }

  Future<void> _setMeasurement(bool enabled) async {
    if (!enabled) {
      await _measurement.setEnabled(false);
      _markChanged();
      await _load();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await _run(() async {
      final result = await _measurement.requestAccessAndImport();
      if (result != null) {
        _message(l10n.healthConnectWeightImportResult(
          result.imported,
          result.updated,
        ));
        _markChanged();
      }
    });
  }

  Future<void> _setExport(bool enabled) async {
    if (!enabled) {
      await _export.setPlatformEnabled(_platform, false);
      _markChanged();
      await _load();
      return;
    }
    await _run(() async {
      final result = await _export.requestPermissions(_platform);
      if (!result.success) {
        _message(_localizeExportMessage(result.message));
      } else {
        _markChanged();
      }
      await _load();
    });
  }

  Future<void> _syncSteps() {
    final l10n = AppLocalizations.of(context)!;
    return _run(() async {
      final result = await _steps.sync(forceRefresh: true);
      if (result.skipped) {
        _message(l10n.healthExportPlatformUnavailable);
      } else {
        _message(l10n.healthSettingsStepsSyncResult(result.upsertedCount));
      }
    });
  }

  Future<void> _syncSleep() {
    final l10n = AppLocalizations.of(context)!;
    return _run(() async {
      final result = await widget.sleepSyncService.importRecent(
        lookbackDays: 365,
        forceFullSync: true,
      );
      _message(result.success
          ? l10n.healthSettingsSleepSyncResult(result.importedSessions)
          : (result.message ?? l10n.healthExportResultFailed));
    });
  }

  Future<void> _syncMeasurement() {
    final l10n = AppLocalizations.of(context)!;
    return _run(() async {
      final result = await _measurement.importNow();
      if (result != null) {
        _message(l10n.healthConnectWeightImportResult(
          result.imported,
          result.updated,
        ));
      }
      await _load();
    });
  }

  Future<void> _syncExport() {
    final l10n = AppLocalizations.of(context)!;
    return _run(() async {
      final permission = await _export.requestPermissions(_platform);
      final result =
          permission.success ? await _export.exportNow(_platform) : permission;
      _message(result.success
          ? l10n.healthExportResultComplete
          : _localizeExportMessage(result.message));
      await _load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _markChanged();
    } on PlatformException catch (error) {
      _message(error.message ?? error.code);
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _localizeExportMessage(String? message) {
    final l10n = AppLocalizations.of(context)!;
    return switch (message) {
      'Adapter unavailable' => l10n.healthExportAdapterUnavailable,
      'Platform unavailable' => l10n.healthExportPlatformUnavailable,
      'Platform not installed' => l10n.healthExportPlatformNotInstalled,
      'Export disabled' => l10n.healthExportExportDisabled,
      'Permission denied' => l10n.healthExportPermissionDenied,
      _ => message ?? l10n.healthExportResultFailed,
    };
  }

  String _permissionLabel(SleepPermissionStatus status) {
    final l10n = AppLocalizations.of(context)!;
    if (status.message?.isNotEmpty == true) return status.message!;
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

  String _stepsStatusLabel(AppLocalizations l10n) {
    if (_stepsAvailability != StepsAvailability.available) {
      return l10n.healthSettingsStepUnavailable;
    }
    return _stepsEnabled
        ? l10n.healthSettingsStepActive
        : l10n.healthSettingsStepAvailable;
  }

  String _exportStatusLabel() {
    final l10n = AppLocalizations.of(context)!;
    final statuses = _exportStatuses[_platform];
    if (statuses == null) return l10n.healthExportStateIdle;
    return HealthExportDomain.values.map((domain) {
      final status = statuses.statusFor(domain);
      final label = switch (status.state) {
        HealthExportState.idle => l10n.healthExportStateIdle,
        HealthExportState.exporting => l10n.healthExportStateExporting,
        HealthExportState.success => l10n.healthExportStateSuccess,
        HealthExportState.failed => l10n.healthExportStateFailed,
        HealthExportState.permissionRequired =>
          l10n.healthExportStatePermissionRequired,
        HealthExportState.disabled => l10n.healthExportStateDisabled,
      };
      return '${_domainLabel(domain)}: $label';
    }).join(' · ');
  }

  String _domainLabel(HealthExportDomain domain) {
    final l10n = AppLocalizations.of(context)!;
    return switch (domain) {
      HealthExportDomain.measurements => l10n.measurementsScreenTitle,
      HealthExportDomain.nutritionHydration =>
        l10n.healthExportDomainNutritionHydration,
      HealthExportDomain.workouts => l10n.healthExportDomainWorkouts,
    };
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _markChanged() {
    _changed = true;
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Column(
      children: [
        AppSettingsRow(
          title: title,
          subtitle: subtitle,
          leading: Icon(icon),
          onTap: _busy ? null : () => onChanged(!value),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value && actionLabel != null) ...[
                IconButton(
                  tooltip: actionLabel,
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : onAction,
                  icon: const Icon(LucideIcons.refresh_cw),
                ),
                const SizedBox(width: 4),
              ],
              PlatformAdaptiveSwitch(
                value: value,
                onChanged: _busy ? null : onChanged,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.healthSettingsTitle,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + top,
        ),
        children: [
          AppSectionHeader(
              title: Platform.isIOS ? 'Apple Health' : 'Health Connect'),
          ValueListenableBuilder<SleepPermissionStatus>(
            valueListenable: widget.sleepPermissionController.state,
            builder: (context, permission, _) => Column(children: [
              _row(
                icon: LucideIcons.footprints,
                title: l10n.stepsSettingsEnableTrackingTitle,
                subtitle: _stepsStatusLabel(l10n),
                value: _stepsEnabled,
                onChanged: _setSteps,
                actionLabel: l10n.healthSettingsSyncSteps,
                onAction: _syncSteps,
              ),
              _row(
                icon: LucideIcons.moon,
                title: l10n.sleepEnableTrackingTitle,
                subtitle: _permissionLabel(permission),
                value: _sleepEnabled,
                onChanged: _setSleep,
                actionLabel: l10n.sleepImportNowTitle,
                onAction: _syncSleep,
              ),
              ValueListenableBuilder<SleepPermissionStatus>(
                valueListenable: _pulsePermissions.state,
                builder: (context, pulsePermission, _) => _row(
                  icon: LucideIcons.heart_pulse,
                  title: l10n.pulseSettingsEnableTitle,
                  subtitle: _permissionLabel(pulsePermission),
                  value: _pulseEnabled,
                  onChanged: _setPulse,
                ),
              ),
              _row(
                icon: LucideIcons.ruler,
                title: Platform.isIOS
                    ? l10n.appleHealthWeightImportTitle
                    : l10n.healthConnectWeightImportTitle,
                subtitle: _measurementStatus?.available == true
                    ? ((_measurementStatus?.isLimited ?? false)
                        ? l10n.healthConnectWeightImportLimited
                        : l10n.healthConnectWeightImportReady)
                    : l10n.healthConnectWeightImportUnavailable,
                value: _measurementEnabled,
                onChanged: _setMeasurement,
                actionLabel: l10n.healthConnectWeightImportNow,
                onAction: _syncMeasurement,
              ),
              _row(
                icon: LucideIcons.heart,
                title: Platform.isIOS
                    ? l10n.healthExportAppleHealthTitle
                    : l10n.healthExportHealthConnectTitle,
                subtitle: _exportStatusLabel(),
                value: _exportEnabled,
                onChanged: _setExport,
                actionLabel: l10n.healthSettingsSyncExport,
                onAction: _syncExport,
              ),
            ]),
          ),
          if (_stepsAvailability == StepsAvailability.notAvailable)
            AppInfoRow(
              title: l10n.healthExportPlatformUnavailable,
              leading: const Icon(LucideIcons.info),
            ),
        ],
      ),
    );
  }
}
