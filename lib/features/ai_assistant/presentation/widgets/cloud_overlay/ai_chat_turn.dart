import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_change_proposal.dart';

/// Represents a single turn in the AI assistant chat conversation.
class AiChatTurn {
  AiChatTurn(this.prompt);

  final String prompt;
  String? userMessageId;
  String? assistantMessageId;
  AssistantAccessRecord? access;
  String response = '';
  String? modelName;
  Duration? duration;
  DateTime? generationStartedAt;
  AssistantChangeProposal? changeProposal;
  String? proposalStatus;
  bool isApplyingProposal = false;
}
