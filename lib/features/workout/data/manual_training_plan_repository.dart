import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../../../services/telemetry/telemetry_service.dart';
import '../domain/models/manual_training_plan.dart';
import '../domain/models/routine.dart';
import 'sources/workout_local_data_source.dart';

/// Persistence and deterministic calendar projection for manually authored
/// plans. All dates are local civil dates; iteration uses calendar construction
/// rather than 24-hour durations, which would break across DST.
class ManualTrainingPlanRepository {
  ManualTrainingPlanRepository({db.AppDatabase? database})
      : _db = database ?? DatabaseHelper.instance.dbInstance;

  final db.AppDatabase _db;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
  DateTime _addDays(DateTime value, int count) =>
      DateTime(value.year, value.month, value.day + count);
  int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  Future<List<db.TrainingPlan>> allPlans() => (_db.select(_db.trainingPlans)
        ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<ManualTrainingPlan?> activePlan() async {
    final row = await (_db.select(_db.trainingPlans)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    return row == null ? null : loadPlan(row.id);
  }

  Future<ManualTrainingPlan?> loadPlan(String planId) async {
    final plan = await (_db.select(_db.trainingPlans)
          ..where((t) => t.id.equals(planId)))
        .getSingleOrNull();
    if (plan == null) return null;
    final revisions = await (_db.select(_db.trainingPlanRevisions)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.number)]))
        .get();
    if (revisions.isEmpty) return null;
    final activation = await (_db.select(_db.trainingPlanActivations)
          ..where((t) => t.planId.equals(planId) & t.endedOn.isNull())
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startedOn)]))
        .getSingleOrNull();
    final firstActivation = await (_db.select(_db.trainingPlanActivations)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.localId)])
          ..limit(1))
        .getSingleOrNull();
    final revision = revisions.first;
    return ManualTrainingPlan(
      id: plan.id,
      name: plan.name,
      kind: TrainingPlanKind.values.byName(plan.kind),
      days: TrainingPlanDay.decodeDays(revision.daysJson),
      revisionId: revision.id,
      revisionNumber: revision.number,
      active: plan.isActive,
      activationId: activation?.id,
      startedOn: firstActivation?.startedOn ?? plan.startedOn,
    );
  }

  Future<TrainingPlanDay> dayFromRoutine(Routine routine) async {
    if (routine.id == null) throw ArgumentError('Unsaved routine');
    final row = await (_db.select(_db.routines)
          ..where((t) => t.localId.equals(routine.id!)))
        .getSingle();
    final detailed =
        await WorkoutLocalDataSource(_db).getRoutineById(routine.id!);
    if (detailed == null) throw StateError('Routine no longer exists');
    if (detailed.exercises.isEmpty ||
        detailed.exercises.every((exercise) => exercise.setTemplates.isEmpty)) {
      throw ArgumentError('Routine needs at least one set');
    }
    return TrainingPlanDay(
      routineUuid: row.id,
      routineSnapshot: detailed.toMap(),
    );
  }

  void _validate(TrainingPlanKind kind, List<TrainingPlanDay> days) {
    if (kind == TrainingPlanKind.week && days.length != 7) {
      throw ArgumentError('Weekly plans require seven days');
    }
    if (kind == TrainingPlanKind.sequence &&
        (days.isEmpty || days.length > 14)) {
      throw ArgumentError('Sequences require one to fourteen days');
    }
    if (!days.any((day) => !day.isRest)) {
      throw ArgumentError('A plan needs at least one workout');
    }
  }

  Future<String> createPlan({
    required String name,
    required TrainingPlanKind kind,
    required List<TrainingPlanDay> days,
    bool activate = true,
  }) async {
    _validate(kind, days);
    if (name.trim().isEmpty) throw ArgumentError('A plan needs a name');
    return _db.transaction(() async {
      final row = await _db.into(_db.trainingPlans).insertReturning(
            db.TrainingPlansCompanion(
              name: drift.Value(name.trim()),
              kind: drift.Value(kind.name),
              lengthDays: drift.Value(days.length),
            ),
          );
      await _db.into(_db.trainingPlanRevisions).insert(
            db.TrainingPlanRevisionsCompanion(
              planId: drift.Value(row.id),
              number: const drift.Value(1),
              effectiveOn: drift.Value(_day(DateTime.now())),
              daysJson: drift.Value(TrainingPlanDay.encodeDays(days)),
            ),
          );
      if (activate) await _activate(row.id, resume: false);
      return row.id;
    });
  }

  Future<void> revisePlan({
    required String planId,
    required String name,
    required TrainingPlanKind kind,
    required List<TrainingPlanDay> days,
    required bool nextCycle,
  }) async {
    _validate(kind, days);
    final now = _day(DateTime.now());
    await _db.transaction(() async {
      final plan = await (_db.select(_db.trainingPlans)
            ..where((t) => t.id.equals(planId)))
          .getSingle();
      final current = await loadPlan(planId);
      if (current == null) throw StateError('Plan has no revision');
      if (kind != current.kind) {
        throw ArgumentError('Changing the calendar type requires a new plan');
      }
      final revisions = await (_db.select(_db.trainingPlanRevisions)
            ..where((t) => t.planId.equals(planId)))
          .get();
      int? effectiveCycle;
      var effectiveOn = now;
      if (nextCycle && plan.isActive) {
        if (kind == TrainingPlanKind.week) {
          effectiveOn = _addDays(now, 8 - now.weekday);
        } else {
          final state = await _sequenceState(planId, now);
          effectiveCycle = state.cycle + 1;
        }
      }
      await (_db.update(_db.trainingPlans)..where((t) => t.id.equals(planId)))
          .write(db.TrainingPlansCompanion(
        name: drift.Value(name.trim()),
        lengthDays: drift.Value(days.length),
      ));
      await _db.into(_db.trainingPlanRevisions).insert(
            db.TrainingPlanRevisionsCompanion(
              planId: drift.Value(planId),
              number: drift.Value(revisions.length + 1),
              effectiveOn: drift.Value(effectiveOn),
              effectiveCycle: drift.Value(effectiveCycle),
              daysJson: drift.Value(TrainingPlanDay.encodeDays(days)),
            ),
          );
    });
  }

  Future<void> activate(String planId, {required bool resume}) =>
      _db.transaction(() => _activate(planId, resume: resume));

  Future<void> _activate(String planId, {required bool resume}) async {
    final today = _day(DateTime.now());
    final active = await (_db.select(_db.trainingPlans)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    if (active?.id == planId && resume) return;
    if (active != null) {
      await (_db.update(_db.trainingPlans)
            ..where((t) => t.id.equals(active.id)))
          .write(const db.TrainingPlansCompanion(isActive: drift.Value(false)));
      await (_db.update(_db.trainingPlanActivations)
            ..where((t) => t.planId.equals(active.id) & t.endedOn.isNull()))
          .write(
              db.TrainingPlanActivationsCompanion(endedOn: drift.Value(today)));
    }
    final previous = await (_db.select(_db.trainingPlanActivations)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.localId)]))
        .getSingleOrNull();
    final plan = await (_db.select(_db.trainingPlans)
          ..where((t) => t.id.equals(planId)))
        .getSingle();
    final cursor = resume && previous != null ? plan.sequenceCursor : 0;
    final cycle = resume && previous != null ? plan.sequenceCycle : 0;
    if (resume &&
        previous != null &&
        _day(previous.startedOn) == today &&
        previous.endedOn != null) {
      await (_db.update(_db.trainingPlanActivations)
            ..where((t) => t.id.equals(previous.id)))
          .write(const db.TrainingPlanActivationsCompanion(
              endedOn: drift.Value(null)));
    } else {
      await _db.into(_db.trainingPlanActivations).insert(
            db.TrainingPlanActivationsCompanion(
              planId: drift.Value(planId),
              startedOn: drift.Value(today),
              initialCursor: drift.Value(cursor),
              initialCycle: drift.Value(cycle),
            ),
          );
    }
    await (_db.update(_db.trainingPlans)..where((t) => t.id.equals(planId)))
        .write(db.TrainingPlansCompanion(
      isActive: const drift.Value(true),
      startedOn: drift.Value(today),
      pausedOn: const drift.Value(null),
      sequenceCursor: drift.Value(cursor),
      sequenceCycle: drift.Value(cycle),
    ));
    unawaited(TelemetryService.instance.trackTrainingPlanToggled(
      action: 'activated',
      kind: plan.kind,
    ));
  }

  Future<void> deactivate(String planId) async {
    final today = _day(DateTime.now());
    await _db.transaction(() async {
      final plan = await loadPlan(planId);
      final sequenceState =
          plan != null && plan.kind == TrainingPlanKind.sequence && plan.active
              ? await _sequenceState(planId, _addDays(today, 1))
              : const _SequenceState(0, 0, 0);
      await (_db.update(_db.trainingPlanActivations)
            ..where((t) => t.planId.equals(planId) & t.endedOn.isNull()))
          .write(
              db.TrainingPlanActivationsCompanion(endedOn: drift.Value(today)));
      await (_db.update(_db.trainingPlans)..where((t) => t.id.equals(planId)))
          .write(db.TrainingPlansCompanion(
        isActive: const drift.Value(false),
        pausedOn: drift.Value(today),
        sequenceCursor: drift.Value(sequenceState.cursor),
        sequenceCycle: drift.Value(sequenceState.cycle),
      ));
      if (plan != null) {
        unawaited(TelemetryService.instance.trackTrainingPlanToggled(
          action: 'deactivated',
          kind: plan.kind.name,
        ));
      }
    });
  }

  Future<List<db.TrainingPlanRevision>> revisions(String planId) =>
      (_db.select(_db.trainingPlanRevisions)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => drift.OrderingTerm.desc(t.number)]))
          .get();

  /// Revisions retain their original snapshots unless the user explicitly
  /// opts to copy the edited routine into future plan days.
  Future<bool> isRoutineUsed(int localRoutineId) async {
    final routine = await (_db.select(_db.routines)
          ..where((t) => t.localId.equals(localRoutineId)))
        .getSingleOrNull();
    if (routine == null) return false;
    for (final plan in await allPlans()) {
      final current = await loadPlan(plan.id);
      if (current?.days.any((day) => day.routineUuid == routine.id) == true) {
        return true;
      }
    }
    return false;
  }

  Future<void> includeRoutineEdit(int localRoutineId) async {
    final routine = await (_db.select(_db.routines)
          ..where((t) => t.localId.equals(localRoutineId)))
        .getSingleOrNull();
    if (routine == null) return;
    final detailed =
        await WorkoutLocalDataSource(_db).getRoutineById(localRoutineId);
    if (detailed == null) return;
    final plans = await allPlans();
    for (final plan in plans) {
      final current = await loadPlan(plan.id);
      if (current == null) continue;
      if (!current.days.any((day) => day.routineUuid == routine.id)) continue;
      final changed = current.days
          .map((day) => day.routineUuid == routine.id
              ? TrainingPlanDay(
                  routineUuid: routine.id,
                  routineSnapshot: detailed.toMap(),
                )
              : day)
          .toList();
      await revisePlan(
        planId: plan.id,
        name: plan.name,
        kind: current.kind,
        days: changed,
        nextCycle: false,
      );
    }
  }

  Future<List<PlannedCalendarDay>> calendar(
      String planId, DateTime first, DateTime last) async {
    final plan = await loadPlan(planId);
    if (plan == null) return [];
    // Older app builds could leave an occurrence behind after deleting its
    // workout. Skips are the only valid occurrences without a workout link;
    // all other orphaned rows must stop influencing the visible status and
    // the sequence cursor.
    await (_db.delete(_db.trainingPlanOccurrences)
          ..where((t) =>
              t.planId.equals(planId) &
              t.workoutLogId.isNull() &
              t.status.isNotValue('skipped')))
        .go();
    final activations = await (_db.select(_db.trainingPlanActivations)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.localId)]))
        .get();
    final revisions = await (_db.select(_db.trainingPlanRevisions)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.number)]))
        .get();
    final unresolved = await (_db.select(_db.trainingPlanOccurrences)
          ..where((t) => t.planId.equals(planId) & t.status.equals('ongoing')))
        .get();
    for (final occurrence in unresolved) {
      if (occurrence.workoutLogId == null) continue;
      final log = await (_db.select(_db.workoutLogs)
            ..where((t) => t.id.equals(occurrence.workoutLogId!)))
          .getSingleOrNull();
      if (log != null && log.status == 'completed') {
        await reconcileWorkout(log.localId);
      }
    }
    final occurrences = await (_db.select(_db.trainingPlanOccurrences)
          ..where((t) => t.planId.equals(planId)))
        .get();
    final results = <PlannedCalendarDay>[];
    for (var date = _day(first);
        !date.isAfter(_day(last));
        date = _addDays(date, 1)) {
      db.TrainingPlanActivation? activation;
      for (final row in activations) {
        if (!date.isBefore(_day(row.startedOn)) &&
            (row.endedOn == null || !date.isAfter(_day(row.endedOn!)))) {
          activation = row;
        }
      }
      if (activation == null) continue;
      var slot = 0;
      var cycle = 0;
      if (plan.kind == TrainingPlanKind.week) {
        slot = date.weekday - 1;
        cycle = _daysBetween(_day(activation.startedOn), date) ~/ 7;
      } else {
        final state = await _sequenceState(planId, date,
            activation: activation,
            revisions: revisions,
            occurrences: occurrences);
        slot = state.slot;
        cycle = state.cycle;
      }
      final revision = _revisionAt(revisions, date, cycle);
      final days = TrainingPlanDay.decodeDays(revision.daysJson);
      slot %= days.length;
      final day = days[slot];
      db.TrainingPlanOccurrence? event;
      for (final row in occurrences) {
        if (row.activationId == activation.id &&
            _day(row.scheduledOn) == date &&
            row.slotIndex == slot) {
          event = row;
          break;
        }
      }
      final status = day.isRest
          ? PlannedDayStatus.rest
          : event == null
              ? PlannedDayStatus.planned
              : PlannedDayStatus.values.byName(event.status);
      int? logLocalId;
      if (event?.workoutLogId != null) {
        final log = await (_db.select(_db.workoutLogs)
              ..where((t) => t.id.equals(event!.workoutLogId!)))
            .getSingleOrNull();
        logLocalId = log?.localId;
      }
      results.add(PlannedCalendarDay(
        date: date,
        slotIndex: slot,
        day: day,
        status: status,
        occurrenceId: event?.id,
        workoutLogId: logLocalId,
        revisionId: revision.id,
      ));
    }
    return results;
  }

  db.TrainingPlanRevision _revisionAt(
      List<db.TrainingPlanRevision> revisions, DateTime date, int cycle) {
    var chosen = revisions.first;
    for (final revision in revisions) {
      if (!date.isBefore(_day(revision.effectiveOn)) &&
          (revision.effectiveCycle == null ||
              cycle >= revision.effectiveCycle!)) {
        chosen = revision;
      }
    }
    return chosen;
  }

  Future<_SequenceState> _sequenceState(String planId, DateTime date,
      {db.TrainingPlanActivation? activation,
      List<db.TrainingPlanRevision>? revisions,
      List<db.TrainingPlanOccurrence>? occurrences}) async {
    activation ??= await (_db.select(_db.trainingPlanActivations)
          ..where((t) => t.planId.equals(planId) & t.endedOn.isNull()))
        .getSingle();
    revisions ??= await this.revisions(planId);
    occurrences ??= await (_db.select(_db.trainingPlanOccurrences)
          ..where((t) => t.activationId.equals(activation!.id)))
        .get();
    var cursor = activation.initialCursor;
    var cycle = activation.initialCycle;
    final today = _day(DateTime.now());
    for (var current = _day(activation.startedOn);
        current.isBefore(_day(date));
        current = _addDays(current, 1)) {
      final revision = _revisionAt(revisions, current, cycle);
      final days = TrainingPlanDay.decodeDays(revision.daysJson);
      final slot = cursor % days.length;
      final event = occurrences.where(
          (row) => _day(row.scheduledOn) == current && row.slotIndex == slot);
      final resolved = days[slot].isRest ||
          event.any((row) =>
              const ['completed', 'partial', 'skipped'].contains(row.status));
      // A future calendar is a projection that assumes the upcoming unit is
      // done. Once its date has actually passed, only a real resolution moves
      // the sequence on.
      if (resolved || !current.isBefore(today)) {
        cursor++;
        if (cursor >= days.length) {
          cursor = 0;
          cycle++;
        }
      }
    }
    final revision = _revisionAt(revisions, date, cycle);
    final slot = cursor % TrainingPlanDay.decodeDays(revision.daysJson).length;
    return _SequenceState(slot, slot, cycle);
  }

  Future<void> skip(ManualTrainingPlan plan, PlannedCalendarDay day) async {
    if (day.day.isRest ||
        day.status != PlannedDayStatus.planned ||
        plan.activationId == null ||
        day.revisionId == null) {
      return;
    }
    await _db.into(_db.trainingPlanOccurrences).insert(
          db.TrainingPlanOccurrencesCompanion(
            planId: drift.Value(plan.id),
            activationId: drift.Value(plan.activationId!),
            revisionId: drift.Value(day.revisionId!),
            scheduledOn: drift.Value(_day(day.date)),
            slotIndex: drift.Value(day.slotIndex),
            status: const drift.Value('skipped'),
            routineSnapshotJson:
                drift.Value(jsonEncode(day.day.routineSnapshot)),
            resolvedAt: drift.Value(DateTime.now()),
          ),
        );
  }

  Future<({Routine routine, db.WorkoutLog log})> start(
      ManualTrainingPlan plan, PlannedCalendarDay day) async {
    if (day.day.isRest ||
        day.status != PlannedDayStatus.planned ||
        plan.activationId == null ||
        day.revisionId == null) {
      throw StateError('This plan day cannot be started');
    }
    final routine = day.day.routine;
    if (routine == null) throw StateError('Routine snapshot is missing');
    return _db.transaction(() async {
      final routineRow = day.day.routineUuid == null
          ? null
          : await (_db.select(_db.routines)
                ..where((t) => t.id.equals(day.day.routineUuid!)))
              .getSingleOrNull();
      final log = await _db.into(_db.workoutLogs).insertReturning(
            db.WorkoutLogsCompanion(
              startTime: drift.Value(DateTime.now()),
              routineId: drift.Value(routineRow?.id),
              routineNameSnapshot: drift.Value(routine.name),
            ),
          );
      await _db.into(_db.trainingPlanOccurrences).insert(
            db.TrainingPlanOccurrencesCompanion(
              planId: drift.Value(plan.id),
              activationId: drift.Value(plan.activationId!),
              revisionId: drift.Value(day.revisionId!),
              scheduledOn: drift.Value(_day(day.date)),
              slotIndex: drift.Value(day.slotIndex),
              status: const drift.Value('ongoing'),
              workoutLogId: drift.Value(log.id),
              routineSnapshotJson:
                  drift.Value(jsonEncode(day.day.routineSnapshot)),
            ),
          );
      return (routine: routine, log: log);
    });
  }

  /// Idempotently resolves started units from persisted workout/set data.
  Future<void> reconcileWorkout(int localLogId) async {
    final log = await (_db.select(_db.workoutLogs)
          ..where((t) => t.localId.equals(localLogId)))
        .getSingleOrNull();
    if (log == null) return;
    final occurrence = await (_db.select(_db.trainingPlanOccurrences)
          ..where((t) => t.workoutLogId.equals(log.id)))
        .getSingleOrNull();
    if (occurrence == null || occurrence.status != 'ongoing') return;
    if (log.status != 'completed') return;
    final snapshot = occurrence.routineSnapshotJson == null
        ? null
        : TrainingPlanDay(
            routineSnapshot: Map<String, dynamic>.from(
                jsonDecode(occurrence.routineSnapshotJson!) as Map));
    final requirements = snapshot?.routine?.exercises
            .map((exercise) => exercise.setTemplates.length)
            .toList() ??
        [];
    final completedSets = await (_db.select(_db.setLogs)
          ..where((t) =>
              t.workoutLogId.equals(log.id) & t.isCompleted.equals(true)))
        .get();
    final completedByBlock = <int, int>{};
    for (final set in completedSets) {
      if (set.exerciseBlock == null) continue;
      completedByBlock.update(set.exerciseBlock!, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final allDone = requirements.isNotEmpty &&
        List.generate(requirements.length, (index) => index).every(
            (index) => (completedByBlock[index] ?? 0) >= requirements[index]);
    final status = allDone ? 'completed' : 'partial';
    await (_db.update(_db.trainingPlanOccurrences)
          ..where(
              (t) => t.id.equals(occurrence.id) & t.status.equals('ongoing')))
        .write(db.TrainingPlanOccurrencesCompanion(
      status: drift.Value(status),
      resolvedAt: drift.Value(DateTime.now()),
    ));
  }
}

class _SequenceState {
  const _SequenceState(this.cursor, this.slot, this.cycle);
  final int cursor;
  final int slot;
  final int cycle;
}
