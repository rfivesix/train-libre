import 'dart:io';

import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/health/health_models.dart';
import '../../../services/health/health_platform_steps.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../util/permission_dialogs.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../sleep/platform/permissions/sleep_permission_controller.dart';
import '../../sleep/platform/permissions/sleep_permission_models.dart';
import '../../sleep/platform/permissions/healthkit_sleep_permissions_service.dart';
import '../../sleep/platform/permissions/health_connect_sleep_permissions_service.dart';
import '../../sleep/platform/sleep_platform_channel.dart';

class StepsSettingsScreen extends StatefulWidget {
  const StepsSettingsScreen({super.key});

  @override
  State<StepsSettingsScreen> createState() => _StepsSettingsScreenState();
}

class _StepsSettingsScreenState extends State<StepsSettingsScreen> {
  final StepsSyncService _stepsSyncService = StepsSyncService();
  late final SleepPermissionController _permissionController;
  bool _stepsTrackingEnabled = false;
  bool _requesting = false;
  StepsProviderFilter _stepsProviderFilter = StepsProviderFilter.all;
  StepsSourcePolicy _stepsSourcePolicy = StepsSourcePolicy.autoDominant;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _permissionController = SleepPermissionController(Platform.isIOS
        ? const HealthKitSleepPermissionsService(
            HealthKitSleepMethodChannelBridge())
        : const HealthConnectSleepPermissionsService(
            HealthConnectSleepMethodChannelBridge()));
    _loadStepsSettings();
  }

  @override
  void dispose() {
    _permissionController.state.dispose();
    super.dispose();
  }

  Future<void> _loadStepsSettings() async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final sourcePolicy = await _stepsSyncService.getSourcePolicy();
    if (!mounted) return;
    setState(() {
      _stepsTrackingEnabled = enabled;
      _stepsProviderFilter = providerFilter;
      _stepsSourcePolicy = sourcePolicy;
    });
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
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.steps,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: l10n.steps),
          ValueListenableBuilder<SleepPermissionStatus>(
            valueListenable: _permissionController.state,
            builder: (context, permission, _) {
              return Column(
                children: [
                  AppSettingsRow.switchTile(
                    title: l10n.stepsSettingsEnableTrackingTitle,
                    subtitle: l10n.stepsSettingsEnableTrackingSubtitle,
                    leading: const Icon(LucideIcons.footprints),
                    value: _stepsTrackingEnabled,
                    onChanged: _requesting ? null : _setEnabled,
                  ),
                  const Divider(height: 1),
                  AppSettingsRow(
                    title: l10n.sleepHealthConnectionStatusTitle,
                    leading: const Icon(LucideIcons.shield_check),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusSubtitle(permission, l10n)),
                        const SizedBox(height: 4),
                        Text(
                          permission.state == SleepPermissionState.ready
                              ? (Platform.isIOS
                                  ? l10n.sleepDataStatusSubtitleIos
                                  : l10n.sleepDataStatusSubtitle)
                              : (permission.state ==
                                          SleepPermissionState.denied ||
                                      permission.state ==
                                          SleepPermissionState.partial
                                  ? l10n.sleepNoPermissionSubtitle
                                  : l10n.sleepFeatureUnavailableSubtitle),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                : (permission.state ==
                                            SleepPermissionState.denied ||
                                        permission.state ==
                                            SleepPermissionState.partial
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
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(
                    title: l10n.stepsSettingsSourcePolicyTitle,
                    autoUpperCase: false,
                  ),
                  AppSettingsRow.radioTile(
                    title: l10n.stepsSettingsSourcePolicyAutoDominant,
                    subtitle: l10n.stepsSettingsSourcePolicyAutoDominantSubtitle,
                    selected: _stepsSourcePolicy == StepsSourcePolicy.autoDominant,
                    onTap: () async {
                      await _stepsSyncService
                          .setSourcePolicy(StepsSourcePolicy.autoDominant);
                      if (!mounted) return;
                      setState(() {
                        _stepsSourcePolicy = StepsSourcePolicy.autoDominant;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  AppSettingsRow.radioTile(
                    title: l10n.stepsSettingsSourcePolicyMaxPerHour,
                    subtitle: l10n.stepsSettingsSourcePolicyMaxPerHourSubtitle,
                    selected: _stepsSourcePolicy == StepsSourcePolicy.maxPerHour,
                    onTap: () async {
                      await _stepsSyncService
                          .setSourcePolicy(StepsSourcePolicy.maxPerHour);
                      if (!mounted) return;
                      setState(() {
                        _stepsSourcePolicy = StepsSourcePolicy.maxPerHour;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(
                    title: l10n.stepsSettingsProviderFilterTitle,
                    autoUpperCase: false,
                  ),
                  AppSettingsRow.radioTile(
                    title: l10n.filterAll,
                    selected: _stepsProviderFilter == StepsProviderFilter.all,
                    onTap: () async {
                      await _stepsSyncService
                          .setProviderFilter(StepsProviderFilter.all);
                      if (!mounted) return;
                      setState(() {
                        _stepsProviderFilter = StepsProviderFilter.all;
                        _hasChanges = true;
                      });
                    },
                  ),
                  if (Platform.isIOS) ...[
                    const Divider(height: 1),
                    AppSettingsRow.radioTile(
                      title: l10n.statisticsProviderAppleHealth,
                      selected: _stepsProviderFilter == StepsProviderFilter.apple,
                      onTap: () async {
                        await _stepsSyncService
                            .setProviderFilter(StepsProviderFilter.apple);
                        if (!mounted) return;
                        setState(() {
                          _stepsProviderFilter = StepsProviderFilter.apple;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                  if (Platform.isAndroid) ...[
                    const Divider(height: 1),
                    AppSettingsRow.radioTile(
                      title: l10n.statisticsProviderHealthConnect,
                      selected: _stepsProviderFilter == StepsProviderFilter.google,
                      onTap: () async {
                        await _stepsSyncService
                            .setProviderFilter(StepsProviderFilter.google);
                        if (!mounted) return;
                        setState(() {
                          _stepsProviderFilter = StepsProviderFilter.google;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _requesting = value);
    await _stepsSyncService.setTrackingEnabled(value);
    if (!mounted) return;

    if (value) {
      const platform = HealthPlatformSteps();
      final availability = await platform.getAvailability();
      if (!mounted || !context.mounted) return;
      if (availability == StepsAvailability.available) {
        final currentL10n = AppLocalizations.of(context)!;
        final confirmed = await showPrePermissionDialog(
          context: context,
          title: currentL10n.health_permission_dialog_title,
          body: currentL10n.health_permission_dialog_body,
          continueLabel: currentL10n.health_permission_continue,
          cancelLabel: currentL10n.health_permission_not_now,
        );
        if (!mounted || !context.mounted) return;
        if (confirmed) {
          await platform.requestPermissions();
          _stepsSyncService.sync();
          await _permissionController.refresh();
        } else {
          await _stepsSyncService.setTrackingEnabled(false);
          value = false;
        }
      } else {
        await _permissionController.refresh();
      }
    } else {
      await _permissionController.refresh();
    }

    if (mounted) {
      setState(() {
        _stepsTrackingEnabled = value;
        _requesting = false;
        _hasChanges = true;
      });
    }
  }

  Future<void> _requestAccess() async {
    final currentL10n = AppLocalizations.of(context)!;
    final confirmed = await showPrePermissionDialog(
      context: context,
      title: currentL10n.health_permission_dialog_title,
      body: currentL10n.health_permission_dialog_body,
      continueLabel: currentL10n.health_permission_continue,
      cancelLabel: currentL10n.health_permission_not_now,
    );
    if (!mounted || !confirmed) return;

    setState(() => _requesting = true);
    const platform = HealthPlatformSteps();
    await platform.requestPermissions();
    _stepsSyncService.sync();
    await _permissionController.refresh();

    if (!mounted) return;
    setState(() => _requesting = false);
  }
}
