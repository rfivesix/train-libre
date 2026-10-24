import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'assistant_data_request.dart';

enum AssistantActionStatus { success, denied, error }

class AssistantActionResult {
  const AssistantActionResult({
    required this.category,
    required this.status,
    this.records = const [],
    this.tables = const {},
    this.tableColumns = const {},
    this.error,
  });
  final AssistantDataCategory category;
  final AssistantActionStatus status;
  final List<Map<String, dynamic>> records;

  /// Optional physical-table snapshots. These are the full approved database
  /// rows; [records] remains the compact, user-facing interpretation.
  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, Map<String, String>> tableColumns;
  final String? error;

  Map<String, dynamic> get manifest => {
        'count': records.length,
        'payloadSha256': sha256
            .convert(utf8.encode(jsonEncode(records, toEncodable: _toEncodable)))
            .toString(),
        'references': [
          for (final record in records) ...[
            if (record['ref'] is String) record['ref'] as String,
            if (record['revisionRef'] is String)
              record['revisionRef'] as String,
            if (record['sourceRefs'] is List)
              ...(record['sourceRefs'] as List).whereType<String>(),
            if (record['sets'] is List)
              for (final set in record['sets'] as List)
                if (set is Map && set['ref'] is String) set['ref'] as String,
            if (record['templateDays'] is List)
              for (final day in record['templateDays'] as List)
                if (day is Map && day['routineRef'] is String)
                  day['routineRef'] as String,
          ],
        ],
        'fields': records.expand((record) => record.keys).toSet().toList()
          ..sort(),
        'tables': {
          for (final entry in tables.entries)
            entry.key: {
              'count': entry.value.length,
              'fields': {
                ...?tableColumns[entry.key],
                for (final field in entry.value.expand((row) => row.keys))
                  field: tableColumns[entry.key]?[field] ?? 'unknown',
              }.keys.toList()
                ..sort(),
              'payloadSha256': sha256
                  .convert(utf8
                      .encode(jsonEncode(entry.value, toEncodable: _toEncodable)))
                  .toString(),
            },
        },
      };

  static Object? _toEncodable(Object? object) {
    if (object is DateTime) return object.toIso8601String();
    return object?.toString();
  }
}

abstract class AssistantDataAction {
  Set<AssistantDataCategory> get categories;
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope);
}

class AssistantDataGateway {
  const AssistantDataGateway(this.actions);
  final List<AssistantDataAction> actions;

  bool supports(AssistantDataRequest request) =>
      request.categories.every((category) =>
          actions
              .where((action) => action.categories.contains(category))
              .length ==
          1);

  Future<List<AssistantActionResult>> readApproved(
    AssistantDataRequest request, {
    required bool approved,
  }) async {
    request.validate();
    if (!approved) {
      return [
        for (final category in request.categories)
          AssistantActionResult(
              category: category, status: AssistantActionStatus.denied),
      ];
    }
    final results = <AssistantActionResult>[];
    for (final category in request.categories) {
      final matching =
          actions.where((action) => action.categories.contains(category));
      if (matching.length != 1) {
        results.add(AssistantActionResult(
            category: category,
            status: AssistantActionStatus.error,
            error: 'No unique read action'));
        continue;
      }
      try {
        results.add(await matching.single.read(category, request.scope));
      } catch (error) {
        results.add(AssistantActionResult(
            category: category,
            status: AssistantActionStatus.error,
            error: error.toString()));
      }
    }
    return results;
  }
}
