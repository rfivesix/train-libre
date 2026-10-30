import 'dart:async';

import '../../../services/local_notification_service.dart';
import '../../../services/unit_service.dart';
import '../data/live_activity/workout_live_activity_service.dart';
import '../domain/classification/exercise_log_mask.dart';
import '../domain/live_activity/build_workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_strings.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import '../domain/live_workout_notification_preferences.dart';

typedef NextOpenSet = ({int exerciseIndex, int templateIndex, int templateId});

/// Host interface supplying live workout state and command execution to
/// [LiveWorkoutLiveActivityCoordinator].
abstract class LiveWorkoutLiveActivityHost {
  bool get isActive;
  WorkoutLog? get workoutLog;
  List<RoutineExercise> get exercises;
  Map<int, SetLog> get setLogs;
  UnitService get unitService;
  DateTime? get targetRestEndTime;
  DateTime? get restStartedAt;
  int? get activeSetTimerId;
  DateTime? get setTimerStartedAt;
  int get pausedSetTimerElapsedSeconds;
  int get setTimerBaseSeconds;
  Future<void>? get pendingProgressionUpdate;

  void cancelRest();
  void adjustRestTime(int deltaSeconds);
  Future<void> completeTimedSet(int timerTemplateId, {int? elapsedSeconds});
  void startSetTimer(int templateId,
      {DateTime? startedAt, int elapsedSeconds = 0});
  Future<void> stopSetTimer(int templateId, {int? elapsedSeconds});
  NextOpenSet? nextOpenSet();
  bool isDurationSet(int templateId);
  Future<void> updateSet(
    int templateId, {
    double? weight,
    int? reps,
    int? rir,
    bool? isCompleted,
  });
}

/// Coordinates Live Activity lifecycle, synchronization, background notification
/// sounds, and command ingestion for an active workout session.
class LiveWorkoutLiveActivityCoordinator {
  static const String liveActivityDeepLink = 'trainlibre://workout/live';

  final LiveWorkoutLiveActivityHost _host;
  final WorkoutLiveActivityService _liveActivityService;

  WorkoutLiveActivityStrings? _strings;
  String _localeName = 'en';
  bool _running = false;
  Future<void> _syncChain = Future<void>.value();
  int _restScheduleGeneration = 0;

  LiveWorkoutLiveActivityCoordinator({
    required LiveWorkoutLiveActivityHost host,
    WorkoutLiveActivityService? liveActivityService,
  })  : _host = host,
        _liveActivityService =
            liveActivityService ?? WorkoutLiveActivityService.instance;

  bool get isRunning => _running;
  WorkoutLiveActivityStrings? get strings => _strings;
  String get localeName => _localeName;
  WorkoutLiveActivityService get liveActivityService => _liveActivityService;

  /// Called by the live workout screen once localizations are available.
  void configure({
    required WorkoutLiveActivityStrings strings,
    required String localeName,
  }) {
    final isFirstConfiguration = _strings == null;
    _strings = strings;
    _localeName = localeName;
    if (isFirstConfiguration && _host.isActive) {
      unawaited(syncLiveActivity());
    }
  }

  void configureLiveActivity({
    required WorkoutLiveActivityStrings strings,
    required String localeName,
  }) =>
      configure(strings: strings, localeName: localeName);

  WorkoutLiveActivityContent? _buildLiveActivityContent() {
    final strings = _strings;
    if (strings == null) return null;
    return buildWorkoutLiveActivityContent(
      exercises: _host.exercises,
      setLogs: _host.setLogs,
      unitService: _host.unitService,
      strings: strings,
      localeName: _localeName,
      restEndsAt: _host.targetRestEndTime,
      restStartedAt: _host.restStartedAt,
      setTimerTemplateId: _host.activeSetTimerId,
      setTimerStartedAt: _host.setTimerStartedAt,
      setTimerElapsedSeconds: _host.activeSetTimerId == null
          ? _host.pausedSetTimerElapsedSeconds
          : _host.setTimerBaseSeconds,
      labelStartTimer: strings.startTimer,
      labelStopTimer: strings.stopTimer,
      labelTimerRunning: strings.timerRunning,
    );
  }

  /// Serializes refreshes so an older async payload cannot overwrite a newer
  /// one when several workout callbacks fire in the same frame.
  Future<void> syncLiveActivity() {
    final next = _syncChain.then((_) => _syncLiveActivityNow());
    _syncChain = next.catchError((_) {});
    return next;
  }

  /// Starts the activity on first call and updates it afterwards. Suggestions
  /// are awaited before building the payload, so pre-filled values are also
  /// visible in the Live Activity.
  Future<void> _syncLiveActivityNow() async {
    if (!_liveActivityService.isPlatformSupported) return;
    final log = _host.workoutLog;
    final strings = _strings;
    if (log == null || log.id == null || strings == null) return;
    if (!_host.isActive) return;

    final pendingProgression = _host.pendingProgressionUpdate;
    if (pendingProgression != null) {
      await pendingProgression;
    }

    final content = _buildLiveActivityContent();
    if (content == null) return;

    if (_running) {
      await _liveActivityService.update(content);
      return;
    }

    await _liveActivityService.start(
      attributes: WorkoutLiveActivityAttributes(
        workoutTitle: log.routineName ?? '',
        workoutStartedAt: log.startTime,
        deepLink: liveActivityDeepLink,
        workoutLogId: log.id!,
        labelAddExercise: strings.addExercise,
        labelOpenApp: strings.openApp,
        labelSkip: strings.skip,
        labelOverdue: strings.overduePrefix,
      ),
      content: content,
    );
    _running = true;
  }

