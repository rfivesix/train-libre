import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/health/apple_health_weight_import.dart';
import '../../../services/health/health_connect_weight_import.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';

/// Health reads belong with body measurements, not with the one-way export.
/// The import is opt-in and then runs again when the app next cold-starts.
class MeasurementImportSettingsScreen extends StatefulWidget {
  const MeasurementImportSettingsScreen({super.key});

  @override
  State<MeasurementImportSettingsScreen> createState() =>
      _MeasurementImportSettingsScreenState();
}

class _MeasurementImportSettingsScreenState
    extends State<MeasurementImportSettingsScreen> {
  late final WeightImportService _service;
  HealthConnectWeightImportStatus? _status;
  bool _enabled = false;
  bool _importing = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _service = Platform.isIOS
        ? AppleHealthWeightImportService()
        : HealthConnectWeightImportService();
    _load();
  }

  Future<void> _load() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final enabled = await _service.isEnabled();
      final status = await _service.getStatus();
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _status = status;
      });
    } on MissingPluginException {
      // Native channels require a full app relaunch after an app update. Keep
      // this screen usable during development hot restarts.
      if (mounted) setState(() => _status = null);
    }
  }

  Future<void> _toggle(bool enabled) async {
    if (!enabled) {
      await _service.setEnabled(false);
      _changed = true;
      await _load();
      return;
    }
    setState(() => _importing = true);
    try {
      final result = await _service.requestAccessAndImport();
      if (mounted && result != null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.healthConnectWeightImportResult(
              result.imported,
              result.updated,
            )),
          ),
        );
      }
      _changed = result != null;
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.code)),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
      await _load();
    }
  }

  Future<void> _importNow() async {
    setState(() => _importing = true);
    try {
      final result = await _service.importNow();
      if (mounted && result != null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.healthConnectWeightImportResult(
              result.imported,
              result.updated,
            )),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.code)),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIos = Platform.isIOS;
    final title = isIos
        ? l10n.appleHealthWeightImportTitle
        : l10n.healthConnectWeightImportTitle;
    final subtitle = isIos
        ? l10n.appleHealthWeightImportSubtitle
        : l10n.healthConnectWeightImportSubtitle;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.measurementsScreenTitle,
        leading: BackButton(onPressed: () => Navigator.pop(context, _changed)),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + top,
        ),
        children: [
          AppSectionHeader(title: l10n.measurementsScreenTitle),
          Column(
            children: [
              AppSettingsRow.switchTile(
                title: title,
                subtitle: subtitle,
                leading: const Icon(LucideIcons.download),
                value: _enabled,
                onChanged: _importing ? null : _toggle,
              ),
              const Divider(height: 1),
              AppSettingsRow(
                title: l10n.healthConnectWeightImportNow,
                leading: const Icon(LucideIcons.download),
                subtitle: _status?.available != true
                    ? isIos
                        ? l10n.healthExportPlatformUnavailable
                        : l10n.healthConnectWeightImportUnavailable
                    : (_status?.isLimited ?? true)
                        ? l10n.healthConnectWeightImportLimited
                        : l10n.healthConnectWeightImportReady,
                trailing: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        LucideIcons.download,
                        size: 20,
                        color: (_enabled && !_importing)
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                      ),
                onTap: _enabled && !_importing ? _importNow : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
