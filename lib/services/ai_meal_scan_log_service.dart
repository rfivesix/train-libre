import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A bounded, device-local diagnostic history. All fields are allowlisted;
/// prompts, meal contents, photos, paths, API keys and error messages never
/// enter this store or its copyable export.
class AiMealScanLogService extends ChangeNotifier {
  AiMealScanLogService._();

  static final instance = AiMealScanLogService._();
  static const _storageKey = 'ai_meal_scan_diagnostics_v1';
  static const maxEntries = 20;

  final List<AiMealScanLog> _entries = [];
  Future<void> _queue = Future<void>.value();
  bool _loaded = false;

  List<AiMealScanLog> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    await _enqueue(() async {});
  }

  Future<void> start({
    required String id,
    required String provider,
    required String inputMode,
    required int photoCount,
    required DateTime startedAt,
  }) =>
      _enqueue(() async {
        _entries.insert(
          0,
          AiMealScanLog(
            id: id,
            startedAt: startedAt,
            provider: _allowedProvider(provider),
            inputMode: _allowedInputMode(inputMode),
            photoCount: photoCount.clamp(0, 10),
          ),
        );
        if (_entries.length > maxEntries) {
          _entries.removeRange(maxEntries, _entries.length);
        }
        notifyListeners();
        await _save();
      });

  Future<void> setProvider(String id, String provider) => _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log.provider = _allowedProvider(provider);
        notifyListeners();
        await _save();
      });

  Future<void> setModel(String id, String model) => _enqueue(() async {
        final log = _find(id);
        if (log == null ||
            log.provider == 'custom' ||
            log.provider == 'ollama') {
          return;
        }
        if (!RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(model)) {
          return;
        }
        log.model = model;
        notifyListeners();
        await _save();
      });

  Future<void> event(
    String id,
    AiMealScanLogStage stage, {
    required int elapsedMilliseconds,
    int? durationMilliseconds,
    AiMealScanLogResult? result,
    int? round,
    AiMealScanLogCandidate? candidate,
    int? validationScore,
    List<AiMealScanLogIssueCategory>? issueCategories,
    int? callIndex,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    bool? usageComplete,
  }) =>
      _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log.events.add(AiMealScanLogEvent(
          stage: stage,
          elapsedMilliseconds: elapsedMilliseconds.clamp(0, 3600000),
          durationMilliseconds: durationMilliseconds?.clamp(0, 3600000),
          result: result,
          round: round?.clamp(1, 4),
          candidate: candidate,
          validationScore: validationScore?.clamp(0, 100),
          issueCategories: issueCategories,
          callIndex: callIndex?.clamp(1, 20),
          inputTokens: inputTokens?.clamp(0, 10000000),
          outputTokens: outputTokens?.clamp(0, 10000000),
          totalTokens: totalTokens?.clamp(0, 10000000),
          usageComplete: usageComplete,
        ));
        notifyListeners();
        await _save();
      });

  Future<void> eventNow(String id, AiMealScanLogStage stage,
          {int? durationMilliseconds,
          AiMealScanLogResult? result,
          int? round}) =>
      _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log.events.add(AiMealScanLogEvent(
          stage: stage,
          elapsedMilliseconds: DateTime.now()
              .difference(log.startedAt)
              .inMilliseconds
              .clamp(0, 3600000),
          durationMilliseconds: durationMilliseconds?.clamp(0, 3600000),
          result: result,
          round: round?.clamp(1, 20),
        ));
        notifyListeners();
        await _save();
      });

  Future<void> finish(
    String id, {
    required AiMealScanLogResult result,
    required int durationMilliseconds,
    int? selectedValidationRounds,
    int? totalValidationRuns,
    int? repairRounds,
    bool? primaryFirstPassAccepted,
    bool? hedgeStarted,
  }) =>
      _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log
          ..result = result
          ..durationMilliseconds = durationMilliseconds.clamp(0, 3600000)
          ..selectedValidationRounds = selectedValidationRounds?.clamp(0, 4)
          ..totalValidationRuns = totalValidationRuns?.clamp(0, 8)
          ..repairRounds = repairRounds?.clamp(0, 3)
          ..primaryFirstPassAccepted = primaryFirstPassAccepted
          ..hedgeStarted = hedgeStarted;
        notifyListeners();
        await _save();
      });

  Future<void> usage(
    String id, {
    required int calls,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
    required bool complete,
  }) =>
      _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log
          ..providerCalls = calls.clamp(0, 20)
          ..inputTokens = inputTokens.clamp(0, 10000000)
          ..outputTokens = outputTokens.clamp(0, 10000000)
          ..totalTokens = totalTokens.clamp(0, 10000000)
          ..usageComplete = complete;
        notifyListeners();
        await _save();
      });

  Future<void> review(
    String id, {
    required AiMealScanLogResult result,
    required int correctionRounds,
  }) =>
      _enqueue(() async {
        final log = _find(id);
        if (log == null) return;
        log
          ..reviewResult = result
          ..correctionRounds = correctionRounds.clamp(0, 20);
        notifyListeners();
        await _save();
      });

  Future<void> clear() => _enqueue(() async {
        _entries.clear();
        notifyListeners();
        await _save();
      });

  String export(AiMealScanLog log) {
    final lines = <String>[
      'AI meal scan ${log.id}',
      'Started: ${log.startedAt.toIso8601String()}',
      'Provider: ${log.provider}; model: ${log.model ?? 'unknown'}; input: ${log.inputMode}; photos: ${log.photoCount}',
      'Scan: ${log.result.name}; duration: ${_seconds(log.durationMilliseconds)} s',
      'First pass: ${log.primaryFirstPassAccepted?.toString() ?? 'unknown'}; '
          'selected validations: ${log.selectedValidationRounds ?? 'unknown'}; '
          'all validations: ${log.totalValidationRuns ?? 'unknown'}; '
          'repairs: ${log.repairRounds ?? 'unknown'}; hedge: ${log.hedgeStarted ?? 'unknown'}',
      'Provider calls: ${log.providerCalls ?? 'unknown'}; '
          'tokens: ${log.usageComplete == true ? '${log.inputTokens} in / ${log.outputTokens} out / ${log.totalTokens} total' : 'unknown'}',
      'Review: ${log.reviewResult?.name ?? 'open'}; AI corrections: ${log.correctionRounds ?? 0}',
      'Timeline:',
      for (final event in log.events)
        '  +${_seconds(event.elapsedMilliseconds)} s  ${event.stage.name}'
            '${event.round == null ? '' : ' #${event.round}'}'
            '${event.durationMilliseconds == null ? '' : ' (${_seconds(event.durationMilliseconds)} s)'}'
            '${event.result == null ? '' : ' ${event.result!.name}'}'
            '${event.candidate == null ? '' : ' candidate=${event.candidate!.name}'}'
            '${event.validationScore == null ? '' : ' score=${event.validationScore}'}'
            '${event.issueCategories.isEmpty ? '' : ' issues=${event.issueCategories.map((e) => e.name).join(',')}'}'
            '${event.callIndex == null ? '' : ' call=${event.callIndex}'}'
            '${event.usageComplete == null ? '' : ' tokens=${event.usageComplete == true ? '${event.inputTokens}/${event.outputTokens}/${event.totalTokens}' : 'unknown'}'}',
    ];
    return lines.join('\n');
  }

  String exportAll() => _entries.map(export).join('\n\n');

  static String _seconds(int? milliseconds) => milliseconds == null
      ? 'unknown'
      : (milliseconds / 1000).toStringAsFixed(2);

  AiMealScanLog? _find(String id) {
    for (final log in _entries) {
      if (log.id == id) return log;
    }
    return null;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (!_loaded) {
        _loaded = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          final saved = prefs.getString(_storageKey);
          if (saved != null) {
            final values = jsonDecode(saved);
            if (values is List) {
              _entries.addAll(values.whereType<Map>().take(maxEntries).map(
                    (value) => AiMealScanLog.fromJson(
                        Map<String, dynamic>.from(value)),
                  ));
            }
          }
        } catch (_) {
          _entries.clear();
        }
        notifyListeners();
      }
      await action();
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _storageKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Diagnostics must never prevent a meal scan.
    }
  }

  static String _allowedProvider(String value) => const {
        'openai',
        'gemini',
        'anthropic',
        'mistral',
        'xai',
        'ollama',
        'custom',
        'appleFoundation',
      }.contains(value)
          ? value
          : 'unknown';
  static String _allowedInputMode(String value) =>
      const {'text_only', 'photo', 'multimodal'}.contains(value)
          ? value
          : 'unknown';
}

