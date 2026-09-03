// lib/features/exercise_catalog/presentation/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../domain/body_slug_mapper.dart';
import '../domain/models/exercise.dart';
import '../../workout/domain/models/set_log.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../widgets/common/global_app_bar.dart';

import '../../../widgets/common/common.dart';
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

enum ExerciseMetric { maxWeight, volume, est1rm, distance, duration, pace }

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
  late ExerciseMetric _selectedMetric = widget.exercise.isCardio
      ? ExerciseMetric.distance
      : ExerciseMetric.maxWeight;
  String _selectedRange = '30D';

  late Exercise _currentExercise = widget.exercise;
  Map<String, SetLog?> _prMap = {};
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
                child: _ExerciseMuscleBodyView(exercise: _currentExercise),
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

  Widget _buildPRSummarySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final items = _prMap.entries.map((entry) {
      final bracket = entry.key;
      final prSet = entry.value;

      String value;
      String subtitle;
      Color? valueColor;

      if (prSet != null) {
        if (_currentExercise.isCardio) {
          if (bracket == 'Best Distance') {
            value = '${prSet.distanceKm?.toStringAsFixed(2) ?? '0.0'} km';
            subtitle = _formatDuration(prSet.durationSeconds ?? 0);
          } else if (bracket == 'Longest Duration') {
            value = _formatDuration(prSet.durationSeconds ?? 0);
            subtitle = '${prSet.distanceKm?.toStringAsFixed(2) ?? '0.0'} km';
          } else if (bracket == 'Fastest Pace') {
            final dur = prSet.durationSeconds ?? 0;
            final dist = prSet.distanceKm ?? 0.0;
            if (dist > 0) {
              final paceSec = dur / dist;
              value = '${_formatDuration(paceSec.round())} / km';
            } else {
              value = '-';
            }
            subtitle = '';
          } else {
            value = '-';
            subtitle = '-';
          }
        } else {
          if (bracket == 'Est. 1RM') {
            value =
                '${context.read<UnitService>().convertDisplayValue(prSet.weightKg! * (36 / (37 - prSet.reps!)), UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
          } else {
            value =
                '${context.read<UnitService>().convertDisplayValue(prSet.weightKg ?? 0.0, UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
          }
          subtitle = l10n.repsCount(prSet.reps!);
        }
        valueColor = theme.colorScheme.primary;
      } else {
        value = '-';
        subtitle = l10n.noData;
        valueColor = theme.colorScheme.onSurfaceVariant;
      }

      return ValueSummaryCard(
        label: bracket,
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
            items: _currentExercise.isCardio
                ? [
                    DropdownMenuItem(
                      value: ExerciseMetric.distance,
                      child: Text(l10n.exerciseMetricDistance),
                    ),
                    DropdownMenuItem(
                      value: ExerciseMetric.duration,
                      child: Text(l10n.exerciseMetricDuration),
                    ),
                    DropdownMenuItem(
                      value: ExerciseMetric.pace,
                      child: Text(l10n.exerciseMetricPace),
                    ),
                  ]
                : [
                    DropdownMenuItem(
                      value: ExerciseMetric.maxWeight,
                      child: Text(l10n.exerciseMetricMaxWeight),
                    ),
                    DropdownMenuItem(
                      value: ExerciseMetric.volume,
                      child: Text(l10n.exerciseMetricVolume),
                    ),
                    DropdownMenuItem(
                      value: ExerciseMetric.est1rm,
                      child: Text(l10n.exerciseMetricEst1RM),
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

  const _ExerciseMuscleBodyView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.isCardio) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasMuscles = exercise.primaryMuscles.isNotEmpty ||
        exercise.secondaryMuscles.isNotEmpty;

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

    final allHighlights = BodySlugMapper.mergedHighlights(
      primaryMuscles: exercise.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles,
    );

    final frontHighlights =
        BodySlugMapper.forSide(allHighlights, BodySide.front);
    final backHighlights = BodySlugMapper.forSide(allHighlights, BodySide.back);

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
          muscles: exercise.primaryMuscles,
          color: theme.colorScheme.primary,
        ),
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 6),
          _MuscleChipRow(
            label: l10n.secondaryLabel,
            muscles: exercise.secondaryMuscles,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
          ),
        ],
      ],
    );
  }
}

/// A labelled row of muscle names used as a text legend.
class _MuscleChipRow extends StatelessWidget {
  final String label;
  final List<String> muscles;
  final Color color;

  const _MuscleChipRow({
    required this.label,
    required this.muscles,
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
              children: muscles.map((m) {
                return Text(
                  BodySlugMapper.localize(context, m),
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
