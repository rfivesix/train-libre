import "../../../services/unit_service.dart";

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/classification/exercise_log_mask.dart';
import '../domain/classification/workout_set_position.dart';
import '../domain/models/set_log.dart';
import '../domain/models/set_template.dart';
import '../domain/models/workout_log.dart';
import '../domain/models/prescription_enums.dart';
import '../domain/parsers/rep_range_parser.dart' hide RepRange;
import '../domain/progression/progression_models.dart';
import '../domain/repositories/workout_repository.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../domain/log_workout_set_use_case.dart';
import '../data/live_activity/workout_live_activity_service.dart';
import '../domain/live_activity/build_workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_strings.dart';
import '../domain/workout_next_set.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/training_autonomy_service.dart';
import '../domain/services/workout_progression_service.dart';
import '../../../util/time_util.dart';
import '../../../services/telemetry/telemetry_service.dart';

class LiveWorkoutViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final IWorkoutRepository _repository;
  final DetectPersonalRecordUseCase _detectPRUseCase;
  final LogWorkoutSetUseCase _logSetUseCase;
  final WorkoutProgressionService _progressionService;
  final TrainingAutonomyService? _trainingAutonomyService;
  final bool _registerLifecycleObserver;

  // ignore: unused_field
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  final UnitService unitService;

  LiveWorkoutViewModel({
    required IWorkoutRepository repository,
    required this.unitService,
    DetectPersonalRecordUseCase? detectPRUseCase,
    LogWorkoutSetUseCase? logSetUseCase,
    WorkoutProgressionService? progressionService,
    TrainingAutonomyService? trainingAutonomyService,
    bool registerLifecycleObserver = true,
  })  : _repository = repository,
        _detectPRUseCase = detectPRUseCase ?? DetectPersonalRecordUseCase(),
        _logSetUseCase = logSetUseCase ?? LogWorkoutSetUseCase(),
        _progressionService = progressionService ??
            WorkoutProgressionService(
              repository: repository,
              unitService: unitService,
            ),
        _trainingAutonomyService = trainingAutonomyService,
        _registerLifecycleObserver = registerLifecycleObserver {
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
    _trainingAutonomyService?.addListener(_onAutonomyChanged);
  }

  @visibleForTesting
  factory LiveWorkoutViewModel.forTesting({
    required IWorkoutRepository workoutDb,
    UnitService? unitService,
    WorkoutProgressionService? progressionService,
    TrainingAutonomyService? trainingAutonomyService,
  }) {
    final resolvedUnitService = unitService ?? UnitService();
    return LiveWorkoutViewModel(
      repository: workoutDb,
      unitService: resolvedUnitService,
      progressionService: progressionService ??
          WorkoutProgressionService(
            repository: workoutDb,
            unitService: resolvedUnitService,
          ),
      trainingAutonomyService: trainingAutonomyService,
      registerLifecycleObserver: false,
    );
  }

  final Map<int, ProgressionSuggestion> _suggestions = {};
  final Set<int> _suggestedTemplates = {};
  final Set<int> _overriddenTemplates = {};
  final List<int> _completedWorkingOrder = [];
  bool _isDisposed = false;
  Future<void>? _pendingProgressionUpdate;

  @visibleForTesting
  Future<void>? get pendingProgressionUpdate => _pendingProgressionUpdate;

  bool get progressionEnabled =>
      _trainingAutonomyService?.level == AutonomyLevel.suggest;

  bool isSetSuggested(int templateId) {
    if (!_suggestedTemplates.contains(templateId)) return false;
    if (_overriddenTemplates.contains(templateId)) return false;
    final log = _setLogs[templateId];
    if (log == null || log.isCompleted == true) return false;
    return true;
  }

  void markSetOverridden(int templateId) {
    // Register a user edit even while the asynchronous suggestion lookup has
    // not yet finished. That makes a late lookup harmless.
    if (!_overriddenTemplates.add(templateId)) return;
    final log = _setLogs[templateId];
    if (log != null && _suggestedTemplates.contains(templateId)) {
      _setLogs[templateId] = log.copyWith(prescriptionOverridden: true);
    }
    notifyListeners();
  }

  String? getSuggestedFormattedWeight(int templateId) {
    final suggestion = _suggestions[templateId];
    if (suggestion == null || suggestion.targetWeight == null) return null;
    return unitService.formatDisplayWeight(suggestion.targetWeight!,
        fractionDigits: 2);
  }

  /// Changes whenever an engine value should perform its short AI-cloud
  /// appearance. Both the load and rep field use this same combined key.
  String? suggestionAppearanceKey(int templateId) {
    if (!isSetSuggested(templateId)) return null;
    final suggestion = _suggestions[templateId];
    if (suggestion == null) return null;
    return '${suggestion.targetWeight}:${suggestion.targetReps}:${suggestion.reason}';
  }

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, SetLog> _setLogs = {};
  final Map<int, int?> pauseTimes = {};

  Timer? _restTimer;
  DateTime? _targetRestEndTime;
  DateTime? _restStartedAt;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;
  int _autoAdvanceRevision = 0;
  int? _autoAdvanceExerciseIndex;

  Timer? _workoutDurationTimer;
  Duration _elapsedDuration = Duration.zero;

  double _totalVolume = 0.0;
  int _totalSets = 0;

  final Map<String, Map<String, double>> _exerciseBests = {};

  // UI State moved from view
  final Map<int, TextEditingController> weightControllers = {};
  final Map<int, TextEditingController> repsControllers = {};
  final Map<int, TextEditingController> rirControllers = {};
  final Map<String, List<SetLog>> lastPerformances = {};

  bool isLoading = true;

  final StreamController<PRAlert> _prEventsController =
      StreamController<PRAlert>.broadcast();
  Stream<PRAlert> get prEvents => _prEventsController.stream;

  double get totalVolume => _totalVolume;
  int get totalSets => _totalSets;
  WorkoutLog? get workoutLog => _workoutLog;
  List<RoutineExercise> get exercises => _exercises;
  int get remainingRestSeconds => _remainingRestSeconds;
  bool get showRestDone => _showRestDone;
  Duration get elapsedDuration => _elapsedDuration;
  Map<int, SetLog> get setLogs => _setLogs;
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;
  int get autoAdvanceRevision => _autoAdvanceRevision;
  int? get autoAdvanceExerciseIndex => _autoAdvanceExerciseIndex;
  int? get nextOpenExerciseIndex => _nextOpenSet()?.exerciseIndex;

  /// Whether a pause is currently counting down. Flips back to false the
  /// moment the countdown hits zero or is skipped, so the minimized bar can
  /// switch back to the workout duration without a delay of its own.
  bool get isResting => _remainingRestSeconds > 0;

  /// The exercise the minimized workout bar should name: the one the next
  /// open set belongs to, or — once every set is ticked off — the last one
  /// worked. Null while the workout holds no exercises at all, so the bar can
  /// leave its second row empty instead of inventing a placeholder.
  String? currentExerciseNameFor(String languageCode) {
    if (_exercises.isEmpty) return null;
    final next = _nextOpenSet();
    if (next != null) {
      return _displayNameOf(_exercises[next.exerciseIndex], languageCode);
    }
    return _displayNameOf(_exercises.last, languageCode);
  }

  ({int exerciseIndex, int templateIndex, int templateId})? _nextOpenSet() {
    final next = findNextWorkoutSet(_exercises, _setLogs);
    if (next == null) return null;
    return (
      exerciseIndex: next.exerciseIndex,
      templateIndex: next.templateIndex,
      templateId: next.templateId,
    );
  }

  String _displayNameOf(RoutineExercise exercise, String languageCode) {
    final localized = exercise.exercise.localizedNameFor(languageCode);
    return localized.isNotEmpty ? localized : exercise.exercise.canonicalName;
  }

  // ---------------------------------------------------------------------------
  // Live Activity (iOS)
  //
  // The view model stays context-free, so the screen injects the localized
  // strings once. Without them the activity is simply not started — the
  // workout itself never depends on it.
  // ---------------------------------------------------------------------------

  static const String liveActivityDeepLink = 'trainlibre://workout/live';

  final WorkoutLiveActivityService _liveActivityService =
      WorkoutLiveActivityService.instance;

  WorkoutLiveActivityStrings? _liveActivityStrings;
  String _liveActivityLocale = 'en';
  bool _liveActivityRunning = false;
  Future<void> _liveActivitySyncChain = Future<void>.value();

  /// Called by the live workout screen once localizations are available.
  void configureLiveActivity({
    required WorkoutLiveActivityStrings strings,
    required String localeName,
  }) {
    final isFirstConfiguration = _liveActivityStrings == null;
    _liveActivityStrings = strings;
    _liveActivityLocale = localeName;
    if (isFirstConfiguration && isActive) {
      unawaited(_syncLiveActivity());
    }
  }

  WorkoutLiveActivityContent? _buildLiveActivityContent() {
    final strings = _liveActivityStrings;
    if (strings == null) return null;
    return buildWorkoutLiveActivityContent(
      exercises: _exercises,
      setLogs: _setLogs,
      unitService: unitService,
      strings: strings,
      localeName: _liveActivityLocale,
      restEndsAt: _targetRestEndTime,
      restStartedAt: _restStartedAt,
    );
  }

  /// Serializes refreshes so an older async payload cannot overwrite a newer
  /// one when several workout callbacks fire in the same frame.
  Future<void> _syncLiveActivity() {
    final next = _liveActivitySyncChain.then((_) => _syncLiveActivityNow());
    _liveActivitySyncChain = next.catchError((_) {});
    return next;
  }

  /// Starts the activity on first call and updates it afterwards. Suggestions
  /// are awaited before building the payload, so pre-filled values are also
  /// visible in the Live Activity.
  Future<void> _syncLiveActivityNow() async {
    if (!_liveActivityService.isPlatformSupported) return;
    final log = _workoutLog;
    final strings = _liveActivityStrings;
    if (log == null || log.id == null || strings == null) return;
    if (!isActive) return;

    final pendingProgression = _pendingProgressionUpdate;
    if (pendingProgression != null) {
      await pendingProgression;
    }

    final content = _buildLiveActivityContent();
    if (content == null) return;

    if (_liveActivityRunning) {
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
    _liveActivityRunning = true;
  }

  Future<void> _endLiveActivity() async {
    if (!_liveActivityRunning) return;
    _liveActivityRunning = false;
    await _liveActivityService.end();
  }

  /// Whether the rest sound is handled natively instead of through
  /// [LocalNotificationService].
  ///
  /// Only on iOS, and only while a Live Activity is up: its App Intents can
  /// move the pause while the app is suspended, and only the native scheduler
  /// can be moved with it.
  ///
  /// Android has a live update of its own now, but its buttons reach a
  /// BroadcastReceiver in the app's own process rather than a separate
  /// extension, so [LocalNotificationService] can still be rescheduled from
  /// Dart — and keeping it means the app needs no exact-alarm permission.
  bool get _usesNativeRestSound =>
      _liveActivityRunning && !kIsWeb && Platform.isIOS;

  void _scheduleRestSound(DateTime endsAt) {
    final strings = _liveActivityStrings;
    if (_usesNativeRestSound && strings != null) {
      unawaited(_liveActivityService.scheduleRestSound(
        endsAt: endsAt,
        title: strings.restDoneTitle,
        body: strings.restDoneBody,
      ));
      return;
    }
    LocalNotificationService.instance.scheduleRestTimerDoneNotification(
      secondsFromNow: endsAt.difference(DateTime.now()).inSeconds,
    );
  }

  void _cancelRestSound() {
    LocalNotificationService.instance.cancelRestTimerNotification();
    if (_usesNativeRestSound) {
      unawaited(_liveActivityService.cancelRestSound());
    }
  }

  /// Applies the commands that Live Activity buttons produced while the app
  /// was suspended or gone. Safe to call repeatedly — the queue is consumed.
  Future<void> applyPendingLiveActivityCommands() async {
    if (!isActive) return;
    final commands = await _liveActivityService.consumePendingCommands();
    if (commands.isEmpty) return;

    for (final command in commands) {
      switch (command['kind']) {
        case 'skipRest':
          cancelRest();
        case 'adjustRest':
          final delta = command['deltaSeconds'];
          if (delta is int) adjustRestTime(delta);
        case 'completeSet':
          await _completeNextPlannedSet();
      }
    }
    await _syncLiveActivity();
  }

  /// Completes the next open set with its planned values — the checkmark in
  /// the Live Activity carries no input of its own.
  ///
  /// Refuses when a required value is missing. The Live Activity already greys
  /// the checkmark out in that case, but a command could still arrive from a
  /// queue written before the values were cleared, and inventing a weight or a
  /// rep count would silently corrupt the log.
  Future<void> _completeNextPlannedSet() async {
    final next = _nextOpenSet();
    if (next != null && next.templateId >= 0) {
      final exercise = _exercises[next.exerciseIndex];
      final template = exercise.setTemplates[next.templateIndex];
      final templateId = next.templateId;
      final log = _setLogs[templateId];
      if (log != null && log.isCompleted != true) {
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
        await updateSet(
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

  bool get _isAppInForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
      WidgetsBinding.instance.lifecycleState == null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  Future<void> tryRestoreSession() async {
    final ongoingWorkout = await _repository.getOngoingWorkout();
    if (ongoingWorkout != null) {
      await restoreWorkoutSession(ongoingWorkout);
    }
  }

  Future<void> startWorkout(
      WorkoutLog log, List<RoutineExercise> routineExercises) async {
    // Reopening a session this view model no longer holds — the restore on
    // startup never ran, or it failed and was swallowed — must not lay a
    // second set of empty rows on top of the ones already stored. That left
    // the workout showing blank values over duplicated sets.
    if (log.id != null && log.endTime == null) {
      final existing = await _repository.getSetLogsForWorkout(log.id!);
      if (existing.isNotEmpty) {
        await restoreWorkoutSession(log);
        return;
      }
    }

    _workoutLog = log;
    _exercises = normalizeSupersetGroups(List.from(routineExercises));

    _setLogs.clear();
    _completedWorkingOrder.clear();
    _suggestions.clear();
    _suggestedTemplates.clear();
    _overriddenTemplates.clear();
    pauseTimes.clear();

    for (var re in _exercises) {
      if (re.id != null) {
        pauseTimes[re.id!] = re.pauseSeconds;
      }
      if (re.notes != null && re.notes!.isNotEmpty) {
        await _repository.saveWorkoutExerciseNote(
          workoutLogId: log.id!,
          exerciseName: re.exercise.canonicalName,
          notes: re.notes,
        );
      }
    }

    await _createInitialSetLogs();
    _startWorkoutTimer();
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  Future<void> _createInitialSetLogs() async {
    _totalVolume = 0;
    _totalSets = 0;

    // Both the position and the exercise it belongs to are written with the
    // row. They used to be left at the column default of 0, which made the
    // rows indistinguishable and the restore's ordering arbitrary.
    final isRoutineWorkout = _workoutLog?.routineId != null ||
        (_workoutLog?.routineName != null &&
            _workoutLog!.routineName!.isNotEmpty);

    var logOrder = 0;
    for (var blockIndex = 0; blockIndex < _exercises.length; blockIndex++) {
      final re = _exercises[blockIndex];
      for (var template in re.setTemplates) {
        if (template.id == null) continue;

        final repRange =
            template.targetRepMin != null && template.targetRepMax != null
                ? (min: template.targetRepMin!, max: template.targetRepMax!)
                : parseRepRange(template.targetReps);

        final newSetLog = SetLog(
          workoutLogId: _workoutLog!.id!,
          exerciseId: re.exercise.uuid,
          exerciseName: re.exercise.canonicalName,
          setType: template.setType,
          weightKg: null,
          reps: null,
          restTimeSeconds: re.pauseSeconds,
          isCompleted: false,
          logOrder: logOrder,
          exerciseBlock: blockIndex,
          supersetGroup: re.supersetGroup,
          rir: null,
          progressionData: re.progression.copyWith(
              loadMode: re.progression.loadMode ??
                  LoadMode.fromString(re.exercise.loadMode),
              events: []).encode(),
          prescriptionOrigin: isRoutineWorkout
              ? PrescriptionOrigin.routine.name
              : PrescriptionOrigin.none.name,
          prescribedRepMin: isRoutineWorkout ? repRange?.min : null,
          prescribedRepMax: isRoutineWorkout ? repRange?.max : null,
          prescribedWeight: isRoutineWorkout ? template.targetWeight : null,
          prescribedRir: isRoutineWorkout ? template.targetRir : null,
        );

        final id = await _repository.insertSetLog(newSetLog);
        _setLogs[template.id!] = newSetLog.copyWith(id: id);
        _totalSets++;
        logOrder++;
      }
    }
    notifyListeners();
  }

  Future<void> restoreWorkoutSession(WorkoutLog log) async {
    _workoutLog = log;
    final savedSets = await _repository.getSetLogsForWorkout(log.id!);
    final savedExerciseNotes =
        await _repository.getWorkoutExerciseNotes(log.id!);

    _setLogs.clear();
    _completedWorkingOrder.clear();
    _suggestions.clear();
    _suggestedTemplates.clear();
    _overriddenTemplates.clear();
    final List<RoutineExercise> restoredExercises = [];
    _exercises = restoredExercises;
    pauseTimes.clear();
    _totalVolume = 0;
    _totalSets = 0;

    if (savedSets.isEmpty) {
      if (log.routineName != null) {
        final routine = await _repository.getRoutineByName(log.routineName!);
        if (routine != null) {
          _exercises = List.from(routine.exercises);
          for (var re in _exercises) {
            if (re.id != null) pauseTimes[re.id!] = re.pauseSeconds;
          }
        }
      }
      _startWorkoutTimer();
      notifyListeners();
      unawaited(_syncLiveActivity());
      return;
    }

    // Two rows with the same position must still come back in the same order
    // every time, or the blocks below get cut in different places on each
    // restore. Sets written before log_order was assigned per set all carry
    // the column default of 0, so the row id is what actually separates them.
    final sortedSets = List<SetLog>.from(savedSets)
      ..sort((a, b) {
        final byOrder = (a.logOrder ?? 0).compareTo(b.logOrder ?? 0);
        if (byOrder != 0) return byOrder;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

    // Sets written before the exercise_block column existed. Their session can
    // only be rebuilt the old way, by cutting the list wherever the exercise
    // name changes — which cannot tell two entries of the same exercise apart.
    // It is healed at the end of this method so the next restore is exact.
    final isLegacySession = sortedSets.any((s) => s.exerciseBlock == null);
    final blocks = isLegacySession
        ? _groupSetsByName(sortedSets)
        : _groupSetsByBlock(sortedSets);

    final usedIds = <int>{};
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.isEmpty) continue;

      final firstSet = block.first;
      final exName = firstSet.exerciseName;
      final exercise = await _repository.resolveExerciseForSetLog(firstSet) ??
          Exercise(
            texts: {'en': ExerciseText(name: exName)},
            categoryName: 'Unknown',
            primaryMuscles: const [],
            secondaryMuscles: const [],
          );

      // Ids derived from the clock could collide across blocks and silently
      // drop a set, because the map they key is the session's only copy of it.
      final syntheticReId = _nextSyntheticId(usedIds);
      usedIds.add(syntheticReId);

      // Every set of an exercise carries that exercise's pause, so the first
      // one that has a real pause defines the block's.
      int pauseSec = 0;
      for (final s in block) {
        if (s.restTimeSeconds != null && s.restTimeSeconds! > 0) {
          pauseSec = s.restTimeSeconds!;
          break;
        }
      }

      final List<SetTemplate> templates = [];
      for (final s in block) {
        final templateId = _nextSyntheticId(usedIds);
        usedIds.add(templateId);

        templates.add(
          SetTemplate(
            id: templateId,
            setType: s.setType,
            // Restore the active row exactly. The authored comparison remains
            // immutable on the SetLog prescription snapshot.
            targetWeight: s.weightKg,
            targetReps: s.prescribedRepMin != null && s.prescribedRepMax != null
                ? '${s.prescribedRepMin}-${s.prescribedRepMax}'
                : s.reps?.toString(),
            targetRepMin: s.prescribedRepMin,
            targetRepMax: s.prescribedRepMax,
            targetRir: s.rir,
          ),
        );

        _setLogs[templateId] = s;
        if (s.isCompleted != true &&
            !s.valuesAutoFilled &&
            (s.weightKg != null || s.reps != null)) {
          // An open row that already contains persisted, non-generated input
          // is a user entry from before the app was suspended. Protect it
          // before re-running suggestions during restoration.
          _overriddenTemplates.add(templateId);
        }
        if (s.isCompleted == true &&
            WorkoutSetPositionMapper.isWorking(s.setType)) {
          _completedWorkingOrder.add(templateId);
        }
        _totalVolume += (s.weightKg ?? 0) * (s.reps ?? 0);
        _totalSets++;
      }

      final savedNote = savedExerciseNotes[exercise.canonicalName] ??
          exercise.allNames
              .map((name) => savedExerciseNotes[name])
              .firstWhere((note) => note != null, orElse: () => null);
      final re = RoutineExercise(
        id: syntheticReId,
        exercise: firstSet.progression.loadMode == null
            ? exercise
            : exercise.copyWith(loadMode: firstSet.progression.loadMode!.name),
        setTemplates: templates,
        pauseSeconds: pauseSec,
        supersetGroup: isLegacySession ? null : firstSet.supersetGroup,
        progressionData: firstSet.progressionData,
        notes: savedNote,
      );

      restoredExercises.add(re);
      pauseTimes[syntheticReId] = pauseSec;
    }
    _exercises = normalizeSupersetGroups(restoredExercises);

    // A session from before this column existed has just been rebuilt by
    // guesswork. Writing the structure down now means the next kill restores
    // it exactly instead of guessing again from rows that all look alike.
    if (isLegacySession && restoredExercises.isNotEmpty) {
      await _updateLogOrdersInDatabase();
    }

    syncControllers();
    _pendingProgressionUpdate = _applyProgressionSuggestions();
    await _pendingProgressionUpdate;

    _startWorkoutTimer();
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  /// Groups sets by the exercise block recorded on each row.
  ///
  /// Blocks appear in the order the sets do, so an exercise the user moved
  /// keeps the position it had on screen.
  List<List<SetLog>> _groupSetsByBlock(List<SetLog> sortedSets) {
    final byBlock = <int, List<SetLog>>{};
    final blockOrder = <int>[];
    for (final s in sortedSets) {
      final block = s.exerciseBlock!;
      final bucket = byBlock.putIfAbsent(block, () {
        blockOrder.add(block);
        return <SetLog>[];
      });
      bucket.add(s);
    }
    return [for (final block in blockOrder) byBlock[block]!];
  }

  /// Groups sets by runs of the same exercise name.
  ///
  /// Only for sessions started before the exercise block was recorded: two
  /// adjacent entries of the same exercise collapse into one here, which is
  /// exactly why the block is written down now.
  List<List<SetLog>> _groupSetsByName(List<SetLog> sortedSets) {
    final blocks = <List<SetLog>>[];
    String? currentExerciseName;
    List<SetLog> currentBlock = [];

    for (final s in sortedSets) {
      if (s.exerciseName != currentExerciseName) {
        if (currentBlock.isNotEmpty) blocks.add(currentBlock);
        currentBlock = [s];
        currentExerciseName = s.exerciseName;
      } else {
        currentBlock.add(s);
      }
    }
    if (currentBlock.isNotEmpty) blocks.add(currentBlock);
    return blocks;
  }

  Future<void> loadInitialData(
      WorkoutLog initialLog, List<RoutineExercise>? initialExercises) async {
    isLoading = true;
    notifyListeners();

    List<RoutineExercise> exercisesToInit = [];
    if (!isActive) {
      exercisesToInit = initialExercises ?? [];
      await startWorkout(initialLog, exercisesToInit);
    } else {
      exercisesToInit = _exercises;
    }

    for (var re in exercisesToInit) {
      final lastSets = await _repository.getLastSetsForExercise(
        exerciseId: re.exercise.uuid,
        exerciseNameSnapshot: re.exercise.canonicalName,
      );
      lastPerformances[re.exercise.canonicalName] = lastSets;
    }

    await loadBodyweight();
    syncControllers();
    _pendingProgressionUpdate = _applyProgressionSuggestions();
    await _pendingProgressionUpdate;
    isLoading = false;
    notifyListeners();
  }

  /// The user's most recently recorded body weight, or null when they have
  /// never weighed themselves. Only used to value body-weight and assisted
  /// sets; a null shows no e1RM for those rather than an inverted one.
  double? bodyweightKg;

  Future<void> loadBodyweight() async {
    try {
      final history = await _repository.getBodyweightHistory();
      bodyweightKg = history.at(DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint('[LiveWorkout] body weight unavailable: $e');
    }
  }

  void syncControllers() {
    _setLogs.forEach((templateId, setLog) {
      final exercise = _exercises.firstWhere(
        (re) => re.setTemplates.any((t) => t.id == templateId),
        orElse: () => _exercises.first,
      );
      final mask = ExerciseLogMask.forExercise(exercise.exercise);

      if (!weightControllers.containsKey(templateId)) {
        String initText;
        if (mask.logsDistance) {
          initText = setLog.distanceKm == null
              ? ''
              : setLog.distanceKm!
                  .toStringAsFixed(3)
                  .replaceAll(RegExp(r'0*$'), '')
                  .replaceAll(RegExp(r'\.$'), '');
        } else {
          // Left blank when nothing was entered — including for an added-weight
          // column, where blank is a meaningful answer rather than a missing
          // one: it means the set was done with body weight alone.
          initText = setLog.weightKg == null
              ? ''
              : unitService.formatDisplayWeight(setLog.weightKg!,
                  fractionDigits: 2);
        }
        weightControllers[templateId] = TextEditingController(text: initText);
      }

      if (!repsControllers.containsKey(templateId)) {
        String initText;
        if (mask.logsDuration) {
          initText = formatPauseDuration(setLog.durationSeconds);
        } else {
          initText = setLog.reps?.toString() ?? '';
        }
        repsControllers[templateId] = TextEditingController(text: initText);
      }

      if (!rirControllers.containsKey(templateId)) {
        rirControllers[templateId] =
            TextEditingController(text: setLog.rir?.toString() ?? '');
      }
    });
  }

  /// Writes a completed set's resolved values into its input fields.
  ///
  /// Completing a set fills in whatever the user left blank from the template's
  /// targets. Those land in the [SetLog] but not in the text fields, which then
  /// keep showing the grey hint instead of the value that was actually logged.
  /// Belongs here rather than in the row widget so every completion path gets
  /// it — the Live Activity's button never goes through the widget at all.
  void _fillControllersFromSet(int templateId, SetLog setLog) {
    final exercise = _exercises.firstWhere(
      (re) => re.setTemplates.any((t) => t.id == templateId),
      orElse: () => _exercises.first,
    );

    final mask = ExerciseLogMask.forExercise(exercise.exercise);

    if (mask.logsDistance) {
      if (setLog.distanceKm != null) {
        weightControllers[templateId]?.text = setLog.distanceKm!
            .toStringAsFixed(3)
            .replaceAll(RegExp(r'0*$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
    } else if (setLog.weightKg != null) {
      weightControllers[templateId]?.text =
          unitService.formatDisplayWeight(setLog.weightKg!, fractionDigits: 2);
    }

    if (mask.logsDuration) {
      if (setLog.durationSeconds != null) {
        repsControllers[templateId]?.text =
            formatPauseDuration(setLog.durationSeconds);
      }
    } else if (setLog.reps != null) {
      repsControllers[templateId]?.text = setLog.reps!.toString();
    }
    rirControllers[templateId]?.text = setLog.rir?.toString() ?? '';
  }

  void disposeControllers() {
    for (var c in weightControllers.values) {
      c.dispose();
    }
    for (var c in repsControllers.values) {
      c.dispose();
    }
    for (var c in rirControllers.values) {
      c.dispose();
    }
    weightControllers.clear();
    repsControllers.clear();
    rirControllers.clear();
  }

  Future<void> updateSet(
    int templateId, {
    double? weight,
    bool clearWeight = false,
    int? reps,
    bool clearReps = false,
    bool? isCompleted,
    String? setType,
    int? rir,
    bool clearRir = false,
    double? distance,
    bool clearDistance = false,
    int? duration,
    bool clearDuration = false,
  }) async {
    if (!_setLogs.containsKey(templateId)) return;
    if (weight != null || reps != null || clearWeight || clearReps) {
      // A suggestion may still be resolving when the user starts typing in
      // the next row. Record the edit immediately, even before that async
      // suggestion has registered itself, so it can never overwrite and
      // subsequently discard a real set at workout finalization.
      markSetOverridden(templateId);
    }

    final oldLog = (weight != null || reps != null)
        ? _setLogs[templateId]!.copyWith(valuesAutoFilled: false)
        : _setLogs[templateId]!;
    SetTemplate? template;
    for (var re in _exercises) {
      for (var t in re.setTemplates) {
        if (t.id == templateId) {
          template = t;
          break;
        }
      }
      if (template != null) break;
    }

    final result = _logSetUseCase.execute(
      oldLog: oldLog,
      template: template,
      weight: weight,
      clearWeight: clearWeight,
      reps: reps,
      clearReps: clearReps,
      isCompleted: isCompleted,
      setType: setType,
      rir: rir,
      clearRir: clearRir,
      distance: distance,
      clearDistance: clearDistance,
      duration: duration,
      clearDuration: clearDuration,
    );

    var finalSet = result.updatedSet;

    // Handle progression suggestion provenance & override status
    final suggestion = _suggestions[templateId];
    if (suggestion != null) {
      final isOverridden = _overriddenTemplates.contains(templateId);
      {
        final repRange =
            template?.targetRepMin != null && template?.targetRepMax != null
                ? (min: template!.targetRepMin!, max: template.targetRepMax!)
                : parseRepRange(template?.targetReps);

        finalSet = finalSet.copyWith(
          prescriptionOrigin: PrescriptionOrigin.engine.name,
          prescribedWeight: suggestion.targetWeight,
          prescribedRepMin: repRange?.min,
          prescribedRepMax: repRange?.max,
          progressionReason: suggestion.reason,
          progressionAlgorithmVersion: suggestion.algorithmVersion,
          prescriptionOverridden: isOverridden,
          // When suggestion accepted unchanged and user left weight field untouched:
          weightKg: isOverridden
              ? finalSet.weightKg
              : (finalSet.weightKg ?? suggestion.targetWeight),
          reps: isOverridden
              ? finalSet.reps
              : (finalSet.reps ?? suggestion.targetReps),
          // Generated values are normal evidence once the user checks the
          // set. The flag only tells finalization that an unfinished row was
          // a disposable engine placeholder.
          // Checking an untouched suggestion is an explicit confirmation of
          // the visible values. It is a performed set, not a disposable
          // placeholder or second-class history record.
          valuesAutoFilled: isCompleted == true
              ? false
              : (!isOverridden && finalSet.valuesAutoFilled),
        );
      }
    }

    _setLogs[templateId] = finalSet;
    if (finalSet.rir != oldLog.rir) {
      rirControllers[templateId]?.text = finalSet.rir?.toString() ?? '';
    }
    // Suggestions populate open rows before they are checked, so the generic
    // use case sees no value delta on completion. Volume must instead track
    // the completed state transition itself.
    double completedVolume(SetLog set) =>
        set.isCompleted == true ? (set.weightKg ?? 0) * (set.reps ?? 0) : 0;
    _totalVolume += completedVolume(finalSet) - completedVolume(oldLog);

    if (isCompleted == true && oldLog.isCompleted != true) {
      if (WorkoutSetPositionMapper.isWorking(finalSet.setType)) {
        _completedWorkingOrder.remove(templateId);
        _completedWorkingOrder.add(templateId);
      }
    } else if (isCompleted == false && oldLog.isCompleted == true) {
      _completedWorkingOrder.remove(templateId);
    }

    if (isCompleted == true &&
        oldLog.isCompleted != true &&
        finalSet.setType != 'warmup') {
      await _checkAndApplyPRs(finalSet, templateId);
    }

    await _repository.updateSetLogs([_setLogs[templateId]!]);

    if (isCompleted == true && oldLog.isCompleted != true) {
      _fillControllersFromSet(templateId, finalSet);

      _applyRestAfterCompletion(templateId);
      final next = _nextOpenSet();
      _autoAdvanceExerciseIndex = next?.exerciseIndex;
      _autoAdvanceRevision++;

      // Advance suggestions to the next open set of the exercise
      _pendingProgressionUpdate = _applyProgressionSuggestions();
      unawaited(_pendingProgressionUpdate!);
    } else if (isCompleted == false && oldLog.isCompleted == true) {
      // Set uncompleted: refresh suggestions
      _pendingProgressionUpdate = _applyProgressionSuggestions();
      unawaited(_pendingProgressionUpdate!);
    } else if (setType != null && setType != oldLog.setType) {
      // A type change can turn a warm-up/drop set into a working position (or
      // remove one). Re-evaluate the position map immediately.
      _pendingProgressionUpdate = _applyProgressionSuggestions();
      unawaited(_pendingProgressionUpdate!);
    }

    notifyListeners();
    // The next set changed — this is the main reason the activity updates.
    unawaited(_syncLiveActivity());
  }

  void _onAutonomyChanged() {
    final autonomy = _trainingAutonomyService?.level ?? AutonomyLevel.off;
    if (autonomy == AutonomyLevel.suggest) {
      _pendingProgressionUpdate = _applyProgressionSuggestions();
      _pendingProgressionUpdate?.then((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      // Autonomy turned off: clear pre-filled suggestions on open unedited sets
      for (final templateId in _suggestedTemplates.toList()) {
        final log = _setLogs[templateId];
        if (log != null &&
            log.isCompleted != true &&
            !_overriddenTemplates.contains(templateId)) {
          weightControllers[templateId]?.text = '';
          repsControllers[templateId]?.text = '';
          _setLogs[templateId] = log.copyWith(
            clearWeight: true,
            clearReps: true,
            clearPrescribedWeight: true,
            clearPrescribedRepMin: true,
            clearPrescribedRepMax: true,
            valuesAutoFilled: false,
            prescriptionOrigin: _workoutLog?.routineName != null
                ? PrescriptionOrigin.routine.name
                : PrescriptionOrigin.none.name,
          );
          unawaited(_repository.updateSetLogs([_setLogs[templateId]!]));
        }
      }
      _suggestedTemplates.clear();
      _suggestions.clear();
      notifyListeners();
    }
  }

  Future<void> _applyProgressionSuggestions() async {
    if (_isDisposed) return;
    final autonomyLevel = _trainingAutonomyService?.level ?? AutonomyLevel.off;
    if (autonomyLevel != AutonomyLevel.suggest) return;

    for (var re in _exercises) {
      if (_isDisposed) return;
      final mask = ExerciseLogMask.forExercise(re.exercise)
          .withSnapshotMode(re.progression.loadMode?.name);
      if (!mask.supportsLoadRepProgression) continue;

      // Progression positions are only normal/failure sets. This is read from
      // the live log rather than the template so a just-changed set type takes
      // effect without requiring a restart.
      final workingTemplates = re.setTemplates.where((template) {
        final type = _setLogs[template.id]?.setType;
        return type != null && WorkoutSetPositionMapper.isWorking(type);
      }).toList();
      if (workingTemplates.isEmpty) continue;

      final currentWorkingSets = workingTemplates
          .map((template) => _setLogs[template.id])
          .whereType<SetLog>()
          .toList();
      final openTemplates = workingTemplates.where((template) {
        return _setLogs[template.id]?.isCompleted != true;
      }).toList();
      if (openTemplates.isEmpty) continue;

      final hasCompletedWorkingSet =
          currentWorkingSets.any((set) => set.isCompleted == true);
      // JIT progression intentionally exposes one next set at a time. The
      // completed predecessor is the evidence for that one prescription; a
      // later row remains untouched until its own predecessor is completed.
      final templatesToFill = <SetTemplate>[openTemplates.first];

      for (final nextOpenTemplate in templatesToFill) {
        final templateId = nextOpenTemplate.id;
        if (templateId == null || _overriddenTemplates.contains(templateId)) {
          continue;
        }

        ProgressionSuggestion? suggestion;
        if (hasCompletedWorkingSet && _workoutLog?.id != null) {
          suggestion = await _progressionService.getInWorkoutSuggestion(
            exercise: re.exercise,
            workingTemplates: workingTemplates,
            currentWorkingSets: currentWorkingSets,
            targetTemplateId: templateId,
            currentWorkoutLogId: _workoutLog!.id!,
            config: currentWorkingSets.first.progression,
            bodyweightKg: bodyweightKg,
          );
        } else {
          suggestion = (await _progressionService.getProgressionSuggestions(
            exercise: re.exercise,
            workingTemplates: workingTemplates,
            config: currentWorkingSets.first.progression,
            excludeWorkoutLogId: _workoutLog?.id,
            bodyweightKg: bodyweightKg,
          ))[templateId];
        }
        if (_isDisposed) return;

        // The user can edit while the history lookup above is in flight.
        // Re-check after awaiting so a late result never replaces their data.
        if (_overriddenTemplates.contains(templateId)) continue;

        if (suggestion == null ||
            (suggestion.targetWeight == null &&
                suggestion.targetReps == null)) {
          continue;
        }

        final previousSuggestion = _suggestions[templateId];
        _suggestions[templateId] = suggestion;
        _suggestedTemplates.add(templateId);

        final controller = weightControllers[templateId];
        if (controller != null && suggestion.targetWeight != null) {
          final previousWeight = previousSuggestion?.targetWeight == null
              ? null
              : unitService.formatDisplayWeight(
                  previousSuggestion!.targetWeight!,
                  fractionDigits: 2);
          if (controller.text.isEmpty || controller.text == previousWeight) {
            controller.text = unitService.formatDisplayWeight(
              suggestion.targetWeight!,
              fractionDigits: 2,
            );
          }
        }
        final repsController = repsControllers[templateId];
        final previousReps = previousSuggestion?.targetReps?.toString();
        final suggestedReps = suggestion.targetReps?.toString();
        if (repsController != null &&
            suggestedReps != null &&
            (repsController.text.isEmpty ||
                repsController.text == previousReps)) {
          repsController.text = suggestedReps;
        }

        // Populate the ordinary set fields. Generated values are deliberately
        // no different from values the user can type over immediately.
        final currentLog = _setLogs[templateId];
        if (currentLog != null) {
          final repRange = nextOpenTemplate.targetRepMin != null &&
                  nextOpenTemplate.targetRepMax != null
              ? (
                  min: nextOpenTemplate.targetRepMin!,
                  max: nextOpenTemplate.targetRepMax!
                )
              : parseRepRange(nextOpenTemplate.targetReps);

          final updated = currentLog.copyWith(
            weightKg: suggestion.targetWeight ?? currentLog.weightKg,
            prescriptionOrigin: PrescriptionOrigin.engine.name,
            prescribedWeight: suggestion.targetWeight,
            prescribedRepMin: repRange?.min,
            prescribedRepMax: repRange?.max,
            reps: suggestion.targetReps ?? currentLog.reps,
            progressionReason: suggestion.reason,
            progressionAlgorithmVersion: suggestion.algorithmVersion,
            prescriptionOverridden: false,
            valuesAutoFilled: true,
          );
          _setLogs[templateId] = updated;
          if (_isDisposed) return;
          await _repository.updateSetLogs([updated]);
        }
      }
    }

    // The progression work above is asynchronous. TextEditingControllers
    // update their field contents themselves, but the suggestion key used by
    // the generated-value morph lives in this view model. Rebuild on the next
    // frame: this method can finish while the workout screen is laying out,
    // and notifying listeners in that phase dirties its semantics tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) notifyListeners();
    });
  }

  void _applyRestAfterCompletion(int templateId) {
    var exerciseIndex = -1;
    var templateIndex = -1;
    for (var index = 0; index < _exercises.length; index++) {
      final found = _exercises[index]
          .setTemplates
          .indexWhere((template) => template.id == templateId);
      if (found != -1) {
        exerciseIndex = index;
        templateIndex = found;
        break;
      }
    }
    if (exerciseIndex == -1) return;

    final exercise = _exercises[exerciseIndex];
    final group = exercise.supersetGroup;
    int? pauseTime = pauseTimes[exercise.id!];
    var shouldRest = templateIndex < exercise.setTemplates.length - 1;

    if (group != null) {
      var groupStart = exerciseIndex;
      var groupEnd = exerciseIndex;
      while (
          groupStart > 0 && _exercises[groupStart - 1].supersetGroup == group) {
        groupStart--;
      }
      while (groupEnd + 1 < _exercises.length &&
          _exercises[groupEnd + 1].supersetGroup == group) {
        groupEnd++;
      }

      final participants = <int>[];
      for (var member = groupStart; member <= groupEnd; member++) {
        if (_exercises[member].setTemplates.length > templateIndex) {
          participants.add(member);
        }
      }
      final participantPosition = participants.indexOf(exerciseIndex);
      if (participants.length > 1 &&
          participantPosition < participants.length - 1) {
        shouldRest = false;
      } else if (participants.length > 1) {
        shouldRest = false;
        for (var member = groupStart; member <= groupEnd; member++) {
          final templates = _exercises[member].setTemplates;
          for (var nextRound = templateIndex + 1;
              nextRound < templates.length;
              nextRound++) {
            final id = templates[nextRound].id;
            if (id != null && _setLogs[id]?.isCompleted != true) {
              shouldRest = true;
              break;
            }
          }
          if (shouldRest) break;
        }
        final lastMember = _exercises[groupEnd];
        pauseTime = pauseTimes[lastMember.id!];
      }
      // With only one participant in an uneven trailing round, the set uses
      // its own pause exactly like a standalone exercise.
    }

    if (shouldRest && pauseTime != null && pauseTime > 0) {
      _startRestTimer(pauseTime);
    } else if (_targetRestEndTime != null) {
      cancelRest();
    }
  }

  Future<void> _checkAndApplyPRs(SetLog setLog, int templateId) async {
    final exName = setLog.exerciseName;

    if (!_exerciseBests.containsKey(exName)) {
      final exercise = await _repository.getExerciseByName(exName);
      final altName =
          exercise?.canonicalName != exName ? exercise?.canonicalName : null;
      final exerciseUuid = exercise?.id != null
          ? await _repository.getExerciseUuidByLocalId(exercise!.id!)
          : null;

      final bests = await _repository.getExerciseBests(
        exName,
        altName: altName,
        exerciseUuid: exerciseUuid,
      );
      _exerciseBests[exName] = bests;
    }

    // The same mask the row was rendered with, so the current set is valued
    // the way its own history was.
    final exerciseForMask = _exercises
        .map((re) => re.exercise)
        .where((e) => e.allNames.contains(exName))
        .firstOrNull;

    final prResult = _detectPRUseCase.execute(
      unitService: unitService,
      currentSet: setLog,
      historicalBests: _exerciseBests[exName]!,
      mask: ExerciseLogMask.forExercise(exerciseForMask),
      bodyweightKg: bodyweightKg,
    );

    _setLogs[templateId] = prResult.updatedSetLog;

    if (prResult.alerts.isNotEmpty) {
      HapticFeedback.heavyImpact();
      for (final alert in prResult.alerts) {
        _prEventsController.add(alert);
      }
    }
  }

  Future<void> addSetToExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    final re = _exercises[reIndex];

    final existingTemplateIds = _allTemplateIds()..addAll(_setLogs.keys);
    final tempTemplateId = _nextSyntheticId(existingTemplateIds);

    // A manually appended set is a new working set. It keeps the preceding
    // working prescription's rep range, but deliberately does not copy logged
    // values and never inherits a drop-set prescription.
    SetTemplate? precedingWorkingTemplate;
    for (final candidate in re.setTemplates.reversed) {
      final currentType = _setLogs[candidate.id]?.setType ?? candidate.setType;
      if (WorkoutSetPositionMapper.isWorking(currentType)) {
        precedingWorkingTemplate = candidate;
        break;
      }
    }

    final repProgressionSupported =
        ExerciseLogMask.forExercise(re.exercise).supportsLoadRepProgression;
    final parsedPrecedingRange =
        parseRepRange(precedingWorkingTemplate?.targetReps);
    final explicitPrecedingRange =
        precedingWorkingTemplate?.targetRepMin != null &&
                precedingWorkingTemplate?.targetRepMax != null
            ? (
                min: precedingWorkingTemplate!.targetRepMin!,
                max: precedingWorkingTemplate.targetRepMax!
              )
            : null;
    // A single prescription such as `10` is a fixed target, not a range to
    // inherit. Only a genuine range is copied; otherwise eligible exercises
    // receive the neutral 8–12 fallback below.
    final candidateRange = explicitPrecedingRange ?? parsedPrecedingRange;
    final hasInheritedRange =
        candidateRange != null && candidateRange.min != candidateRange.max;
    final inheritedRange = hasInheritedRange ? candidateRange : null;
    final targetReps = inheritedRange == null
        ? (repProgressionSupported ? '8-12' : null)
        : '${inheritedRange.min}-${inheritedRange.max}';

    final newTemplate = SetTemplate(
      id: tempTemplateId,
      setType: 'normal',
      targetReps: targetReps,
      targetRepMin: inheritedRange?.min ?? (repProgressionSupported ? 8 : null),
      targetRepMax:
          inheritedRange?.max ?? (repProgressionSupported ? 12 : null),
      targetWeight: null,
      targetRir: precedingWorkingTemplate?.targetRir,
    );

    // copyWith rather than the constructor: rebuilding it by hand dropped the
    // exercise's notes every time a set was added.
    final updatedRe = re.copyWith(
      setTemplates: [...re.setTemplates, newTemplate],
    );
    final newExercises = List<RoutineExercise>.from(_exercises);
    newExercises[reIndex] = updatedRe;
    _exercises = newExercises;

    final newSetLog = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseId: re.exercise.uuid,
      exerciseName: re.exercise.canonicalName,
      setType: 'normal',
      progressionData: re.progressionData,
      // A newly added working set has no made-up raw-row predecessor. Once a
      // real working set exists today, the progression fallback supplies it
      // from that set (and never from a warm-up or drop set).
      weightKg: null,
      reps: null,
      restTimeSeconds: re.pauseSeconds,
      isCompleted: false,
      // Placeholder only. The set belongs after the exercise's other sets, not
      // at the end of the workout, which is where the number of sets logged so
      // far used to put it — and that is what tore an exercise in two on the
      // next restore. _updateLogOrdersInDatabase below assigns the real one.
      logOrder: _setLogs.length,
      exerciseBlock: reIndex,
      supersetGroup: re.supersetGroup,
      rir: null,
    );

    final dbId = await _repository.insertSetLog(newSetLog);
    _setLogs[tempTemplateId] = newSetLog.copyWith(id: dbId);
    _totalSets++;

    await _updateLogOrdersInDatabase();
    syncControllers();
    _pendingProgressionUpdate = _applyProgressionSuggestions();
    unawaited(_pendingProgressionUpdate!);
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  Future<void> removeSet(int templateId) async {
    if (!_setLogs.containsKey(templateId)) return;
    final log = _setLogs[templateId]!;
    if (log.id != null) {
      await _repository.deleteSetLogs([log.id!]);
    }
    _setLogs.remove(templateId);
    _completedWorkingOrder.remove(templateId);

    final newExercises = List<RoutineExercise>.from(_exercises);
    for (var i = 0; i < newExercises.length; i++) {
      final re = newExercises[i];
      final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
      if (tIndex != -1) {
        final newTemplates = List<SetTemplate>.from(re.setTemplates)
          ..removeAt(tIndex);
        newExercises[i] = re.copyWith(setTemplates: newTemplates);
        _exercises = newExercises;
        break;
      }
    }
    _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
    _totalSets--;

    weightControllers[templateId]?.dispose();
    repsControllers[templateId]?.dispose();
    rirControllers[templateId]?.dispose();
    weightControllers.remove(templateId);
    repsControllers.remove(templateId);
    rirControllers.remove(templateId);

    // Removing a set leaves a hole in the stored positions; close it so the
    // rows keep describing the session as it now looks.
    await _updateLogOrdersInDatabase();

    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  Future<void> addExercise(Exercise exercise) async {
    final tempReId = _nextSyntheticId(_allRoutineExerciseIds());
    final isCardio = exercise.isCardio;
    final initialSetCount = isCardio ? 1 : 3;
    final repProgressionSupported =
        ExerciseLogMask.forExercise(exercise).supportsLoadRepProgression;
    final initialReps = repProgressionSupported ? '8-12' : '';

    final existingTemplateIds = _allTemplateIds()..addAll(_setLogs.keys);
    final templates = <SetTemplate>[];
    for (var index = 0; index < initialSetCount; index++) {
      final templateId =
          _nextSyntheticId(existingTemplateIds, seed: tempReId + index + 1);
      existingTemplateIds.add(templateId);
      templates.add(SetTemplate(
          id: templateId,
          setType: 'normal',
          targetReps: initialReps,
          targetRepMin: repProgressionSupported ? 8 : null,
          targetRepMax: repProgressionSupported ? 12 : null,
          targetWeight: null));
    }

    final re = RoutineExercise(
        id: tempReId,
        exercise: exercise,
        setTemplates: templates,
        pauseSeconds: 0);

    // Insert directly after the lowest exercise that has at least 1 completed set
    int lastCompletedIndex = -1;
    for (int i = _exercises.length - 1; i >= 0; i--) {
      final ex = _exercises[i];
      final hasCompletedSet =
          ex.setTemplates.any((t) => _setLogs[t.id]?.isCompleted == true);
      if (hasCompletedSet) {
        lastCompletedIndex = i;
        break;
      }
    }

    final newExercises = List<RoutineExercise>.from(_exercises);
    if (lastCompletedIndex != -1) {
      newExercises.insert(lastCompletedIndex + 1, re);
    } else {
      newExercises.add(re);
    }
    _exercises = newExercises;
    pauseTimes[tempReId] = 0;

    for (var t in templates) {
      final newSetLog = SetLog(
        workoutLogId: _workoutLog!.id!,
        exerciseId: exercise.uuid,
        exerciseName: exercise.canonicalName,
        setType: 'normal',
        weightKg: null,
        reps: null,
        restTimeSeconds: 0,
        isCompleted: false,
        logOrder: _setLogs.length,
      );
      final dbId = await _repository.insertSetLog(newSetLog);
      _setLogs[t.id!] = newSetLog.copyWith(id: dbId);
      _totalSets++;
    }

    await _updateLogOrdersInDatabase();
    syncControllers();
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  Future<void> removeExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    final re = _exercises[reIndex];

    final idsToDelete = <int>[];
    for (var t in re.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.id != null) idsToDelete.add(log.id!);
        _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
        _totalSets--;
        _setLogs.remove(t.id);

        weightControllers[t.id]?.dispose();
        repsControllers[t.id]?.dispose();
        rirControllers[t.id]?.dispose();
        weightControllers.remove(t.id);
        repsControllers.remove(t.id);
        rirControllers.remove(t.id);
      }
    }
    await _repository.deleteSetLogs(idsToDelete);
    final newExercises = List<RoutineExercise>.from(_exercises);
    newExercises.removeAt(reIndex);
    _exercises = normalizeSupersetGroups(newExercises);
    pauseTimes.remove(routineExerciseId);

    // Every block after the removed one shifted down by one.
    await _updateLogOrdersInDatabase();

    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  /// Moves the exercise at [oldIndex] to [newIndex].
  ///
  /// [newIndex] is expected in post-removal coordinates, matching the
  /// `onReorderItem` callback of ReorderableListView (which already accounts
  /// for the removed item — unlike the obsolete `onReorder`).
  Future<void> reorderExercise(int oldIndex, int newIndex) async {
    _exercises = reorderRoutineExercise(_exercises, oldIndex, newIndex);
    await _updateLogOrdersInDatabase();
    notifyListeners();
    // Reordering can change which set is "next" without touching any set.
    unawaited(_syncLiveActivity());
  }

  /// Connects or separates the two exercises at a visible card boundary.
  ///
  /// The running session owns its own structure, so changing a superset here
  /// updates the set-log snapshot used for restoring this workout.
  Future<void> toggleSupersetAfter(int upperIndex) async {
    _exercises = toggleSupersetConnectionAfter(_exercises, upperIndex);
    await _updateLogOrdersInDatabase();
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  /// Writes the session's structure — every set's position and the exercise it
  /// belongs to — back to the database.
  ///
  /// This is what a restore after the app is killed reads, so it has to run
  /// after *every* change to the structure: adding or removing a set or an
  /// exercise, and reordering. Skipping it anywhere leaves the stored order
  /// disagreeing with the screen, and the next restore rebuilds the wrong
  /// session.
  Future<void> _updateLogOrdersInDatabase() async {
    int globalOrderCounter = 0;
    final List<SetLog> setsToUpdate = [];
    for (var blockIndex = 0; blockIndex < _exercises.length; blockIndex++) {
      final routineExercise = _exercises[blockIndex];
      for (final template in routineExercise.setTemplates) {
        final setLog = _setLogs[template.id];
        if (setLog != null) {
          final updatedLog = setLog.copyWith(
            logOrder: globalOrderCounter,
            exerciseBlock: blockIndex,
            supersetGroup: routineExercise.supersetGroup,
          );
          _setLogs[template.id!] = updatedLog;
          setsToUpdate.add(updatedLog);
          globalOrderCounter++;
        }
      }
    }
    if (setsToUpdate.isNotEmpty) await _repository.updateSetLogs(setsToUpdate);
  }

  Future<void> updatePauseTime(int routineExerciseId, int seconds) async {
    pauseTimes[routineExerciseId] = seconds;
    await _repository.updatePauseTime(routineExerciseId, seconds);

    final idx = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (idx != -1) {
      _exercises[idx] = _exercises[idx].copyWith(pauseSeconds: seconds);

      final setsToUpdate = <SetLog>[];
      for (var t in _exercises[idx].setTemplates) {
        if (_setLogs.containsKey(t.id)) {
          final log = _setLogs[t.id]!;
          final updatedLog = log.copyWith(restTimeSeconds: seconds);
          _setLogs[t.id!] = updatedLog;
          setsToUpdate.add(updatedLog);
        }
      }
      if (setsToUpdate.isNotEmpty) {
        await _repository.updateSetLogs(setsToUpdate);
      }
    }
    notifyListeners();
  }

  Future<void> updateExerciseNotes(String exerciseName, String? notes) async {
    final newExercises = List<RoutineExercise>.from(_exercises);
    for (int i = 0; i < newExercises.length; i++) {
      if (newExercises[i].exercise.allNames.contains(exerciseName)) {
        newExercises[i] = newExercises[i].copyWith(
          notes: notes,
          clearNotes: notes == null || notes.isEmpty,
        );
        break;
      }
    }
    _exercises = newExercises;

    if (_workoutLog?.id != null) {
      await _repository.saveWorkoutExerciseNote(
        workoutLogId: _workoutLog!.id!,
        exerciseName: exerciseName,
        notes: notes,
      );
    }
    notifyListeners();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _cancelRestSound();
    _showRestDone = false;
    _remainingRestSeconds = seconds;
    _restStartedAt = DateTime.now();
    _targetRestEndTime = _restStartedAt!.add(Duration(seconds: seconds));

    _scheduleRestSound(_targetRestEndTime!);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetRestEndTime != null) {
        final remaining =
            _targetRestEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          if (_remainingRestSeconds != remaining) {
            _remainingRestSeconds = remaining;
            notifyListeners();
          }
        } else {
          timer.cancel();
          _remainingRestSeconds = 0;
          _showRestDone = true;

          if (_isAppInForeground) {
            try {
              unawaited(HapticFeedbackService.instance.vibrate());
              unawaited(SoundService.instance.playTimerDoneSound());
              // A banner on top of a visible Live Activity is pure noise —
              // the card already says the pause is over. Sound and haptics,
              // which are the actual point, still fire.
              if (!_liveActivityRunning) {
                unawaited(LocalNotificationService.instance
                    .showRestTimerDoneNotification(foreground: true));
              }
            } catch (_) {}
          }

          _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
            _showRestDone = false;
            notifyListeners();
          });
          notifyListeners();
          // Push the overdue state the moment the pause ends. Without this the
          // Live Activity only switches when iOS gets around to honouring
          // staleDate, which can lag by a noticeable amount. The staleDate
          // fallback still covers the case where the app is suspended here.
          unawaited(_syncLiveActivity());
        }
      }
    });
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  void cancelRest() {
    _restTimer?.cancel();
    _cancelRestSound();
    _remainingRestSeconds = 0;
    _targetRestEndTime = null;
    _restStartedAt = null;
    _showRestDone = false;
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  void adjustRestTime(int deltaSeconds) {
    if (_remainingRestSeconds <= 0) return;
    _remainingRestSeconds += deltaSeconds;
    if (_targetRestEndTime != null) {
      _targetRestEndTime =
          _targetRestEndTime!.add(Duration(seconds: deltaSeconds));
    }

    _cancelRestSound();

    if (_remainingRestSeconds <= 0) {
      _remainingRestSeconds = 0;
      _restTimer?.cancel();
      if (_isAppInForeground) {
        try {
          unawaited(HapticFeedbackService.instance.vibrate());
        } catch (_) {}
      }
      _showRestDone = true;
      _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
        _showRestDone = false;
        notifyListeners();
      });
    } else if (_targetRestEndTime != null) {
      _scheduleRestSound(_targetRestEndTime!);
    }
    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  void _startWorkoutTimer() {
    _workoutDurationTimer?.cancel();
    _elapsedDuration = Duration.zero;
    if (_workoutLog != null) {
      _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
    }
    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_workoutLog != null) {
        _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> finishWorkout({String? title, String? notes}) async {
    if (_workoutLog != null) {
      final pending = _pendingProgressionUpdate;
      if (pending != null) await pending;

      final logId = _workoutLog!.id!;
      int globalOrderCounter = 0;
      final List<SetLog> setsToPersist = [];
      for (final routineExercise in _exercises) {
        for (final template in routineExercise.setTemplates) {
          final setLog = _setLogs[template.id];
          if (setLog != null) {
            setsToPersist.add(setLog.copyWith(logOrder: globalOrderCounter));
            globalOrderCounter++;
          }
        }
      }

      // Empty rows should never appear as ghost sets in workout history.
      // Generated values are also placeholders until their set is checked.
      // A manually entered open set remains recoverable instead of silently
      // disappearing when the user saves the workout.
      final discardSetIds = <int>[];
      for (final set in setsToPersist) {
        final hasManualInput = set.weightKg != null ||
            set.reps != null ||
            set.distanceKm != null ||
            set.durationSeconds != null ||
            set.rir != null ||
            (set.notes?.trim().isNotEmpty ?? false);
        final isUnconfirmedSuggestion =
            set.valuesAutoFilled && !set.prescriptionOverridden;
        if (set.isCompleted != true &&
            (!hasManualInput || isUnconfirmedSuggestion) &&
            set.id != null) {
          discardSetIds.add(set.id!);
        }
      }

      if (_repository is WorkoutFinalizationRepository) {
        await (_repository as WorkoutFinalizationRepository).finalizeWorkout(
          workoutLogId: logId,
          sets: setsToPersist,
          discardSetIds: discardSetIds,
          title: title,
          notes: notes,
        );
      } else {
        // Test doubles and alternate repositories retain every set in the
        // safe fallback rather than using the old delete-first sequence.
        await _repository.updateSetLogs(setsToPersist);
        await _repository.finishWorkout(logId, title: title, notes: notes);
      }

      final duration = _elapsedDuration;
      final workoutType =
          (_workoutLog?.routineId != null) ? 'routine' : 'custom';
      // BOLT OPTIMIZATION: Replaced multiple .where(), .any(), .map() passes with a single loop
      int totalSetCount = 0;
      int rirSetsCount = 0;
      bool hasWarmupSets = false;
      bool hasDropSets = false;
      bool hasFailureSets = false;
      final supersetIds = <int>{};

      for (final s in _setLogs.values) {
        if (s.isCompleted == true) {
          totalSetCount++;

          if (s.rir != null || s.rpe != null) {
            rirSetsCount++;
          }

          final type = s.setType.toLowerCase();
          if (!hasWarmupSets && type.contains('warm')) hasWarmupSets = true;
          if (!hasDropSets && type.contains('drop')) hasDropSets = true;
          if (!hasFailureSets && type.contains('fail')) hasFailureSets = true;

          if (s.supersetGroup != null) {
            supersetIds.add(s.supersetGroup!);
          }
        }
      }

      _workoutDurationTimer?.cancel();
      _restTimer?.cancel();
      _restDoneBannerTimer?.cancel();
      _showRestDone = false;
      _remainingRestSeconds = 0;
      _targetRestEndTime = null;
      _restStartedAt = null;
      _cancelRestSound();
      await _endLiveActivity();

      unawaited(TelemetryService.instance.trackWorkoutCompleted(
        workoutType: workoutType,
        exerciseCount: _exercises.length,
        setCount: totalSetCount,
        durationMinutes: duration.inMinutes,
        hasRestTimer: pauseTimes.isNotEmpty,
        restTimerCount: pauseTimes.length,
        hasRir: rirSetsCount > 0,
        rirSetsCount: rirSetsCount,
        hasSupersets: supersetIds.isNotEmpty,
        supersetCount: supersetIds.length,
        hasWarmupSets: hasWarmupSets,
        hasDropSets: hasDropSets,
        hasFailureSets: hasFailureSets,
        hasWorkoutNotes: notes != null && notes.trim().isNotEmpty,
      ));

      _workoutLog = null;
      _setLogs.clear();
      _completedWorkingOrder.clear();
      _suggestions.clear();
      _suggestedTemplates.clear();
      _overriddenTemplates.clear();
      pauseTimes.clear();
      _exercises.clear();
      disposeControllers();

      notifyListeners();
    }
  }

  Future<void> clearLocalSessionState() async {
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _cancelRestSound();
    // Covers the abort path — a discarded workout must not leave an activity
    // behind on the lock screen.
    await _endLiveActivity();

    _targetRestEndTime = null;
    _restStartedAt = null;
    _workoutLog = null;
    _exercises.clear();
    _setLogs.clear();
    _completedWorkingOrder.clear();
    _exerciseBests.clear();
    pauseTimes.clear();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    _elapsedDuration = Duration.zero;
    _totalVolume = 0.0;
    _totalSets = 0;
    _suggestions.clear();
    _suggestedTemplates.clear();
    _overriddenTemplates.clear();
    disposeControllers();
    notifyListeners();
  }

  Set<int> _allTemplateIds() {
    final ids = <int>{};
    for (final exercise in _exercises) {
      for (final template in exercise.setTemplates) {
        if (template.id != null) ids.add(template.id!);
      }
    }
    return ids;
  }

  Set<int> _allRoutineExerciseIds() {
    final ids = <int>{...pauseTimes.keys};
    for (final exercise in _exercises) {
      if (exercise.id != null) ids.add(exercise.id!);
    }
    return ids;
  }

  int _nextSyntheticId(Set<int> existingIds, {int? seed}) {
    var candidate = seed ?? DateTime.now().microsecondsSinceEpoch;
    while (existingIds.contains(candidate)) {
      candidate += 1;
    }
    return candidate;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _trainingAutonomyService?.removeListener(_onAutonomyChanged);
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _workoutDurationTimer?.cancel();
    _prEventsController.close();
    disposeControllers();
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
