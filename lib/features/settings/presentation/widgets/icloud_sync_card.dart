// lib/features/settings/presentation/widgets/icloud_sync_card.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/infrastructure/icloud_sync_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/platform_adaptive_switch.dart';

/// A settings card (iOS/macOS only) that lets the user enable/disable
/// automatic iCloud backup and trigger a manual backup.
///
/// Rendered inside [DataManagementScreen] below the existing auto-backup card.
class ICloudSyncCard extends StatefulWidget {
  /// Called when the user initiates a manual "Backup Now" action.
  final Future<bool> Function() onBackupNow;

  const ICloudSyncCard({super.key, required this.onBackupNow});

  @override
  State<ICloudSyncCard> createState() => _ICloudSyncCardState();
}

class _ICloudSyncCardState extends State<ICloudSyncCard> {
  bool _isEnabled = false;
  bool _isBackingUp = false;
  bool? _lastBackupSuccess;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await ICloudSyncService.instance.isSyncEnabled();
    if (mounted) setState(() => _isEnabled = enabled);
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
    });
    final success = await widget.onBackupNow();
    if (mounted) {
      setState(() {
        _isBackingUp = false;
        _lastBackupSuccess = success;
      });
    }
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
            child: OutlinedButton.icon(
              key: const Key('icloud_backup_now_button'),
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.cloud_upload),
              label: Text(
                _isBackingUp
                    ? l10n.icloudBackupUploading
                    : l10n.icloudBackupNow,
              ),
              onPressed: _isBackingUp ? null : _runBackupNow,
            ),
          ),
        ],
      ),
    );
  }
}
