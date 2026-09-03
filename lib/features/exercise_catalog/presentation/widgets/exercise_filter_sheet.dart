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

/// The catalog filter, as named sections of chips.
///
/// It used to be one flat popup that listed body regions and then equipment
/// with nothing in between, so "Cardio" and "Cardio machine" sat six rows
/// apart meaning different things, and nothing said whether picking one of
/// each narrowed the results or replaced the other.
///
/// Sections make the axes visible. The pattern — [AppSectionHeader] over a
/// [Wrap] of [FilterChip]s — is the one the create-exercise screen already
/// uses for muscle selection, so this is not a second way of doing it.
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
              return FilterChip(
                label: Text(option.label),
                selected: section.selection.contains(option.value),
                onSelected: (selected) => _apply(() {
                  if (selected) {
                    section.selection.add(option.value);
                  } else {
                    section.selection.remove(option.value);
                  }
                }),
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
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
        if (_hasSelection) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _apply(() {
                for (final section in widget.sections) {
                  section.selection.clear();
                }
              }),
              child: Text(l10n.catalogFilterReset),
            ),
          ),
        ],
      ],
    );
  }
}
