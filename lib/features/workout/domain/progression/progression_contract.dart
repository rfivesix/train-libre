import 'dart:convert';
import '../models/prescription_enums.dart';

enum ProgressionPolicy { linkedWorkingSets, independentWorkingSets }

enum SetCompletion {
  completed,
  abandoned,
  stoppedForPain,
  equipmentInterrupted
}

enum LoadLadderSource { user, equipmentClass, incrementFallback }

enum ReviewKind {
  largeStepTrial,
  overRepBridge,
  stepUnavailable,
  farAboveRange,
  stallCandidate,
  modeBoundary
}

enum ReviewAction {
  offered,
  accepted,
  rejected,
  dismissed,
  confirmedLog,
  recalibrated
}

T _enum<T extends Enum>(List<T> values, dynamic name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

/// Values use the same unit as engine input; persisted configurations use kg.
class LoadLadder {
  final List<double> values;
  final LoadLadderSource source;
  LoadLadder(Iterable<num> values, {required this.source})
      : values = List.unmodifiable(values
            .where((v) => v.isFinite && v >= 0)
            .map((v) => v.toDouble())
            .toSet()
            .toList()
          ..sort());
  double? next(double load, {bool assisted = false}) => assisted
      ? values.where((v) => v < load).lastOrNull
      : values.where((v) => v > load).firstOrNull;
  Map<String, dynamic> toJson() => {'values': values, 'source': source.name};
  factory LoadLadder.fromJson(Map<String, dynamic> json) =>
      LoadLadder((json['values'] as List).cast<num>(),
          source: _enum(
              LoadLadderSource.values, json['source'], LoadLadderSource.user));
}

class ProgressionReview {
  final ReviewKind kind;
  final String position;
  final double? currentLoad;
  final double? targetLoad;
  final int? targetReps;
  final double? relativeJump;
  final LoadMode? targetMode;
  final ProgressionPolicy policy;
  final LoadLadderSource ladderSource;
  final String reason;
  final String algorithmVersion;
  bool get requiresUserConfirmation => true;
  const ProgressionReview(
      {required this.kind,
      required this.position,
      required this.policy,
      required this.ladderSource,
      required this.reason,
      this.currentLoad,
      this.targetLoad,
      this.targetReps,
      this.relativeJump,
      this.targetMode,
      this.algorithmVersion = 'progression_v1.5'});
  String get key =>
      '$algorithmVersion:${kind.name}:$position:$currentLoad:$targetLoad:$targetReps';
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'position': position,
        'currentLoad': currentLoad,
        'targetLoad': targetLoad,
        'targetReps': targetReps,
        'relativeJump': relativeJump,
        'targetMode': targetMode?.name,
        'policy': policy.name,
        'ladderSource': ladderSource.name,
        'reason': reason,
        'algorithmVersion': algorithmVersion
      };
  factory ProgressionReview.fromJson(Map<String, dynamic> j) =>
      ProgressionReview(
          kind: _enum(ReviewKind.values, j['kind'], ReviewKind.stepUnavailable),
          position: j['position'],
          currentLoad: (j['currentLoad'] as num?)?.toDouble(),
          targetLoad: (j['targetLoad'] as num?)?.toDouble(),
          targetReps: j['targetReps'],
          relativeJump: (j['relativeJump'] as num?)?.toDouble(),
          targetMode: j['targetMode'] == null
              ? null
              : LoadMode.fromString(j['targetMode']),
          policy: _enum(ProgressionPolicy.values, j['policy'],
              ProgressionPolicy.linkedWorkingSets),
          ladderSource: _enum(LoadLadderSource.values, j['ladderSource'],
              LoadLadderSource.incrementFallback),
          reason: j['reason'],
          algorithmVersion: j['algorithmVersion']);
}

class ReviewDecision {
  final ProgressionReview review;
  final ReviewAction action;
  final DateTime at;
  final double? chosenLoad;
  final String? note;
  const ReviewDecision(
      {required this.review,
      required this.action,
      required this.at,
      this.chosenLoad,
      this.note});
  Map<String, dynamic> toJson() => {
        'review': review.toJson(),
        'action': action.name,
        'at': at.toIso8601String(),
        'chosenLoad': chosenLoad,
        'note': note
      };
  factory ReviewDecision.fromJson(Map<String, dynamic> j) => ReviewDecision(
      review: ProgressionReview.fromJson(j['review']),
      action: _enum(ReviewAction.values, j['action'], ReviewAction.dismissed),
      at: DateTime.parse(j['at']),
      chosenLoad: (j['chosenLoad'] as num?)?.toDouble(),
      note: j['note']);
}

