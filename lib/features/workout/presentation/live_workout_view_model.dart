import "../../../services/unit_service.dart";

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/set_template.dart';
import '../domain/models/workout_log.dart';
import '../domain/repositories/workout_repository.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../domain/log_workout_set_use_case.dart';
import '../data/live_activity/workout_live_activity_service.dart';
import '../domain/live_activity/build_workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_content.dart';
import '../domain/live_activity/workout_live_activity_strings.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/sound_service.dart';
import '../../../util/time_util.dart';
import '../../../services/telemetry/telemetry_service.dart';

class LiveWorkoutViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final IWorkoutRepository _repository;
  final DetectPersonalRecordUseCase _detectPRUseCase;
  final LogWorkoutSetUseCase _logSetUseCase;
  final bool _registerLifecycleObserver;

  // ignore: unused_field
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  final UnitService unitService;

  LiveWorkoutViewModel({
    required IWorkoutRepository repository,
    required this.unitService,
    DetectPersonalRecordUseCase? detectPRUseCase,
    LogWorkoutSetUseCase? logSetUseCase,
    bool registerLifecycleObserver = true,
  })  : _repository = repository,
        _detectPRUseCase = detectPRUseCase ?? DetectPersonalRecordUseCase(),
        _logSetUseCase = logSetUseCase ?? LogWorkoutSetUseCase(),
        _registerLifecycleObserver = registerLifecycleObserver {
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @visibleForTesting
  factory LiveWorkoutViewModel.forTesting({
    required IWorkoutRepository workoutDb,
    UnitService? unitService,
  }) {
    return LiveWorkoutViewModel(
      repository: workoutDb,
      unitService: unitService ?? UnitService(),
      registerLifecycleObserver: false,
    );
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

  /// Starts the activity on first call and updates it afterwards. Cheap to
  /// call often — the service drops pushes that would not change anything.
  Future<void> _syncLiveActivity() async {
    if (!_liveActivityService.isPlatformSupported) return;
    final log = _workoutLog;
    final strings = _liveActivityStrings;
    if (log == null || log.id == null || strings == null) return;
    if (!isActive) return;

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
  /// Only while a Live Activity is up: its App Intents can move the pause
  /// while the app is suspended, and only the native scheduler can be moved
  /// with it. Without a Live Activity — and on Android — nothing changes.
  bool get _usesNativeRestSound => _liveActivityRunning;

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
    for (final exercise in _exercises) {
      for (final template in exercise.setTemplates) {
        final templateId = template.id;
        if (templateId == null) continue;
        final log = _setLogs[templateId];
        if (log == null || log.isCompleted == true) continue;

        final weight = template.targetWeight ?? log.weightKg;
        final reps = int.tryParse(template.targetReps ?? '') ?? log.reps;
        if (exercise.exercise.isCardio) {
          if (log.durationSeconds == null && log.distanceKm == null) return;
        } else if (weight == null || reps == null) {
          return;
        }

        await updateSet(
          templateId,
          weight: weight,
          reps: reps,
          rir: template.targetRir ?? log.rir,
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
    _workoutLog = log;
    _exercises = List.from(routineExercises);
    _setLogs.clear();
    pauseTimes.clear();

    for (var re in _exercises) {
      if (re.id != null) {
        pauseTimes[re.id!] = re.pauseSeconds;
      }
      if (re.notes != null && re.notes!.isNotEmpty) {
        await _repository.saveWorkoutExerciseNote(
          workoutLogId: log.id!,
          exerciseName: re.exercise.nameEn,
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

    for (var re in _exercises) {
      for (var template in re.setTemplates) {
        if (template.id == null) continue;

        final newSetLog = SetLog(
          workoutLogId: _workoutLog!.id!,
          exerciseName: re.exercise.nameEn,
          setType: template.setType,
          weightKg: null,
          reps: null,
          restTimeSeconds: re.pauseSeconds,
          isCompleted: false,
          rir: null,
        );

        final id = await _repository.insertSetLog(newSetLog);
        _setLogs[template.id!] = newSetLog.copyWith(id: id);
        _totalSets++;
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

    final sortedSets = List<SetLog>.from(savedSets)
      ..sort((a, b) => (a.logOrder ?? 0).compareTo(b.logOrder ?? 0));

    String? currentExerciseName;
    List<SetLog> currentBlock = [];
    final List<List<SetLog>> blocks = [];

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

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.isEmpty) continue;

      final firstSet = block.first;
      final exName = firstSet.exerciseName;
      final exercise = await _repository.resolveExerciseForSetLog(firstSet) ??
          Exercise(
            nameDe: exName,
            nameEn: exName,
            descriptionDe: '',
            descriptionEn: '',
            categoryName: 'Unknown',
            primaryMuscles: const [],
            secondaryMuscles: const [],
          );

      final syntheticReId = DateTime.now().millisecondsSinceEpoch + i;
      int pauseSec = 0;
      for (final s in block) {
        if (s.restTimeSeconds != null && s.restTimeSeconds! > 0) {
          pauseSec = s.restTimeSeconds!;
          break;
        }
      }
      if (pauseSec == 0 && block.isNotEmpty) {
        pauseSec = block.first.restTimeSeconds ?? 0;
      }

      final List<SetTemplate> templates = [];
      for (int j = 0; j < block.length; j++) {
        final s = block[j];
        final templateId =
            DateTime.now().millisecondsSinceEpoch + j * 1000 + i * 10000;

        templates.add(
          SetTemplate(
            id: templateId,
            setType: s.setType,
            targetWeight: s.weightKg,
            targetReps: s.reps?.toString(),
            targetRir: s.rir,
          ),
        );

        _setLogs[templateId] = s;
        _totalVolume += (s.weightKg ?? 0) * (s.reps ?? 0);
        _totalSets++;
      }

      final savedNote = savedExerciseNotes[exercise.nameEn] ??
          savedExerciseNotes[exercise.nameDe];
      final re = RoutineExercise(
        id: syntheticReId,
        exercise: exercise,
        setTemplates: templates,
        pauseSeconds: pauseSec,
        notes: savedNote,
      );

      restoredExercises.add(re);
      pauseTimes[syntheticReId] = pauseSec;
    }
    _exercises = restoredExercises;

    _startWorkoutTimer();
    notifyListeners();
    unawaited(_syncLiveActivity());
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
      final lastSets =
          await _repository.getLastSetsForExercise(re.exercise.nameEn);
      lastPerformances[re.exercise.nameEn] = lastSets;
    }

    syncControllers();
    isLoading = false;
    notifyListeners();
  }

  void syncControllers() {
    _setLogs.forEach((templateId, setLog) {
      final exercise = _exercises.firstWhere(
        (re) => re.setTemplates.any((t) => t.id == templateId),
        orElse: () => _exercises.first,
      );
      final isCardio = exercise.exercise.categoryName.toLowerCase() == 'cardio';

      if (!weightControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
          initText = setLog.distanceKm == null
              ? ''
              : setLog.distanceKm!
                  .toStringAsFixed(3)
                  .replaceAll(RegExp(r'0*$'), '')
                  .replaceAll(RegExp(r'\.$'), '');
        } else {
          initText = setLog.weightKg == null
              ? ''
              : unitService.formatDisplayWeight(setLog.weightKg!,
                  fractionDigits: 2);
        }
        weightControllers[templateId] = TextEditingController(text: initText);
      }

      if (!repsControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
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

    final oldLog = _setLogs[templateId]!;
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

    _setLogs[templateId] = result.updatedSet;
    _totalVolume += result.volumeDelta;

    if (isCompleted == true &&
        oldLog.isCompleted != true &&
        result.updatedSet.setType != 'warmup') {
      await _checkAndApplyPRs(result.updatedSet, templateId);
    }

    await _repository.updateSetLogs([_setLogs[templateId]!]);

    if (isCompleted == true && oldLog.isCompleted != true) {
      int? pauseTime;
      bool isLastSet = false;
      for (var re in _exercises) {
        final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
        if (tIndex != -1) {
          pauseTime = pauseTimes[re.id!];
          if (tIndex == re.setTemplates.length - 1) {
            isLastSet = true;
          }
          break;
        }
      }
      if (pauseTime != null && pauseTime > 0 && !isLastSet) {
        _startRestTimer(pauseTime);
      } else if (_targetRestEndTime != null) {
        // The set that was just completed defines the pause — if it has none
        // (or it was the exercise's last set), a pause still running from an
        // earlier set is stale and must not keep counting. It used to survive,
        // so ticking off a set of a pause-less exercise left the previous
        // exercise's timer running.
        cancelRest();
      }
    }

    notifyListeners();
    // The next set changed — this is the main reason the activity updates.
    unawaited(_syncLiveActivity());
  }

  Future<void> _checkAndApplyPRs(SetLog setLog, int templateId) async {
    final exName = setLog.exerciseName;

    if (!_exerciseBests.containsKey(exName)) {
      final exercise = await _repository.getExerciseByName(exName);
      final altName = exercise?.nameEn != exName ? exercise?.nameEn : null;
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

    final prResult = _detectPRUseCase.execute(
      unitService: unitService,
      currentSet: setLog,
      historicalBests: _exerciseBests[exName]!,
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

    final newTemplate = SetTemplate(
      id: tempTemplateId,
      setType: 'normal',
      targetReps: null,
      targetWeight: null,
      targetRir: null,
    );

    final updatedRe = RoutineExercise(
      id: re.id,
      exercise: re.exercise,
      setTemplates: [...re.setTemplates, newTemplate],
      pauseSeconds: re.pauseSeconds,
    );
    final newExercises = List<RoutineExercise>.from(_exercises);
    newExercises[reIndex] = updatedRe;
    _exercises = newExercises;

    final prevSet = _setLogs.values
        .where((s) => s.exerciseName == re.exercise.nameEn)
        .lastOrNull;

    final newSetLog = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: re.exercise.nameEn,
      setType: 'normal',
      weightKg: prevSet?.weightKg,
      reps: prevSet?.reps,
      restTimeSeconds: re.pauseSeconds,
      isCompleted: false,
      logOrder: _setLogs.length,
      rir: null,
    );

    final dbId = await _repository.insertSetLog(newSetLog);
    _setLogs[tempTemplateId] = newSetLog.copyWith(id: dbId);
    _totalSets++;

    syncControllers();
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

    final newExercises = List<RoutineExercise>.from(_exercises);
    for (var i = 0; i < newExercises.length; i++) {
      final re = newExercises[i];
      final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
      if (tIndex != -1) {
        final newTemplates = List<SetTemplate>.from(re.setTemplates)
          ..removeAt(tIndex);
        newExercises[i] = RoutineExercise(
          id: re.id,
          exercise: re.exercise,
          setTemplates: newTemplates,
          pauseSeconds: re.pauseSeconds,
        );
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

    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  Future<void> addExercise(Exercise exercise) async {
    final tempReId = _nextSyntheticId(_allRoutineExerciseIds());
    final isCardio = exercise.categoryName.toLowerCase() == 'cardio';
    final initialSetCount = isCardio ? 1 : 3;
    final initialReps = isCardio ? '' : '10';

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
        exerciseName: exercise.nameEn,
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
    _exercises = newExercises;
    pauseTimes.remove(routineExerciseId);

    notifyListeners();
    unawaited(_syncLiveActivity());
  }

  /// Moves the exercise at [oldIndex] to [newIndex].
  ///
  /// [newIndex] is expected in post-removal coordinates, matching the
  /// `onReorderItem` callback of ReorderableListView (which already accounts
  /// for the removed item — unlike the obsolete `onReorder`).
  Future<void> reorderExercise(int oldIndex, int newIndex) async {
    final newExercises = List<RoutineExercise>.from(_exercises);
    final item = newExercises.removeAt(oldIndex);
    newExercises.insert(newIndex, item);
    _exercises = newExercises;
    await _updateLogOrdersInDatabase();
    notifyListeners();
    // Reordering can change which set is "next" without touching any set.
    unawaited(_syncLiveActivity());
  }

  Future<void> _updateLogOrdersInDatabase() async {
    int globalOrderCounter = 0;
    final List<SetLog> setsToUpdate = [];
    for (final routineExercise in _exercises) {
      for (final template in routineExercise.setTemplates) {
        final setLog = _setLogs[template.id];
        if (setLog != null) {
          final updatedLog = setLog.copyWith(logOrder: globalOrderCounter);
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
      if (newExercises[i].exercise.nameEn == exerciseName ||
          newExercises[i].exercise.nameDe == exerciseName) {
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
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _showRestDone = false;
    _remainingRestSeconds = 0;
    _targetRestEndTime = null;
    _restStartedAt = null;
    _cancelRestSound();
    await _endLiveActivity();

    if (_workoutLog != null) {
      final logId = _workoutLog!.id!;
      // BOLT OPTIMIZATION: Replaced chained .where().map().toList() with a single-pass loop
      final incompleteSetIds = <int>[];
      for (final s in _setLogs.values) {
        if (s.isCompleted == false && s.id != null) {
          incompleteSetIds.add(s.id!);
        }
      }

      if (incompleteSetIds.isNotEmpty) {
        await _repository.deleteSetLogs(incompleteSetIds);
      }

      int globalOrderCounter = 0;
      final List<SetLog> setsToUpdate = [];
      for (final routineExercise in _exercises) {
        for (final template in routineExercise.setTemplates) {
          final setLog = _setLogs[template.id];
          if (setLog != null && setLog.isCompleted == true) {
            setsToUpdate.add(setLog.copyWith(logOrder: globalOrderCounter));
            globalOrderCounter++;
          }
        }
      }
      if (setsToUpdate.isNotEmpty) {
        await _repository.updateSetLogs(setsToUpdate);
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

          if (s.supersetId != null) {
            supersetIds.add(s.supersetId!);
          }
        }
      }

      await _repository.finishWorkout(logId, title: title, notes: notes);

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
    _exerciseBests.clear();
    pauseTimes.clear();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    _elapsedDuration = Duration.zero;
    _totalVolume = 0.0;
    _totalSets = 0;
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
