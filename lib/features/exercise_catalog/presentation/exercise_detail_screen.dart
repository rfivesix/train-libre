// lib/features/exercise_catalog/presentation/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../../data/database_helper.dart';
import '../domain/body_slug_mapper.dart';
import '../domain/exercise_metrics.dart';
import '../../workout/domain/classification/exercise_log_mask.dart';
import '../domain/exercise_classification_labels.dart';
import '../domain/muscle_vocabulary.dart';
import '../domain/models/exercise.dart';
import '../../workout/domain/models/set_log.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../widgets/common/global_app_bar.dart';

import '../../../widgets/common/common.dart';
import '../../../services/experience_level_service.dart';
import '../../../services/unit_service.dart';
import '../../profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_service.dart';
import 'create_exercise_screen.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

/// A screen displaying detailed information about a specific [Exercise].
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final IExerciseCatalogRepository? repository;

  const ExerciseDetailScreen(
      {super.key, required this.exercise, this.repository});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
  bool _isLoading = true;

  /// What the chart can be drawn on, and which of those it opens with.
  late List<ExerciseMetric> _availableMetrics =
      exerciseMetricsFor(widget.exercise);
  late ExerciseMetric _selectedMetric = _availableMetrics.first;
  String _selectedRange = '30D';

  late Exercise _currentExercise = widget.exercise;

  /// The catalog's muscle vocabulary, when it has one. Loaded alongside the
  /// rest of the screen's data rather than per rebuild.
  MuscleVocabulary _muscleVocabulary = MuscleVocabulary.empty;
  Map<String, SetLog?> _prMap = {};

  /// Current body weight, so a pull-up record can be shown as what it was
  /// worth rather than as the empty weight column it was logged in. Null until
  /// the first load, and null forever for a user who has never weighed in —
  /// in which case the body-weight cards read "-" rather than 0 kg.
  double? _bodyweightKg;
  List<Map<String, dynamic>> _timeSeriesData = [];

  /// The UI language, read once per load rather than per row.
  String get _languageCode => Localizations.localeOf(context).languageCode;

  int? get _selectedRangeDays {
    if (_selectedRange == '30D') return 30;
    if (_selectedRange == '90D') return 90;
    return null; // 'All'
  }

  List<Map<String, dynamic>> get _filteredTimeSeriesData {
    if (_selectedRangeDays == null) return _timeSeriesData;
    final cutoff = DateTime.now().subtract(Duration(days: _selectedRangeDays!));
    return _timeSeriesData
        .where((data) => (data['date'] as DateTime).isAfter(cutoff))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.exerciseDetail));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _muscleVocabulary =
        await MuscleVocabulary.load(await DatabaseHelper.instance.database);
    _bodyweightKg = await DatabaseHelper.instance.getLatestWeight();

    Exercise exercise = widget.exercise;
    if (widget.exercise.id != null) {
      final String? exerciseUuid = widget.exercise.uuid ??
          await _repository.getExerciseUuidByLocalId(widget.exercise.id!);
      if (exerciseUuid != null) {
        final fresh = await _repository.getExerciseByUuid(exerciseUuid);
        if (fresh != null) {
          exercise = fresh;
        }
      }
    }

    final String? exerciseUuid = exercise.id != null
        ? await _repository.getExerciseUuidByLocalId(exercise.id!)
        : null;

    // Statistics are keyed by the name that was logged, which may be in any
    // language the user has run the app in — so the primary key is the name
    // they see now and the alternate is the stable English one.
    final displayName = exercise.localizedNameFor(_languageCode);
    final canonical = exercise.canonicalName;
    final altName =
        canonical.isNotEmpty && canonical != displayName ? canonical : null;

    final prs = await _repository.getExercisePRs(
      displayName,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );

    final timeSeries = await _repository.getExerciseTimeSeriesData(
      displayName,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );

    if (mounted) {
      setState(() {
        _currentExercise = exercise;
        // The screen is entered with a list row, which carries no muscle ids
        // and may carry no classification; the fresh row does. So the metrics
        // are recomputed here rather than fixed at construction — and the
        // selection follows, in case it is no longer one of them.
        _availableMetrics = exerciseMetricsFor(exercise);
        if (!_availableMetrics.contains(_selectedMetric)) {
          _selectedMetric = _availableMetrics.first;
        }
        _prMap = prs;
        _timeSeriesData = timeSeries;
        _isLoading = false;
      });
    }
  }

  Future<void> _duplicateAndEdit() async {
    setState(() => _isLoading = true);
    try {
      final duplicate = Exercise.duplicateAsCustom(_currentExercise);
      final inserted = await _repository.insertExercise(duplicate);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.exerciseCopyCreated(inserted.getLocalizedName(context)),
          ),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreateExerciseScreen(
            repository: _repository,
            exerciseToEdit: inserted,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error duplicating exercise: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  void _showSystemEditMenu(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final title = l10n.copySystemExerciseTitle;
    final body = l10n.copySystemExerciseBody;
    final buttonLabel = l10n.createCopyAndEdit;
    final cancelLabel = l10n.cancel;

    showGlassBottomMenu(
      context: context,
      title: title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS,
                  vertical: DesignConstants.spacingS),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () => close(),
                    label: cancelLabel,
                    tooltip: cancelLabel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      close();
                      _duplicateAndEdit();
                    },
                    label: buttonLabel,
                    tooltip: buttonLabel,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmMenu(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final exerciseName = _currentExercise.getLocalizedName(context);

    showGlassBottomMenu(
      context: context,
      title: l10n.deleteCustomExerciseTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS,
                  vertical: DesignConstants.spacingS),
              child: Text(
                l10n.deleteCustomExerciseBody(exerciseName),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.25),
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.rotate_ccw_clock,
                          size: 16, color: colorScheme.error),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: Text(
                          l10n.deleteCustomExerciseWithLogsWarning,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.dumbbell,
                          size: 16, color: colorScheme.error),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: Text(
                          l10n.deleteCustomExerciseWithRoutinesWarning,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () => close(),
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.danger(
                    onPressed: () async {
                      close();
                      await _deleteExercise();
                    },
                    label: l10n.delete,
                    tooltip: l10n.delete,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExercise() async {
    final localId = _currentExercise.id;
    if (localId == null) return;

    setState(() => _isLoading = true);
    try {
      await _repository.deleteCustomExercise(localId);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteCustomExerciseSuccess)),
      );
      Navigator.of(context).pop('deleted');
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: _currentExercise.getLocalizedName(context),
        actions: [
          if (_currentExercise.source == 'user')
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(LucideIcons.trash_2),
              onPressed: () => _showDeleteConfirmMenu(context),
            ),
          MorphSourceScope(
            builder: (context, setHidden) => Builder(
              builder: (iconCtx) {
                // The button is the morph's source, so it also has to be the
                // copy that flies with the growing container.
                late final Widget editButton;
                editButton = IconButton(
                  tooltip: l10n.edit,
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () {
                    if (_currentExercise.source == 'user') {
                      Navigator.of(context)
                          .push(
                        CardMorphRoute(
                          sourceContext: iconCtx,
                          sourceBorderRadius: 20.0,
                          sourceBuilder: (_) => editButton,
                          onSourceVisibilityChanged: setHidden,
                          builder: (context) => CreateExerciseScreen(
                            repository: _repository,
                            exerciseToEdit: _currentExercise,
                          ),
                        ),
                      )
                          .then((wasSaved) {
                        if (wasSaved == true) {
                          _loadData();
                        }
                      });
                    } else {
                      _showSystemEditMenu(context);
                    }
                  },
                );
                return editButton;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: DesignConstants.spacingM),
            child: _CategoryBadge(text: _currentExercise.categoryName),
          ),
        ],
      ),
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((_currentExercise.imagePath ?? '').isNotEmpty)
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusL),
                ),
                child: Image.asset(
                  _currentExercise.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusL),
                    ),
                    child: const Icon(LucideIcons.image_off),
                  ),
                ),
              ),
            if ((_currentExercise.imagePath ?? '').isNotEmpty)
              const SizedBox(height: DesignConstants.spacingXL),
            _ClassificationChips(exercise: _currentExercise),
            AppInfoRow(
              title: l10n.descriptionLabel,
              subtitle:
                  _currentExercise.getLocalizedDescription(context).isNotEmpty
                      ? _currentExercise.getLocalizedDescription(context)
                      : l10n.noDescriptionAvailable,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            if (!_currentExercise.isCardio) ...[
              AppSectionHeader(title: l10n.involvedMuscles),
              RepaintBoundary(
                child: _ExerciseMuscleBodyView(
                  exercise: _currentExercise,
                  vocabulary: _muscleVocabulary,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingXL),
            ],
            if (_isLoading &&
                _timeSeriesData.isEmpty &&
                _prMap.values.every((v) => v == null))
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingXXL),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_timeSeriesData.isEmpty &&
                _prMap.values.every((v) => v == null))
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingXL),
                  child: Text(
                    l10n.exerciseAnalyticsNoData,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(title: l10n.workoutHistoryButton),
                      RepaintBoundary(
                        child: _buildConsolidatedChart(l10n),
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),
                      _buildPRSummarySection(l10n),
                    ],
                  ),
                  if (_isLoading)
                    const Positioned(
                      top: DesignConstants.spacingM,
                      right: DesignConstants.spacingM,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// A readable name for a record.
  ///
  /// The map keys are English identifiers and were rendered straight onto the
  /// cards, so a German user read "Best Distance" over their longest row. The
  /// rep brackets stay as they are: "2-3 RM" is numerals and an abbreviation
  /// that reads the same in every language the app ships.
  String _prLabel(String bracket, AppLocalizations l10n) => switch (bracket) {
        'Best Distance' => l10n.exerciseMetricDistance,
        'Longest Duration' => l10n.exerciseMetricDuration,
        'Fastest Pace' => l10n.exerciseMetricPace,
        'Est. 1RM' => l10n.exerciseMetricEst1RM,
        _ => bracket,
      };

  Widget _buildPRSummarySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final items = _prMap.entries.map((entry) {
      final bracket = entry.key;
      final prSet = entry.value;

      String value;
      String subtitle;
      Color? valueColor;

      if (prSet != null) {
        // Formatted by which record it is, not by whether the exercise was
        // once called cardio. A plank now holds a "Longest Duration" record
        // like a run does, and it is not cardio — the branch it used to sit in
        // would have printed a weight for it.
        final units = context.read<UnitService>();
        switch (bracket) {
          case 'Best Distance':
            value = '${prSet.distanceKm?.toStringAsFixed(2) ?? '0.0'} km';
            subtitle = _formatDuration(prSet.durationSeconds ?? 0);
          case 'Longest Duration':
            value = _formatDuration(prSet.durationSeconds ?? 0);
            final km = prSet.distanceKm ?? 0.0;
            subtitle = km > 0 ? '${km.toStringAsFixed(2)} km' : '';
          case 'Fastest Pace':
            final dur = prSet.durationSeconds ?? 0;
            final dist = prSet.distanceKm ?? 0.0;
            value = dist > 0
                ? '${_formatDuration((dur / dist).round())} / km'
                : '-';
            subtitle = '';
          default:
            // Through the shared helper, not a third copy of Brzycki. The copy
            // that stood here read `prSet.weightKg!` — which is null on every
            // body-weight set, so this card crashed rather than showing the
            // pull-up record it had just been handed.
            final mask = ExerciseLogMask.forExercise(_currentExercise);
            final displayKg = bracket == 'Est. 1RM'
                ? mask.estimatedOneRepMax(
                    loggedWeightKg: prSet.weightKg,
                    reps: prSet.reps,
                    bodyweightKg: _bodyweightKg,
                  )
                : mask.effectiveLoadKg(prSet.weightKg, _bodyweightKg);
            value = displayKg == null
                ? '-'
                : '${units.convertDisplayValue(displayKg, UnitDimension.weight).toStringAsFixed(1)} '
                    '${units.suffixFor(UnitDimension.weight)}';
            subtitle = l10n.repsCount(prSet.reps ?? 0);
        }
        valueColor = theme.colorScheme.primary;
      } else {
        value = '-';
        subtitle = l10n.noData;
        valueColor = theme.colorScheme.onSurfaceVariant;
      }

      return ValueSummaryCard(
        label: _prLabel(bracket, l10n),
        value: value,
        subtitle: subtitle,
        valueColor: valueColor,
        useSecondarySurface: false,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.exerciseAnalyticsPrsLabel),
        _buildTwoColumnGrid(items),
      ],
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(children: rows);
  }

  Widget _buildConsolidatedChart(AppLocalizations l10n) {
    final unitService = context.watch<UnitService>();
    final filteredData = _filteredTimeSeriesData;

    if (filteredData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.screenPaddingHorizontal,
            ),
            child: _buildChartHeader(l10n),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Container(
            height: 160,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              l10n.exerciseAnalyticsNotEnoughData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      );
    }

    final dataPoints = filteredData.map((e) {
      double y;
      switch (_selectedMetric) {
        case ExerciseMetric.maxWeight:
          y = (e['maxWeight'] as num?)?.toDouble() ?? 0.0;
          break;
        case ExerciseMetric.volume:
          y = (e['totalVolume'] as num?)?.toDouble() ?? 0.0;
          break;
        case ExerciseMetric.est1rm:
          y = (e['maxEst1rm'] as num?)?.toDouble() ?? 0.0;
          break;
        case ExerciseMetric.distance:
          y = (e['maxDistance'] as num?)?.toDouble() ?? 0.0;
          break;
        case ExerciseMetric.duration:
          y = ((e['totalDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
          break;
        case ExerciseMetric.pace:
          y = ((e['maxPace'] as num?)?.toDouble() ?? 0.0) / 60.0;
          break;
      }
      return ChartDataPoint(date: e['date'] as DateTime, value: y);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.screenPaddingHorizontal,
          ),
          child: _buildChartHeader(l10n),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        MeasurementChartWidget.fromData(
          dataPoints: dataPoints,
          unit: _selectedMetric == ExerciseMetric.distance
              ? 'km'
              : (_selectedMetric == ExerciseMetric.duration
                  ? 'min'
                  : (_selectedMetric == ExerciseMetric.pace
                      ? 'min/km'
                      : unitService.suffixFor(UnitDimension.weight))),
          axisMode: MeasurementChartAxisMode.day,
          edgeToEdge: true,
        ),
      ],
    );
  }

  String _metricLabel(ExerciseMetric metric, AppLocalizations l10n) =>
      switch (metric) {
        ExerciseMetric.maxWeight => l10n.exerciseMetricMaxWeight,
        ExerciseMetric.volume => l10n.exerciseMetricVolume,
        ExerciseMetric.est1rm => l10n.exerciseMetricEst1RM,
        ExerciseMetric.distance => l10n.exerciseMetricDistance,
        ExerciseMetric.duration => l10n.exerciseMetricDuration,
        ExerciseMetric.pace => l10n.exerciseMetricPace,
      };

  Widget _buildChartHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: PlatformAdaptiveDropdownFormField<ExerciseMetric>(
            value: _selectedMetric,
            onChanged: (ExerciseMetric? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMetric = newValue;
                });
              }
            },
            items: [
              for (final metric in _availableMetrics)
                DropdownMenuItem(
                  value: metric,
                  child: Text(_metricLabel(metric, l10n)),
                ),
            ],
          ),
        ),
        if (_selectedMetric == ExerciseMetric.est1rm) ...[
          const SizedBox(width: DesignConstants.spacingXS),
          AlgorithmInfoButton(
            title: "Estimated 1-Rep Max Heuristic (Epley Equation)",
            explanation:
                "Estimates maximal strength capacities based on submaximal workloads to allow safe, non-clinical progression tracking.",
            keyPoints: const [
              "1RM ≈ w * (36 / (37 - r)) where w = weight, r = repetitions (valid for r <= 10).",
              "Estimates are sports-science heuristics designed for healthy individuals.",
              "Provides a safe way to track strength progression without testing true failure.",
            ],
            technicalTitle: "Epley Equation Details",
            technicalExplanation:
                "The Epley equation estimates one-repetition maximum (1RM) as 1RM = w * (1 + r/30) which simplifies to w * (36 / (37 - r)) for r <= 10. Research suggests this linear approximation is reliable for low repetitions (2-10 reps) in healthy active individuals, but tends to overestimate capacity beyond 10 repetitions.",
            citationUrl:
                "https://rfivesix.github.io/train-libre/intelligent-workouts/#evidence",
          ),
        ],
        const SizedBox(width: DesignConstants.spacingS),
        Wrap(
          spacing: 8.0,
          children: [
            _buildFilterButton(l10n.filter30DaysShort, '30D'),
            _buildFilterButton(l10n.filter90DaysShort, '90D'),
            _buildFilterButton(l10n.filterMax, 'All'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedRange == key;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedbackService.instance.selectionFeedback();
          setState(() => _selectedRange = key);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// What the catalog knows about the movement, as a row of chips.
///
/// Five axes the data repo annotates on 877 of 909 exercises. This screen is
/// the only place any of them is read: they are description, not machinery,
/// and nothing filters, groups or computes on the two added last.
///
/// [ExerciseClassificationLabels.forceVector] is derived upstream from
/// [ExerciseClassificationLabels.movementPattern], so where both exist the
/// pair reads a little doubled — "Ziehen · Vertikales Ziehen". Kept because
/// the force vector survives 62 static exercises that have no pattern anyone
/// would call a direction, and because the shorter word is the one a reader
/// scanning the row actually takes in.
///
/// Renders nothing at all when none of the five is set — a user-created
/// exercise, or one of the 32 unclassified catalog rows — rather than drawing
/// an empty strip above the description.
class _ClassificationChips extends StatelessWidget {
  final Exercise exercise;

  const _ClassificationChips({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      for (final label in [
        ExerciseClassificationLabels.mechanic(context, exercise.mechanic),
        ExerciseClassificationLabels.forceVector(context, exercise.forceVector),
        ExerciseClassificationLabels.movementPattern(
          context,
          exercise.movementPattern,
        ),
        ExerciseClassificationLabels.laterality(context, exercise.laterality),
        ExerciseClassificationLabels.difficulty(context, exercise.difficulty),
      ])
        if (label != null) label,
    ];
    if (labels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Pill, outline and full-strength text. The first cut used
    // surfaceContainerHighest with onSurfaceVariant on top, which against the
    // near-black scaffold was an unlit rectangle behind grey text — three
    // words that read as a leftover rather than as the exercise's own
    // description of itself.
    //
    // Not the category badge's treatment either: that one is filled with the
    // accent colour and there is exactly one of it per screen, so three more
    // in the same paint would turn the top of the page into a traffic light.
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingXL),
      child: Wrap(
        spacing: DesignConstants.spacingS,
        runSpacing: DesignConstants.spacingS,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: DesignConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String text;
  const _CategoryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withValues(alpha: 0.15);
    final fg = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: DesignConstants.spacingS),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Displays front + back [BodyHighlighter] views side by side, plus a compact
/// chip legend listing primary and secondary muscle names.
class _ExerciseMuscleBodyView extends StatelessWidget {
  final Exercise exercise;
  final MuscleVocabulary vocabulary;

  const _ExerciseMuscleBodyView({
    required this.exercise,
    required this.vocabulary,
  });

  @override
  Widget build(BuildContext context) {
    if (exercise.isCardio) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Muscle ids are the precise annotation; the legacy name columns are what
    // the fifteen-name vocabulary could still express. 38 active exercises
    // have the former and nothing in the latter.
    final useIds = !vocabulary.isEmpty && exercise.primaryMuscleIds.isNotEmpty;
    final primaryLabels =
        useIds ? exercise.primaryMuscleIds : exercise.primaryMuscles;
    final secondaryLabels =
        useIds ? exercise.secondaryMuscleIds : exercise.secondaryMuscles;
    final hasMuscles = primaryLabels.isNotEmpty || secondaryLabels.isNotEmpty;

    if (!hasMuscles) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingS),
        child: Text(
          l10n.noMusclesSpecified,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final allHighlights = useIds
        ? BodySlugMapper.mergedHighlightsFromIds(
            primaryMuscleIds: exercise.primaryMuscleIds,
            secondaryMuscleIds: exercise.secondaryMuscleIds,
            vocabulary: vocabulary,
          )
        : BodySlugMapper.mergedHighlights(
            primaryMuscles: exercise.primaryMuscles,
            secondaryMuscles: exercise.secondaryMuscles,
          );

    final frontHighlights =
        BodySlugMapper.forSide(allHighlights, BodySide.front);
    final backHighlights = BodySlugMapper.forSide(allHighlights, BodySide.back);

    // The names are coarsened, the highlights above are not: a beginner reads
    // "shoulders" while the body map still paints the single head that works.
    final coarse =
        context.watch<ExperienceLevelService>().usesCoarseMuscleNames;
    final resolvedVocabulary = useIds ? vocabulary : null;
    final primaryNames = BodySlugMapper.localizeAll(
      context,
      primaryLabels,
      vocabulary: resolvedVocabulary,
      coarse: coarse,
    );
    // A secondary muscle that coarsens into a primary region says nothing —
    // "shoulders" cannot be both the point of the exercise and an aside.
    final secondaryNames = BodySlugMapper.localizeAll(
      context,
      secondaryLabels,
      vocabulary: resolvedVocabulary,
      coarse: coarse,
    ).where((name) => !primaryNames.contains(name)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Body diagrams ──────────────────────────────────────────────
        DualBodyHighlighter(
          gender: context.watch<ProfileService>().gender.toBodyGender(),
          frontHighlights: frontHighlights,
          backHighlights: backHighlights,
        ),
        // ── Legend ─────────────────────────────────────────────────────
        const SizedBox(height: DesignConstants.spacingL),
        _MuscleChipRow(
          label: l10n.primaryLabel,
          names: primaryNames,
          color: theme.colorScheme.primary,
        ),
        if (secondaryNames.isNotEmpty) ...[
          const SizedBox(height: 6),
          _MuscleChipRow(
            label: l10n.secondaryLabel,
            names: secondaryNames,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
          ),
        ],
      ],
    );
  }
}

/// A labelled row of muscle names used as a text legend.
///
/// Takes names, not ids: which name a muscle gets — the head or its region —
/// is decided by the caller, together with the de-duplication that decision
/// makes necessary.
class _MuscleChipRow extends StatelessWidget {
  final String label;
  final List<String> names;
  final Color color;

  const _MuscleChipRow({
    required this.label,
    required this.names,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: names.map((name) {
                return Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
