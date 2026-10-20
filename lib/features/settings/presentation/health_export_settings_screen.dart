import 'dart:io';

import 'package:flutter/material.dart';

import '../../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../../health_export/export_service.dart';
import '../../health_export/models/export_models.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class HealthExportSettingsScreen extends StatefulWidget {
  const HealthExportSettingsScreen({super.key});

  @override
  State<HealthExportSettingsScreen> createState() =>
      _HealthExportSettingsScreenState();
}

class _HealthExportSettingsScreenState
    extends State<HealthExportSettingsScreen> {
  late final HealthExportService _healthExportService;
  Map<HealthExportPlatform, HealthExportPlatformStatus> _exportStatuses = {
    for (final platform in HealthExportPlatform.values)
      platform: HealthExportPlatformStatus.initial(platform),
  };
  bool _appleExportEnabled = false;
  bool _healthConnectExportEnabled = false;
  bool _isAppleExporting = false;
  bool _isHealthConnectExporting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _healthExportService = HealthExportService(
      adapters: [AppleHealthExportAdapter(), HealthConnectExportAdapter()],
    );
    _loadHealthExportSettings();
  }

  Future<void> _loadHealthExportSettings() async {
    final appleEnabled = await _healthExportService.isPlatformEnabled(
      HealthExportPlatform.appleHealth,
    );
    final healthConnectEnabled = await _healthExportService.isPlatformEnabled(
      HealthExportPlatform.healthConnect,
    );
    final statuses = await _healthExportService.getStatuses();
    if (!mounted) return;
    setState(() {
      _appleExportEnabled = appleEnabled;
      _healthConnectExportEnabled = healthConnectEnabled;
      _exportStatuses = statuses;
    });
  }

  Future<void> _toggleHealthExport({
    required HealthExportPlatform platform,
    required bool enabled,
  }) async {
    if (enabled) {
      final permission =
          await _healthExportService.requestPermissions(platform);
      if (!permission.success) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizeHealthExportMessage(
                permission.message ?? l10n.healthExportPermissionDenied,
                l10n,
              ),
            ),
          ),
        );
      }
    } else {
      await _healthExportService.setPlatformEnabled(platform, false);
    }
    await _loadHealthExportSettings();
    if (!mounted) return;
    setState(() => _hasChanges = true);
  }

  Future<void> _exportNow(HealthExportPlatform platform) async {
    if (!mounted) return;
    setState(() {
      if (platform == HealthExportPlatform.appleHealth) {
        _isAppleExporting = true;
      } else {
        _isHealthConnectExporting = true;
      }
    });

    // A manual export is also the recovery path when permissions were revoked
    // or a newer app version needs additional HealthKit read scopes.
    final permission = await _healthExportService.requestPermissions(platform);
    final result = permission.success
        ? await _healthExportService.exportNow(platform)
        : permission;
    await _loadHealthExportSettings();
    if (!mounted) return;

    setState(() {
      if (platform == HealthExportPlatform.appleHealth) {
        _isAppleExporting = false;
      } else {
        _isHealthConnectExporting = false;
      }
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_healthExportResultMessage(result, context))),
    );
  }

  String _exportPlatformTitle(
    HealthExportPlatform platform,
    AppLocalizations l10n,
  ) {
    return switch (platform) {
      HealthExportPlatform.appleHealth => l10n.healthExportAppleHealthTitle,
      HealthExportPlatform.healthConnect => l10n.healthExportHealthConnectTitle,
    };
  }

  String _domainLabel(HealthExportDomain domain, AppLocalizations l10n) {
    return switch (domain) {
      HealthExportDomain.measurements => l10n.measurementsScreenTitle,
      HealthExportDomain.nutritionHydration =>
        l10n.healthExportDomainNutritionHydration,
      HealthExportDomain.workouts => l10n.healthExportDomainWorkouts,
    };
  }

  String _stateLabel(HealthExportState state, AppLocalizations l10n) {
    return switch (state) {
      HealthExportState.idle => l10n.healthExportStateIdle,
      HealthExportState.exporting => l10n.healthExportStateExporting,
      HealthExportState.success => l10n.healthExportStateSuccess,
      HealthExportState.failed => l10n.healthExportStateFailed,
      HealthExportState.permissionRequired =>
        l10n.healthExportStatePermissionRequired,
      HealthExportState.disabled => l10n.healthExportStateDisabled,
    };
  }

  IconData _exportStateIcon(HealthExportState state) {
    return switch (state) {
      HealthExportState.success => LucideIcons.circle_check,
      HealthExportState.exporting => LucideIcons.refresh_cw,
      HealthExportState.failed => LucideIcons.triangle_alert,
      HealthExportState.permissionRequired => LucideIcons.shield_alert,
      HealthExportState.disabled => LucideIcons.toggle_left,
      HealthExportState.idle => LucideIcons.hourglass,
    };
  }

  Color _exportStateColor(BuildContext context, HealthExportState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      HealthExportState.success => Colors.green,
      HealthExportState.exporting => scheme.primary,
      HealthExportState.failed => scheme.error,
      HealthExportState.permissionRequired => scheme.error,
      HealthExportState.disabled => scheme.outline,
      HealthExportState.idle => scheme.outline,
    };
  }

  String _healthExportResultMessage(
    HealthExportResult result,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (result.success) {
      return l10n.healthExportResultComplete;
    }
    return _localizeHealthExportMessage(
      result.message ?? l10n.healthExportResultFailed,
      l10n,
    );
  }

  String _localizeHealthExportMessage(String message, AppLocalizations l10n) {
    // Keep in sync with HealthExportService fallback messages.
    // Unknown values are returned unchanged to preserve diagnostics.
    return switch (message) {
      'Adapter unavailable' => l10n.healthExportAdapterUnavailable,
      'Platform unavailable' => l10n.healthExportPlatformUnavailable,
      'Platform not installed' => l10n.healthExportPlatformNotInstalled,
      'Export disabled' => l10n.healthExportExportDisabled,
      'Permission denied' => l10n.healthExportPermissionDenied,
      _ => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.healthExportTitle,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: l10n.healthExportTitle),
          Column(
            children: [
              if (Platform.isIOS) ...[
                AppSettingsRow.switchTile(
                  title: _exportPlatformTitle(
                    HealthExportPlatform.appleHealth,
                    l10n,
                  ),
                  subtitle: l10n.healthExportAppleHealthSubtitle,
                  leading: const Icon(LucideIcons.heart),
                  value: _appleExportEnabled,
                  onChanged: (value) => _toggleHealthExport(
                    platform: HealthExportPlatform.appleHealth,
                    enabled: value,
                  ),
                ),
                AppSettingsRow(
                  title: l10n.healthExportAppleHealthStatusTitle,
                  leading: const Icon(LucideIcons.shield_check),
                  subtitle: HealthExportDomain.values.map((domain) {
                    final status =
                        _exportStatuses[HealthExportPlatform.appleHealth]
                            ?.statusFor(domain);
                    return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
                  }).join(' · '),
                  trailing: _isAppleExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _exportStateIcon(
                            _exportStatuses[HealthExportPlatform.appleHealth]
                                    ?.statusFor(HealthExportDomain.measurements)
                                    .state ??
                                HealthExportState.idle,
                          ),
                          size: 20,
                          color: _exportStateColor(
                            context,
                            _exportStatuses[HealthExportPlatform.appleHealth]
                                    ?.statusFor(HealthExportDomain.measurements)
                                    .state ??
                                HealthExportState.idle,
                          ),
                        ),
                  onTap: _appleExportEnabled
                      ? () => _exportNow(HealthExportPlatform.appleHealth)
                      : null,
                ),
              ],
              if (Platform.isAndroid) ...[
                AppSettingsRow.switchTile(
                  title: _exportPlatformTitle(
                    HealthExportPlatform.healthConnect,
                    l10n,
                  ),
                  subtitle: l10n.healthExportHealthConnectSubtitle,
                  leading: const Icon(LucideIcons.heart),
                  value: _healthConnectExportEnabled,
                  onChanged: (value) => _toggleHealthExport(
                    platform: HealthExportPlatform.healthConnect,
                    enabled: value,
                  ),
                ),
                AppSettingsRow(
                  title: l10n.healthExportHealthConnectStatusTitle,
                  leading: const Icon(LucideIcons.shield_check),
                  subtitle: HealthExportDomain.values.map((domain) {
                    final status =
                        _exportStatuses[HealthExportPlatform.healthConnect]
                            ?.statusFor(domain);
                    return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
                  }).join(' · '),
                  trailing: _isHealthConnectExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _exportStateIcon(
                            _exportStatuses[HealthExportPlatform.healthConnect]
                                    ?.statusFor(HealthExportDomain.measurements)
                                    .state ??
                                HealthExportState.idle,
                          ),
                          size: 20,
                          color: _exportStateColor(
                            context,
                            _exportStatuses[HealthExportPlatform.healthConnect]
                                    ?.statusFor(HealthExportDomain.measurements)
                                    .state ??
                                HealthExportState.idle,
                          ),
                        ),
                  onTap: _healthConnectExportEnabled
                      ? () => _exportNow(HealthExportPlatform.healthConnect)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
