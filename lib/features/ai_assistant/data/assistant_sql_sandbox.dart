import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../domain/assistant_data_action.dart';

/// Result of a read-only query against one approved, in-memory data snapshot.
class AssistantSqlQueryResult {
  const AssistantSqlQueryResult({
    required this.sql,
    required this.tables,
    required this.rows,
    required this.truncated,
  });

  final String sql;
  final List<String> tables;
  final List<Map<String, Object?>> rows;
  final bool truncated;

  List<String> get fields =>
      rows.expand((row) => row.keys).toSet().toList()..sort();

  Map<String, Object?> get sharedPayload => {
        'rows': rows,
        'truncated': truncated,
      };

  Map<String, Object?> get auditManifest {
    final encoded = jsonEncode(sharedPayload);
    return {
      'tables': tables,
      'rowCount': rows.length,
      'fields': fields,
      'truncated': truncated,
      'querySha256': sha256.convert(utf8.encode(sql)).toString(),
      'payloadSha256': sha256.convert(utf8.encode(encoded)).toString(),
    };
  }
}

class AssistantSqlQueryException implements Exception {
  const AssistantSqlQueryException(this.message, {this.terminal = false});
  final String message;
  final bool terminal;
  @override
  String toString() => message;
}

/// A short-lived SQLite copy of only the records approved for one request.
/// SQLite work happens in a disposable isolate, so a slow query can be stopped
/// by terminating the isolate and destroying the entire data snapshot.
class AssistantSqlSandbox {
  AssistantSqlSandbox._(this._responses);

  static const int maxSnapshotRows = 50000;
  // Current snapshots can include the local exercise catalog alongside plan
  // and routine records. Keep a hard ceiling, with room for those approved
  // catalog tables to be prepared together.
  static const int maxSnapshotBytes = 20 * 1024 * 1024;
  static const int maxQueryRows = 200;
  static const int maxResultCharacters = 12000;
  static const int maxSqlCharacters = 8000;
  static const Duration queryTimeout = Duration(seconds: 3);

  final ReceivePort _responses;
  final Map<int, Completer<Map<String, Object?>>> _pending = {};
  late StreamSubscription<Object?> _responseSubscription;
  late Completer<Map<String, Object?>> _ready;
  Completer<void>? _closedCompleter;
  Isolate? _isolate;
  SendPort? _commands;
  String schema = '';
  int _nextId = 0;
  bool _closed = false;

  static Future<AssistantSqlSandbox> create(
      List<AssistantActionResult> results) async {
    final successful = results
        .where((result) => result.status == AssistantActionStatus.success)
        .toList();
    final tableRows = <String, List<Map<String, dynamic>>>{};
    final tableColumns = <String, Map<String, String>>{};
    for (final result in successful) {
      if (result.tables.isEmpty) {
        if (result.records.isNotEmpty) {
          tableRows['data_${result.category.name}'] = result.records;
        }
        continue;
      }
      for (final entry in result.tables.entries) {
        tableColumns
            .putIfAbsent(entry.key, () => <String, String>{})
            .addAll(result.tableColumns[entry.key] ?? const {});
        final rows = tableRows.putIfAbsent(entry.key, () => []);
        final known = <Object>{};
        for (final row in rows) {
          final id = row['id']?.toString();
          final localId = row['local_id']?.toString();
          final key = (id != null && id.isNotEmpty)
              ? 'id:$id'
              : (localId != null && localId.isNotEmpty)
                  ? 'local_id:$localId'
                  : jsonEncode(row);
          known.add(key);
        }
        for (final row in entry.value) {
          final id = row['id']?.toString();
          final localId = row['local_id']?.toString();
          final key = (id != null && id.isNotEmpty)
              ? 'id:$id'
              : (localId != null && localId.isNotEmpty)
                  ? 'local_id:$localId'
                  : jsonEncode(row);
          if (known.add(key)) rows.add(row);
        }
      }
      if (result.tables.isNotEmpty &&
          result.tableColumns.values.every((columns) => columns.isEmpty) &&
          result.records.isNotEmpty) {
        tableRows['data_${result.category.name}'] = result.records;
      }
    }
    final datasets = [
      for (final entry in tableRows.entries)
        {
          'table': entry.key,
          'records': entry.value,
          'columns': tableColumns[entry.key] ?? const <String, String>{},
        },
    ];
    final snapshotRows =
        tableRows.values.fold<int>(0, (sum, rows) => sum + rows.length);
    final snapshotBytes = tableRows.values.fold<int>(
        0, (sum, rows) => sum + utf8.encode(jsonEncode(rows)).length);
    if (snapshotRows > maxSnapshotRows || snapshotBytes > maxSnapshotBytes) {
      throw const AssistantSqlQueryException(
          'The approved data set is too large to prepare safely. Please choose a shorter date range.');
    }

    final sandbox = AssistantSqlSandbox._(ReceivePort());
    sandbox._ready = Completer<Map<String, Object?>>();
    sandbox._responseSubscription =
        sandbox._responses.listen(sandbox._onMessage);
    try {
      sandbox._isolate = await Isolate.spawn<Map<String, Object?>>(
        _assistantSqlSandboxWorker,
        {'replyTo': sandbox._responses.sendPort, 'datasets': datasets},
        onError: sandbox._responses.sendPort,
        onExit: sandbox._responses.sendPort,
        errorsAreFatal: true,
      );
      final ready =
          await sandbox._ready.future.timeout(const Duration(seconds: 10));
      if (ready['error'] is String) {
        throw AssistantSqlQueryException(ready['error'] as String);
      }
      sandbox._commands = ready['port'] as SendPort;
      sandbox.schema = ready['schema'] as String;
      return sandbox;
    } catch (_) {
      await sandbox.close();
      rethrow;
    }
  }

