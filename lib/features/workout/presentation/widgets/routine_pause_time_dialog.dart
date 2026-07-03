import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';
import '../../../../generated/app_localizations.dart';

/// A dialog that lets the user pick a pause/rest duration using an iOS-style
/// minute:second scroll wheel, matching the glass picker styling used in the
/// food-logging bottom sheets.
class RoutinePauseTimeDialog extends StatefulWidget {
  final int? initialPauseSeconds;
  final Function(int?) onSave;
  final VoidCallback onCancel;

  const RoutinePauseTimeDialog({
    super.key,
    this.initialPauseSeconds,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<RoutinePauseTimeDialog> createState() => _RoutinePauseTimeDialogState();
}

class _RoutinePauseTimeDialogState extends State<RoutinePauseTimeDialog> {
  late Duration _selectedDuration;

  @override
  void initState() {
    super.initState();
    final seconds =
        (widget.initialPauseSeconds != null && widget.initialPauseSeconds! > 0)
            ? widget.initialPauseSeconds!
            : 0;
    _selectedDuration = Duration(
      minutes: seconds ~/ 60,
      seconds: seconds % 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: DesignConstants.spacingS),
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                ),
              ),
            ),
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.ms,
              initialTimerDuration: _selectedDuration,
              onTimerDurationChanged: (Duration newDuration) {
                _selectedDuration = newDuration;
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: DesignConstants.spacingL,
            right: DesignConstants.spacingL,
            top: DesignConstants.spacingXS,
            bottom: DesignConstants.spacingM,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    final totalSeconds = _selectedDuration.inSeconds;
                    widget.onSave(totalSeconds > 0 ? totalSeconds : null);
                  },
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
