import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../application/assistant_chat_service.dart';
import '../../../data/assistant_history_repository.dart';
import 'ai_chat_turn.dart';
import 'cloud_overlay_access_audit_modal.dart' show formatModelDisplayName;

/// Holds the restored turn history and pending access state for a loaded conversation.
class LoadedConversationData {
  final String conversationId;
  final List<AiChatTurn> turns;
  final AssistantAccessRecord? pendingAccess;
  final String? pendingQuestion;
  final int selectedSidebarIndex;

  const LoadedConversationData({
    required this.conversationId,
    required this.turns,
    required this.pendingAccess,
    required this.pendingQuestion,
    required this.selectedSidebarIndex,
  });
}

/// Manages fetching, restoring, and tracking assistant conversation history.
class CloudHistoryManager {
  AssistantHistoryRepository? _history;
  List<AssistantConversation> _conversations = const [];
  int _selectedSidebarExample = 0;

  AssistantHistoryRepository? get repository => _history;
  List<AssistantConversation> get conversations => _conversations;
  int get selectedSidebarExample => _selectedSidebarExample;

  void setRepository(AssistantHistoryRepository history) {
    _history = history;
  }

  void setSelectedSidebarIndex(int index) {
    _selectedSidebarExample = index;
  }

  String getConversationTitle(String? conversationId) {
    if (conversationId == null) return '';
    for (final conversation in _conversations) {
      if (conversation.id == conversationId) return conversation.title;
    }
    return '';
  }

  Future<List<AssistantConversation>> loadConversations() async {
    final history = _history;
    if (history == null) return const [];
    try {
      final loaded = await history.conversations();
      _conversations = loaded;
      return loaded;
    } catch (error) {
      debugPrint('[Assistant] Could not load history: $error');
      return const [];
    }
  }

  Future<LoadedConversationData?> restoreConversation(
    String id, {
    required String locale,
  }) async {
    final history = _history;
    if (history == null) return null;

    await history.recoverInterruptedConversation(id, locale: locale);
    var messages = await history.messages(id);
    var pending = await history.latestAccess(id, status: 'pending');

    if (pending != null &&
        DateTime.now().toUtc().difference(pending.requestedAt) >
            AssistantChatService.approvalLifetime) {
      final isDe = locale.toLowerCase().startsWith('de');
      await history.expireAccess(pending.id);
      await history.addMessage(
        conversationId: id,
        role: 'assistant',
        content: isDe
            ? 'Die Datenanfrage ist abgelaufen. Es wurden keine App-Daten gesendet.'
            : 'Data request expired. No app data was sent.',
        status: 'complete',
      );
      messages = await history.messages(id);
      pending = null;
    }

    final accesses = await history.accessForConversation(id);
    final accessByMessage = {
      for (final access in accesses) access.messageId: access,
    };

    final turns = <AiChatTurn>[];
    for (final message in messages) {
      if (message.role == 'user') {
        turns.add(
          AiChatTurn(message.content)
            ..userMessageId = message.id
            ..access = accessByMessage[message.id],
        );
      } else if (turns.isNotEmpty) {
        turns.last.response = message.content;
        turns.last.modelName =
            formatModelDisplayName(message.providerId, message.modelId);
        turns.last.assistantMessageId = message.id;
      }
    }

    final selectedIndex = _conversations.indexWhere((item) => item.id == id);
    _selectedSidebarExample = selectedIndex;
    final restoredPending = pending;

    return LoadedConversationData(
      conversationId: id,
      turns: turns,
      pendingAccess: restoredPending,
      pendingQuestion: restoredPending == null
          ? null
          : turns
              .where((turn) => turn.userMessageId == restoredPending.messageId)
              .map((turn) => turn.prompt)
              .firstOrNull,
      selectedSidebarIndex: selectedIndex,
    );
  }

  Future<AssistantAccessRecord?> getAccess(String accessId) async {
    return _history?.access(accessId);
  }
}
