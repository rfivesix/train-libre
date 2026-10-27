// lib/features/exercise_catalog/presentation/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../../data/database_helper.dart';
import '../domain/exercise_metrics.dart';
import '../../workout/domain/classification/exercise_log_mask.dart';
import '../domain/muscle_vocabulary.dart';
import '../domain/models/exercise.dart';
import '../../workout/domain/models/set_log.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../workout/presentation/widgets/exercise_notes_dialog.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';

import '../../../widgets/common/common.dart';
import '../../../services/unit_service.dart';
import '../../profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:provider/provider.dart';
import 'create_exercise_screen.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../workout/domain/models/workout_log.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../../workout/presentation/workout_log_detail_screen.dart';
import '../../workout/presentation/widgets/workout_exercise_log_card.dart';
import 'package:intl/intl.dart';
import 'widgets/exercise_classification_chips.dart';
import 'widgets/exercise_muscle_body_view.dart';

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
  late final Stream<List<WorkoutLog>> _workoutHistory =
      context.read<IWorkoutRepository>().watchFullWorkoutLogs();

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

  Future<void> _editPinnedNote() async {
    final uuid = _currentExercise.uuid;
    if (uuid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final result = await showGlassBottomMenu<String?>(
      context: context,
      title: l10n.pinnedExerciseNoteTitle,
      contentBuilder: (ctx, close) => ExerciseNotesDialog(
        initialNotes: _currentExercise.pinnedNote,
        onSave: (notes) {
          close();
          Navigator.of(ctx).pop(notes);
        },
        onDelete: () {
          close();
          Navigator.of(ctx).pop('');
        },
        onCancel: () {
          close();
          Navigator.of(ctx).pop(null);
        },
      ),
    );
    if (result == null) return;
    await WorkoutLocalDataSource.instance.savePinnedExerciseNote(
      exerciseUuid: uuid,
      notes: result,
    );
    await _loadData();
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
    final isLightMode = theme.brightness == Brightness.light;
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
              icon: const Icon(LucideIcons.trash),
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
            child: ExerciseCategoryBadge(text: _currentExercise.categoryName),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(children: [
          SizedBox(height: topPadding),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingL,
              vertical: DesignConstants.spacingXS,
            ),
            child: TabBar(
              isScrollable: false,
              indicator: const BoxDecoration(),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelPadding: EdgeInsets.zero,
              labelColor: isLightMode ? Colors.black : Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(text: 'Zusammenfassung'),
                Tab(text: 'Historie'),
                Tab(text: 'So geht’s'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _buildSummaryTab(l10n, textTheme),
              _buildExerciseHistoryTab(),
              _buildInstructionsTab(l10n),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryTab(AppLocalizations l10n, TextTheme textTheme) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: DesignConstants.cardPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!_currentExercise.isCardio) ...[
          RepaintBoundary(
              child: ExerciseMuscleBodyView(
                  exercise: _currentExercise,
                  vocabulary: _muscleVocabulary,
                  showExerciseTitle: true)),
          const SizedBox(height: DesignConstants.spacingXL),
        ],
        ExerciseClassificationChips(exercise: _currentExercise),
        if (_isLoading &&
            _timeSeriesData.isEmpty &&
            _prMap.values.every((v) => v == null))
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingXXL),
                  child: CircularProgressIndicator()))
        else if (_timeSeriesData.isEmpty &&
            _prMap.values.every((v) => v == null))
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingXL),
                  child: Text(l10n.exerciseAnalyticsNoData,
                      style: textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))))
        else
          Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildPRSummarySection(l10n),
              const SizedBox(height: DesignConstants.spacingXL),
              AppSectionHeader(title: l10n.workoutHistoryButton),
              RepaintBoundary(child: _buildConsolidatedChart(l10n)),
            ]),
            if (_isLoading)
              const Positioned(
                  top: DesignConstants.spacingM,
                  right: DesignConstants.spacingM,
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))),
          ]),
      ]),
    );
  }

  Widget _buildInstructionsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: DesignConstants.cardPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!_currentExercise.isCardio) ...[
          ExerciseMuscleBodyView(
              exercise: _currentExercise, vocabulary: _muscleVocabulary),
          const SizedBox(height: DesignConstants.spacingXL),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _currentExercise.getLocalizedDescription(context).isNotEmpty
                ? _currentExercise.getLocalizedDescription(context)
                : l10n.noDescriptionAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        AppLinkRow(
          title: l10n.pinnedExerciseNoteTitle,
          subtitle: _currentExercise.pinnedNote?.trim().isNotEmpty == true
              ? _currentExercise.pinnedNote!
              : l10n.exerciseNoteHint,
          trailingIcon: LucideIcons.pencil,
          onTap: _editPinnedNote,
        ),
      ]),
    );
  }

  Widget _buildExerciseHistoryTab() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return StreamBuilder<List<WorkoutLog>>(
      stream: _workoutHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final targetUuid = _currentExercise.uuid;
        final names = {
          _currentExercise.localizedNameFor(_languageCode).toLowerCase(),
          _currentExercise.canonicalName.toLowerCase()
        };
        final entries = (snapshot.data ?? [])
            .map((log) => (
                  log: log,
                  sets: log.sets
                      .where((set) =>
                          (targetUuid != null &&
                              set.exerciseId == targetUuid) ||
                          names.contains(set.exerciseName.toLowerCase()))
                      .toList()
                ))
            .where((entry) => entry.sets.isNotEmpty)
            .toList();
        if (entries.isEmpty) {
          return Center(child: Text(l10n.exerciseAnalyticsNoData));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: DesignConstants.spacingXL),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final log = entry.log;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(log.routineName ?? l10n.freeWorkoutTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat.yMMMMd(locale)
                        .add_Hm()
                        .format(log.startTime)),
                    trailing: const Icon(LucideIcons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            WorkoutLogDetailScreen(logId: log.id!))),
                  ),
                  WorkoutExerciseLogCard(
                    exerciseName: _currentExercise.getLocalizedName(context),
                    exercise: _currentExercise,
                    sets: entry.sets,
                    isEditMode: false,
                    isCardio: _currentExercise.isCardio,
                    showExerciseHeader: false,
                    mask: ExerciseLogMask.forExercise(_currentExercise),
                    bodyweightKg: _bodyweightKg,
                    weightControllers: const {},
                    repsControllers: const {},
                    rirControllers: const {},
                    exerciseNote: null,
                    onEditNotes: (_) {},
                    onDeleteExercise: (_) {},
                    onAddSet: () {},
                    onDeleteSet: (_) {},
                    index: index,
                  ),
                  const Divider(height: 1),
                ]);
          },
        );
      },
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
          _buildChartHeader(l10n),
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
        _buildChartHeader(l10n),
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
            title: l10n.estimatedOneRepMaxInfoTitle,
            explanation: l10n.estimatedOneRepMaxInfoExplanation,
            keyPoints: l10n.estimatedOneRepMaxInfoPoints.split('\n'),
            technicalTitle: l10n.estimatedOneRepMaxInfoDetailsTitle,
            technicalExplanation: l10n.estimatedOneRepMaxInfoDetails,
            citationUrl:
                "https://trainlibre.com/docs/features/intelligent-workouts/#evidence",
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
