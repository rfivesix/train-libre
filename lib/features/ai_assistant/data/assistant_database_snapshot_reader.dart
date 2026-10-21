import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../../data/drift_database.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

/// Reads complete rows from an explicit allowlist of user-data tables.
/// Date-scoped categories are filtered in SQLite before entering the temporary
/// assistant snapshot. App configuration, social data, assistant history, and
/// unrelated catalog tables are never included.
class AssistantDatabaseSnapshotReader {
  const AssistantDatabaseSnapshotReader(this.database);

  final AppDatabase database;

  Future<Map<String, Map<String, String>>> columnsFor(
      Map<String, List<Map<String, dynamic>>> tables) async {
    final result = <String, Map<String, String>>{};
    for (final entry in tables.entries) {
      final table = entry.key;
      final presentFields = entry.value.expand((row) => row.keys).toSet();
      final rows =
          await database.customSelect('PRAGMA table_info($table)').get();
      result[table] = {
        for (final row in rows)
          if (presentFields.contains(row.read<String>('name')))
            row.read<String>('name'): _sqliteType(row.read<String>('type')),
      };
    }
    return result;
  }

  Future<Map<String, List<Map<String, dynamic>>>> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    switch (category) {
      case AssistantDataCategory.workouts:
        final range = _range(scope);
        final workoutWhere = _dateWhere('start_time', range);
        final workoutIds = 'SELECT id FROM workout_logs$workoutWhere';
        return {
          'workout_logs':
              await _select('workout_logs', workoutWhere, values: range),
          'set_logs': await _select(
            'set_logs',
            ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
            values: range,
          ),
          'workout_exercise_logs': await _select(
            'workout_exercise_logs',
            ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
            values: range,
          ),
          'cardio_activities': await _select(
            'cardio_activities',
            ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
            values: range,
          ),
          'cardio_samples': await _select(
            'cardio_samples',
            ''' WHERE deleted_at IS NULL AND cardio_activity_id IN (
              SELECT id FROM cardio_activities WHERE deleted_at IS NULL
              AND workout_log_id IN ($workoutIds))''',
            values: range,
          ),
        };
      case AssistantDataCategory.routines:
        const routineIds = 'SELECT id FROM routines WHERE deleted_at IS NULL';
        const routineExerciseIds =
            'SELECT id FROM routine_exercises WHERE deleted_at IS NULL AND routine_id IN ($routineIds)';
        const exerciseIds =
            'SELECT exercise_id FROM routine_exercises WHERE deleted_at IS NULL AND routine_id IN ($routineIds)';
        const muscleIds =
            'SELECT muscle_id FROM exercise_muscles WHERE exercise_id IN ($exerciseIds)';
        const equipmentIds =
            'SELECT equipment_id FROM exercise_equipment WHERE exercise_id IN ($exerciseIds)';
        return {
          'routines': await _select('routines', ' WHERE deleted_at IS NULL'),
          'routine_exercises': await _select(
            'routine_exercises',
            ' WHERE deleted_at IS NULL AND routine_id IN ($routineIds)',
          ),
          'routine_set_templates': await _select(
            'routine_set_templates',
            ' WHERE deleted_at IS NULL AND routine_exercise_id IN ($routineExerciseIds)',
          ),
          'exercises': await _select(
            'exercises',
            ' WHERE deleted_at IS NULL AND id IN ($exerciseIds)',
          ),
          'pinned_exercise_notes': await _select(
              'pinned_exercise_notes', ' WHERE exercise_id IN ($exerciseIds)'),
          'exercise_translations': await _select(
            'exercise_translations',
            ' WHERE deleted_at IS NULL AND exercise_id IN ($exerciseIds)',
          ),
          'exercise_muscles': await _select(
              'exercise_muscles', ' WHERE exercise_id IN ($exerciseIds)'),
          'muscles': await _select('muscles', ' WHERE id IN ($muscleIds)'),
          'muscle_translations': await _select(
              'muscle_translations', ' WHERE muscle_id IN ($muscleIds)'),
          'exercise_equipment': await _select(
              'exercise_equipment', ' WHERE exercise_id IN ($exerciseIds)'),
          'equipment':
              await _select('equipment', ' WHERE id IN ($equipmentIds)'),
          'equipment_translations': await _select('equipment_translations',
              ' WHERE equipment_id IN ($equipmentIds)'),
          'exercise_tags': await _select(
              'exercise_tags', ' WHERE exercise_id IN ($exerciseIds)'),
        };
      case AssistantDataCategory.trainingPlans:
        const planIds =
            'SELECT id FROM training_plans WHERE deleted_at IS NULL';
        final tables = <String, List<Map<String, dynamic>>>{
          'training_plans':
              await _select('training_plans', ' WHERE deleted_at IS NULL'),
          'training_plan_revisions': await _select(
            'training_plan_revisions',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
          'training_plan_activations': await _select(
            'training_plan_activations',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
          'training_plan_occurrences': await _select(
            'training_plan_occurrences',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
        };
        final activeWeek = _activeWeekSchedule(tables);
        if (activeWeek.isNotEmpty) tables['active_plan_week'] = activeWeek;
        return tables;
      case AssistantDataCategory.diary:
      case AssistantDataCategory.nutrition:
        final range = _range(scope);
        final foodWhere = _dateWhere('consumed_at', range);
        final mealWhere = _dateWhere('consumed_at', range);
        final fluidWhere = _dateWhere('consumed_at', range);
        final supplementWhere = _dateWhere('taken_at', range);
        final supplementLogs =
            'SELECT supplement_id FROM supplement_logs$supplementWhere';
        final settingHistoryWhere = range.isEmpty
            ? ' WHERE deleted_at IS NULL'
            : ' WHERE deleted_at IS NULL AND created_at < ? AND supplement_id IN ($supplementLogs)';
        return {
          'meal_entries':
              await _select('meal_entries', mealWhere, values: range),
          'nutrition_logs':
              await _select('nutrition_logs', foodWhere, values: range),
          'fluid_logs': await _select('fluid_logs', fluidWhere, values: range),
          'supplement_logs':
              await _select('supplement_logs', supplementWhere, values: range),
          'products': await _select(
            'products',
            ' WHERE deleted_at IS NULL AND id IN (SELECT product_id FROM nutrition_logs$foodWhere)',
            values: range,
          ),
          'off_products_archive': await _select(
            'off_products_archive',
            ' WHERE deleted_at IS NULL AND local_id IN (SELECT archive_local_id FROM nutrition_logs$foodWhere)',
            values: range,
          ),
          'supplements': await _select(
            'supplements',
            ' WHERE deleted_at IS NULL AND id IN (SELECT supplement_id FROM supplement_logs$supplementWhere)',
            values: range,
          ),
          'supplement_settings_history': await _select(
            'supplement_settings_history',
            settingHistoryWhere,
            values: range.isEmpty ? const [] : [range.last, ...range],
          ),
          'user_food_overrides': await _select(
            'user_food_overrides',
            ''' WHERE deleted_at IS NULL AND barcode IN (
              SELECT legacy_barcode FROM nutrition_logs$foodWhere)''',
            values: range,
          ),
          'user_food_override_translations': await _select(
            'user_food_override_translations',
            ''' WHERE deleted_at IS NULL AND user_food_override_id IN (
              SELECT id FROM user_food_overrides WHERE deleted_at IS NULL
              AND barcode IN (SELECT legacy_barcode FROM nutrition_logs$foodWhere))''',
            values: range,
          ),
          'daily_goals_history': await _select(
            'daily_goals_history',
            _dateWhere('created_at', range),
            values: range,
          ),
          'meals': await _select('meals', ' WHERE deleted_at IS NULL'),
          'meal_items': await _select(
            'meal_items',
            ' WHERE meal_id IN (SELECT id FROM meals WHERE deleted_at IS NULL)',
          ),
        };
      case AssistantDataCategory.steps:
        final range = _range(scope);
        return {
          'health_step_segments': await _select(
              'health_step_segments', _dateWhere('start_at', range),
              values: range),
        };
      case AssistantDataCategory.sleep:
        final dateRange = _range(scope, dateOnly: true);
        final analysisWhere =
            _dateWhere('night_date', dateRange, hasDeletedAt: false);
        final analyses = await _select('sleep_nightly_analyses', analysisWhere,
            values: dateRange);
        final sessionsByAnalysis = analyses
            .map((row) => row['session_id'])
            .whereType<String>()
            .toSet();
        final sessionRange = _range(scope);
        final scopedSessions = await _select(
          'sleep_canonical_sessions',
          _dateWhere('started_at', sessionRange, hasDeletedAt: false),
          values: sessionRange,
        );
        final sessionIds = {
          ...sessionsByAnalysis,
          ...scopedSessions.map((row) => row['id']).whereType<String>(),
        }.toList();
        final analysisSessions = sessionIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'sleep_canonical_sessions',
                ' WHERE id IN (${List.filled(sessionIds.length, '?').join(',')})',
                values: sessionIds,
              );
        final ids = sessionIds.isEmpty
            ? 'IN (NULL)'
            : 'IN (${List.filled(sessionIds.length, '?').join(',')})';
        final rawImports = sessionIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'sleep_raw_imports',
                ' WHERE id IN (SELECT raw_import_id FROM sleep_canonical_sessions WHERE id $ids)',
                values: sessionIds,
              );
        return {
          'sleep_canonical_sessions': analysisSessions,
          'sleep_canonical_stage_segments': await _select(
              'sleep_canonical_stage_segments', ' WHERE session_id $ids',
              values: sessionIds),
          'sleep_canonical_heart_rate_samples': await _select(
              'sleep_canonical_heart_rate_samples', ' WHERE session_id $ids',
              values: sessionIds),
          'sleep_nightly_analyses': analyses,
          'sleep_raw_imports': rawImports,
        };
      case AssistantDataCategory.measurements:
        final range = _range(scope);
        return {
          'measurements': await _select(
              'measurements', _dateWhere('date', range),
              values: range),
        };
      case AssistantDataCategory.goals:
        const goalIds = 'SELECT id FROM user_goals WHERE deleted_at IS NULL';
        return {
          'user_goals':
              await _select('user_goals', ' WHERE deleted_at IS NULL'),
          'goal_events': await _select(
            'goal_events',
            ' WHERE deleted_at IS NULL AND goal_id IN ($goalIds)',
          ),
          'goal_reviews': await _select(
            'goal_reviews',
            ' WHERE deleted_at IS NULL AND goal_id IN ($goalIds)',
          ),
        };
      case AssistantDataCategory.profile:
        return {
          'profiles': await _select(
            'profiles',
            ' WHERE deleted_at IS NULL',
            columns: const ['id', 'birthday', 'height', 'gender'],
          ),
          'app_settings': await _select(
            'app_settings',
            ''' WHERE deleted_at IS NULL AND user_id IN (
              SELECT id FROM profiles WHERE deleted_at IS NULL)''',
            columns: const [
              'user_id',
              'unit_system',
              'target_calories',
              'target_protein',
              'target_carbs',
              'target_fat',
              'target_water',
              'target_steps',
              'experience_level',
            ],
          ),
        };
      case AssistantDataCategory.supplements:
        return {
          'supplements':
              await _select('supplements', ' WHERE deleted_at IS NULL'),
          'supplement_settings_history': await _select(
            'supplement_settings_history',
            ''' WHERE deleted_at IS NULL AND created_at = (
              SELECT MAX(latest.created_at) FROM supplement_settings_history latest
              WHERE latest.supplement_id = supplement_settings_history.supplement_id
              AND latest.deleted_at IS NULL)''',
          ),
        };
      case AssistantDataCategory.recovery:
        return const {};
    }
  }