  Future<void> endLiveActivity() async {
    if (!_running) return;
    _running = false;
    await _liveActivityService.end();
  }

  void scheduleRestSound(DateTime endsAt) {
    final generation = ++_restScheduleGeneration;
    unawaited(_scheduleRestSound(endsAt, generation));
  }

  Future<void> _scheduleRestSound(DateTime endsAt, int generation) async {
    final strings = _strings;
    if (_liveActivityService.isPlatformSupported && strings != null) {
      final enabled =
          await LiveWorkoutNotificationPreferences.restNotificationsEnabled();
      final ignoreSilent =
          await LiveWorkoutNotificationPreferences.ignoreSilentMode();
      if (generation != _restScheduleGeneration) return;
      await _liveActivityService.setRestNotificationsEnabled(enabled,
          refreshPending: false);
      if (generation != _restScheduleGeneration) return;
      await _liveActivityService.scheduleRestSound(
        endsAt: endsAt,
        title: strings.restDoneTitle,
        body: strings.restDoneBody,
        ignoreSilentMode: ignoreSilent,
      );
      return;
    }
    await LocalNotificationService.instance.scheduleRestTimerDoneNotification(
      secondsFromNow: endsAt.difference(DateTime.now()).inSeconds,
    );
  }

  void cancelRestSound() {
    _restScheduleGeneration++;
    LocalNotificationService.instance.cancelRestTimerNotification();
    unawaited(_liveActivityService.cancelRestSound());
  }

  /// Applies the commands that Live Activity buttons produced while the app
  /// was suspended or gone. Safe to call repeatedly — the queue is consumed.
  Future<void> applyPendingLiveActivityCommands() async {
    if (!_host.isActive) return;
    final commands = await _liveActivityService.consumePendingCommands();
    if (commands.isEmpty) return;

    for (final command in commands) {
      switch (command['kind']) {
        case 'skipRest':
          _host.cancelRest();
        case 'adjustRest':
          final delta = command['deltaSeconds'];
          if (delta is int) _host.adjustRestTime(delta);
        case 'completeSet':
          final timerTemplateId = command['timerTemplateId'];
          final elapsedSeconds = command['elapsedSeconds'];
          if (timerTemplateId is int && elapsedSeconds is int) {
            await _host.completeTimedSet(
              timerTemplateId,
              elapsedSeconds: elapsedSeconds,
            );
          } else {
            await _completeNextPlannedSet();
          }
        case 'startSetTimer':
          final id = command['templateId'];
          final startedAtMs = command['startedAtEpochMs'];
          if (id is int) {
            _host.startSetTimer(
              id,
              startedAt: startedAtMs is int
                  ? DateTime.fromMillisecondsSinceEpoch(startedAtMs)
                  : null,
              elapsedSeconds: command['elapsedSeconds'] is int
                  ? command['elapsedSeconds'] as int
                  : 0,
            );
          }
        case 'stopSetTimer':
          final id = command['templateId'];
          final elapsed = command['elapsedSeconds'];
          if (id is int) {
            await _host.stopSetTimer(
              id,
              elapsedSeconds: elapsed is int ? elapsed : null,
            );
          }
      }
    }
    await syncLiveActivity();
  }

  /// Completes the next open set with its planned values — the checkmark in
  /// the Live Activity carries no input of its own.
  ///
  /// Refuses when a required value is missing. The Live Activity already greys
  /// the checkmark out in that case, but a command could still arrive from a
  /// queue written before the values were cleared, and inventing a weight or a
  /// rep count would silently corrupt the log.
  Future<void> _completeNextPlannedSet() async {
    final next = _host.nextOpenSet();
    if (next != null && next.templateId >= 0) {
      final exercise = _host.exercises[next.exerciseIndex];
      final template = exercise.setTemplates[next.templateIndex];
      final templateId = next.templateId;
      final log = _host.setLogs[templateId];
      if (log != null && log.isCompleted != true) {
        if (_host.isDurationSet(templateId) &&
            _host.activeSetTimerId == templateId) {
          await _host.completeTimedSet(templateId);
          return;
        }
        // A set counts as filled in when the fields its mask actually shows
        // have values. Asking a plank for reps would block the finish button
        // on a number the row never offered.
        final mask = ExerciseLogMask.forExercise(exercise.exercise);
        if (mask.logsDistance &&
            log.durationSeconds == null &&
            log.distanceKm == null) {
          return;
        }
        if (mask.logsDuration &&
            !mask.logsDistance &&
            log.durationSeconds == null) {
          return;
        }

        // Only what the user actually entered is passed on; updateSet fills
        // the rest from the template, the same way the in-app checkmark does.
        // Resolving the targets here instead meant reimplementing that fill,
        // and the copy could not read a rep range like "8-12".
        await _host.updateSet(
          templateId,
          weight: log.weightKg,
          reps: log.reps,
          rir: log.rir ?? template.targetRir,
          isCompleted: true,
        );
        return;
      }
    }
  }
}
