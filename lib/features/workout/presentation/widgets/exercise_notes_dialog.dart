import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ExerciseNotesDialog extends StatefulWidget {
  final String? initialNotes;
  final Function(String) onSave;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const ExerciseNotesDialog({
    super.key,
    this.initialNotes,
    required this.onSave,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  State<ExerciseNotesDialog> createState() => _ExerciseNotesDialogState();
}

class _ExerciseNotesDialogState extends State<ExerciseNotesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes ?? '');
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.exerciseNoteHint,
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
            if (widget.initialNotes != null &&
                widget.initialNotes!.isNotEmpty) ...[
              IconButton(
                icon: Icon(
                  LucideIcons.trash_2,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: l10n.deleteNoteTooltip,
                onPressed: widget.onDelete,
              ),
              const SizedBox(width: DesignConstants.spacingS),
            ],
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
                  widget.onSave(_controller.text.trim());
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
