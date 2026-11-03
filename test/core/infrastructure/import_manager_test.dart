import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_libre/core/infrastructure/import_manager.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('de_DE', null);
  });

  group('ImportManager decodeAndGroupWorkouts tests', () {
    test('CSV parsing with standard English headers and metrics', () async {
      final csvString =
          'title,start_time,end_time,exercise,set_type,weight,reps,distance,duration,rpe,set_notes\n'
          'Upper Body Workout,2026-05-20 10:00:00,2026-05-20 11:30:00,Bench Press,normal,100,5,,,9,Felt strong\n'
          'Upper Body Workout,2026-05-20 10:00:00,2026-05-20 11:30:00,Bench Press,warmup,60,10,,,6,\n'
          'Cardio Session,2026-05-21 08:00:00,,Running,normal,,1,5.2,1800,8,\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = await ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 2);

      // Verify first workout (Upper Body Workout)
      final workout1 = result.firstWhere(
        (w) => w.title == 'Upper Body Workout',
      );
      expect(workout1.notes, isNull);
      expect(workout1.startTime, DateTime(2026, 5, 20, 10, 0, 0));
      expect(workout1.endTime, DateTime(2026, 5, 20, 11, 30, 0));
      expect(workout1.sets.length, 2);

      final set1 = workout1.sets[0];
      expect(set1.exerciseName, 'Bench Press');
      expect(set1.setType, 'normal');
      expect(set1.weightKg, 100.0);
      expect(set1.reps, 5);
      expect(set1.rpe, 9);
      expect(set1.notes, 'Felt strong');

      final set2 = workout1.sets[1];
      expect(set2.exerciseName, 'Bench Press');
      expect(set2.setType, 'warmup');
      expect(set2.weightKg, 60.0);
      expect(set2.reps, 10);
      expect(set2.rpe, 6);

      // Verify second workout (Cardio Session)
      final workout2 = result.firstWhere((w) => w.title == 'Cardio Session');
      expect(workout2.startTime, DateTime(2026, 5, 21, 8, 0, 0));
      expect(workout2.endTime, isNull);
      expect(workout2.sets.length, 1);

      final cardioSet = workout2.sets[0];
      expect(cardioSet.exerciseName, 'Running');
      expect(cardioSet.setType, 'normal');
      expect(cardioSet.reps, 1);
      expect(cardioSet.distanceKm, 5.2);
      expect(cardioSet.durationSeconds, 1800);
      expect(cardioSet.rpe, 8);
    });

    test(
      'CSV parsing with German headers and set-type abbreviations',
      () async {
        final csvString =
            'übung,typ,gewicht,wiederholungen,notiz,datum,name\n'
            'Kniebeugen,w,120,5,Erster Satz,23.05.2026 15:30,Leg Day\n'
            'Kniebeugen,f,150,3,Failure set,23.05.2026 15:30,Leg Day\n'
            'Kreuzheben,d,100,8,Drop set,23.05.2026 15:30,Leg Day\n';

        final params = ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode(csvString)),
          extension: 'csv',
          isImperial: false,
        );

        final result = await ImportManager.decodeAndGroupWorkouts(params);

        expect(result.length, 1);
        final workout = result.first;
        expect(workout.title, 'Leg Day');
        expect(workout.startTime, DateTime(2026, 5, 23, 15, 30, 0));
        expect(workout.sets.length, 3);

        expect(workout.notes, 'Erster Satz');
        expect(workout.sets[0].exerciseName, 'Kniebeugen');
        expect(workout.sets[0].setType, 'warmup');
        expect(workout.sets[0].weightKg, 120.0);
        expect(workout.sets[0].reps, 5);
        expect(workout.sets[0].notes, isNull);

        expect(workout.sets[1].exerciseName, 'Kniebeugen');
        expect(workout.sets[1].setType, 'failure');
        expect(workout.sets[1].weightKg, 150.0);
        expect(workout.sets[1].reps, 3);

        expect(workout.sets[2].exerciseName, 'Kreuzheben');
        expect(workout.sets[2].setType, 'dropset');
        expect(workout.sets[2].weightKg, 100.0);
        expect(workout.sets[2].reps, 8);
      },
    );

    test(
      'semicolon CSV with decimal commas is parsed as a German export',
      () async {
        final csvString =
            'Workout;Date;Exercise Name;Weight;Weight Unit;Reps\n'
            'Beine;23.05.2026 15:30;Kniebeuge;100,5;kg;6\n';
        final result = await ImportManager.decodeAndGroupWorkouts(
          ImportBackgroundTaskParams(
            fileBytes: Uint8List.fromList(utf8.encode(csvString)),
            extension: 'csv',
            isImperial: false,
          ),
        );

        expect(result, hasLength(1));
        expect(result.single.title, 'Beine');
        expect(result.single.sets.single.weightKg, 100.5);
        expect(result.single.sets.single.reps, 6);
      },
    );

    test('CSV parsing with imperial flag converts lbs to kg', () async {
      final csvString =
          'workout,start,exercise,mass,reps\n'
          'Chest Day,2026-05-22 18:00,Incline Press,220.46,8\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: true, // triggers conversion
      );

      final result = await ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 1);
      final set = result.first.sets.first;
      expect(set.exerciseName, 'Incline Press');
      // 220.46 lbs should convert to approximately 100 kg
      expect(set.weightKg, closeTo(100.0, 0.1));
    });

    test('Date parsing handles various formats cleanly', () async {
      final formats = [
        '20 May 2026, 14:35',
        '25 Juli 2026, 14:21',
        '25 July 2026, 14:21',
        '25. Juli 2026, 14:21',
        '2026-05-20 14:35:10',
        '2026-05-20 14:35',
        '20.05.2026, 14:35',
        '20.05.2026 14:35',
        '05/20/2026 14:35',
        '2026-05-20T14:35:00Z',
      ];

      for (final rawDate in formats) {
        final csvString =
            'title,start_time,exercise,weight,reps\n'
            'Test Date,"$rawDate",Curls,20,10\n';

        final params = ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode(csvString)),
          extension: 'csv',
          isImperial: false,
        );

        final result = await ImportManager.decodeAndGroupWorkouts(params);
        expect(
          result.length,
          1,
          reason: 'Failed parsing date string: $rawDate',
        );
        expect(result.first.startTime.year, 2026);
        expect(
          result.first.startTime.hour,
          rawDate.contains('14:21') ? 14 : 14,
        );
        expect(
          result.first.startTime.minute,
          rawDate.contains('14:21') ? 21 : 35,
        );
      }
    });

    test('CSV parsing with Hevy German format ("25 Juli 2026, 14:21")', () async {
      final csvString =
          '"title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe"\n'
          '"Beine","25 Juli 2026, 14:21","25 Juli 2026, 16:27","","Hackenschmidt Squat (Maschine)",,"Die schwere Variante",0,"warmup",20,10,,,\n'
          '"Beine","25 Juli 2026, 14:21","25 Juli 2026, 16:27","","Hackenschmidt Squat (Maschine)",,"Die schwere Variante",1,"normal",80,6,,,\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = await ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 1);
      final workout = result.first;
      expect(workout.title, 'Beine');
      expect(workout.startTime, DateTime(2026, 7, 25, 14, 21));
      expect(workout.endTime, DateTime(2026, 7, 25, 16, 27));
      expect(workout.sets.length, 2);
      expect(workout.sets[0].exerciseName, 'Hackenschmidt Squat (Maschine)');
      expect(workout.sets[0].setType, 'warmup');
      expect(workout.sets[0].weightKg, 20.0);
      expect(workout.sets[0].reps, 10);
      expect(workout.sets[0].notes, isNull);
      expect(workout.exerciseNotesByBlock[0], 'Die schwere Variante');
    });

    test(
      'Hevy profile converts explicit pounds and miles automatically',
      () async {
        final csvString =
            '\uFEFFtitle,start_time,exercise_title,set_type,weight_lbs,reps,distance_miles,duration_seconds\n'
            'Run and lift,2026-07-25 14:21,Run,normal,220.46,5,3.1,3600\n';
        final result = await ImportManager.decodeAndGroupWorkouts(
          ImportBackgroundTaskParams(
            fileBytes: Uint8List.fromList(utf8.encode(csvString)),
            extension: 'csv',
            isImperial: false,
          ),
        );

        expect(result, hasLength(1));
        expect(result.single.sourceProfile, WorkoutImportProfile.hevy);
        expect(result.single.sets.single.weightKg, closeTo(100, 0.1));
        expect(result.single.sets.single.distanceKm, closeTo(4.989, 0.001));
        expect(result.single.sets.single.durationSeconds, 3600);
      },
    );

    test(
      'Hevy kilogram columns are not converted by a global imperial choice',
      () async {
        final csvString =
            'title,start_time,exercise_title,weight_kg,reps\n'
            'Chest,2026-07-25 14:21,Bench Press,140,5\n';
        final result = await ImportManager.decodeAndGroupWorkouts(
          ImportBackgroundTaskParams(
            fileBytes: Uint8List.fromList(utf8.encode(csvString)),
            extension: 'csv',
            isImperial: true,
          ),
        );

        expect(result.single.sets.single.weightKg, 140);
      },
    );

    test('Strong profile maps common export headers and set fields', () async {
      final csvString =
          'Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Weight Unit,Reps,Distance,Distance Unit,Seconds,Notes,Workout Notes,RPE\n'
          '2026-05-20 10:00:00,Leg Day,01:15:00,Barbell Squat,1,140,kg,5,,,45,Top set,Heavy day,8\n'
          'bad date,Leg Day,01:15:00,Barbell Squat,2,140,kg,5,,,45,,Heavy day,8\n';
      final result = await ImportManager.decodeAndGroupWorkouts(
        ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode(csvString)),
          extension: 'csv',
          isImperial: true,
        ),
      );

      expect(result, hasLength(1));
      final workout = result.single;
      expect(workout.sourceProfile, WorkoutImportProfile.strong);
      expect(workout.title, 'Leg Day');
      expect(workout.endTime, DateTime(2026, 5, 20, 11, 15));
      expect(workout.skippedInvalidRows, 1);
      expect(workout.notes, 'Heavy day');
      expect(workout.sets.single.exerciseName, 'Barbell Squat');
      expect(workout.sets.single.weightKg, 140);
      expect(workout.sets.single.reps, 5);
      expect(workout.sets.single.durationSeconds, 45);
      expect(workout.sets.single.notes, 'Top set');
      expect(workout.sets.single.rpe, 8);
    });

    test('redacted Hevy export imports German month abbreviations', () async {
      final bytes = await File('test/fixtures/workout_import/hevy_redacted.csv')
          .readAsBytes();
      final result = await ImportManager.decodeAndGroupWorkouts(
        ImportBackgroundTaskParams(
          fileBytes: bytes,
          extension: 'csv',
          isImperial: false,
        ),
      );

      expect(result, hasLength(8));
      expect(
        result.every(
          (workout) => workout.sourceProfile == WorkoutImportProfile.hevy,
        ),
        isTrue,
      );
      expect(result.first.startTime, DateTime(2000, 10, 1, 7, 25));
      expect(result.first.endTime, DateTime(2000, 10, 1, 8, 25));
      final sets = result.expand((workout) => workout.sets);
      expect(sets.any((set) => set.setType == 'dropset'), isTrue);
      expect(sets.any((set) => set.setType == 'failure'), isTrue);
      expect(sets.any((set) => set.setType == 'warmup'), isTrue);
    });

    test(
      'redacted German Strong export skips rest rows and attaches pauses',
      () async {
        final bytes = await File(
          'test/fixtures/workout_import/strong_redacted.csv',
        ).readAsBytes();
        final result = await ImportManager.decodeAndGroupWorkouts(
          ImportBackgroundTaskParams(
            fileBytes: bytes,
            extension: 'csv',
            isImperial: false,
          ),
        );

        expect(result, hasLength(1));
        final workout = result.single;
        expect(workout.sourceProfile, WorkoutImportProfile.strong);
        expect(workout.title, 'Redacted Strong Test');
        expect(workout.startTime, DateTime(2026, 1, 15, 12));
        expect(workout.endTime, DateTime(2026, 1, 15, 12, 2));
        expect(workout.sets, hasLength(11));
        expect(workout.sets.any((set) => set.setType == 'warmup'), isTrue);
        expect(workout.sets.any((set) => set.setType == 'dropset'), isTrue);
        expect(workout.sets.any((set) => set.setType == 'failure'), isTrue);
        expect(workout.sets.any((set) => set.restTimeSeconds == 120), isTrue);
        expect(workout.sets.any((set) => set.durationSeconds == 1), isTrue);
      },
    );

    test('generic imports preserve reps in reserve', () async {
      const csvString =
          'title,start_time,exercise,weight_kg,reps,rir\n'
          'Upper,2026-05-20 10:00:00,Bench Press,100,6,2\n';
      final result = await ImportManager.decodeAndGroupWorkouts(
        ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode(csvString)),
          extension: 'csv',
          isImperial: false,
        ),
      );

      expect(result.single.sets.single.rir, 2);
    });

    test('Missing date fallback returns current date', () async {
      final csvString =
          'title,start_time,exercise,weight,reps\n'
          'Test Date,,Curls,20,10\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = await ImportManager.decodeAndGroupWorkouts(params);
      expect(result.length, 0); // start_time is required in CSV row grouping!
    });

    test(
      'Handles malformed file extensions or data errors gracefully',
      () async {
        final params = ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode('random,garbage,data')),
          extension: 'unsupported',
          isImperial: false,
        );

        final result = await ImportManager.decodeAndGroupWorkouts(params);
        expect(result, isEmpty);
      },
    );

    test('Handles empty and minimal CSV inputs without crashing', () async {
      final paramsEmpty = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList([]),
        extension: 'csv',
        isImperial: false,
      );

      final result1 = await ImportManager.decodeAndGroupWorkouts(paramsEmpty);
      expect(result1, isEmpty);

      final paramsHeaderOnly = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(
          utf8.encode('title,start_time,exercise\n'),
        ),
        extension: 'csv',
        isImperial: false,
      );

      final result2 = await ImportManager.decodeAndGroupWorkouts(
        paramsHeaderOnly,
      );
      expect(result2, isEmpty);
    });
  });
}