enum AiMealScanLogStage {
  requested,
  preparationFinished,
  primaryStarted,
  hedgeStarted,
  providerFinished,
  providerUsageReported,
  validationFinished,
  candidateSelected,
  repairStarted,
  repairFinished,
  reviewVisible,
  preliminaryNutritionReady,
  reviewReady,
  correctionStarted,
  correctionFinished,
}

enum AiMealScanLogCandidate { primary, hedge }

enum AiMealScanLogIssueCategory {
  semanticMatch,
  catalogMatch,
  quantity,
  nutritionAnchor,
  preparationState,
  confidence,
  otherValidation,
}

enum AiMealScanLogResult {
  running,
  accepted,
  needsRepair,
  failed,
  cancelled,
  savedUnchanged,
  savedAfterManualEdit,
  savedAfterAiCorrection,
  discarded,
}

class AiMealScanLogEvent {
  final AiMealScanLogStage stage;
  final int elapsedMilliseconds;
  final int? durationMilliseconds;
  final AiMealScanLogResult? result;
  final int? round;
  final AiMealScanLogCandidate? candidate;
  final int? validationScore;
  final List<AiMealScanLogIssueCategory> issueCategories;
  final int? callIndex;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final bool? usageComplete;

  const AiMealScanLogEvent(
      {required this.stage,
      required this.elapsedMilliseconds,
      this.durationMilliseconds,
      this.result,
      this.round,
      this.candidate,
      this.validationScore,
      List<AiMealScanLogIssueCategory>? issueCategories,
      this.callIndex,
      this.inputTokens,
      this.outputTokens,
      this.totalTokens,
      this.usageComplete})
      : issueCategories = issueCategories ?? const [];

