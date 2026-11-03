import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/data/live_activity/workout_live_activity_service.dart';
import 'package:train_libre/features/workout/domain/live_activity/workout_live_activity_content.dart';
import 'package:train_libre/features/workout/domain/live_workout_notification_preferences.dart';
import 'package:train_libre/features/workout/domain/live_activity/workout_live_activity_strings.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/presentation/live_workout_live_activity_coordinator.dart';
import 'package:train_libre/services/unit_service.dart';

class FakeLiveActivityService extends WorkoutLiveActivityService {
  @override
  bool get isPlatformSupported => true;

  final soundScheduled = Completer<void>();
  bool? bannerEnabled;
  bool? soundIgnoresSilent;

  @override
  Future<void> setRestNotificationsEnabled(
    bool enabled, {
    bool refreshPending = true,
  }) async {
    bannerEnabled = enabled;
  }

  @override
  Future<void> scheduleRestSound({
    required DateTime endsAt,
    required String title,
    required String body,
    bool ignoreSilentMode = true,
  }) async {
    soundIgnoresSilent = ignoreSilentMode;
    soundScheduled.complete();
  }

  int startCalls = 0;
  int updateCalls = 0;
  int endCalls = 0;
  WorkoutLiveActivityAttributes? lastAttributes;
  WorkoutLiveActivityContent? lastContent;
  List<Map<String, dynamic>> queuedCommands = [];

  @override
  Future<void> start({
    required WorkoutLiveActivityAttributes attributes,
    required WorkoutLiveActivityContent content,
  }) async {
    startCalls++;
    lastAttributes = attributes;
    lastContent = content;
  }

  @override
  Future<void> update(WorkoutLiveActivityContent content) async {
    updateCalls++;
    lastContent = content;
  }

  @override
  Future<void> end() async {
    endCalls++;
  }

  @override
  Future<List<Map<String, dynamic>>> consumePendingCommands() async {
    final list = List<Map<String, dynamic>>.from(queuedCommands);
    queuedCommands.clear();
    return list;
  }
}

class FakeHost implements LiveWorkoutLiveActivityHost {
  @override
  bool isActive = true;

  @override
  WorkoutLog? workoutLog = WorkoutLog(
    id: 1,
    routineName: 'Test Routine',
    startTime: DateTime(2026, 1, 1, 10, 0),
  );

  @override
  List<RoutineExercise> exercises = [];

  @override
  Map<int, SetLog> setLogs = {};

  @override
  UnitService unitService = UnitService();

  @override
  DateTime? targetRestEndTime;

  @override
  DateTime? restStartedAt;

  @override
  int? activeSetTimerId;

  @override
  DateTime? setTimerStartedAt;

  @override
  int pausedSetTimerElapsedSeconds = 0;

  @override
  int setTimerBaseSeconds = 0;

  @override
  Future<void>? pendingProgressionUpdate;

  bool cancelRestCalled = false;
  int? adjustedRestDelta;
  final List<({int templateId, int? elapsedSeconds})> completedTimedSets = [];
  final List<({int templateId, DateTime? startedAt, int elapsedSeconds})>
  startedSetTimers = [];
  final List<({int templateId, int? elapsedSeconds})> stoppedSetTimers = [];
  final List<Map<String, dynamic>> updatedSets = [];

  @override
  void cancelRest() {
    cancelRestCalled = true;
  }

  @override
  void adjustRestTime(int deltaSeconds) {
    adjustedRestDelta = deltaSeconds;
  }

  @override
  Future<void> completeTimedSet(
    int timerTemplateId, {
    int? elapsedSeconds,
  }) async {
    completedTimedSets.add((
      templateId: timerTemplateId,
      elapsedSeconds: elapsedSeconds,
    ));
  }

  @override
  void startSetTimer(
    int templateId, {
    DateTime? startedAt,
    int elapsedSeconds = 0,
  }) {
    startedSetTimers.add((
      templateId: templateId,
      startedAt: startedAt,
      elapsedSeconds: elapsedSeconds,
    ));
  }

  @override
  Future<void> stopSetTimer(int templateId, {int? elapsedSeconds}) async {
    stoppedSetTimers.add((
      templateId: templateId,
      elapsedSeconds: elapsedSeconds,
    ));
  }

  @override
  NextOpenSet? nextOpenSet() {
    if (exercises.isEmpty) return null;
    return (exerciseIndex: 0, templateIndex: 0, templateId: 101);
  }

  @override
  bool isDurationSet(int templateId) => false;

  @override
  Future<void> updateSet(
    int templateId, {
    double? weight,
    int? reps,
    int? rir,
    bool? isCompleted,
  }) async {
    updatedSets.add({
      'templateId': templateId,
      'weight': weight,
      'reps': reps,
      'rir': rir,
      'isCompleted': isCompleted,
    });
  }
}

