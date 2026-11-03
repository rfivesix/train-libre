import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/workout/domain/classification/set_load.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/bottom_content_spacer.dart';

class _FakeWorkoutRepository implements IWorkoutRepository {
  @override
  Future<BodyweightHistory> getBodyweightHistory() async =>
      BodyweightHistory.empty;
  @override
  Future<WorkoutLog?> getOngoingWorkout() async => null;
  @override
  Future<int> insertSetLog(SetLog log) async => 0;
  @override
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async => [];
  @override
  Future<Routine?> getRoutineByName(String name) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ActiveLiveWorkoutViewModel extends LiveWorkoutViewModel {
  _ActiveLiveWorkoutViewModel({
    required super.repository,
    required super.unitService,
  });
  @override
  bool get isActive => true;
}

void main() {
  testWidgets(
    'BottomContentSpacer does not crash when LiveWorkoutViewModel is not present',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomContentSpacer())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomContentSpacer), findsOneWidget);
      final size = tester.getSize(find.byType(BottomContentSpacer));
      expect(size.height, equals(kOverlayBaseHeight));
    },
  );

  testWidgets('BottomContentSpacer adds running extra when workout is active', (
    tester,
  ) async {
    final vm = _ActiveLiveWorkoutViewModel(
      repository: _FakeWorkoutRepository(),
      unitService: UnitService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<LiveWorkoutViewModel>.value(
        value: vm,
        child: const MaterialApp(home: Scaffold(body: BottomContentSpacer())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(BottomContentSpacer));
    expect(size.height, equals(kOverlayBaseHeight + kOverlayRunningExtra));
  });
}
