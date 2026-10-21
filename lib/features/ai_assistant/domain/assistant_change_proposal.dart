import '../../sharing/share_link_codec.dart';

enum AssistantChangeOperation { create, update }

/// A validated, still-unapplied change proposed by the assistant.
class AssistantChangeProposal {
  const AssistantChangeProposal({
    required this.operation,
    required this.payload,
    required this.summary,
    this.targetId,
    this.nextCycle = true,
  });

  final AssistantChangeOperation operation;
  final ShareLinkPayload payload;
  final String summary;
  final String? targetId;

  /// For an active training plan, preserve the current cycle by default.
  final bool nextCycle;

  Map<String, dynamic> toJson() => {
        'operation': operation.name,
        'targetId': targetId,
        'nextCycle': nextCycle,
        'summary': summary,
        'payload': payload.toJson(),
      };

  factory AssistantChangeProposal.fromJson(Map<String, dynamic> json) {
    final operationName = json['operation'];
    final operation = AssistantChangeOperation.values
        .where((value) => value.name == operationName)
        .firstOrNull;
    final targetId = json['targetId'];
    final nextCycle = json['nextCycle'];
    final summary = json['summary'];
    final rawPayload = json['payload'];
    if (operation == null ||
        (operation == AssistantChangeOperation.create && targetId != null) ||
        (operation == AssistantChangeOperation.update &&
            (targetId is! String || targetId.trim().isEmpty)) ||
        (nextCycle != null && nextCycle is! bool) ||
        summary is! String ||
        summary.trim().isEmpty ||
        summary.length > 2000 ||
        rawPayload is! Map<String, dynamic>) {
      throw const FormatException('Invalid assistant change proposal.');
    }
    final payload = ShareLinkPayload.fromJson(rawPayload);
    if (!const {'routine', 'plan', 'recipe'}.contains(payload.type)) {
      throw const FormatException('Unsupported assistant change type.');
    }
    return AssistantChangeProposal(
      operation: operation,
      payload: payload,
      summary: summary.trim(),
      targetId: targetId as String?,
      nextCycle: nextCycle as bool? ?? true,
    );
  }
}
