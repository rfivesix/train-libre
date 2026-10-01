import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../../health_export/export_service.dart';
import '../../health_export/models/export_models.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../services/health/health_connect_weight_import.dart';
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
  final HealthConnectWeightImportService _weightImportService =
      HealthConnectWeightImportService();
  HealthConnectWeightImportStatus? _weightImportStatus;
  bool _weightImportEnabled = false;
  bool _isWeightImporting = false;
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
    final weightImportEnabled =
        Platform.isAndroid ? await _weightImportService.isEnabled() : false;
    final weightImportStatus =
        Platform.isAndroid ? await _weightImportService.getStatus() : null;
    if (!mounted) return;
    setState(() {
      _appleExportEnabled = appleEnabled;
      _healthConnectExportEnabled = healthConnectEnabled;
      _exportStatuses = statuses;
      _weightImportEnabled = weightImportEnabled;
      _weightImportStatus = weightImportStatus;
    });
  }

  Future<void> _toggleWeightImport(bool enabled) async {
    if (!enabled) {
      await _weightImportService.setEnabled(false);
      await _loadHealthExportSettings();
      return;
    }
    setState(() => _isWeightImporting = true);
    try {
      final result = await _weightImportService.requestAccessAndImport();
      await _showWeightImportResult(result);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.code)),
        );
      }
    } finally {
      if (mounted) setState(() => _isWeightImporting = false);
      await _loadHealthExportSettings();
    }
  }

  Future<void> _importWeightsNow() async {
    setState(() => _isWeightImporting = true);
    try {
      final result = await _weightImportService.importNow();
      await _showWeightImportResult(result);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.code)),
        );
      }
    } finally {
      if (mounted) setState(() => _isWeightImporting = false);
      await _loadHealthExportSettings();
    }
  }

  Future<void> _showWeightImportResult(
    HealthConnectWeightImportResult? result,
  ) async {
    if (!mounted || result == null) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.healthConnectWeightImportResult(
            result.imported,
            result.updated,
          ),
        ),
      ),
    );
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
          SummaryCard(
            child: Column(
              children: [
                if (Platform.isIOS) ...[
                  PlatformAdaptiveSwitchListTile(
                    secondary: const Icon(LucideIcons.heart),
                    title: Text(
                      _exportPlatformTitle(
                        HealthExportPlatform.appleHealth,
                        l10n,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.healthExportAppleHealthSubtitle,
                    ),
                    value: _appleExportEnabled,
                    onChanged: (value) => _toggleHealthExport(
                      platform: HealthExportPlatform.appleHealth,
                      enabled: value,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      _exportStateIcon(
                        _exportStatuses[HealthExportPlatform.appleHealth]
                                ?.statusFor(HealthExportDomain.measurements)
                                .state ??
                            HealthExportState.idle,
                      ),
                      color: _exportStateColor(
                        context,
                        _exportStatuses[HealthExportPlatform.appleHealth]
                                ?.statusFor(HealthExportDomain.measurements)
                                .state ??
                            HealthExportState.idle,
                      ),
                    ),
                    title: Text(
                      l10n.healthExportAppleHealthStatusTitle,
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.appleHealth]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
                      }).join(' · '),
                    ),
                    trailing: _isAppleExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.chevron_right),
                    onTap: _appleExportEnabled
                        ? () => _exportNow(HealthExportPlatform.appleHealth)
                        : null,
                  ),
                ],
                if (Platform.isAndroid) ...[
                  PlatformAdaptiveSwitchListTile(
                    secondary: const Icon(LucideIcons.heart),
                    title: Text(
                      _exportPlatformTitle(
                        HealthExportPlatform.healthConnect,
                        l10n,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.healthExportHealthConnectSubtitle,
                    ),
                    value: _healthConnectExportEnabled,
                    onChanged: (value) => _toggleHealthExport(
                      platform: HealthExportPlatform.healthConnect,
                      enabled: value,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      _exportStateIcon(
                        _exportStatuses[HealthExportPlatform.healthConnect]
                                ?.statusFor(HealthExportDomain.measurements)
                                .state ??
                            HealthExportState.idle,
                      ),
                      color: _exportStateColor(
                        context,
                        _exportStatuses[HealthExportPlatform.healthConnect]
                                ?.statusFor(HealthExportDomain.measurements)
                                .state ??
                            HealthExportState.idle,
                      ),
                    ),
                    title: Text(
                      l10n.healthExportHealthConnectStatusTitle,
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.healthConnect]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
                      }).join(' · '),
                    ),
                    trailing: _isHealthConnectExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.chevron_right),
                    onTap: _healthConnectExportEnabled
                        ? () => _exportNow(HealthExportPlatform.healthConnect)
                        : null,
                  ),
                  const Divider(),
                  PlatformAdaptiveSwitchListTile(
                    secondary: const Icon(LucideIcons.scale),
                    title: Text(
                      l10n.healthConnectWeightImportTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.healthConnectWeightImportSubtitle),
                    value: _weightImportEnabled,
                    onChanged: _isWeightImporting ? null : _toggleWeightImport,
                  ),
                  ListTile(
                    leading: _isWeightImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.download),
                    title: Text(l10n.healthConnectWeightImportNow),
                    subtitle: Text(
                      _weightImportStatus?.available != true
                          ? l10n.healthConnectWeightImportUnavailable
                          : (_weightImportStatus?.isLimited ?? true)
                              ? l10n.healthConnectWeightImportLimited
                              : l10n.healthConnectWeightImportReady,
                    ),
                    enabled: _weightImportEnabled && !_isWeightImporting,
                    onTap: _weightImportEnabled && !_isWeightImporting
                        ? _importWeightsNow
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
