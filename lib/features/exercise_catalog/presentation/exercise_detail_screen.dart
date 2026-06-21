// lib/features/exercise_catalog/presentation/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../../generated/app_localizations.dart';
import '../domain/body_slug_mapper.dart';
import '../domain/models/exercise.dart';
import '../../workout/domain/models/set_log.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import 'widgets/wger_attribution_widget.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';
import 'create_exercise_screen.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum ExerciseMetric { maxWeight, volume, est1rm }

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
  ExerciseMetric _selectedMetric = ExerciseMetric.maxWeight;
  String _selectedRange = '30D';

  late Exercise _currentExercise = widget.exercise;
  Map<String, SetLog?> _prMap = {};
  List<Map<String, dynamic>> _timeSeriesData = [];

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

    final altName =
        exercise.nameEn.isNotEmpty && exercise.nameEn != exercise.nameDe
            ? exercise.nameEn
            : null;

    final prs = await _repository.getExercisePRs(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final timeSeries = await _repository.getExerciseTimeSeriesData(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => close(),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      _duplicateAndEdit();
                    },
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
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
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: () {
              if (_currentExercise.source == 'user') {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryBadge(text: _currentExercise.categoryName),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            AppSectionHeader(title: l10n.descriptionLabel),
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Text(
                  _currentExercise.getLocalizedDescription(context).isNotEmpty
                      ? _currentExercise.getLocalizedDescription(context)
                      : l10n.noDescriptionAvailable,
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            AppSectionHeader(title: l10n.involvedMuscles),
            RepaintBoundary(
              child: _ExerciseMuscleBodyView(exercise: _currentExercise),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_timeSeriesData.isEmpty &&
                _prMap.values.every((v) => v == null))
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    l10n.exerciseAnalyticsNoData,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else ...[
              AppSectionHeader(title: l10n.workoutHistoryButton),
              RepaintBoundary(
                child: _buildConsolidatedChart(l10n),
              ),
              const SizedBox(height: DesignConstants.spacingXL),
              _buildPRSummarySection(l10n),
            ],
            const SizedBox(height: DesignConstants.spacingXL),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: DesignConstants.spacingM,
                ),
                child: WgerAttributionWidget(
                  textStyle: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRSummarySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.exerciseAnalyticsPrsLabel),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _prMap.entries.map((entry) {
            final bracket = entry.key;
            final prSet = entry.value;

            return Container(
              width: (MediaQuery.of(context).size.width - 40) / 2,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prSet != null
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bracket,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (prSet != null) ...[
                    if (bracket == 'Est. 1RM')
                      Text(
                        '${context.read<UnitService>().convertDisplayValue(prSet.weightKg! * (36 / (37 - prSet.reps!)), UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '${context.read<UnitService>().convertDisplayValue(prSet.weightKg ?? 0.0, UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      l10n.repsCount(prSet.reps!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ] else ...[
                    Text(
                      '-',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      l10n.noData,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConsolidatedChart(AppLocalizations l10n) {
    final unitService = context.watch<UnitService>();
    final filteredData = _filteredTimeSeriesData;

    if (filteredData.isEmpty) {
      return SummaryCard(
        child: Column(
          children: [
            _buildChartHeader(l10n),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(l10n.exerciseAnalyticsNotEnoughData),
            ),
          ],
        ),
      );
    }

    final dataPoints = filteredData.map((e) {
      double y;
      switch (_selectedMetric) {
        case ExerciseMetric.maxWeight:
          y = (e['maxWeight'] as num).toDouble();
          break;
        case ExerciseMetric.volume:
          y = (e['totalVolume'] as num).toDouble();
          break;
        case ExerciseMetric.est1rm:
          y = (e['maxEst1rm'] as num).toDouble();
          break;
      }
      return ChartDataPoint(date: e['date'] as DateTime, value: y);
    }).toList();

    return SummaryCard(
      padding: DesignConstants.cardPadding,
      child: Column(
        children: [
          _buildChartHeader(l10n),
          const SizedBox(height: DesignConstants.spacingS),
          MeasurementChartWidget.fromData(
            dataPoints: dataPoints,
            unit: unitService.suffixFor(UnitDimension.weight),
            axisMode: MeasurementChartAxisMode.day,
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(AppLocalizations l10n) {
    final theme = Theme.of(context);
    String metricTitle = '';
    switch (_selectedMetric) {
      case ExerciseMetric.maxWeight:
        metricTitle = l10n.exerciseMetricMaxWeight;
        break;
      case ExerciseMetric.volume:
        metricTitle = l10n.exerciseMetricVolume;
        break;
      case ExerciseMetric.est1rm:
        metricTitle = l10n.exerciseMetricEst1RM;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MenuAnchor(
          builder: (context, controller, child) {
            return GestureDetector(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metricTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevron_down,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.maxWeight),
              child: Text(l10n.exerciseMetricMaxWeight),
            ),
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.volume),
              child: Text(l10n.exerciseMetricVolume),
            ),
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.est1rm),
              child: Text(l10n.exerciseMetricEst1RM),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: [
            _buildFilterButton('30D', '30D'),
            _buildFilterButton('90D', '90D'),
            _buildFilterButton('All', 'All'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedRange == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedRange = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(8.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasMuscles = exercise.primaryMuscles.isNotEmpty ||
        exercise.secondaryMuscles.isNotEmpty;

    if (!hasMuscles) {
      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            l10n.noMusclesSpecified,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
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

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Body diagrams ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.frontLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 200,
                        child: BodyHighlighter(
                          gender: context
                              .watch<ProfileService>()
                              .gender
                              .toBodyGender(),
                          highlightedParts: frontHighlights,
                          side: BodySide.front,
                          outlineWidth: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.backLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 200,
                        child: BodyHighlighter(
                          gender: context
                              .watch<ProfileService>()
                              .gender
                              .toBodyGender(),
                          highlightedParts: backHighlights,
                          side: BodySide.back,
                          outlineWidth: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Legend ─────────────────────────────────────────────────────
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}

/// A labelled row of compact muscle-name chips used as a text legend.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: muscles
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      m,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
