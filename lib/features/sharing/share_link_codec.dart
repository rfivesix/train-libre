import 'dart:convert';
import 'dart:io';

import '../workout/domain/models/manual_training_plan.dart';
import '../workout/domain/models/routine.dart';
import '../workout/domain/models/workout_log.dart';

/// Versioned, self-contained payload shared in a URL fragment. Fragments are
/// kept off HTTP requests, including requests to the static preview page.
class ShareLinkPayload {
  const ShareLinkPayload(this.type, this.name, this.data);

  final String type;
  final String name;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {'v': 1, 't': type, 'n': name, 'd': data};

  static ShareLinkPayload fromJson(Map<String, dynamic> json) {
    if (json['v'] != 1 ||
        !const {'routine', 'plan', 'recipe', 'workout'}.contains(json['t']) ||
        json['n'] is! String ||
        (json['n'] as String).trim().isEmpty ||
        (json['n'] as String).length > 200 ||
        json['d'] is! Map) {
      throw const FormatException('Unsupported share link');
    }
    final data = Map<String, dynamic>.from(json['d'] as Map);
    final rows = switch (json['t']) {
      'routine' => data['exercises'],
      'plan' => data['days'],
      'workout' => data['sets'],
      _ => data['items'],
    };
    if (rows is! List || rows.length > (json['t'] == 'workout' ? 2000 : 100)) {
      throw const FormatException('Invalid shared content');
    }
    switch (json['t']) {
      case 'routine':
        for (final raw in rows) {
          if (raw is! Map ||
              raw['name'] is! String ||
              (raw['name'] as String).trim().isEmpty ||
              (raw['uuid'] != null && raw['uuid'] is! String) ||
              (raw['category'] != null && raw['category'] is! String) ||
              (raw['muscles'] != null &&
                  (raw['muscles'] is! List ||
                      !(raw['muscles'] as List)
                          .every((value) => value is String))) ||
              (raw['secondaryMuscles'] != null &&
                  (raw['secondaryMuscles'] is! List ||
                      !(raw['secondaryMuscles'] as List)
                          .every((value) => value is String))) ||
              (raw['tracking'] != null && raw['tracking'] is! String) ||
              (raw['loadMode'] != null && raw['loadMode'] is! String) ||
              (raw['equipment'] != null && raw['equipment'] is! String) ||
              (raw['pause'] != null && raw['pause'] is! num) ||
              (raw['superset'] != null && raw['superset'] is! num) ||
              (raw['notes'] != null &&
                  (raw['notes'] is! String ||
                      (raw['notes'] as String).length > 10000)) ||
              (raw['progression'] != null && raw['progression'] is! String) ||
              raw['sets'] is! List ||
              (raw['sets'] as List).length > 100) {
            throw const FormatException('Invalid routine exercise');
          }
          for (final set in raw['sets'] as List) {
            if (set is! Map ||
                set['type'] is! String ||
                (set['reps'] != null && set['reps'] is! String) ||
                (set['weight'] != null && set['weight'] is! num) ||
                (set['rir'] != null && set['rir'] is! num) ||
                (set['repMin'] != null && set['repMin'] is! int) ||
                (set['repMax'] != null && set['repMax'] is! int)) {
              throw const FormatException('Invalid routine set');
            }
          }
        }
      case 'plan':
        if (!const {'week', 'sequence'}.contains(data['kind']) ||
            rows.isEmpty ||
            rows.length > 14 ||
            !rows.any((day) => day != null) ||
            (data['lengthDays'] != null && data['lengthDays'] != rows.length) ||
            (data['revisionNumber'] != null &&
                (data['revisionNumber'] is! int ||
                    data['revisionNumber'] <= 0)) ||
            (data['activeAtExport'] != null &&
                data['activeAtExport'] is! bool) ||
            (data['startedOn'] != null &&
                (data['startedOn'] is! String ||
                    DateTime.tryParse(data['startedOn'] as String) == null)) ||
            (data['kind'] == 'week' && rows.length != 7)) {
          throw const FormatException('Invalid plan');
        }
        for (final day in rows) {
          if (day == null) continue;
          if (day is! Map) {
            throw const FormatException('Invalid plan day');
          }
          final routine =
              ShareLinkPayload.fromJson(Map<String, dynamic>.from(day));
          if (routine.type != 'routine' ||
              !(routine.data['exercises'] as List)
                  .any((exercise) => (exercise['sets'] as List).isNotEmpty)) {
            throw const FormatException('Invalid plan day');
          }
        }
      case 'recipe':
        if (rows.isEmpty ||
            (data['notes'] != null &&
                (data['notes'] is! String ||
                    (data['notes'] as String).length > 10000)) ||
            (data['portions'] != null &&
                (data['portions'] is! int || data['portions'] <= 0)) ||
            (data['cookedWeightInGrams'] != null &&
                (data['cookedWeightInGrams'] is! int ||
                    data['cookedWeightInGrams'] <= 0))) {
          throw const FormatException('Invalid recipe');
        }
        for (final item in rows) {
          if (item is! Map ||
              item['barcode'] is! String ||
              (item['barcode'] as String).isEmpty ||
              item['name'] is! String ||
              (item['name'] as String).isEmpty ||
              item['grams'] is! num ||
              (item['grams'] as num) <= 0 ||
              (item['unit'] != null &&
                  !const {'g', 'ml'}.contains(item['unit'])) ||
              (item['kcal'] != null && item['kcal'] is! num) ||
              (item['protein'] != null && item['protein'] is! num) ||
              (item['carbs'] != null && item['carbs'] is! num) ||
              (item['fat'] != null && item['fat'] is! num)) {
            throw const FormatException('Invalid ingredient');
          }
        }
      case 'workout':
        final start = data['start'];
        final end = data['end'];
        if (start is! String ||
            DateTime.tryParse(start) == null ||
            (end != null &&
                (end is! String || DateTime.tryParse(end) == null)) ||
            (end is String &&
                DateTime.tryParse(end) != null &&
                DateTime.parse(end).isBefore(DateTime.parse(start))) ||
            (data['notes'] != null && data['notes'] is! String) ||
            (data['startZoneOffsetMinutes'] != null &&
                data['startZoneOffsetMinutes'] is! int) ||
            (data['endZoneOffsetMinutes'] != null &&
                data['endZoneOffsetMinutes'] is! int)) {
          throw const FormatException('Invalid workout');
        }
        for (final raw in rows) {
          if (raw is! Map ||
              raw['exercise_name'] is! String ||
              (raw['exercise_name'] as String).trim().isEmpty ||
              raw['set_type'] is! String ||
              (raw['exercise_id'] != null && raw['exercise_id'] is! String) ||
              (raw['notes'] != null &&
                  (raw['notes'] is! String ||
                      (raw['notes'] as String).length > 10000)) ||
              (raw['workout_exercise_note'] != null &&
                  (raw['workout_exercise_note'] is! String ||
                      (raw['workout_exercise_note'] as String).length >
                          10000)) ||
              (raw['exercise_block'] != null &&
                  raw['exercise_block'] is! int) ||
              (raw['progression_data'] != null &&
                  raw['progression_data'] is! String) ||
              (raw['is_completed'] != null &&
                  raw['is_completed'] != 0 &&
                  raw['is_completed'] != 1) ||
              !const ['weight_kg', 'distance_km', 'prescribed_weight']
                  .every((key) => raw[key] == null || raw[key] is num) ||
              !const [
                'reps',
                'rir',
                'rpe',
                'rest_time_seconds',
                'duration_seconds',
                'log_order',
                'exercise_block',
                'superset_group',
                'prescribed_rep_min',
                'prescribed_rep_max',
                'prescribed_rir',
              ].every((key) => raw[key] == null || raw[key] is int)) {
            throw const FormatException('Invalid workout set');
          }
        }
    }
    return ShareLinkPayload(json['t'] as String, json['n'] as String, data);
  }
}

