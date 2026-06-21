import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/time_util.dart';

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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPauseSeconds == null || widget.initialPauseSeconds == 0
          ? ''
          : formatPauseDuration(widget.initialPauseSeconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [TimerInputFormatter()],
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final seconds = parsePauseDuration(_controller.text);
            widget.onSave(seconds);
          },
          decoration: InputDecoration(
            labelText: l10n.restTimerLabel,
            hintText: "00:00",
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Row(
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
                onPressed: () {
                  final seconds = parsePauseDuration(_controller.text);
                  widget.onSave(seconds);
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
