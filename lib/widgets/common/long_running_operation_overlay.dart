import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

import '../../generated/app_localizations.dart';
import '../../util/cancellation_token.dart';

class LongRunningOperationOverlay extends StatefulWidget {
  final String title;
  final String initialStatus;
  final IconData icon;
  final Future<void> Function(
    CancellationToken token,
    void Function(String status, double progress) updateProgress,
  ) operation;

  const LongRunningOperationOverlay({
    super.key,
    required this.title,
    required this.initialStatus,
    required this.icon,
    required this.operation,
  });

  static Future<bool> run({
    required BuildContext context,
    required String title,
    required String initialStatus,
    required IconData icon,
    required Future<void> Function(
      CancellationToken token,
      void Function(String status, double progress) updateProgress,
    ) operation,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (dialogCtx) => LongRunningOperationOverlay(
          title: title,
          initialStatus: initialStatus,
          icon: icon,
          operation: (token, updateProgress) async {
            try {
              await operation(token, updateProgress);
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop(true);
              }
            } catch (e) {
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop(false);
              }
              if (e is! OperationCanceledException) {
                rethrow;
              }
            }
          },
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<LongRunningOperationOverlay> createState() =>
      _LongRunningOperationOverlayState();
}

class _LongRunningOperationOverlayState
    extends State<LongRunningOperationOverlay> {
  final CancellationToken _token = CancellationToken();
  String _status = '';
  double _progress = 0.0;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.operation(_token, _updateProgress);
    });
  }

  void _updateProgress(String status, double progress) {
    if (!mounted || _isCanceling) return;
    setState(() {
      _status = status;
      _progress = progress;
    });
  }

  void _cancel() {
    if (_isCanceling) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isCanceling = true;
      _status = l10n.cancelingAndRollingBack;
    });
    _token.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.icon,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 40),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignConstants.spacingL),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value:
                        _progress >= 0 && _progress <= 1.0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white10
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXXL),
                Center(
                  child: TextButton(
                    onPressed: _isCanceling ? null : _cancel,
                    child: Text(
                      _isCanceling ? "${l10n.cancel}..." : l10n.cancel,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
