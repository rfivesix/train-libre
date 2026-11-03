import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_sql_sandbox.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_action.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistantSqlSandbox sandbox;

  setUp(() async {
    sandbox = await AssistantSqlSandbox.create([
      AssistantActionResult(
        category: AssistantDataCategory.workouts,
        status: AssistantActionStatus.success,
        records: const [
          {
            'ref': 'workout:1',
            'startedAt': '2026-10-18T09:00:00',
            'sets': [
              {'ref': 'set:1', 'exercise': 'Squat', 'reps': 5, 'weightKg': 80},
              {
                'ref': 'set:2',
                'exercise': 'Squat',
                'reps': 5,
                'weightKg': 82.5,
              },
            ],
          },
          {
            'ref': 'workout:2',
            'startedAt': '2026-10-19T09:00:00',
            'sets': [
              {'ref': 'set:3', 'exercise': 'Squat', 'reps': 3, 'weightKg': 85},
            ],
          },
        ],
      ),
      AssistantActionResult(
        category: AssistantDataCategory.nutrition,
        status: AssistantActionStatus.success,
        records: const [
          {
            'ref': 'nutrition:2026-10-18',
            'date': '2026-10-18',
            'caloriesKcal': 2100,
          },
        ],
      ),
    ]);
  });

  tearDown(() => sandbox.close());

  test(
    'supports local aggregation and joins across nested child tables',
    () async {
      final result = await sandbox.query('''
      SELECT w.ref, COUNT(s.ref) AS set_count, SUM(s.reps) AS total_reps
      FROM data_workouts AS w
      JOIN data_workouts_sets AS s ON s._parent_ref = w.ref
      GROUP BY w.ref
      ORDER BY w.ref
    ''');

      expect(result.rows, [
        {'ref': 'workout:1', 'set_count': 2, 'total_reps': 10},
        {'ref': 'workout:2', 'set_count': 1, 'total_reps': 3},
      ]);
      expect(result.tables, ['data_workouts', 'data_workouts_sets']);
      expect(result.auditManifest['rowCount'], 2);
      expect((result.auditManifest['payloadSha256'] as String), hasLength(64));
    },
  );

  test(
    'keeps categories in one approved snapshot available for analysis',
    () async {
      final result = await sandbox.query('''
      SELECT AVG(caloriesKcal) AS average_calories
      FROM data_nutrition
    ''');

      expect(result.rows.single['average_calories'], 2100);
      expect(sandbox.schema, contains('data_nutrition'));
      expect(sandbox.schema, contains('kilocalories'));
    },
  );

  test(
    'rejects writes, multiple statements, and tables outside the snapshot',
    () async {
      for (final sql in [
        'DELETE FROM data_workouts',
        'SELECT * FROM data_workouts; DELETE FROM data_workouts',
        'SELECT * FROM sqlite_master',
        'SELECT * FROM private_records',
        'SELECT * FROM pragma_table_info("data_workouts")',
        'SELECT 1',
        'WITH RECURSIVE n(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM n) SELECT * FROM n',
        'SELECT load_extension("anything")',
        'SELECT * FROM data_workouts CROSS JOIN data_nutrition',
      ]) {
        await expectLater(
          sandbox.query(sql),
          throwsA(isA<AssistantSqlQueryException>()),
          reason: sql,
        );
      }
    },
  );

  test(
    'limits result size and rejects queries after the snapshot closes',
    () async {
      await sandbox.close();
      await expectLater(
        sandbox.query('SELECT * FROM data_workouts'),
        throwsA(isA<AssistantSqlQueryException>()),
      );
    },
  );

  test('caps query results at 200 rows and marks them truncated', () async {
    final largeSandbox = await AssistantSqlSandbox.create([
      AssistantActionResult(
        category: AssistantDataCategory.steps,
        status: AssistantActionStatus.success,
        records: [
          for (var i = 0; i < 205; i++) {'ref': 'steps:$i', 'steps': i},
        ],
      ),
    ]);
    addTearDown(largeSandbox.close);

    final result = await largeSandbox.query('SELECT * FROM data_steps');

    expect(result.rows, hasLength(200));
    expect(result.truncated, isTrue);
  });
}
