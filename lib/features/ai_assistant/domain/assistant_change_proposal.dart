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
    this.sourceImageAttachmentIds = const [],
    this.createdRecordId,
  });

  final AssistantChangeOperation operation;
  final ShareLinkPayload payload;
  final String summary;
  final String? targetId;

  /// For an active training plan, preserve the current cycle by default.
  final bool nextCycle;

  /// IDs of images attached to the user message that produced a meal draft.
  /// These are bound by the app after model output is parsed; the model must
  /// never choose which local files become part of a saved diary entry.
  final List<String> sourceImageAttachmentIds;

  /// App-generated stable key for an approved create proposal. It makes a
  /// retry after an interrupted save idempotent; model output never supplies
  /// this value.
  final String? createdRecordId;

  Map<String, dynamic> toJson() => {
        'operation': operation.name,
        'targetId': targetId,
        'nextCycle': nextCycle,
        'summary': summary,
        'payload': payload.toJson(),
        if (sourceImageAttachmentIds.isNotEmpty)
          'sourceImageAttachmentIds': sourceImageAttachmentIds,
        if (createdRecordId != null) 'createdRecordId': createdRecordId,
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
    final rawAttachmentIds = json['sourceImageAttachmentIds'];
    final rawCreatedRecordId = json['createdRecordId'];
    final attachmentIds = rawAttachmentIds == null
        ? const <String>[]
        : rawAttachmentIds is List &&
                rawAttachmentIds.length <= 4 &&
                rawAttachmentIds.every(
                  (value) => value is String && value.trim().isNotEmpty,
                )
            ? rawAttachmentIds.cast<String>()
            : null;
    if (operation == null ||
        (operation == AssistantChangeOperation.create && targetId != null) ||
        (operation == AssistantChangeOperation.update &&
            (targetId is! String || targetId.trim().isEmpty)) ||
        (nextCycle != null && nextCycle is! bool) ||
        summary is! String ||
        summary.trim().isEmpty ||
        summary.length > 2000 ||
        rawPayload is! Map<String, dynamic> ||
        attachmentIds == null ||
        (rawCreatedRecordId != null &&
            (rawCreatedRecordId is! String || !_isUuid(rawCreatedRecordId)))) {
      throw const FormatException('Invalid assistant change proposal.');
    }
    final payload = ShareLinkPayload.fromJson(rawPayload);
    if (!const {'routine', 'plan', 'recipe', 'meal_entry'}
        .contains(payload.type)) {
      throw const FormatException('Unsupported assistant change type.');
    }
    if (payload.type == 'meal_entry' &&
        operation != AssistantChangeOperation.create) {
      throw const FormatException('Meal entries can only be created.');
    }
    if (payload.type != 'meal_entry' && attachmentIds.isNotEmpty) {
      throw const FormatException(
          'Only meal proposals can reference source images.');
    }
    if (payload.type != 'meal_entry' && rawCreatedRecordId != null) {
      throw const FormatException(
          'Only meal proposals can include a created record id.');
    }
    return AssistantChangeProposal(
      operation: operation,
      payload: payload,
      summary: summary.trim(),
      targetId: targetId as String?,
      nextCycle: nextCycle as bool? ?? true,
      sourceImageAttachmentIds: List.unmodifiable(attachmentIds),
      createdRecordId: rawCreatedRecordId as String?,
    );
  }

  AssistantChangeProposal withSourceImageAttachmentIds(List<String> ids) =>
      AssistantChangeProposal(
        operation: operation,
        payload: payload,
        summary: summary,
        targetId: targetId,
        nextCycle: nextCycle,
        sourceImageAttachmentIds: List.unmodifiable(ids.take(4)),
        createdRecordId: createdRecordId,
      );

  AssistantChangeProposal withCreatedRecordId(String id) =>
      AssistantChangeProposal(
        operation: operation,
        payload: payload,
        summary: summary,
        targetId: targetId,
        nextCycle: nextCycle,
        sourceImageAttachmentIds: sourceImageAttachmentIds,
        createdRecordId: id,
      );

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);
}