  Map<String, Object?> toJson() => {
        'stage': stage.name,
        'elapsed': elapsedMilliseconds,
        'duration': durationMilliseconds,
        'result': result?.name,
        'round': round,
        'candidate': candidate?.name,
        'score': validationScore,
        'issueCategories': issueCategories.map((e) => e.name).toList(),
        'callIndex': callIndex,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'totalTokens': totalTokens,
        'usageComplete': usageComplete,
      };

  factory AiMealScanLogEvent.fromJson(Map<String, dynamic> json) =>
      AiMealScanLogEvent(
        stage: AiMealScanLogStage.values.firstWhere(
            (e) => e.name == json['stage'],
            orElse: () => AiMealScanLogStage.requested),
        elapsedMilliseconds: (json['elapsed'] as num?)?.toInt() ?? 0,
        durationMilliseconds: (json['duration'] as num?)?.toInt(),
        result: _resultFromJson(json['result']),
        round: (json['round'] as num?)?.toInt(),
        candidate: AiMealScanLogCandidate.values
            .where((e) => e.name == json['candidate'])
            .firstOrNull,
        validationScore: (json['score'] as num?)?.toInt(),
        issueCategories: (json['issueCategories'] as List? ?? [])
            .map((value) => AiMealScanLogIssueCategory.values
                .where((e) => e.name == value)
                .firstOrNull)
            .whereType<AiMealScanLogIssueCategory>()
            .toList(),
        callIndex: (json['callIndex'] as num?)?.toInt(),
        inputTokens: (json['inputTokens'] as num?)?.toInt(),
        outputTokens: (json['outputTokens'] as num?)?.toInt(),
        totalTokens: (json['totalTokens'] as num?)?.toInt(),
        usageComplete: json['usageComplete'] as bool?,
      );
}