class ShareLinkCodec {
  static const baseUrl = 'https://trainlibre.com/share/';
  static const maxLinkLength = 2000;
  static const maxEncodedLength = 16000;
  static const maxDecodedBytes = 128 * 1024;

  const ShareLinkCodec._();

  static String encode(ShareLinkPayload payload) {
    if (payload.type == 'workout') {
      throw const FormatException('Workouts require a JSON export');
    }
    final json = utf8.encode(jsonEncode(payload.toJson()));
    if (json.length > maxDecodedBytes) {
      throw const FormatException('Shared content is too large');
    }
    return base64UrlEncode(gzip.encode(json)).replaceAll('=', '');
  }

  static String link(ShareLinkPayload payload) =>
      '$baseUrl#data=${encode(payload)}';

  static ShareLinkPayload decode(String encoded) {
    if (encoded.isEmpty ||
        encoded.length > maxEncodedLength ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(encoded)) {
      throw const FormatException('Invalid share code');
    }
    final compressed = base64Url.decode(base64Url.normalize(encoded));
    // Reject oversized streams before allocating arbitrarily large objects.
    final sink = _LimitedByteSink(maxDecodedBytes);
    final decoder = gzip.decoder.startChunkedConversion(sink);
    decoder.add(compressed);
    decoder.close();
    final decoded = sink.bytes;
    final value = jsonDecode(utf8.decode(decoded));
    if (value is! Map) throw const FormatException('Invalid shared content');
    final payload = ShareLinkPayload.fromJson(Map<String, dynamic>.from(value));
    if (payload.type == 'workout') {
      throw const FormatException('Unsupported share link');
    }
    return payload;
  }

