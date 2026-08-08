// lib/features/settings/presentation/widgets/icloud_sync_card.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../core/infrastructure/icloud_sync_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/cancellation_token.dart';
import '../../../../widgets/common/long_running_operation_overlay.dart';
import '../../../../widgets/common/glass_menu.dart';
import '../../../../widgets/common/platform_adaptive_switch.dart';
import '../../../../widgets/common/app_button.dart';

/// A settings card (iOS/macOS only) that lets the user enable/disable
/// automatic iCloud backup and trigger a manual backup.
///
/// Rendered inside [DataManagementScreen] below the existing auto-backup card.
class ICloudSyncCard extends StatefulWidget {
  /// Called when the user initiates a manual "Backup Now" action.
  final Future<bool> Function({void Function(double progress)? onProgress})
      onBackupNow;

  const ICloudSyncCard({super.key, required this.onBackupNow});

  @override
  State<ICloudSyncCard> createState() => _ICloudSyncCardState();
}

class _ICloudSyncCardState extends State<ICloudSyncCard> {
  bool _isEnabled = false;
  bool _isBackingUp = false;
  bool? _lastBackupSuccess;
  String? _nativeDiagnosticLog;
  DateTime? _lastSyncDate;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await ICloudSyncService.instance.isSyncEnabled();
    final lastSync = await ICloudSyncService.instance.getLastSyncTimestamp();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _lastSyncDate = lastSync;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    await ICloudSyncService.instance.setSyncEnabled(value);
    setState(() {
      _isEnabled = value;
      _lastBackupSuccess = null;
    });
    // Immediately trigger an initial backup when the user enables the feature.
    if (value) {
      await _runBackupNow();
    }
  }

  Future<void> _runBackupNow() async {
    setState(() {
      _isBackingUp = true;
      _lastBackupSuccess = null;
      _nativeDiagnosticLog = null;
    });

    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    Object? capturedError;
    StackTrace? capturedStackTrace;

    try {
      success = await LongRunningOperationOverlay.run(
        context: context,
        title: l10n.icloudBackupNow,
        initialStatus: 'Starting upload...',
        icon: LucideIcons.cloud_upload,
        operation: (token, updateProgress) async {
          try {
            await widget.onBackupNow(
              onProgress: (progress) {
                final normProgress =
                    progress > 1.0 ? progress / 100.0 : progress;
                final percent = (normProgress * 100).toStringAsFixed(0);
                updateProgress('Uploading... $percent%', normProgress);
              },
            );
          } catch (e, st) {
            capturedError = e;
            capturedStackTrace = st;
            throw OperationCanceledException();
          }
        },
      );
    } catch (e, stackTrace) {
      capturedError ??= e;
      capturedStackTrace ??= stackTrace;
    }

    if (capturedError != null) {
      final err = capturedError!;
      final st = capturedStackTrace ?? StackTrace.current;
      _bindErrorDump(
        err is PlatformException
            ? 'PlatformException [${err.code}]:\nMessage: ${err.message}\nDetails: ${err.details}'
            : err.toString(),
        st,
      );
      _showGlassErrorSheet(err, st);
    }

    if (mounted) {
      setState(() {
        _isBackingUp = false;
        if (_nativeDiagnosticLog == null) {
          _lastBackupSuccess = success;
        }
        if (success) {
          _lastSyncDate = DateTime.now();
        }
      });
    }
  }

  void _bindErrorDump(String rawMessage, StackTrace stackTrace) {
    final String dump =
        "=== RAW NATIVE EXCEPTION ===\n$rawMessage\n\n=== STACK TRACE ===\n${stackTrace.toString()}";
    setState(() {
      _nativeDiagnosticLog = dump;
      _lastBackupSuccess = false;
    });
  }

  void _showGlassErrorSheet(dynamic error, StackTrace stackTrace) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String technicalDetails =
        "=== RAW NATIVE EXCEPTION ===\n$error\n\n=== STACK TRACE ===\n$stackTrace";

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogCtx) {
        return GlassMenu(
          title: l10n.icloudSyncErrorTitle,
          subtitle: l10n.icloudSyncErrorHelp,
          onDismiss: () => Navigator.of(dialogCtx).pop(),
          items: [
            GlassMenuItem(
              icon: LucideIcons.copy,
              label: l10n.icloudSyncErrorCopyLog,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: technicalDetails));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.icloudSyncErrorCopied),
                      backgroundColor: theme.colorScheme.secondary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            GlassMenuItem(
              icon: LucideIcons.circle_x,
              label: l10n.icloudSyncErrorClose,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This card is strictly for Apple platforms only.
    if (!Platform.isIOS && !Platform.isMacOS) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with toggle ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.icloudAutoBackupTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PlatformAdaptiveSwitch(
                key: const Key('icloud_sync_toggle'),
                value: _isEnabled,
                onChanged: _isBackingUp ? null : _toggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingXS),
          Text(
            l10n.icloudAutoBackupDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            _lastSyncDate != null
                ? l10n.icloudLastSynced(
                    '${DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(_lastSyncDate!)}, ${DateFormat.Hm(Localizations.localeOf(context).languageCode).format(_lastSyncDate!)}')
                : l10n.icloudNeverSynced,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),

          // ── Status indicator ─────────────────────────────────────────────
          if (_lastBackupSuccess != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _lastBackupSuccess!
                      ? LucideIcons.circle_check
                      : LucideIcons.circle_x,
                  size: 16,
                  color: _lastBackupSuccess!
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: DesignConstants.spacingXS),
                Expanded(
                  child: Text(
                    _lastBackupSuccess!
                        ? l10n.icloudBackupSuccess
                        : l10n.icloudBackupFailed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _lastBackupSuccess!
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
          ],

          // ── Manual backup button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: _isBackingUp ? null : _runBackupNow,
              label: _isBackingUp
                  ? l10n.icloudBackupUploading
                  : l10n.icloudBackupNow,
              tooltip: _isBackingUp
                  ? l10n.icloudBackupUploading
                  : l10n.icloudBackupNow,
            ),
          ),

          // ── Alpha Diagnostics Console ────────────────────────────────────
          if (_nativeDiagnosticLog != null) ...[
            const SizedBox(height: DesignConstants.spacingL),
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                border: Border.all(color: theme.colorScheme.error, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NATIVE ICLOUD EXCEPTION',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(DesignConstants.spacingS),
                    color: Colors.black,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _nativeDiagnosticLog!,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11.0,
                          color: Colors.greenAccent,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  AppButton.primary(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: _nativeDiagnosticLog!));
                      if (context.mounted) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.icloudSyncErrorCopied),
                            backgroundColor: theme.colorScheme.secondary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    label: 'COPY RAW LOGS',
                    tooltip: 'COPY RAW LOGS',
                    icon: LucideIcons.copy,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
