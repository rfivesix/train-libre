import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/infrastructure/icloud_sync_service.dart';
import 'package:train_libre/data/drift_database.dart';

/// The iCloud restore copies the backup into the database the app already has
/// open, table by table. It deletes every one of them on the way, so what it
/// does with a snapshot that does not match the current schema is not a detail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workDir;
  late AppDatabase live;

  setUp(() async {
    workDir = await Directory.systemTemp.createTemp('icloud_copy_test');
    live =
        AppDatabase(NativeDatabase(File(p.join(workDir.path, 'live.sqlite'))));
  });

  tearDown(() async {
    await live.close();
    if (await workDir.exists()) await workDir.delete(recursive: true);
  });

  /// Builds a snapshot database on disk and returns its path.
  Future<String> buildSnapshot(
    Future<void> Function(AppDatabase snapshot) fill,
  ) async {
    final path = p.join(workDir.path, 'snapshot.sqlite');
    final snapshot = AppDatabase(NativeDatabase(File(path)));
    await fill(snapshot);
    await snapshot.close();
    return path;
  }

  Future<void> insertProfile(AppDatabase db, String id, String username) {
    return db.customStatement(
      'INSERT INTO profiles (id, username) VALUES (?, ?)',
      [id, username],
    );
  }

  Future<List<String>> usernames(AppDatabase db) async {
    final rows = await db.customSelect('SELECT username FROM profiles').get();
    return [for (final row in rows) row.read<String>('username')];
  }

  test('replaces what the live database holds with the backup', () async {
    await insertProfile(live, 'local', 'On this device');
    final snapshotPath = await buildSnapshot(
      (snapshot) => insertProfile(snapshot, 'backed-up', 'From the backup'),
    );

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    // Not merged: a restore means the backup's state, not both states.
    expect(await usernames(live), ['From the backup']);
  });

  test('leaves the live database usable afterwards', () async {
    // The whole point of copying instead of swapping the file: the connection
    // every provider holds must survive the restore.
    final snapshotPath = await buildSnapshot(
      (snapshot) => insertProfile(snapshot, 'backed-up', 'From the backup'),
    );

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    await insertProfile(live, 'after', 'Written after the restore');
    expect(await usernames(live), hasLength(2));

    final foreignKeys =
        await live.customSelect('PRAGMA foreign_keys').getSingle();
    expect(foreignKeys.read<int>('foreign_keys'), 1,
        reason: 'foreign keys must be back on once the copy is done');
  });

  test('carries the preferences table the restore reads afterwards', () async {
    final snapshotPath = await buildSnapshot((snapshot) async {
      await snapshot.customStatement(
        'CREATE TABLE IF NOT EXISTS system_preferences '
        '(key TEXT PRIMARY KEY, value TEXT)',
      );
      await snapshot.customStatement(
        "INSERT INTO system_preferences (key, value) "
        "VALUES ('hasSeenOnboarding', 'b:true')",
      );
    });

    // The live database has no such table yet — it is created by the backup
    // run, not by the schema, so the copy has to bring it into existence.
    await live.customStatement(
      'CREATE TABLE IF NOT EXISTS system_preferences '
      '(key TEXT PRIMARY KEY, value TEXT)',
    );

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    final rows =
        await live.customSelect('SELECT value FROM system_preferences').get();
    expect(rows.single.read<String>('value'), 'b:true');
  });

  test('a table the backup does not carry is left alone', () async {
    // It belongs to a feature added after the backup was written. Wiping it
    // would lose data the backup never claimed to replace.
    final snapshotPath = await buildSnapshot((snapshot) async {
      await snapshot.customStatement('DROP TABLE profiles');
    });

    await insertProfile(live, 'local', 'Newer feature row');

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    expect(await usernames(live), ['Newer feature row']);
  });

  test('ignores a table whose name is not a plain identifier', () async {
    // The snapshot comes out of the iCloud container, so its sqlite_master is
    // external input, and SQLite cannot parameterise an identifier. A crafted
    // name must not reach the raw DELETE the copy runs per table.
    final snapshotPath = await buildSnapshot((snapshot) async {
      await snapshot.customStatement(
        'CREATE TABLE "evil""; DROP TABLE profiles; --" (id TEXT)',
      );
      await insertProfile(snapshot, 'backed-up', 'From the backup');
    });

    await insertProfile(live, 'local', 'On this device');
    await live.customStatement(
      'CREATE TABLE "evil""; DROP TABLE profiles; --" (id TEXT)',
    );

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    // The well-named table still restored, and the live schema is intact.
    expect(await usernames(live), ['From the backup']);
    final tables = await live
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(
      [for (final row in tables) row.read<String>('name')],
      contains('profiles'),
    );
  });

  test('restores the columns both sides share when they differ', () async {
    // A backup from an older build has fewer columns. It must restore what it
    // has rather than failing the whole thing.
    final snapshotPath = await buildSnapshot((snapshot) async {
      await snapshot.customStatement('DROP TABLE profiles');
      await snapshot.customStatement(
        'CREATE TABLE profiles (local_id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'id TEXT NOT NULL UNIQUE, username TEXT NULL)',
      );
      await insertProfile(snapshot, 'old-build', 'From an older build');
    });

    await ICloudSyncService.instance
        .copySnapshotIntoLiveDatabaseForTesting(live, snapshotPath);

    expect(await usernames(live), ['From an older build']);
  });
}