  static ShareLinkPayload? fromUri(Uri uri) {
    final isWeb = uri.scheme == 'https' &&
        uri.host == 'trainlibre.com' &&
        (uri.path == '/share' || uri.path == '/share/');
    final isApp = uri.scheme == 'trainlibre' && uri.host == 'share';
    final isRelative =
        uri.scheme.isEmpty && (uri.path == '/share' || uri.path == '/share/');
    if (!isWeb && !isApp && !isRelative) return null;
    final fragment = Uri.splitQueryString(uri.fragment);
    final code = fragment['data'];
    if (code == null) throw const FormatException('Missing share code');
    return decode(code);
  }

  static ShareLinkPayload forRoutine(Routine routine) => ShareLinkPayload(
        'routine',
        routine.name,
        {
          'exercises': routine.exercises
              .map((entry) => {
                    'uuid': entry.exercise.uuid,
                    'name': entry.exercise.canonicalName,
                    'category': entry.exercise.categoryName,
                    'muscles': entry.exercise.primaryMuscles,
                    'secondaryMuscles': entry.exercise.secondaryMuscles,
                    'tracking': entry.exercise.trackingType,
                    'loadMode': entry.exercise.loadMode,
                    'equipment': entry.exercise.primaryEquipment,
                    'pause': entry.pauseSeconds,
                    'superset': entry.supersetGroup,
                    'notes': entry.notes,
                    'progression': entry.progressionData,
                    'sets': entry.setTemplates
                        .map((set) => {
                              'type': set.setType,
                              'reps': set.targetReps,
                              'weight': set.targetWeight,
                              'rir': set.targetRir,
                              'repMin': set.targetRepMin,
                              'repMax': set.targetRepMax,
                            })
                        .toList(),
                  })
              .toList(),
        },
      );

  static ShareLinkPayload forPlan(ManualTrainingPlan plan) => ShareLinkPayload(
        'plan',
        plan.name,
        {
          'kind': plan.kind.name,
          'lengthDays': plan.days.length,
          'revisionNumber': plan.revisionNumber,
          'activeAtExport': plan.active,
          'startedOn': plan.startedOn?.toIso8601String(),
          'days': plan.days.map((day) {
            final routine = day.routine;
            return routine == null ? null : forRoutine(routine).toJson();
          }).toList(),
        },
      );

  static ShareLinkPayload forWorkout(WorkoutLog workout) => ShareLinkPayload(
        'workout',
        workout.routineName?.trim().isNotEmpty == true
            ? workout.routineName!.trim()
            : 'Workout',
        {
          'start': workout.startTime.toIso8601String(),
          'end': workout.endTime?.toIso8601String(),
          'notes': workout.notes,
          'startZoneOffsetMinutes': workout.startZoneOffsetMinutes,
          'endZoneOffsetMinutes': workout.endZoneOffsetMinutes,
          'sets': workout.sets.map((set) {
            final row = set.toMap();
            row.remove('id');
            row.remove('workout_log_id');
            row['workout_exercise_note'] =
                workout.exerciseNotesByBlock[set.exerciseBlock];
            return row;
          }).toList(),
        },
      );
}

/// Readable JSON files use the same validated data model as URL links.
class SharePortableCodec {
  const SharePortableCodec._();

  static const maxFileBytes = 5 * 1024 * 1024;

  static String encode(ShareLinkPayload payload) {
    ShareLinkPayload.fromJson(payload.toJson());
    final encoded = const JsonEncoder.withIndent('  ').convert({
      'format': 'train-libre-share',
      'version': 1,
      'type': payload.type,
      'name': payload.name,
      'data': payload.data,
    });
    if (utf8.encode(encoded).length > maxFileBytes) {
      throw const FormatException('Share file is too large');
    }
    return encoded;
  }

  static ShareLinkPayload decode(String content) {
    if (utf8.encode(content).length > maxFileBytes) {
      throw const FormatException('Share file is too large');
    }
    final value = jsonDecode(content);
    if (value is Map && value['v'] == 1) {
      return ShareLinkPayload.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is! Map ||
        value['format'] != 'train-libre-share' ||
        value['version'] != 1) {
      throw const FormatException('Unsupported share file');
    }
    return ShareLinkPayload.fromJson({
      'v': value['version'],
      't': value['type'],
      'n': value['name'],
      'd': value['data'],
    });
  }
}

class _LimitedByteSink implements ChunkedConversionSink<List<int>> {
  _LimitedByteSink(this.limit);

  final int limit;
  final List<int> bytes = [];

  @override
  void add(List<int> chunk) {
    if (bytes.length + chunk.length > limit) {
      throw const FormatException('Shared content is too large');
    }
    bytes.addAll(chunk);
  }

  @override
  void close() {}
}
