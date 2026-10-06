import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../../util/cancellation_token.dart';
import 'operation_progress_widget.dart';

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
    final l10n = AppLocalizations.of(context)!;

    final displayTitle = widget.title.isNotEmpty ? widget.title : _status;
    final displayDetail =
        widget.title.isNotEmpty && _status != widget.title ? _status : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: OperationProgressWidget(
                icon: widget.icon,
                title: displayTitle,
                detail: displayDetail,
                progress: _progress >= 0 && _progress <= 1.0 ? _progress : null,
                action: TextButton(
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
            ),
          ),
        ),
      ),
    );
  }
}
