import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/app_button.dart';

/// Glass accessory controls shown above the keyboard on workout screens.
class WorkoutKeyboardAccessoryBar extends StatefulWidget {
  const WorkoutKeyboardAccessoryBar({super.key});

  @override
  State<WorkoutKeyboardAccessoryBar> createState() =>
      _WorkoutKeyboardAccessoryBarState();
}

class _WorkoutKeyboardAccessoryBarState
    extends State<WorkoutKeyboardAccessoryBar> with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateKeyboardHeight());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _updateKeyboardHeight();

  void _updateKeyboardHeight() {
    if (!mounted) return;
    final view = View.of(context);
    final height = view.viewInsets.bottom / view.devicePixelRatio;
    if (height != _keyboardHeight) setState(() => _keyboardHeight = height);
  }

  void _insertHyphen() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final editable =
        focusContext?.findAncestorWidgetOfExactType<EditableText>();
    if (editable == null ||
        editable.keyboardType.index != TextInputType.number.index) {
      return;
    }

    final controller = editable.controller;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start;
    final end = selection.end;
    final text = value.text.replaceRange(start, end, '-');
    controller.value = value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: start + 1),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_keyboardHeight <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F7),
        elevation: 8,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.secondary(
                  label: '-',
                  semanticsLabel: 'Insert hyphen',
                  size: AppButtonSize.small,
                  onPressed: _insertHyphen,
                ),
                const SizedBox(width: 8),
                AppButton.primary(
                  label: l10n.doneButtonLabel,
                  size: AppButtonSize.small,
                  onPressed: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
