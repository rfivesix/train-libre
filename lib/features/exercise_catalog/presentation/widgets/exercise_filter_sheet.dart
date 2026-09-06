import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';

/// One selectable option in a filter section.
@immutable
class ExerciseFilterOption {
  /// What goes into the query.
  final String value;

  /// What the user reads.
  final String label;

  const ExerciseFilterOption({required this.value, required this.label});
}

/// One named group of chips: a single question, with its own answers.
@immutable
class ExerciseFilterSection {
  final String title;
  final List<ExerciseFilterOption> options;

  /// The live selection for this section. Mutated in place by the sheet.
  final List<String> selection;

  const ExerciseFilterSection({
    required this.title,
    required this.options,
    required this.selection,
  });
}

/// The catalog filter: one collapsed field per axis.
///
/// It began as one flat popup that listed body regions and then equipment with
/// nothing in between, so "Cardio" and "Cardio machine" sat six rows apart
/// meaning different things. Naming the sections fixed that but not the
/// length — eight body regions and fourteen implements as open lists is a
/// sheet you scroll past rather than read.
///
/// Each axis is now a [PlatformAdaptiveMultiSelectField]: collapsed to a
/// single line showing what is picked, expanding into the same glass menu the
/// rest of the app's dropdowns use. Multi-select rather than the plain
/// dropdown beside it, because "chest or back" is a legitimate filter — at the
/// cost of one reopen per extra pick, since that menu closes itself on every
/// tap and cannot be told not to.
///
/// A separate widget rather than a closure inside the screen because the
/// screen cannot be built without a seeded catalog, and a filter nobody can
/// pump is a filter nobody tests.
class ExerciseFilterSheet extends StatefulWidget {
  final List<ExerciseFilterSection> sections;

  /// Called after every change, so the list behind the sheet updates live.
  final VoidCallback onChanged;

  const ExerciseFilterSheet({
    super.key,
    required this.sections,
    required this.onChanged,
  });

  @override
  State<ExerciseFilterSheet> createState() => _ExerciseFilterSheetState();
}

class _ExerciseFilterSheetState extends State<ExerciseFilterSheet> {
  bool get _hasSelection =>
      widget.sections.any((section) => section.selection.isNotEmpty);

  void _apply(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible =
        widget.sections.where((section) => section.options.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in visible) ...[
          PlatformAdaptiveMultiSelectField<String>(
            label: section.title,
            selected: section.selection,
            items: section.options
                .map((option) => PlatformAdaptivePopupMenuItem<String>(
                      value: option.value,
                      label: option.label,
                    ))
                .toList(),
            onToggled: (value) => _apply(() {
              if (section.selection.contains(value)) {
                section.selection.remove(value);
              } else {
                section.selection.add(value);
              }
            }),
          ),
          const SizedBox(height: DesignConstants.spacingS),
        ],
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          l10n.catalogFilterCombineHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Align(
          alignment: Alignment.centerLeft,
          // Always present, disabled when there is nothing to reset. Appearing
          // on first selection moved everything above it, so the menu shifted
          // under the finger that had just tapped a chip.
          child: TextButton(
            onPressed: _hasSelection
                ? () => _apply(() {
                      for (final section in widget.sections) {
                        section.selection.clear();
                      }
                    })
                : null,
            child: Text(l10n.catalogFilterReset),
          ),
        ),
      ],
    );
  }
}
