import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_change_proposal.dart';
import '../../../domain/assistant_progress_status.dart';

/// Represents a single turn in the AI assistant chat conversation.
class AiChatTurn {
  AiChatTurn(this.prompt);

  final String prompt;
  String? userMessageId;
  String? assistantMessageId;
  AssistantAccessRecord? access;
  String response = '';
  AssistantProgressStatus progressStatus = AssistantProgressStatus.thinking;
  String? modelName;
  Duration? duration;
  DateTime? generationStartedAt;
  AssistantChangeProposal? changeProposal;
  String? proposalStatus;
  bool isApplyingProposal = false;
}
