import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_section_header.dart';

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

/// A filter chip whose width does not depend on whether it is selected.
///
/// A Material [FilterChip] adds a checkmark when selected, which makes it
/// wider, which re-wraps the row, which makes the menu jump under the finger
/// that just tapped it. Selection here is a background colour and nothing
/// else — the same thing the statistics time-range switcher does.
class ExerciseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const ExerciseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Identical geometry in both states. Only the two colours below may
    // differ, or the width follows the selection again.
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelected(!selected),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// The catalog filter, as named sections of chips.
///
/// It used to be one flat popup that listed body regions and then equipment
/// with nothing in between, so "Cardio" and "Cardio machine" sat six rows
/// apart meaning different things, and nothing said whether picking one of
/// each narrowed the results or replaced the other.
///
/// Sections make the axes visible, under [AppSectionHeader] headings — the
/// same structure the create-exercise screen uses for muscle selection.
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
        for (final (index, section) in visible.indexed) ...[
          AppSectionHeader(title: section.title, isFirst: index == 0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: section.options.map((option) {
              return ExerciseFilterChip(
                label: option.label,
                selected: section.selection.contains(option.value),
                onSelected: (selected) => _apply(() {
                  if (selected) {
                    section.selection.add(option.value);
                  } else {
                    section.selection.remove(option.value);
                  }
                }),
              );
            }).toList(),
          ),
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
