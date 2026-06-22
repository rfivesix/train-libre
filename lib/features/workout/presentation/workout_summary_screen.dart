// lib/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../data/sources/workout_local_data_source.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import 'edit_routine_screen.dart';
import '../../../services/health/workout_heart_rate_models.dart';
import '../../../services/health/workout_heart_rate_service.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'widgets/workout_summary_bar.dart';
import 'widgets/muscle_color_helper.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A screen providing a summary of a recently finished workout session.
///
/// Typically shown after [LiveWorkoutScreen] ends, it highlights key metrics
/// like total volume, duration, and exercise-specific results.
class WorkoutSummaryScreen extends StatefulWidget {
  /// The unique identifier of the summarized workout log.
  final int logId;

  const WorkoutSummaryScreen({super.key, required this.logId});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  final WorkoutHeartRateService _heartRateService =
      const WorkoutHeartRateService();
  WorkoutHeartRateSummary? _heartRateSummary;
  static const ShareService _shareService = ShareService();

  // Store metric values and format them at build time so unit toggles update.
  Map<String, _ExerciseSummaryData> _summaryPerExercise = {};

  /// Stores new records achieved in this session per exercise.
  Map<String, List<_ExerciseRecordData>> _newRecordsPerExercise = {};

  Map<String, Exercise> _exerciseDetails = {};

