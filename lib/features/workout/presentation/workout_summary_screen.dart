import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/exercise_record_data.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../data/sources/workout_local_data_source.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../../home_widgets/application/home_widget_sync_service.dart';
import '../../../services/theme_service.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import 'edit_routine_screen.dart';
import '../../../services/health/workout_heart_rate_models.dart';
import '../../../services/health/workout_heart_rate_service.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/summary_card.dart';
import 'widgets/workout_photo_card.dart';
import 'widgets/workout_summary_bar.dart';
import 'widgets/muscle_color_helper.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../domain/classification/exercise_log_mask.dart';
import '../domain/classification/set_load.dart';

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
  Map<String, List<ExerciseRecordData>> _newRecordsPerExercise = {};

  Map<String, Exercise> _exerciseDetails = {};

  bool _showSyncBanner = false;
  Routine? _associatedRoutine;
  bool _isSyncing = false;
  bool _pulseTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.workoutSummary));
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
      final pulseTrackingFuture = PulseTrackingService().isTrackingEnabled();
      final Map<String, _ExerciseSummaryData> summaryMap = {};
      final Map<String, List<ExerciseRecordData>> newRecordsMap = {};
      final Map<String, Exercise> detailsMap = {};

      // Body weight on the day of this session, not today's.
      final bodyweightKg = (await db.getBodyweightHistory()).at(data.startTime);

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

        final isCardio = exercise?.isCardio ?? false;

        if (isCardio) {
          double totalDist = 0;
          int totalSeconds = 0;

          double sessionMaxDist = 0;
          int sessionMaxDur = 0;
          double sessionFastestPace = double.infinity;

          for (var s in sets) {
            final dist = s.distanceKm ?? 0.0;
            final dur = s.durationSeconds ?? 0;

            totalDist += dist;
            totalSeconds += dur;

            if (s.isCompleted == true) {
              if (dist > sessionMaxDist) sessionMaxDist = dist;
              if (dur > sessionMaxDur) sessionMaxDur = dur;
              if (dist > 0 && dur > 0) {
                final pace = dur / dist;
                if (pace < sessionFastestPace) sessionFastestPace = pace;
              }
            }
          }
          final int minutes = (totalSeconds / 60).round();
          summaryMap[name] = _ExerciseSummaryData.cardio(
            distanceKm: totalDist,
            minutes: minutes,
          );

          // Calculate PRs for cardio exercises
          final historicalBests = await db.getExerciseBests(
            name,
            excludeWorkoutLogId: widget.logId,
            isCardio: true,
          );

          List<ExerciseRecordData> records = [];
          if (sessionMaxDist > (historicalBests['maxDistance'] ?? 0)) {
            final double old = historicalBests['maxDistance'] ?? 0;
            records.add(
              ExerciseRecordData.cardio(
                label: 'Best Distance', // Or localized label later
                value:
                    '${sessionMaxDist.toStringAsFixed(2).replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "")} km',
                diff: old > 0
                    ? '+${(sessionMaxDist - old).toStringAsFixed(2).replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "")} km'
                    : null,
              ),
            );
          }
          if (sessionMaxDur > (historicalBests['maxDuration']?.toInt() ?? 0)) {
            final int old = historicalBests['maxDuration']?.toInt() ?? 0;
            final m = sessionMaxDur ~/ 60;
            final s = sessionMaxDur % 60;

            String? diffStr;
            if (old > 0) {
              final diff = sessionMaxDur - old;
              final dm = diff ~/ 60;
              final ds = diff % 60;
              diffStr = '+${dm > 0 ? '${dm}m ' : ''}${ds}s';
            }

            records.add(
              ExerciseRecordData.cardio(
                label: 'Longest Duration',
                value: '${m}m ${s}s',
                diff: diffStr,
              ),
            );
          }
          if (sessionFastestPace != double.infinity) {
            final oldFastest = historicalBests['fastestPace'] ?? 0.0;
            if (oldFastest == 0.0 || sessionFastestPace < oldFastest) {
              final pm = sessionFastestPace.toInt() ~/ 60;
              final ps = sessionFastestPace.toInt() % 60;

              String? diffStr;
              if (oldFastest > 0) {
                final diff = oldFastest - sessionFastestPace;
                final dm = diff.toInt() ~/ 60;
                final ds = diff.toInt() % 60;
                diffStr = '-${dm > 0 ? '${dm}m ' : ''}${ds}s';
              }

              records.add(
                ExerciseRecordData.cardio(
                  label: 'Fastest Pace',
                  value: '${pm}m ${ps}s / km',
                  diff: diffStr,
                ),
              );
            }
          }

          if (records.isNotEmpty) {
            newRecordsMap[name] = records;
          }
        } else {
          double totalVol = 0;
          double sessionMaxWeight = 0;
          double sessionMaxVolume = 0;
          double sessionMaxEst1rm = 0;

          final summaryMask = ExerciseLogMask.forExercise(exercise);

          for (var s in sets) {
            final w = s.weightKg ?? 0.0;
            final vol = setTonnageKg(
              trackingType: summaryMask.trackingType,
              loadMode: summaryMask.loadMode,
              loggedWeightKg: s.weightKg,
              reps: s.reps,
              bodyweightKg: bodyweightKg,
            );
            totalVol += vol;

            if (s.isCompleted == true && s.setType != 'warmup') {
              if (w > sessionMaxWeight) sessionMaxWeight = w;
              if (vol > sessionMaxVolume) sessionMaxVolume = vol;
              // Through the mask: an assistance machine's number is help, not
              // load, and reading it as load inverts the session best.
              final e1rm = summaryMask.estimatedOneRepMax(
                loggedWeightKg: s.weightKg,
                reps: s.reps,
                bodyweightKg: bodyweightKg,
              );
              if (e1rm != null && e1rm > sessionMaxEst1rm) {
                sessionMaxEst1rm = e1rm;
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

          List<ExerciseRecordData> records = [];
          if (sessionMaxWeight > (historicalBests['maxWeight'] ?? 0)) {
            final double old = historicalBests['maxWeight'] ?? 0;
            records.add(
              ExerciseRecordData.weight(
                label: l10n.exerciseMetricMaxWeight,
                valueKg: sessionMaxWeight,
                diffKg: old > 0 ? sessionMaxWeight - old : null,
              ),
            );
          }
          if (sessionMaxVolume > (historicalBests['maxVolume'] ?? 0)) {
            final double old = historicalBests['maxVolume'] ?? 0;
            records.add(
              ExerciseRecordData.weight(
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
              ExerciseRecordData.weight(
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
      final pulseTrackingEnabled = await pulseTrackingFuture;

      if (mounted) {
        setState(() {
          _log = data;
          _summaryPerExercise = summaryMap;
          _newRecordsPerExercise = newRecordsMap;
          _exerciseDetails = detailsMap;
          _heartRateSummary = heartRate;
          _pulseTrackingEnabled = pulseTrackingEnabled;
          _associatedRoutine = associatedRoutine;
          _showSyncBanner = showSyncBanner;
          _isLoading = false;
        });

        // Publish the heatmap for the Home Screen widget from here: this is the
        // one place per finished workout that has both the resolved exercises
        // and a live overlay to rasterise into.
        unawaited(_refreshHomeWidgets());
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// A finished workout moves recovery, the Last Workout card and its muscle
  /// heatmap all at once, so the cached statistics sections are dropped here
  /// rather than waited out.
  ///
  /// The heatmap itself is rendered by the sync service, not from this screen:
  /// tying it to a screen visit left every workout logged before the feature
  /// existed without one.
  Future<void> _refreshHomeWidgets() async {
    if (!mounted) return;
    // One frame of grace so the summary is on screen before the off-screen
    // render competes with it for the raster thread.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final sync = context.read<HomeWidgetSyncService>();
    sync.invalidateStatistics();
    await sync.refresh(
      l10n: AppLocalizations.of(context)!,
      isAiEnabled: context.read<ThemeService>().isAiEnabled,
    );
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
              icon: Icon(DesignConstants.adaptiveShareIcon),
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
                            // Overall statistics (very top, under the app bar)
                            WorkoutSummaryBar(
                              duration:
                                  _log!.endTime?.difference(_log!.startTime),
                              volume: globalVolume,
                              sets: _log!.sets.length,
                              progress: null,
                            ),
                            const SizedBox(height: DesignConstants.spacingL),

                            // Routine Title, Date/Time & Notes
                            Text(
                              _log!.routineName != null &&
                                      _log!.routineName!.isNotEmpty
                                  ? _log!.routineName!
                                  : l10n.freeWorkoutTitle,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMMd(
                                Localizations.localeOf(context).toString(),
                              ).add_Hm().format(_log!.startTime),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_log!.notes != null &&
                                _log!.notes!.isNotEmpty) ...[
                              const SizedBox(height: DesignConstants.spacingXS),
                              Text(
                                _log!.notes!,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                            const SizedBox(height: DesignConstants.spacingM),

                            // Photos (under Title, Date, Time and Stats)
                            WorkoutPhotoCard(
                              workoutLogId: _log!.id,
                              photoPaths: _log!.photoPaths,
                              isEditable: true,
                              onPhotosChanged: (updatedPaths) {
                                setState(() {
                                  _log = _log!.copyWith(
                                    photoPaths: updatedPaths,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: DesignConstants.spacingL),

                            if (_exerciseDetails.isNotEmpty) ...[
                              _buildMuscleHeatmap(l10n),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],
                            if (_heartRateSummary != null &&
                                (_pulseTrackingEnabled ||
                                    _heartRateSummary!.hasData)) ...[
                              _buildHeartRateCard(l10n, _heartRateSummary!),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            // NEW RECORDS SECTION
                            if (_newRecordsPerExercise.isNotEmpty) ...[
                              AppSectionHeader(
                                title: l10n.workoutSummaryNewRecordsTitle,
                                padding: EdgeInsets.zero,
                                action: AlgorithmInfoButton(
                                  title:
                                      "Estimated 1-Rep Max Heuristic (Epley Equation)",
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
                                      _exerciseDetails[entry.key]
                                              ?.getLocalizedName(context) ??
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

                            AppSectionHeader(
                              title: l10n.workoutSummaryExerciseOverview,
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            ..._summaryPerExercise.entries.map((entry) {
                              return SummaryCard(
                                child: ListTile(
                                  title: Text(
                                    _exerciseDetails[entry.key]
                                            ?.getLocalizedName(context) ??
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

                            // Update Routine Banner at the very bottom of the screen
                            if (_showSyncBanner &&
                                _associatedRoutine != null) ...[
                              const SizedBox(height: DesignConstants.spacingL),
                              _buildSyncBanner(colorScheme, textTheme),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),

                      // Fertig-Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          label: l10n.doneButtonLabel,
                          tooltip: l10n.doneButtonLabel,
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
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: DesignConstants.spacingS),
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
      if (ex.isCardio) continue;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.analyticsRecentDistributionHeatmap,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        DualBodyHighlighter(
          gender: context.watch<ProfileService>().gender.toBodyGender(),
          frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
          backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
        ),
      ],
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
    final logExCounts = <String, int>{};
    final logExNames = <String>[];

    for (final s in log.sets) {
      if (s.isCompleted == true && s.setType.toLowerCase() != 'warmup') {
        final name = s.exerciseName;
        final currentCount = logExCounts[name];
        if (currentCount != null) {
          logExCounts[name] = currentCount + 1;
        } else {
          logExNames.add(name);
          logExCounts[name] = 1;
        }
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

      if (routineEx.setTemplates.length != logExCounts[logName]) {
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
                  AppButton.primary(
                    onPressed: _isSyncing ? null : _syncRoutine,
                    label: l10n.updateNow,
                    tooltip: l10n.updateNow,
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