class ConfirmedBaseline {
  final double load;
  final DateTime at;
  const ConfirmedBaseline(this.load, this.at);
  Map<String, dynamic> toJson() => {'load': load, 'at': at.toIso8601String()};
  factory ConfirmedBaseline.fromJson(Map<String, dynamic> j) =>
      ConfirmedBaseline((j['load'] as num).toDouble(), DateTime.parse(j['at']));
}

/// Versioned prescription/context snapshot. Events are append-only; authored
/// ranges live in their original columns and are never replaced by a bridge.
class ProgressionConfig {
  final ProgressionPolicy policy;
  final LoadLadder? ladder;
  final String? equipmentIdentity;
  final LoadMode? loadMode;
  final SetCompletion completion;
  final List<ReviewDecision> events;
  final String? contextNote;
  final int? bridgeTarget;
  final double? bridgeLoad;
  final String? prescriptionKey;
  final Map<String, ConfirmedBaseline> baselines;
  const ProgressionConfig(
      {this.policy = ProgressionPolicy.linkedWorkingSets,
      this.ladder,
      this.equipmentIdentity,
      this.loadMode,
      this.completion = SetCompletion.completed,
      this.events = const [],
      this.contextNote,
      this.bridgeTarget,
      this.bridgeLoad,
      this.prescriptionKey,
      this.baselines = const {}});
  ProgressionConfig copyWith(
          {ProgressionPolicy? policy,
          LoadLadder? ladder,
          String? equipmentIdentity,
          LoadMode? loadMode,
          SetCompletion? completion,
          List<ReviewDecision>? events,
          String? contextNote,
          int? bridgeTarget,
          double? bridgeLoad,
          bool clearBridge = false,
          String? prescriptionKey,
          Map<String, ConfirmedBaseline>? baselines}) =>
      ProgressionConfig(
          policy: policy ?? this.policy,
          ladder: ladder ?? this.ladder,
          equipmentIdentity: equipmentIdentity ?? this.equipmentIdentity,
          loadMode: loadMode ?? this.loadMode,
          completion: completion ?? this.completion,
          events: events ?? this.events,
          contextNote: contextNote ?? this.contextNote,
          bridgeTarget: clearBridge ? null : bridgeTarget ?? this.bridgeTarget,
          bridgeLoad: clearBridge ? null : bridgeLoad ?? this.bridgeLoad,
          prescriptionKey: prescriptionKey ?? this.prescriptionKey,
          baselines: baselines ?? this.baselines);
  String encode() => jsonEncode({
        'schemaVersion': 1,
        'policy': policy.name,
        'bridgeTarget': bridgeTarget,
        'bridgeLoad': bridgeLoad,
        'prescriptionKey': prescriptionKey,
        'baselines': baselines.map((k, v) => MapEntry(k, v.toJson())),
        'ladder': ladder?.toJson(),
        'equipmentIdentity': equipmentIdentity,
        'loadMode': loadMode?.name,
        'completion': completion.name,
        'events': events.map((e) => e.toJson()).toList(),
        'contextNote': contextNote
      });
  factory ProgressionConfig.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ProgressionConfig();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return ProgressionConfig(
        policy: _enum(ProgressionPolicy.values, j['policy'],
            ProgressionPolicy.linkedWorkingSets),
        ladder: j['ladder'] == null ? null : LoadLadder.fromJson(j['ladder']),
        equipmentIdentity: j['equipmentIdentity'],
        loadMode:
            j['loadMode'] == null ? null : LoadMode.fromString(j['loadMode']),
        completion: _enum(
            SetCompletion.values, j['completion'], SetCompletion.completed),
        prescriptionKey: j['prescriptionKey'],
        baselines: (j['baselines'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, ConfirmedBaseline.fromJson(v))),
        bridgeTarget: j['bridgeTarget'],
        bridgeLoad: (j['bridgeLoad'] as num?)?.toDouble(),
        events: (j['events'] as List? ?? [])
            .map((e) => ReviewDecision.fromJson(e))
            .toList(),
        contextNote: j['contextNote']);
  }
}

bool canAnchorPosition(ProgressionPolicy policy,
        {required bool hasOwnHistory}) =>
    policy == ProgressionPolicy.linkedWorkingSets || !hasOwnHistory;