  bool _showSyncBanner = false;
  Routine? _associatedRoutine;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  Future<void> _loadWorkoutDetails() async {
    final db = WorkoutLocalDataSource.instance;
    final data = await db.getWorkoutLogById(widget.logId);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (data != null) {
      final heartRateFuture = _heartRateService.loadForWorkoutWindow(
        startTime: data.startTime,
        endTime: data.endTime,
      );
      final Map<String, _ExerciseSummaryData> summaryMap = {};
      final Map<String, List<_ExerciseRecordData>> newRecordsMap = {};
      final Map<String, Exercise> detailsMap = {};

      final groupedSets = <String, List<SetLog>>{};
      for (var set in data.sets) {
        groupedSets.putIfAbsent(set.exerciseName, () => []).add(set);
      }

      for (var entry in groupedSets.entries) {
        final name = entry.key;
        final sets = entry.value;

        final exercise = await db.resolveExerciseForSetLog(sets.first);

        if (exercise != null) {
          detailsMap[name] = exercise;
        }

        final isCardio = exercise?.categoryName.toLowerCase() == 'cardio';

        if (isCardio) {
          double totalDist = 0;
          int totalSeconds = 0;
          for (var s in sets) {
            final dist = s.distanceKm ?? 0.0;
            final dur = s.durationSeconds ?? 0;

            totalDist += dist;
            totalSeconds += dur;
          }
          final int minutes = (totalSeconds / 60).round();
          summaryMap[name] = _ExerciseSummaryData.cardio(
            distanceKm: totalDist,
            minutes: minutes,
          );
        } else {
          double totalVol = 0;
          double sessionMaxWeight = 0;
          double sessionMaxVolume = 0;
          double sessionMaxEst1rm = 0;

          for (var s in sets) {
            final w = s.weightKg ?? 0.0;
            final r = s.reps ?? 0;
            totalVol += w * r;

            if (s.isCompleted == true && s.setType != 'warmup') {
              if (w > sessionMaxWeight) sessionMaxWeight = w;
              final vol = w * r;
              if (vol > sessionMaxVolume) sessionMaxVolume = vol;
              if (r > 0 && r <= 10) {
                final e1rm = w * (36 / (37 - r));
                if (e1rm > sessionMaxEst1rm) sessionMaxEst1rm = e1rm;
              }
            }
          }
          summaryMap[name] =
              _ExerciseSummaryData.strength(totalVolumeKg: totalVol);

          // Calculate PRs for strength exercises
          final historicalBests = await db.getExerciseBests(
            name,
            excludeWorkoutLogId: widget.logId,
          );

          List<_ExerciseRecordData> records = [];
          if (sessionMaxWeight > (historicalBests['maxWeight'] ?? 0)) {
            final double old = historicalBests['maxWeight'] ?? 0;
            records.add(
              _ExerciseRecordData.weight(
                label: l10n.exerciseMetricMaxWeight,
                valueKg: sessionMaxWeight,
                diffKg: old > 0 ? sessionMaxWeight - old : null,
              ),
            );
          }
          if (sessionMaxVolume > (historicalBests['maxVolume'] ?? 0)) {
            final double old = historicalBests['maxVolume'] ?? 0;
            records.add(
              _ExerciseRecordData.weight(
                label: l10n.exerciseMetricVolume,
                valueKg: sessionMaxVolume,
                diffKg: old > 0 ? sessionMaxVolume - old : null,
                fractionDigits: 0,
              ),
            );
          }
          if (sessionMaxEst1rm > (historicalBests['maxEst1rm'] ?? 0)) {
            final double old = historicalBests['maxEst1rm'] ?? 0;
            records.add(
              _ExerciseRecordData.weight(
                label: l10n.exerciseMetricEst1RM,
                valueKg: sessionMaxEst1rm,
                diffKg: old > 0 ? sessionMaxEst1rm - old : null,
              ),
            );
          }

          if (records.isNotEmpty) {
            newRecordsMap[name] = records;
          }
        }
      }

      // Fetch routine and compute structural/sequence delta
      bool showSyncBanner = false;
      Routine? associatedRoutine;

      if (data.routineId != null) {
        final routine = await db.getRoutineByUuid(data.routineId!);
        if (routine != null) {
          associatedRoutine = routine;
          showSyncBanner = _detectRoutineDelta(routine, data, detailsMap);
        }
      }

      final heartRate = await heartRateFuture;

      if (mounted) {
        setState(() {
          _log = data;
          _summaryPerExercise = summaryMap;
          _newRecordsPerExercise = newRecordsMap;
          _exerciseDetails = detailsMap;
          _heartRateSummary = heartRate;
          _associatedRoutine = associatedRoutine;
          _showSyncBanner = showSyncBanner;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate total volume only for strength, or omit it for mixed workouts?
    // Keep the global "Volume" header as the sum of all strength volume.
    double globalVolume = 0;
    if (_log != null) {
      for (var set in _log!.sets) {
        // Add only weight * reps (cardio usually has 0 or null here).
        globalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: l10n.workoutSummaryTitle,
        actions: [
          if (!_isLoading && _log != null)
            IconButton(
              tooltip: l10n.share,
              icon: const Icon(LucideIcons.share),
              onPressed: () => _shareService.showWorkoutShareSheet(
                context: context,
                workout: _log!,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Padding(
                  padding: DesignConstants.cardPadding,
                  child: Column(
                    children: [
                      // Exercise list and all summary content
                      Expanded(
                        child: ListView(
                          children: [
                            // Overall statistics
                            WorkoutSummaryBar(
                              duration:
                                  _log!.endTime?.difference(_log!.startTime),
                              volume: globalVolume,
                              sets: _log!.sets.length,
                              progress: null,
                            ),
                            const SizedBox(height: DesignConstants.spacingL),
                            if (_showSyncBanner &&
                                _associatedRoutine != null) ...[
                              _buildSyncBanner(colorScheme, textTheme),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],
                            if (_exerciseDetails.isNotEmpty) ...[
                              _buildMuscleHeatmap(l10n),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],
                            if (_heartRateSummary != null) ...[
                              _buildHeartRateCard(l10n, _heartRateSummary!),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            if (_log!.routineName != null &&
                                _log!.routineName!.isNotEmpty) ...[
                              Text(
                                _log!.routineName!,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                            ],
                            if (_log!.notes != null &&
                                _log!.notes!.isNotEmpty) ...[
                              Text(
                                _log!.notes!,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            // NEW RECORDS SECTION
                            if (_newRecordsPerExercise.isNotEmpty) ...[
                              Text(
                                l10n.workoutSummaryNewRecordsTitle,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                              ..._newRecordsPerExercise.entries.map((entry) {
                                return SummaryCard(
                                  child: ListTile(
                                    leading: const Icon(
                                      LucideIcons.trophy,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      entry.value
                                          .map(
                                            (record) =>
                                                record.format(unitService),
                                          )
                                          .join(', '),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            Text(
                              l10n.workoutSummaryExerciseOverview,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            ..._summaryPerExercise.entries.map((entry) {
                              return SummaryCard(
                                child: ListTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    entry.value.format(unitService),
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),

                      // Fertig-Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingL),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n.doneButtonLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeartRateCard(
    AppLocalizations l10n,
    WorkoutHeartRateSummary summary,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final hasMetrics = summary.hasSummaryMetrics;
    final qualityLabel = _qualityLabel(l10n, summary.quality);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutHeartRateSectionTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            if (hasMetrics)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: l10n.workoutHeartRateAverageLabel,
                      value:
                          '${summary.averageBpm!.round()} ${l10n.sleepBpmUnit}',
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: _buildMetricTile(
                      label: l10n.workoutHeartRateMaxLabel,
                      value: '${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}',
                    ),
                  ),
                ],
              )
            else
              Text(
                _noDataMessage(l10n, summary.noDataReason),
                style: textTheme.bodyMedium,
              ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              '${l10n.workoutHeartRateSampleCount(summary.sampleCount)} • $qualityLabel',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: DesignConstants.spacingS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(
    AppLocalizations l10n,
    WorkoutHeartRateDataQuality quality,
  ) {
    return switch (quality) {
      WorkoutHeartRateDataQuality.ready => l10n.workoutHeartRateQualityReady,
      WorkoutHeartRateDataQuality.limited =>
        l10n.workoutHeartRateQualityLimited,
      WorkoutHeartRateDataQuality.insufficient =>
        l10n.workoutHeartRateQualityInsufficient,
      WorkoutHeartRateDataQuality.noData => l10n.workoutHeartRateQualityNoData,
    };
  }

  Widget _buildMuscleHeatmap(AppLocalizations l10n) {
    final muscleCounts = <BodyPartSlug, int>{};

    for (final ex in _exerciseDetails.values) {
      final exerciseSlugs = <BodyPartSlug>{};
      for (final name in ex.primaryMuscles) {
        exerciseSlugs.addAll(BodySlugMapper.fromRawName(name));
      }

      for (final slug in exerciseSlugs) {
        muscleCounts[slug] = (muscleCounts[slug] ?? 0) + 1;
      }
    }

    final highlights = MuscleColorHelper.mapSlugWorkloadToPrimaryColors(
      context,
      muscleCounts.map((k, v) => MapEntry(k, v.toDouble())),
    );

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsRecentDistributionHeatmap,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: BodyHighlighter(
                      gender:
                          context.watch<ProfileService>().gender.toBodyGender(),
                      side: BodySide.front,
                      highlightedParts:
                          BodySlugMapper.forSide(highlights, BodySide.front),
                    ),
                  ),
                  Expanded(
                    child: BodyHighlighter(
                      gender:
                          context.watch<ProfileService>().gender.toBodyGender(),
                      side: BodySide.back,
                      highlightedParts:
                          BodySlugMapper.forSide(highlights, BodySide.back),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _noDataMessage(
    AppLocalizations l10n,
    WorkoutHeartRateNoDataReason reason,
  ) {
    return switch (reason) {
      WorkoutHeartRateNoDataReason.permissionDenied =>
        l10n.workoutHeartRateNoDataPermission,
      WorkoutHeartRateNoDataReason.platformUnavailable =>
        l10n.workoutHeartRateNoDataUnavailable,
      WorkoutHeartRateNoDataReason.workoutNotFinished =>
        l10n.workoutHeartRateNoDataWorkoutNotFinished,
      WorkoutHeartRateNoDataReason.invalidWorkoutWindow =>
        l10n.workoutHeartRateNoDataInvalidWindow,
      WorkoutHeartRateNoDataReason.queryFailed =>
        l10n.workoutHeartRateNoDataQueryFailed,
      _ => l10n.workoutHeartRateNoDataGeneral,
    };
  }

  bool _detectRoutineDelta(
    Routine routine,
    WorkoutLog log,
    Map<String, Exercise> exerciseDetails,
  ) {
    final workingSets = log.sets
        .where(
            (s) => s.isCompleted == true && s.setType.toLowerCase() != 'warmup')
        .toList();

    final logExNames = <String>[];
    for (final s in workingSets) {
      if (!logExNames.contains(s.exerciseName)) {
        logExNames.add(s.exerciseName);
      }
    }

    if (routine.exercises.length != logExNames.length) {
      return true;
    }

    for (int i = 0; i < logExNames.length; i++) {
      final logName = logExNames[i];
      final routineEx = routine.exercises[i];
      final logEx = exerciseDetails[logName];

      if (logEx == null) {
        return true;
      }

      if (routineEx.exercise.id != logEx.id &&
          routineEx.exercise.uuid != logEx.uuid) {
        return true;
      }

      final logSetsForEx =
          workingSets.where((s) => s.exerciseName == logName).toList();
      if (routineEx.setTemplates.length != logSetsForEx.length) {
        return true;
      }
    }

    return false;
  }

  Widget _buildSyncBanner(ColorScheme colorScheme, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        key: const ValueKey('sync_routine_banner'),
        elevation: 4,
        shadowColor: colorScheme.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.secondary.withValues(alpha: 0.03),
              ],
            ),
          ),
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignConstants.spacingS),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.refresh_cw,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.syncRoutineTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.syncRoutineSubtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Text(
                l10n.syncRoutineBody(_associatedRoutine!.name),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showSyncBanner = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.outline,
                    ),
                    child: Text(l10n.discard),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  FilledButton.icon(
                    onPressed: _isSyncing ? null : _syncRoutine,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL,
                        vertical: 10,
                      ),
                    ),
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(LucideIcons.check, size: 18),
                    label: Text(l10n.updateNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncRoutine() async {
    if (_log?.routineId == null || _log?.id == null) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final db = WorkoutLocalDataSource.instance;
      await db.syncRoutineWithWorkout(
        routineUuid: _log!.routineId!,
        workoutLogId: _log!.id!,
      );

      final updatedRoutine = await db.getRoutineByUuid(_log!.routineId!);

      if (mounted) {
        try {
          HapticFeedbackService.instance.confirmationFeedback();
        } catch (_) {}

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.syncRoutineSuccess),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: l10n.snackbarRoutineSavedAction,
              textColor: Colors.white,
              onPressed: () {
                if (updatedRoutine != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditRoutineScreen(routine: updatedRoutine),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.syncRoutineError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _showSyncBanner = false;
        });
      }
    }
  }
}

class _ExerciseSummaryData {
  final bool isCardio;
  final double? distanceKm;
  final int? minutes;
  final double? totalVolumeKg;

  const _ExerciseSummaryData._({
    required this.isCardio,
    this.distanceKm,
    this.minutes,
    this.totalVolumeKg,
  });

  factory _ExerciseSummaryData.cardio({
    required double distanceKm,
    required int minutes,
  }) {
    return _ExerciseSummaryData._(
      isCardio: true,
      distanceKm: distanceKm,
      minutes: minutes,
    );
  }

  factory _ExerciseSummaryData.strength({required double totalVolumeKg}) {
    return _ExerciseSummaryData._(
      isCardio: false,
      totalVolumeKg: totalVolumeKg,
    );
  }

  String format(UnitService unitService) {
    if (isCardio) {
      return '${(distanceKm ?? 0).toStringAsFixed(1).replaceAll('.0', '')} km | ${minutes ?? 0} min';
    }
    final volume = unitService.convertDisplayValue(
      totalVolumeKg ?? 0,
      UnitDimension.weight,
    );
    return '${volume.toStringAsFixed(0)} ${unitService.suffixFor(UnitDimension.weight)}';
  }
}

class _ExerciseRecordData {
  final String label;
  final double valueKg;
  final double? diffKg;
  final int fractionDigits;

  const _ExerciseRecordData.weight({
    required this.label,
    required this.valueKg,
    this.diffKg,
    this.fractionDigits = 1,
  });

  String format(UnitService unitService) {
    final value = unitService.convertDisplayValue(
      valueKg,
      UnitDimension.weight,
    );
    final diffText = diffKg == null
        ? ''
        : ' (+${unitService.convertDisplayValue(diffKg!, UnitDimension.weight).toStringAsFixed(fractionDigits).replaceAll('.0', '')})';
    return '$label (${value.toStringAsFixed(fractionDigits).replaceAll('.0', '')} ${unitService.suffixFor(UnitDimension.weight)}$diffText)';
  }
}
