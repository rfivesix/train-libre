// lib/widgets/set_type_chip.dart

import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';

/// A visual indicator for a workout set's type (e.g., normal, warmup, failure).
///
/// Displays a single-character code ('W', 'F', 'D') or the set index.
class SetTypeChip extends StatelessWidget {
  /// The type of set ('normal', 'warmup', 'failure', 'dropset').
  final String setType;

  /// The 1-based index for 'normal' sets.
  final int? setIndex;

  /// Whether the set is marked as completed; disables interaction if true.
  final bool isCompleted;

  /// Optional callback to cycle through set types.
  final VoidCallback? onTap;

  const SetTypeChip({
    super.key,
    required this.setType,
    this.setIndex, // setIndex is now optional
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic> typeInfo = {
      'normal': {
        'char': setIndex.toString(),
        'color': Theme.of(context).colorScheme.onSurfaceVariant,
        'label': l10n.set_type_normal,
      },
      'warmup': {
        'char': 'W',
        'color': Colors.orange,
        'label': l10n.set_type_warmup
      },
      'failure': {
        'char': 'F',
        'color': Theme.of(context).colorScheme.error,
        'label': l10n.set_type_failure
      },
      'dropset': {
        'char': 'D',
        'color': Colors.blue,
        'label': l10n.set_type_dropset
      },
    };
    final type = typeInfo[setType] ?? typeInfo['normal']!;
    final Color textColor = type['color'];
    final String typeLabel = type['label'];

    return Semantics(
      button: true,
      label: typeLabel,
      child: GestureDetector(
        onTap: isCompleted ? null : onTap,
        child: SizedBox(
          width: 40, // Fixed width for the column
          height: 40, // Fixed height
          child: Center(
            child: Text(
              type['char'],
              style: TextStyle(
                color: textColor,
                fontSize: 20, // Larger font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
