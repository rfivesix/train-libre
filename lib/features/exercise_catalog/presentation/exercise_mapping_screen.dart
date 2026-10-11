// lib/features/exercise_catalog/presentation/exercise_mapping_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/exercise.dart';
import 'exercise_catalog_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/glass_pill_button.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';

/// A screen for mapping unknown exercise names to known database [Exercise] objects.
class ExerciseMappingScreen extends StatefulWidget {
  /// A list of exercise names that could not be matched automatically.
  final List<String> unknownNames;
  final IExerciseCatalogRepository? repository;

  const ExerciseMappingScreen(
      {super.key, required this.unknownNames, this.repository});

  @override
  State<ExerciseMappingScreen> createState() => _ExerciseMappingScreenState();
}

class _ExerciseMappingScreenState extends State<ExerciseMappingScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
  final Map<String, Exercise> _selection = {};
  final Map<String, List<Exercise>> _suggestions = {};
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  /// Read once: this runs in a loop over every unknown name.
  late final String _languageCode =
      Localizations.localeOf(context).languageCode;

  Future<void> _loadSuggestions() async {
    for (var offset = 0; offset < widget.unknownNames.length; offset += 8) {
      final batch = widget.unknownNames.skip(offset).take(8);
      await Future.wait(batch.map(_loadSuggestionsForName));
    }
  }

  Future<void> _loadSuggestionsForName(String name) async {
    final candidates = <String, Exercise>{};
    final cleanedName = name.replaceAll(RegExp(r'\([^)]*\)'), ' ').trim();
    for (final exactName in {name, cleanedName}) {
      if (exactName.isEmpty) continue;
      final exact = await _repository.getExerciseByName(exactName);
      if (exact != null) {
        candidates[exact.uuid ?? exact.localizedNameFor(_languageCode)] = exact;
      }
    }
    final tokens = cleanedName
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((token) => token.length >= 3)
        .toList();
    final queries = <String>{name, cleanedName};
    if (tokens.isNotEmpty) {
      queries.add(tokens.first);
      queries.add(tokens.last);
      final longest = tokens.reduce((a, b) => a.length >= b.length ? a : b);
      if (longest.length >= 5) queries.add(longest.substring(0, 4));
    }
    final results = await Future.wait(
      queries
          .where((query) => query.isNotEmpty)
          .map((query) => _repository.searchExercises(
                query: query,
                languageCode: _languageCode,
              )),
    );
    for (final result in results) {
      for (final exercise in result) {
        candidates[exercise.uuid ?? exercise.localizedNameFor(_languageCode)] =
            exercise;
      }
    }

    final normalizedSource = _normalize(name);
    final matches = candidates.values.toList()
      ..sort((a, b) => _similarity(
              normalizedSource, _normalize(a.localizedNameFor(_languageCode)))
          .compareTo(_similarity(normalizedSource,
              _normalize(b.localizedNameFor(_languageCode)))));
    if (matches.isNotEmpty && mounted) {
      setState(() {
        _suggestions[name] = matches.take(4).toList();
        if (!_selection.containsKey(name)) _selection[name] = matches.first;
      });
    }
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  double _similarity(String source, String candidate) {
    if (source == candidate) return 0;
    if (source.isEmpty || candidate.isEmpty) return 1;
    final sourceTokens = source.split(' ').toSet();
    final candidateTokens = candidate.split(' ').toSet();
    final overlap = sourceTokens.intersection(candidateTokens).length;
    final tokenScore = 1 - overlap / sourceTokens.length;
    final distance = List<int>.generate(candidate.length + 1, (i) => i);
    for (var i = 1; i <= source.length; i++) {
      var previousDiagonal = distance[0];
      distance[0] = i;
      for (var j = 1; j <= candidate.length; j++) {
        final old = distance[j];
        distance[j] = (source.codeUnitAt(i - 1) == candidate.codeUnitAt(j - 1))
            ? previousDiagonal
            : 1 +
                [distance[j], distance[j - 1], previousDiagonal].reduce(
                  (a, b) => a < b ? a : b,
                );
        previousDiagonal = old;
      }
    }
    final characterScore = distance[candidate.length] /
        (source.length > candidate.length ? source.length : candidate.length);
    return tokenScore < characterScore ? tokenScore : characterScore;
  }

  Future<void> _pickTarget(String sourceName) async {
    final Exercise? picked = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseCatalogScreen(
            isSelectionMode: true, repository: _repository),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selection[sourceName] = picked);
    }
  }

  Future<void> _apply() async {
    if (_selection.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _applying = true);
    final mapping = <String, String>{
      for (final e in _selection.entries)
        e.key: e.value
            .localizedNameFor(Localizations.localeOf(context).languageCode),
    };
    await _repository.applyExerciseNameMapping(mapping);
    if (mounted) {
      setState(() => _applying = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.mapExercisesTitle),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.screenPaddingHorizontal,
          DesignConstants.cardPaddingInternal + topPadding,
          DesignConstants.screenPaddingHorizontal,
          0,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: DesignConstants.spacingS,
                  bottom: DesignConstants.spacingL,
                ),
                itemCount: widget.unknownNames.length,
                itemBuilder: (context, index) {
                  final src = widget.unknownNames[index];
                  final picked = _selection[src];
                  final suggestions = _suggestions[src] ?? [];

                  return SummaryCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingM,
                      vertical: DesignConstants.spacingXS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          minVerticalPadding: 0,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            src,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: picked == null
                              ? Text(
                                  l10n.noSelection,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Text(
                                  '→ ${picked.getLocalizedName(context)}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.search),
                            onPressed: () => _pickTarget(src),
                            tooltip: l10n.selectButton,
                          ),
                        ),
                        if (suggestions.isNotEmpty) ...[
                          const Divider(height: 16),
                          Text(
                            l10n.mappingSuggestions,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                          Wrap(
                            spacing: DesignConstants.spacingS,
                            runSpacing: DesignConstants.spacingS,
                            children: suggestions.map((s) {
                              final isSelected = picked?.uuid == s.uuid;
                              return GlassPillButton(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacingM,
                                ),
                                onTap: () {
                                  setState(() => _selection[src] = s);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(
                                        LucideIcons.check,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      s.getLocalizedName(context),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : null,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                        ] else if (picked != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() => _selection.remove(src));
                              },
                              child: Text(l10n.cancel),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignConstants.spacingM,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    onPressed: _applying ? null : _apply,
                    label: _applying ? l10n.applyingChanges : l10n.applyMapping,
                    tooltip:
                        _applying ? l10n.applyingChanges : l10n.applyMapping,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