AiMealScanLogResult? _resultFromJson(Object? value) {
  for (final result in AiMealScanLogResult.values) {
    if (result.name == value) return result;
  }
  return null;
}

class AiMealScanLog {
  final String id;
  final DateTime startedAt;
  String provider;
  String? model;
  final String inputMode;
  final int photoCount;
  final List<AiMealScanLogEvent> events;
  AiMealScanLogResult result;
  int? durationMilliseconds;
  int? selectedValidationRounds;
  int? totalValidationRuns;
  int? repairRounds;
  bool? primaryFirstPassAccepted;
  bool? hedgeStarted;
  int? providerCalls;
  int? inputTokens;
  int? outputTokens;
  int? totalTokens;
  bool? usageComplete;
  AiMealScanLogResult? reviewResult;
  int? correctionRounds;

  AiMealScanLog(
      {required this.id,
      required this.startedAt,
      required this.provider,
      this.model,
      required this.inputMode,
      required this.photoCount,
      List<AiMealScanLogEvent>? events,
      this.result = AiMealScanLogResult.running,
      this.durationMilliseconds,
      this.selectedValidationRounds,
      this.totalValidationRuns,
      this.repairRounds,
      this.primaryFirstPassAccepted,
      this.hedgeStarted,
      this.providerCalls,
      this.inputTokens,
      this.outputTokens,
      this.totalTokens,
      this.usageComplete,
      this.reviewResult,
      this.correctionRounds})
      : events = events ?? [];

  Map<String, Object?> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'provider': provider,
        'model': model,
        'inputMode': inputMode,
        'photoCount': photoCount,
        'events': events.map((e) => e.toJson()).toList(),
        'result': result.name,
        'duration': durationMilliseconds,
        'selectedValidations': selectedValidationRounds,
        'allValidations': totalValidationRuns,
        'repairs': repairRounds,
        'firstPass': primaryFirstPassAccepted,
        'hedge': hedgeStarted,
        'calls': providerCalls,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'totalTokens': totalTokens,
        'usageComplete': usageComplete,
        'reviewResult': reviewResult?.name,
        'corrections': correctionRounds,
      };

  factory AiMealScanLog.fromJson(Map<String, dynamic> json) => AiMealScanLog(
        id: json['id'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        provider: AiMealScanLogService._allowedProvider(
            json['provider'] as String? ?? ''),
        model: RegExp(r'^[A-Za-z0-9._-]{1,80}$')
                .hasMatch(json['model'] as String? ?? '')
            ? json['model'] as String
            : null,
        inputMode: AiMealScanLogService._allowedInputMode(
            json['inputMode'] as String? ?? ''),
        photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
        events: (json['events'] as List? ?? [])
            .whereType<Map>()
            .map((e) =>
                AiMealScanLogEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        result: _resultFromJson(json['result']) ?? AiMealScanLogResult.running,
        durationMilliseconds: (json['duration'] as num?)?.toInt(),
        selectedValidationRounds:
            (json['selectedValidations'] as num?)?.toInt(),
        totalValidationRuns: (json['allValidations'] as num?)?.toInt(),
        repairRounds: (json['repairs'] as num?)?.toInt(),
        primaryFirstPassAccepted: json['firstPass'] as bool?,
        hedgeStarted: json['hedge'] as bool?,
        providerCalls: (json['calls'] as num?)?.toInt(),
        inputTokens: (json['inputTokens'] as num?)?.toInt(),
        outputTokens: (json['outputTokens'] as num?)?.toInt(),
        totalTokens: (json['totalTokens'] as num?)?.toInt(),
        usageComplete: json['usageComplete'] as bool?,
        reviewResult: _resultFromJson(json['reviewResult']),
        correctionRounds: (json['corrections'] as num?)?.toInt(),
      );
}
