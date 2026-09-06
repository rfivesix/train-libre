import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../data/drift_database.dart';

/// Outcome of one pass over the alias register. Logged, and asserted on in
/// tests; the counts are the only way to tell a no-op run from a run that did
/// nothing because it silently failed.
@immutable
class ExerciseAliasMigrationResult {
  final int aliasesApplied;
  final int routineExercisesRewritten;
  final int setLogsRewritten;
  final int overridesRewritten;
  final int duplicateSlotsRemoved;
  final int duplicateSlotsKept;
  final int skippedMissingTarget;

  const ExerciseAliasMigrationResult({
    this.aliasesApplied = 0,
    this.routineExercisesRewritten = 0,
    this.setLogsRewritten = 0,
    this.overridesRewritten = 0,
    this.duplicateSlotsRemoved = 0,
    this.duplicateSlotsKept = 0,
    this.skippedMissingTarget = 0,
  });

  bool get changedSomething =>
      routineExercisesRewritten > 0 ||
      setLogsRewritten > 0 ||
      overridesRewritten > 0 ||
      duplicateSlotsRemoved > 0;

  @override
  String toString() => 'aliases=$aliasesApplied '
      'routineExercises=$routineExercisesRewritten '
      'setLogs=$setLogsRewritten overrides=$overridesRewritten '
      'duplicatesRemoved=$duplicateSlotsRemoved '
      'duplicatesKept=$duplicateSlotsKept '
      'skipped=$skippedMissingTarget';
}

/// Points user data at the exercise that survived a merge.
///
/// `exercises.id` is a foreign key in `routine_exercises` and `set_logs`, so
/// the catalog can never delete an exercise; it retires one and records where
/// it went. This is the other half of that bargain — without it, a merged
/// exercise means a routine entry and a pile of set logs that resolve to a row
/// hidden from search, and the history quietly falls out of every statistic.
///
/// Three properties this has to have:
///
/// * **Idempotent.** After one pass nothing points at a retired id, so a second
///   pass is a no-op. That is what lets the whole register be applied on every
///   import, which in turn is what covers devices that skipped a release.
/// * **Never destructive.** A pointer is moved, never dropped;
///   `exercise_name_snapshot` is left alone because it records what the user
///   chose at the time, not where that exercise lives today.
/// * **Safe against a half-built catalog.** An alias whose target is not in the
///   database is skipped rather than applied. A stale pointer is recoverable;
///   a routine entry aimed at nothing is not.
class ExerciseAliasMigration {
  const ExerciseAliasMigration();

  Future<ExerciseAliasMigrationResult> run(AppDatabase db) async {
    final aliases = await db.select(db.exerciseAliases).get();
    if (aliases.isEmpty) return const ExerciseAliasMigrationResult();

    var applied = 0;
    var routineExercises = 0;
    var setLogs = 0;
    var overrides = 0;
    var skipped = 0;

    for (final alias in aliases) {
      final oldId = alias.oldId;
      final newId = alias.newId;
      if (oldId == newId || oldId.isEmpty || newId.isEmpty) continue;

      final target = await (db.select(db.exercises)
            ..where((tbl) => tbl.id.equals(newId))
            ..limit(1))
          .getSingleOrNull();
      if (target == null) {
        skipped++;
        debugPrint(
          '[ExerciseAliases] $oldId -> $newId skipped: target not in database',
        );
        continue;
      }
      applied++;

      routineExercises += await db.customUpdate(
        'UPDATE routine_exercises SET exercise_id = ? WHERE exercise_id = ?',
        variables: [Variable.withString(newId), Variable.withString(oldId)],
        updates: {db.routineExercises},
      );

      setLogs += await db.customUpdate(
        'UPDATE set_logs SET exercise_id = ? WHERE exercise_id = ?',
        variables: [Variable.withString(newId), Variable.withString(oldId)],
        updates: {db.setLogs},
      );

      // A user's own exercise that overrides a merged one has to follow it,
      // or the override is orphaned: search keeps hiding the retired row while
      // the survivor shows up next to the user's replacement.
      overrides += await db.customUpdate(
        'UPDATE exercises SET replaces_exercise_id = ? '
        'WHERE replaces_exercise_id = ?',
        variables: [Variable.withString(newId), Variable.withString(oldId)],
        updates: {db.exercises},
      );
    }

    final duplicates = await _collapseEmptyDuplicateSlots(db);

    final result = ExerciseAliasMigrationResult(
      aliasesApplied: applied,
      routineExercisesRewritten: routineExercises,
      setLogsRewritten: setLogs,
      overridesRewritten: overrides,
      duplicateSlotsRemoved: duplicates.removed,
      duplicateSlotsKept: duplicates.kept,
      skippedMissingTarget: skipped,
    );
    if (result.changedSomething || skipped > 0) {
      debugPrint('[ExerciseAliases] $result');
    }
    return result;
  }

  /// Removes routine slots that a merge turned into exact duplicates — but
  /// only the ones that carry nothing.
  ///
  /// Two ids collapsing into one (1793 and 1800 both become 1778) leaves a
  /// routine holding the same exercise twice. Tidying that up is tempting, and
  /// mostly wrong: `routine_set_templates` cascades off `routine_exercises`,
  /// so deleting the losing row deletes the user's planned sets with it. The
  /// two entries were different exercises when they were added and may well
  /// carry different set schemes.
  ///
  /// So only a slot with no set templates and no note is removed — one the
  /// user added and never configured, where there is provably nothing to lose.
  /// Anything else stays and shows up twice, which is confusing for a moment
  /// and fixable in two taps.
  Future<({int removed, int kept})> _collapseEmptyDuplicateSlots(
    AppDatabase db,
  ) async {
    final duplicateGroups = await db.customSelect(
      '''
      SELECT routine_id, exercise_id
      FROM routine_exercises
      GROUP BY routine_id, exercise_id
      HAVING COUNT(*) > 1
      ''',
      readsFrom: {db.routineExercises},
    ).get();
    if (duplicateGroups.isEmpty) return (removed: 0, kept: 0);

    var removed = 0;
    var kept = 0;

    for (final group in duplicateGroups) {
      final routineId = group.read<String>('routine_id');
      final exerciseId = group.read<String>('exercise_id');

      final slots = await db.customSelect(
        '''
        SELECT re.id AS uuid, re.local_id AS local_id, re.notes AS notes,
               (SELECT COUNT(*) FROM routine_set_templates t
                 WHERE t.routine_exercise_id = re.id) AS template_count
        FROM routine_exercises re
        WHERE re.routine_id = ? AND re.exercise_id = ?
        ORDER BY re.order_index ASC, re.local_id ASC
        ''',
        variables: [
          Variable.withString(routineId),
          Variable.withString(exerciseId),
        ],
        readsFrom: {db.routineExercises, db.routineSetTemplates},
      ).get();

      // The first one in routine order is the survivor, whatever it holds.
      for (final slot in slots.skip(1)) {
        final notes = slot.read<String?>('notes');
        final hasContent = slot.read<int>('template_count') > 0 ||
            (notes != null && notes.trim().isNotEmpty);
        if (hasContent) {
          kept++;
          continue;
        }
        await (db.delete(db.routineExercises)
              ..where((tbl) => tbl.localId.equals(slot.read<int>('local_id'))))
            .go();
        removed++;
      }
    }

    return (removed: removed, kept: kept);
  }
}