  List<Object?> _range(AssistantDateScope? scope, {bool dateOnly = false}) {
    if (scope == null) return const [];
    if (dateOnly) {
      return [
        _day(scope.start),
        _day(DateTime(scope.end.year, scope.end.month, scope.end.day + 1)),
      ];
    }
    return [
      scope.start.millisecondsSinceEpoch,
      DateTime(scope.end.year, scope.end.month, scope.end.day + 1)
          .millisecondsSinceEpoch,
    ];
  }

  String _dateWhere(String column, List<Object?> range,
      {bool hasDeletedAt = true}) {
    if (range.isEmpty) return hasDeletedAt ? ' WHERE deleted_at IS NULL' : '';
    return '${hasDeletedAt ? ' WHERE deleted_at IS NULL AND' : ' WHERE'} $column >= ? AND $column < ?';
  }

  Future<List<Map<String, dynamic>>> _select(
    String table,
    String suffix, {
    List<Object?> values = const [],
    List<String>? columns,
  }) async {
    final variables = [
      for (final value in values)
        if (value is int)
          drift.Variable.withInt(value)
        else if (value is String)
          drift.Variable.withString(value)
        else
          throw ArgumentError('Unsupported snapshot query variable.'),
    ];
    return (await database
            .customSelect(
                'SELECT ${columns?.join(', ') ?? '*'} FROM $table$suffix',
                variables: variables)
            .get())
        .map((row) => Map<String, dynamic>.from(row.data))
        .toList();
  }

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _activeWeekSchedule(
      Map<String, List<Map<String, dynamic>>> tables) {
    final activePlans = (tables['training_plans'] ?? const [])
        .where((plan) => plan['is_active'] == true || plan['is_active'] == 1)
        .where((plan) => plan['kind'] == 'week')
        .toList();
    if (activePlans.isEmpty) return const [];
    final plan = activePlans.first;
    final planId = plan['id'];
    if (planId is! String) return const [];
    final activations = (tables['training_plan_activations'] ?? const [])
        .where((row) => row['plan_id'] == planId && row['ended_on'] == null)
        .toList()
      ..sort((a, b) =>
          _dateValue(a['started_on']).compareTo(_dateValue(b['started_on'])));
    if (activations.isEmpty) return const [];
    final activation = activations.last;
    final startedOn = _dateValue(activation['started_on']);
    final today = DateTime.now();
    final monday =
        DateTime(today.year, today.month, today.day - today.weekday + 1);
    final revisions = (tables['training_plan_revisions'] ?? const [])
        .where((row) => row['plan_id'] == planId)
        .toList()
      ..sort((a, b) =>
          (a['number'] as num? ?? 0).compareTo(b['number'] as num? ?? 0));
    final occurrences = tables['training_plan_occurrences'] ?? const [];
    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < 7; index++) {
      final date = DateTime(monday.year, monday.month, monday.day + index);
      if (date
          .isBefore(DateTime(startedOn.year, startedOn.month, startedOn.day))) {
        continue;
      }
      final cycle = DateTime.utc(date.year, date.month, date.day)
              .difference(
                  DateTime.utc(startedOn.year, startedOn.month, startedOn.day))
              .inDays ~/
          7;
      Map<String, dynamic>? revision;
      for (final candidate in revisions) {
        final effectiveOn = _dateValue(candidate['effective_on']);
        final effectiveCycle = candidate['effective_cycle'] as num?;
        if (!date.isBefore(effectiveOn) &&
            (effectiveCycle == null || cycle >= effectiveCycle.toInt())) {
          revision = candidate;
        }
      }
      if (revision == null || revision['days_json'] is! String) continue;
      final days = jsonDecode(revision['days_json'] as String);
      if (days is! List || index >= days.length || days[index] is! Map) {
        continue;
      }
      final day = Map<String, dynamic>.from(days[index] as Map);
      final routine = day['routineSnapshot'] is Map
          ? Map<String, dynamic>.from(day['routineSnapshot'] as Map)
          : null;
      final occurrence = occurrences.where((row) {
        return row['activation_id'] == activation['id'] &&
            _sameDate(_dateValue(row['scheduled_on']), date) &&
            row['slot_index'] == index;
      }).firstOrNull;
      result.add({
        'plan_id': planId,
        'plan_name': plan['name'],
        'plan_kind': plan['kind'],
        'date': _day(date),
        'weekday_index': index + 1,
        'slot_index': index,
        'revision_id': revision['id'],
        'revision_number': revision['number'],
        'routine_uuid': day['routineUuid'],
        'routine_name': routine?['name'],
        'is_rest': routine == null,
        'status': routine == null ? 'rest' : occurrence?['status'] ?? 'planned',
        'workout_log_id': occurrence?['workout_log_id'],
        'routine_snapshot': routine,
      });
    }
    return result;
  }

  DateTime _dateValue(Object? value) => value is int
      ? DateTime.fromMillisecondsSinceEpoch(value)
      : DateTime.parse(value.toString());

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _sqliteType(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('INT')) return 'INTEGER';
    if (normalized.contains('REAL') ||
        normalized.contains('FLOA') ||
        normalized.contains('DOUB')) {
      return 'REAL';
    }
    if (normalized.contains('BLOB')) return 'BLOB';
    return 'TEXT';
  }
}

/// Adds complete allowlisted SQLite table snapshots to existing semantic
/// action results so analysis can use all stored fields and relationships.
class AssistantComprehensiveDataAction implements AssistantDataAction {
  AssistantComprehensiveDataAction({
    required this.reader,
    required this.actions,
  });

  final AssistantDatabaseSnapshotReader reader;
  final List<AssistantDataAction> actions;

  @override
  Set<AssistantDataCategory> get categories => {
        for (final action in actions) ...action.categories,
      };

  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    final matches =
        actions.where((action) => action.categories.contains(category));
    if (matches.length != 1) throw StateError('No unique action for $category');
    final semantic = await matches.single.read(category, scope);
    if (semantic.status != AssistantActionStatus.success) return semantic;
    final tables = await reader.read(category, scope);
    return AssistantActionResult(
      category: category,
      status: semantic.status,
      records: semantic.records,
      tables: tables,
      tableColumns: await reader.columnsFor(tables),
      error: semantic.error,
    );
  }
}
