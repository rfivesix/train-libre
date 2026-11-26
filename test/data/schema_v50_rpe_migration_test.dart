import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates legacy effort without overwriting data and stores halves',
    () async {
      final directory = await Directory.systemTemp.createTemp('rpe_migration_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File(p.join(directory.path, 'db.sqlite'));
      var db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      // Match the old column affinity, then write representative v49 rows.
      await db.customStatement('ALTER TABLE set_logs DROP COLUMN rpe');
      await db.customStatement(
        'ALTER TABLE set_logs DROP COLUMN prescribed_rpe',
      );
      await db.customStatement(
        'ALTER TABLE routine_set_templates DROP COLUMN target_rpe',
      );
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement(
        "INSERT INTO routine_set_templates (id, routine_exercise_id, target_rir) VALUES ('t', 'legacy', 2)",
      );
      await db.customStatement('PRAGMA foreign_keys = ON');
      await db.customStatement('ALTER TABLE set_logs ADD COLUMN rpe INTEGER');
      await db.customStatement(
        "INSERT INTO workout_logs (id, start_time) VALUES ('w', 1)",
      );
      await db.customStatement(
        "INSERT INTO set_logs (id, workout_log_id, rir, rpe, prescribed_rir) VALUES ('a','w',2,NULL,3), ('b','w',1,7,NULL), ('c','w',NULL,NULL,NULL), ('d','w',12,NULL,NULL)",
      );
      await db.customStatement('PRAGMA user_version = 49');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final rows = await (db.select(
        db.setLogs,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(rows.map((r) => r.rpe).toList(), [8.0, 7.0, null, null]);
      expect(rows.map((r) => r.rir).toList(), [2, 1, null, 12]);
      expect(rows.first.prescribedRpe, 7.0);
      final template = await db.select(db.routineSetTemplates).getSingle();
      expect(template.targetRpe, 8.0);
      expect(template.targetRir, 2);
      await db.customStatement(
        "UPDATE routine_set_templates SET target_rpe = 8.5 WHERE id = 't'",
      );
      expect(
        (await db.select(db.routineSetTemplates).getSingle()).targetRpe,
        8.5,
      );
      await db.customStatement("UPDATE set_logs SET rpe = 8.5 WHERE id = 'a'");
      final half = await (db.select(
        db.setLogs,
      )..where((t) => t.id.equals('a'))).getSingle();
      expect(half.rpe, 8.5);
    },
  );
}