final testStrings = WorkoutLiveActivityStrings(
  setPosition: (index, total) => 'Set $index of $total',
  weightUnit: 'kg',
  distanceUnit: 'km',
  repsShort: 'reps',
  rirLabel: 'RIR',
  rpeLabel: 'RPE',
  addExercise: 'Add Exercise',
  openApp: 'Open App',
  skip: 'Skip',
  overduePrefix: '+',
  startTimer: 'Start',
  stopTimer: 'Stop',
  timerRunning: 'Running',
  restDoneTitle: 'Rest Done',
  restDoneBody: 'Next set ready',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveWorkoutLiveActivityCoordinator', () {
    late FakeHost host;
    late FakeLiveActivityService service;
    late LiveWorkoutLiveActivityCoordinator coordinator;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      host = FakeHost();
      service = FakeLiveActivityService();
      coordinator = LiveWorkoutLiveActivityCoordinator(
        host: host,
        liveActivityService: service,
      );
    });

    test(
      'schedules the rest sound even when the notification banner is off',
      () async {
        SharedPreferences.setMockInitialValues({
          LiveWorkoutNotificationPreferences.restNotificationsKey: false,
          LiveWorkoutNotificationPreferences.ignoreSilentModeKey: false,
        });
        host.isActive = false;
        coordinator.configure(strings: testStrings, localeName: 'en');
        coordinator.scheduleRestSound(
          DateTime.now().add(const Duration(seconds: 20)),
        );
        await service.soundScheduled.future;
        expect(service.bannerEnabled, isFalse);
        expect(service.soundIgnoresSilent, isFalse);
      },
    );

    test('configure triggers initial sync when host is active', () async {
      expect(coordinator.isRunning, isFalse);

      coordinator.configure(strings: testStrings, localeName: 'en');
      // Awaiting coordinator sync drains the chain
      await coordinator.syncLiveActivity();

      expect(coordinator.isRunning, isTrue);
      expect(service.startCalls, equals(1));
      expect(service.lastAttributes?.workoutTitle, equals('Test Routine'));
      expect(
        service.lastAttributes?.deepLink,
        equals(LiveWorkoutLiveActivityCoordinator.liveActivityDeepLink),
      );
    });

    test('does not sync on configure when host is not active', () async {
      host.isActive = false;
      coordinator.configure(strings: testStrings, localeName: 'en');
      expect(service.startCalls, equals(0));
      expect(coordinator.isRunning, isFalse);
    });

    test(
      'subsequent sync updates live activity instead of restarting',
      () async {
        coordinator.configure(strings: testStrings, localeName: 'en');
        await coordinator.syncLiveActivity();
        expect(service.startCalls, equals(1));
        expect(service.updateCalls, equals(1));

        await coordinator.syncLiveActivity();
        expect(service.startCalls, equals(1));
        expect(service.updateCalls, equals(2));
      },
    );

    test('endLiveActivity stops running activity', () async {
      coordinator.configure(strings: testStrings, localeName: 'en');
      await coordinator.syncLiveActivity();
      expect(coordinator.isRunning, isTrue);

      await coordinator.endLiveActivity();
      expect(coordinator.isRunning, isFalse);
      expect(service.endCalls, equals(1));

      // Calling end when not running is a no-op
      await coordinator.endLiveActivity();
      expect(service.endCalls, equals(1));
    });

    test('applies pending live activity commands correctly', () async {
      coordinator.configure(strings: testStrings, localeName: 'en');

      final exercise = Exercise(
        id: 1,
        texts: const {'en': ExerciseText(name: 'Bench Press', description: '')},
        categoryName: 'Strength',
        primaryMuscles: const [],
        secondaryMuscles: const [],
      );
      final template = SetTemplate(
        id: 101,
        setType: 'normal',
        targetReps: '10',
        targetRir: 2,
      );
      host.exercises = [
        RoutineExercise(id: 10, exercise: exercise, setTemplates: [template]),
      ];
      host.setLogs = {
        101: SetLog(
          workoutLogId: 1,
          exerciseName: 'Bench Press',
          setType: 'normal',
          reps: 10,
          weightKg: 80,
        ),
      };

      service.queuedCommands = [
        {'kind': 'skipRest'},
        {'kind': 'adjustRest', 'deltaSeconds': 30},
        {'kind': 'completeSet', 'timerTemplateId': 202, 'elapsedSeconds': 45},
        {'kind': 'completeSet'},
        {
          'kind': 'startSetTimer',
          'templateId': 303,
          'startedAtEpochMs': 1700000000000,
          'elapsedSeconds': 15,
        },
        {'kind': 'stopSetTimer', 'templateId': 303, 'elapsedSeconds': 60},
      ];

      await coordinator.applyPendingLiveActivityCommands();

      expect(host.cancelRestCalled, isTrue);
      expect(host.adjustedRestDelta, equals(30));
      expect(
        host.completedTimedSets,
        equals([(templateId: 202, elapsedSeconds: 45)]),
      );
      expect(host.updatedSets.length, equals(1));
      expect(host.updatedSets.first['templateId'], equals(101));
      expect(host.updatedSets.first['weight'], equals(80.0));
      expect(host.updatedSets.first['reps'], equals(10));
      expect(host.updatedSets.first['isCompleted'], isTrue);
      expect(host.startedSetTimers.length, equals(1));
      expect(host.startedSetTimers.first.templateId, equals(303));
      expect(host.startedSetTimers.first.elapsedSeconds, equals(15));
      expect(host.stoppedSetTimers.length, equals(1));
      expect(host.stoppedSetTimers.first.templateId, equals(303));
      expect(host.stoppedSetTimers.first.elapsedSeconds, equals(60));
    });
  });
}
