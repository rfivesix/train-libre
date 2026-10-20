import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'assistant_data_request.dart';

enum AssistantActionStatus { success, denied, error }

class AssistantActionResult {
  const AssistantActionResult({
    required this.category,
    required this.status,
    this.records = const [],
    this.error,
  });
  final AssistantDataCategory category;
  final AssistantActionStatus status;
  final List<Map<String, dynamic>> records;
  final String? error;

  Map<String, dynamic> get manifest => {
        'count': records.length,
        'payloadSha256':
            sha256.convert(utf8.encode(jsonEncode(records))).toString(),
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
      };
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