  Future<AssistantSqlQueryResult> query(String sql) async {
    if (_closed || _commands == null) {
      throw const AssistantSqlQueryException('The data snapshot has expired.',
          terminal: true);
    }
    final trimmed = sql.trim();
    if (trimmed.isEmpty || trimmed.length > maxSqlCharacters) {
      throw const AssistantSqlQueryException(
          'The SQL query is empty or too long.');
    }
    final id = ++_nextId;
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _commands!.send({'type': 'query', 'id': id, 'sql': trimmed});
    Map<String, Object?> result;
    try {
      result = await completer.future.timeout(queryTimeout);
    } on TimeoutException {
      await close();
      throw const AssistantSqlQueryException(
          'The SQL query exceeded the time limit and the temporary snapshot was discarded.',
          terminal: true);
    } finally {
      _pending.remove(id);
    }
    if (result['error'] is String) {
      throw AssistantSqlQueryException(result['error'] as String);
    }
    return AssistantSqlQueryResult(
      sql: trimmed,
      tables: (result['tables'] as List).cast<String>(),
      rows: (result['rows'] as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList(),
      truncated: result['truncated'] as bool,
    );
  }

  void _onMessage(Object? message) {
    if (message == null || message is List) {
      final error = StateError('The temporary data query process stopped.');
      for (final pending in _pending.values) {
        if (!pending.isCompleted) pending.completeError(error);
      }
      if (_ready.isCompleted == false) {
        _ready.complete({'error': error.message});
      }
      if (_closedCompleter?.isCompleted == false) _closedCompleter!.complete();
      return;
    }
    if (message is! Map) return;
    final map = Map<String, Object?>.from(message);
    switch (map['type']) {
      case 'ready':
        if (!_ready.isCompleted) _ready.complete(map);
        return;
      case 'query_result':
        final id = map['id'];
        final pending = id is int ? _pending[id] : null;
        if (pending != null && !pending.isCompleted) pending.complete(map);
        return;
      case 'closed':
        if (_closedCompleter?.isCompleted == false) {
          _closedCompleter!.complete();
        }
        return;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final commands = _commands;
    final isolate = _isolate;
    if (commands != null && isolate != null) {
      _closedCompleter = Completer<void>();
      commands.send({'type': 'close'});
      try {
        await _closedCompleter!.future.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        isolate.kill(priority: Isolate.immediate);
      }
    } else {
      isolate?.kill(priority: Isolate.immediate);
    }
    await _responseSubscription.cancel();
    _responses.close();
  }
}

void _assistantSqlSandboxWorker(Map<String, Object?> init) async {
  final replyTo = init['replyTo'] as SendPort;
  final commands = ReceivePort();
  final database = sqlite.sqlite3.openInMemory();
  final tableNames = <String>{};
  final schemas = <String>[];
  try {
    for (final dataset in init['datasets'] as List) {
      final map = Map<String, Object?>.from(dataset as Map);
      final table = map['table'] as String;
      final records = (map['records'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final declaredColumns = Map<String, String>.from(
          map['columns'] as Map? ?? const <String, String>{});
      if (records.isEmpty && declaredColumns.isEmpty) continue;
      await _createRecordsTable(
        database,
        table,
        records,
        tableNames,
        schemas,
        declaredColumns: declaredColumns,
      );
    }
    if (tableNames.isEmpty) {
      throw const AssistantSqlQueryException(
          'No records were available in the approved scope.');
    }
    database.execute('PRAGMA query_only = ON');
    final schema = [
      schemas.join('\n'),
      'Tables contain approved local database rows in snake_case plus explicitly named derived columns. '
          'Foreign keys can be joined by their documented *_id columns. '
          'Child tables contain `_parent_ref`, which joins to the parent row `ref`. '
          'Maps and lists of scalar values stay as JSON text in the parent table.',
      'Timestamps in Drift tables (e.g. consumed_at, start_time, end_time, created_at, date) '
          'are stored as Unix epoch timestamps in seconds (UTC). '
          'Use SQLite datetime(col, \'unixepoch\', \'localtime\') or date(col, \'unixepoch\', \'localtime\') '
          'to group or filter by local civil date/time. '
          'Sleep session timestamps (started_at, ended_at in sleep_canonical_sessions) are Unix epoch milliseconds; '
          'use datetime(col / 1000, \'unixepoch\', \'localtime\'). Date-only calendar columns use YYYY-MM-DD.',
      'Nutrition relationships & calculations: `nutrition_logs.amount` is the consumed amount in grams (or milliliters if `effective_is_fluid` is 1). '
          'Entries link to `products` by `product_id` or `legacy_barcode` / `barcode`, or to `off_products_archive` by `archive_local_id` / `local_id`. '
          'When archive_local_id is set, the archived values take precedence over current products and overrides. '
          'User overrides match by `effective_barcode` / `barcode` in `user_food_overrides`. '
          '`nutrition_logs` contains pre-calculated effective totals for consumed amounts: '
          '`calories_kcal`, `protein_g`, `carbs_g`, `fat_g`, `sugar_g`, `fiber_g`, `salt_g`, `caffeine_mg`. '
          'Base nutrient densities per 100g/100ml are on `nutrition_logs` (`calories_per_100g`, `protein_per_100g`, `carbs_per_100g`, etc.), '
          '`products`, `off_products_archive`, and `user_food_overrides`. '
          'Calculation formula: consumed_nutrient = (amount / 100.0) * nutrient_per_100g. '
          'Unlinked products have NULL nutrients, NOT 0. Do not treat NULL as zero unless explicitly 0. '
          'Detailed micronutrients for approved German Federal Food Key (BLS) foods live in `bls_food_nutrients` '
          '(columns: barcode, component_code, nutrient_name, name_de, name_en, nutrient_group, '
          'value_per_100g, value_text, unit, is_missing, origin, reference). '
          'Join nutrition_logs.effective_barcode to bls_food_nutrients.barcode. '
          'In `bls_food_nutrients`, numeric 0.0 has is_missing = 0. '
          'When unmeasured or missing, value_per_100g is NULL and is_missing is 1. Consumed BLS nutrient = (nutrition_logs.amount / 100.0) * bls_food_nutrients.value_per_100g.',
      'Workout relationships & exercise metadata: `workout_logs` (start_time, end_time, routine_id, routine_name_snapshot) joins to `set_logs` via `set_logs.workout_log_id = workout_logs.id`. '
          '`set_logs` includes `exercise_id`, `weight`, `reps`, `rpe`, `effective_exercise_name`, `canonical_exercise_name`, and `exercise_name_snapshot`. '
          'Exercise metadata: `exercises` (id, name, name_de, name_en, modality, tracking_type), `exercise_translations` (exercise_id, language_code, name), '
          '`exercise_muscles` (exercise_id, muscle_id, role: primary/secondary), `muscles` (id), and `exercise_equipment` (exercise_id, equipment_id) with `equipment` (id). '
          'Historical names: if an exercise or routine is renamed or deleted from the catalog, `set_logs.exercise_name_snapshot` '
          'and `workout_logs.routine_name_snapshot` preserve the historical name recorded during the workout. '
          '`effective_exercise_name` and `effective_routine_name` prefer the current name and fall back to the snapshot. '
          'Routines: `workout_logs.routine_id = routines.id`. Saved recipes (`meals`, `meal_items`) require a separate recipes approval; meal_entries has no recipe foreign key.',
      'Known units: weightKg and weight_kg are kilograms; caloriesKcal and calories_kcal are kilocalories; '
          'fields ending in Grams or _g are grams; fields ending in Milliliters or _ml are milliliters; '
          'fields ending in Minutes or _minutes are minutes; fields ending in Seconds or _seconds are seconds; '
          'caffeine_mg is milligrams. Measurement values use their accompanying unit column.',
    ].join('\n');
    replyTo
        .send({'type': 'ready', 'port': commands.sendPort, 'schema': schema});
  } catch (_) {
    database.close();
    commands.close();
    replyTo.send({
      'type': 'ready',
      'error': 'The approved records could not be prepared for analysis.',
    });
    return;
  }

  await for (final message in commands) {
    if (message is! Map) continue;
    if (message['type'] == 'close') {
      database.close();
      replyTo.send({'type': 'closed'});
      commands.close();
      return;
    }
    if (message['type'] != 'query') continue;
    final id = message['id'] as int;
    try {
      final sql = message['sql'] as String;
      final tables = _validateReadOnlySelect(sql, tableNames);
      final executable = sql.endsWith(';')
          ? sql.substring(0, sql.length - 1).trimRight()
          : sql;
      final result = database.select(
          'SELECT * FROM ($executable) AS assistant_query_result LIMIT ${AssistantSqlSandbox.maxQueryRows + 1}');
      var rows = result
          .take(AssistantSqlSandbox.maxQueryRows)
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: true);
      final initialRowCount = rows.length;
      var truncated = result.length > AssistantSqlSandbox.maxQueryRows;
      while (rows.isNotEmpty &&
          jsonEncode({'rows': rows, 'truncated': truncated}).length >
              AssistantSqlSandbox.maxResultCharacters) {
        rows.removeLast();
        truncated = true;
      }
      if (initialRowCount > 0 && rows.isEmpty && truncated) {
        throw const AssistantSqlQueryException(
            'The query returned a value that is too large. Select fewer or shorter columns.');
      }
      replyTo.send({
        'type': 'query_result',
        'id': id,
        'tables': tables.toList()..sort(),
        'rows': rows,
        'truncated': truncated,
      });
    } on AssistantSqlQueryException catch (error) {
      replyTo.send({'type': 'query_result', 'id': id, 'error': error.message});
    } catch (_) {
      replyTo.send({
        'type': 'query_result',
        'id': id,
        'error':
            'The SQL query could not be run. Check the table and column names.',
      });
    }
  }
}

Set<String> _validateReadOnlySelect(String sql, Set<String> allowedTables) {
  final source = sql.trim().endsWith(';') ? sql : '$sql;';
  final parsed = SqlEngine().parse(ParserEntrypoint.multiple, source);
  if (parsed.errors.isNotEmpty) {
    throw const AssistantSqlQueryException(
        'Only one read-only SELECT query is allowed.');
  }
  if (parsed.rootNode.statements.length != 1) {
    throw const AssistantSqlQueryException(
        'Only one SQL statement is allowed.');
  }
  if (parsed.rootNode.statements.single is! BaseSelectStatement) {
    throw const AssistantSqlQueryException(
        'Only a read-only SELECT query is allowed.');
  }
  final statement = parsed.rootNode.statements.single as BaseSelectStatement;
  if (statement.selfAndDescendants.length > 1000) {
    throw const AssistantSqlQueryException('The SQL query is too complex.');
  }
  if (statement.selfAndDescendants
      .whereType<WithClause>()
      .any((clause) => clause.recursive)) {
    throw const AssistantSqlQueryException(
        'Recursive SQL queries are not allowed.');
  }
  final cteNames = statement.selfAndDescendants
      .whereType<WithClause>()
      .expand((clause) => clause.ctes)
      .map((cte) => cte.cteTableName.toLowerCase())
      .toSet();
  if (cteNames.any(allowedTables.contains)) {
    throw const AssistantSqlQueryException(
        'A query cannot shadow an approved data table.');
  }
  const allowedFunctions = {
    'abs',
    'avg',
    'coalesce',
    'count',
    'date',
    'datetime',
    'group_concat',
    'ifnull',
    'iif',
    'instr',
    'julianday',
    'length',
    'lower',
    'ltrim',
    'max',
    'min',
    'nullif',
    'replace',
    'round',
    'rtrim',
    'strftime',
    'substr',
    'sum',
    'time',
    'total',
    'trim',
    'unixepoch',
    'upper',
  };
  for (final invocation
      in statement.selfAndDescendants.whereType<SqlInvocation>()) {
    if (invocation is TableValuedFunction ||
        invocation.schemaName != null ||
        !allowedFunctions.contains(invocation.name.toLowerCase())) {
      throw const AssistantSqlQueryException(
          'The query uses a SQL function that is not allowed.');
    }
  }
  for (final join in statement.selfAndDescendants.whereType<Join>()) {
    if (join.operator.operator == JoinOperatorKind.cross ||
        join.operator.operator == JoinOperatorKind.comma ||
        join.constraint == null) {
      throw const AssistantSqlQueryException(
          'Queries must use an explicit condition for each table join.');
    }
  }
  final referenced = <String>{};
  final repeatedTables = <String>{};
  for (final reference
      in statement.selfAndDescendants.whereType<TableReference>()) {
    final name = reference.tableName.toLowerCase();
    if (reference.schemaName != null ||
        (!allowedTables.contains(name) && !cteNames.contains(name))) {
      throw const AssistantSqlQueryException(
          'The query references a table outside the approved data snapshot.');
    }
    if (allowedTables.contains(name) && !referenced.add(name)) {
      repeatedTables.add(name);
    }
  }
  if (referenced.length > 10 || repeatedTables.isNotEmpty) {
    throw const AssistantSqlQueryException(
        'A query can use at most ten approved tables and cannot self-join a table.');
  }
  if (referenced.isEmpty) {
    throw const AssistantSqlQueryException(
        'A query must read at least one approved data table.');
  }
  return referenced;
}

Future<void> _createRecordsTable(
  sqlite.Database database,
  String table,
  List<Map<String, dynamic>> records,
  Set<String> tableNames,
  List<String> schemas, {
  String? parentRef,
  Map<String, String> declaredColumns = const {},
}) async {
  final fields = <String, String>{
    for (final entry in declaredColumns.entries)
      entry.key: _safeSqlType(entry.value),
  };
  final childLists = <String, List<Map<String, dynamic>>>{};
  for (final record in records) {
    for (final entry in record.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty && value.first is Map) {
        childLists
            .putIfAbsent(entry.key, () => <Map<String, dynamic>>[])
            .addAll(value.whereType<Map>().map((row) =>
                Map<String, dynamic>.from(row.cast<String, dynamic>())));
      } else {
        fields.putIfAbsent(entry.key, () => _sqliteType(value));
      }
    }
  }
  if (parentRef != null) fields['_parent_ref'] = 'TEXT';
  if (fields.isEmpty) fields['ref'] = 'TEXT';
  final quotedTable = _quoteIdentifier(table);
  final definitions = fields.entries
      .map((entry) => '${_quoteIdentifier(entry.key)} ${entry.value}')
      .join(', ');
  database.execute('CREATE TABLE $quotedTable ($definitions)');
  tableNames.add(table.toLowerCase());

  final columns = fields.keys.toList();
  final insertSql =
      'INSERT INTO $quotedTable (${columns.map(_quoteIdentifier).join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')})';
  for (final record in records) {
    final values = [
      for (final column in columns)
        if (column == '_parent_ref')
          parentRef ?? _sqliteValue(record[column])
        else
          _sqliteValue(record[column]),
    ];
    database.execute(insertSql, values);
  }
  schemas.add(
      'Table $table(${fields.entries.map((entry) => '${entry.key} ${entry.value}').join(', ')}).');
  for (final entry in childLists.entries) {
    final childTable = '${table}_${_safeIdentifier(entry.key)}';
    final parents = <String, List<Map<String, dynamic>>>{};
    for (final record in records) {
      final ref = record['ref']?.toString();
      final children = record[entry.key];
      if (ref != null && children is List) {
        parents[ref] = children
            .whereType<Map>()
            .map(
                (row) => Map<String, dynamic>.from(row.cast<String, dynamic>()))
            .toList();
      }
    }
    final flattened = <Map<String, dynamic>>[
      for (final parent in parents.entries)
        for (final child in parent.value) {...child, '_parent_ref': parent.key},
    ];
    if (flattened.isNotEmpty) {
      await _createRecordsTable(
          database, childTable, flattened, tableNames, schemas);
    }
  }
}

String _safeSqlType(String value) => switch (value.toUpperCase()) {
      'INTEGER' => 'INTEGER',
      'REAL' => 'REAL',
      'BLOB' => 'BLOB',
      _ => 'TEXT',
    };

Object? _sqliteValue(Object? value) {
  if (value is bool) return value ? 1 : 0;
  if (value is Map || value is List) return jsonEncode(value);
  if (value is String || value is num || value == null) return value;
  return value.toString();
}

String _sqliteType(Object? value) => value is bool || value is int
    ? 'INTEGER'
    : value is num
        ? 'REAL'
        : 'TEXT';

String _safeIdentifier(String value) {
  final normalized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return normalized.isEmpty ? 'items' : normalized;
}

String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';
