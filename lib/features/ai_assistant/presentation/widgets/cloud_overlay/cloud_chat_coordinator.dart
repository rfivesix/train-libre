import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../services/ai_service.dart';
import '../../../../../services/haptic_feedback_service.dart';
import '../../../application/assistant_chat_service.dart';
import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_progress_status.dart';
import 'ai_chat_turn.dart';
import 'cloud_demo_generation_runner.dart';
import 'cloud_history_manager.dart';
import 'cloud_live_assistant_runner.dart';
import 'cloud_loading_animation_controller.dart';
import 'cloud_overlay_formatters.dart';
import 'cloud_waiting_haptics_handler.dart';

/// Coordinates chat turns, live AI and demo responses, permissions, and history for the AI overlay.
class CloudChatCoordinator extends ChangeNotifier {
  final TickerProvider vsync;
  final bool useLiveAi;
  final AssistantModelClient? modelClient;
  final ValueChanged<bool>? onGenerationChanged;
  final void Function({bool force})? onScrollToBottom;
  final void Function(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  })? onShowMessage;
  final ValueGetter<bool> isExpandedGetter;
  final ValueGetter<bool> isDockedSettledGetter;
  final ValueGetter<String> localeGetter;

  final CloudHistoryManager _historyManager = CloudHistoryManager();
  final CloudLiveAssistantRunner _liveRunner = CloudLiveAssistantRunner();
  final CloudDemoGenerationRunner _demoRunner = CloudDemoGenerationRunner();
  late final CloudLoadingAnimationController _loadingCloud;
  late final CloudWaitingHapticsHandler _waitingHaptics;

  final List<AiChatTurn> _chatTurns = [];
  String? _conversationId;
  AssistantAccessRecord? _pendingAccess;
  AssistantAccessRecord? _activeAuditRecord;
  String? _pendingQuestion;
  Completer<bool>? _additionalAccessGate;
  bool _assistantInitialized = false;

  int _activeGenerationId = 0;

  AiChatTurn? _copiedTurn;
  Timer? _copiedTurnTimer;
  Timer? _completionPulseTimer;

  bool _isGenerating = false;
  bool _hasCompletedResponse = false;
  bool _permissionPending = false;
  bool _showPermissionBadge = false;
  bool _attentionPeekDismissed = false;
  bool? _permissionApproved;
  bool _completionPulse = false;
  String? _currentModelName;
  bool _autoApproveDataRequests = false;
  bool _isDisposed = false;

  CloudChatCoordinator({
    required this.vsync,
    required this.useLiveAi,
    this.modelClient,
    this.onGenerationChanged,
    this.onScrollToBottom,
    this.onShowMessage,
    required this.isExpandedGetter,
    required this.isDockedSettledGetter,
    required this.localeGetter,
  }) {
    _loadingCloud = CloudLoadingAnimationController(
      animation: AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 320),
      ),
    );
    _waitingHaptics = CloudWaitingHapticsHandler(
      isExpandedGetter: isExpandedGetter,
    );
    AiService.instance.configurationRevision
        .addListener(_handleAiConfigurationChanged);
    unawaited(refreshCurrentModelName());
  }

  // --- Getters ---
  List<AiChatTurn> get chatTurns => _chatTurns;
  List<AssistantConversation> get conversations =>
      _historyManager.conversations;
  String? get conversationId => _conversationId;
  int get selectedSidebarExample => _historyManager.selectedSidebarExample;
  AssistantAccessRecord? get pendingAccess => _pendingAccess;
  AssistantAccessRecord? get activeAuditRecord => _activeAuditRecord;
  bool get isGenerating => _isGenerating;
  bool get isLoadingCloudVisible => _loadingCloud.isVisible;
  AnimationController get loadingCloudAnimation => _loadingCloud.animation;
  bool get hasCompletedResponse => _hasCompletedResponse;
  bool get permissionPending => _permissionPending;
  bool get showPermissionBadge => _showPermissionBadge;
  bool get attentionPeekDismissed => _attentionPeekDismissed;
  bool? get permissionApproved => _permissionApproved;
  bool get completionPulse => _completionPulse;
  bool get autoApproveDataRequests => _autoApproveDataRequests;
  String? get currentModelName => _currentModelName;
  AiChatTurn? get copiedTurn => _copiedTurn;

  String get activeConversationTitle =>
      _historyManager.getConversationTitle(_conversationId);

  String? get composerModelName => !useLiveAi
      ? 'Demo'
      : _currentModelName ??
          (_chatTurns.isNotEmpty ? _chatTurns.last.modelName : null);

  void markAttentionPeekDismissed() {
    _attentionPeekDismissed = true;
    notifyListeners();
  }

  void clearActiveAudit() {
    _activeAuditRecord = null;
    notifyListeners();
  }

  void showAccessAudit(AssistantAccessRecord access) {
    _activeAuditRecord = access;
    notifyListeners();
  }

  void initializeAssistant(
    AssistantChatService assistant,
    AssistantHistoryRepository history,
  ) {
    if (_assistantInitialized) return;
    _assistantInitialized = true;
    _liveRunner.setAssistant(assistant);
    _historyManager.setRepository(history);
    unawaited(_loadAutoApprovePreference());
    unawaited(_loadAssistantHistory());
  }

  Future<void> _loadAutoApprovePreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (_isDisposed) return;
    _autoApproveDataRequests =
        preferences.getBool('ai_overlay_auto_approve_data_requests') ?? false;
    notifyListeners();
  }

  Future<void> toggleAutoApproveDataRequests() async {
    final next = !_autoApproveDataRequests;
    _autoApproveDataRequests = next;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('ai_overlay_auto_approve_data_requests', next);
  }

  void _handleAiConfigurationChanged() {
    unawaited(refreshCurrentModelName());
  }

  Future<void> refreshCurrentModelName() async {
    final name = await _resolveCurrentModelName();
    if (!_isDisposed && _currentModelName != name) {
      _currentModelName = name;
      notifyListeners();
    }
  }

  Future<String> _resolveCurrentModelName() async {
    if (!useLiveAi) return 'Demo';
    if (modelClient != null) {
      try {
        final identity = await modelClient!.identity();
        final formatted =
            formatModelDisplayName(identity.providerId, identity.modelId);
        if (formatted != null) return formatted;
      } catch (_) {}
    }
    try {
      final provider = await AiService.instance.getSelectedProvider();
      if (provider == AiProvider.appleFoundation) {
        return 'Apple Intelligence';
      }
      final model = await AiService.instance.getSelectedModel(provider);
      if (model.isNotEmpty) {
        return model;
      }
      return AiService.instance.getProviderMetadata(provider).displayName;
    } catch (_) {
      return 'KI';
    }
  }

  Future<void> _loadAssistantHistory() async {
    final loaded = await _historyManager.loadConversations();
    if (_isDisposed) return;
    notifyListeners();
    if (_conversationId == null && loaded.isNotEmpty) {
      await openConversation(loaded.first.id);
    }
  }

  Future<void> openConversation(String id) async {
    stopGeneration();
    final cancellation = _liveRunner.activeGenerationCancellation;
    if (cancellation != null) await cancellation;
    if (_isDisposed) return;

    final data = await _historyManager.restoreConversation(
      id,
      locale: localeGetter(),
    );
    if (_isDisposed || data == null) return;

    _conversationId = data.conversationId;
    _activeAuditRecord = null;
    _chatTurns
      ..clear()
      ..addAll(data.turns);
    _pendingAccess = data.pendingAccess;
    _pendingQuestion = data.pendingQuestion;
    _permissionPending = data.pendingAccess != null;
    _showPermissionBadge = data.pendingAccess != null;
    _permissionApproved = null;
    notifyListeners();
    onScrollToBottom?.call(force: true);
  }

  void selectSidebarExample(int index) {
    if (useLiveAi) {
      if (index >= 0 && index < _historyManager.conversations.length) {
        unawaited(openConversation(_historyManager.conversations[index].id));
      }
      return;
    }
    _historyManager.setSelectedSidebarIndex(index);
    notifyListeners();
  }

  void startNewChat() {
    if (useLiveAi) {
      _conversationId = null;
      _pendingAccess = null;
      _pendingQuestion = null;
    }
    _activeGenerationId++;
    _demoRunner.cancelAllTimers();
    _liveRunner.cancelActiveResponseSubscription();
    _loadingCloud.reset();
    _completionPulseTimer?.cancel();
    _waitingHaptics.resetWordHaptics();

    _chatTurns.clear();
    _isGenerating = false;
    _hasCompletedResponse = false;
    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    _attentionPeekDismissed = false;
    _completionPulse = false;
    _demoRunner.resetWordIndex();
    _historyManager.setSelectedSidebarIndex(-1);
    notifyListeners();

    _waitingHaptics.sync(isGenerating: false);
    onGenerationChanged?.call(false);
  }

  void sendPrompt(String prompt) {
    if (prompt.trim().isEmpty) return;
    if (useLiveAi) {
      unawaited(_sendAssistantPrompt(prompt.trim()));
    } else {
      _sendDemoPrompt(prompt.trim());
    }
  }

  void _sendDemoPrompt(String prompt) {
    if (_isGenerating) stopGeneration();

    final generationId = ++_activeGenerationId;
    _demoRunner.stopWordTicker();
    _liveRunner.cancelActiveResponseSubscription();
    _waitingHaptics.resetWordHaptics();

    final turn = AiChatTurn(prompt)
      ..generationStartedAt = DateTime.now()
      ..modelName = 'Demo';

    _demoRunner.cancelPermissionBadgeTimer();
    _chatTurns.add(turn);
    _isGenerating = true;
    _hasCompletedResponse = false;
    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    _demoRunner.resetWordIndex();
    notifyListeners();

    final enterFuture = _loadingCloud.show();
    _waitingHaptics.sync(isGenerating: true);
    onGenerationChanged?.call(true);
    onScrollToBottom?.call(force: true);

    unawaited(
      enterFuture.then((_) {
        return _demoRunner.startStreamingAfterLoadingCloud(
          loadingCloud: _loadingCloud,
          isStillActive: () =>
              !_isDisposed &&
              _activeGenerationId == generationId &&
              _isGenerating,
          onWord: _handleDemoWordEmitted,
        );
      }).catchError((_) {}),
    );
  }

  Future<void> _sendAssistantPrompt(String prompt) async {
    if (_isGenerating) stopGeneration();
    if (_liveRunner.assistant == null) return;
    final locale = localeGetter();
    final isDe = locale.toLowerCase().startsWith('de');

    if (_permissionPending) {
      final skippedAccess = _pendingAccess;
      final gate = _additionalAccessGate;
      _additionalAccessGate = null;
      if (gate != null && !gate.isCompleted) gate.complete(false);
      _pendingAccess = null;
      _pendingQuestion = null;
      _permissionPending = false;
      _showPermissionBadge = false;
      if (skippedAccess != null && gate == null) {
        unawaited(
          _liveRunner
              .denyAccess(accessId: skippedAccess.id, locale: locale)
              .then((_) => refreshTurnAccess(skippedAccess.id))
              .catchError((Object _) {}),
        );
      }
    }

    final generationId = ++_activeGenerationId;
    _waitingHaptics.resetWordHaptics();
    final turn = AiChatTurn(prompt)
      ..generationStartedAt = DateTime.now()
      ..modelName = _currentModelName;

    _activeAuditRecord = null;
    _chatTurns.add(turn);
    _isGenerating = true;
    _hasCompletedResponse = false;
    _permissionApproved = null;
    notifyListeners();

    unawaited(_resolveCurrentModelName().then((name) {
      if (_isDisposed) return;
      _currentModelName = name;
      turn.modelName ??= name;
      notifyListeners();
    }));

    _waitingHaptics.sync(isGenerating: true);
    onGenerationChanged?.call(true);
    _loadingCloud.show();
    onScrollToBottom?.call(force: true);

    try {
      final submission = await _liveRunner.submitPrompt(
        prompt: prompt,
        conversationId: _conversationId,
        now: DateTime.now(),
        locale: locale,
      );
      if (_isDisposed ||
          _activeGenerationId != generationId ||
          submission == null) {
        return;
      }

      turn.userMessageId = submission.userMessage.id;
      turn.access = submission.access;
      turn.modelName =
          formatModelDisplayName(submission.providerId, submission.modelId) ??
              _currentModelName ??
              turn.modelName;

      await _loadingCloud.hide();
      if (_isDisposed || _activeGenerationId != generationId) return;

      if (submission.access != null) {
        _conversationId = submission.conversationId;
        _pendingAccess = submission.access;
        _pendingQuestion = prompt;
        _permissionPending = true;
        _showPermissionBadge = true;
        _attentionPeekDismissed = false;
        _isGenerating = false;
        notifyListeners();

        _waitingHaptics.sync(isGenerating: false);
        unawaited(HapticFeedbackService.instance.strongImpact());
        onGenerationChanged?.call(false);
        unawaited(_loadAssistantHistory());
        onScrollToBottom?.call(force: true);

        if (_autoApproveDataRequests) {
          scheduleMicrotask(() => resolvePermission(true));
        }
        return;
      }

      _conversationId = submission.conversationId;
      _pendingAccess = null;
      _pendingQuestion = null;
      turn.response = submission.clarification ?? '';
      notifyListeners();

      _completeDemoGeneration();
      unawaited(_loadAssistantHistory());
      onScrollToBottom?.call(force: true);
    } catch (error) {
      if (_isDisposed || _activeGenerationId != generationId) return;
      await _loadingCloud.hide();
      if (_isDisposed || _activeGenerationId != generationId) return;

      turn.response = isDe
          ? 'Diese Anfrage konnte nicht verarbeitet werden: $error'
          : 'Could not save this question: $error';
      _isGenerating = false;
      notifyListeners();

      _waitingHaptics.sync(isGenerating: false);
      onGenerationChanged?.call(false);
    }
  }

  void resolvePermission(bool approved) {
    if (useLiveAi) {
      _resolveAssistantPermission(approved);
    } else {
      _resolveDemoPermission(approved);
    }
  }

  void _resolveAssistantPermission(bool approved) {
    final access = _pendingAccess;
    final question = _pendingQuestion;
    if (access == null || question == null) return;
    final locale = localeGetter();

    final additionalGate = _additionalAccessGate;
    if (additionalGate != null) {
      _additionalAccessGate = null;
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _pendingAccess = null;
      _pendingQuestion = null;
      _isGenerating = true;
      if (_chatTurns.isNotEmpty) {
        _chatTurns.last.progressStatus = AssistantProgressStatus.thinking;
      }
      notifyListeners();
      _waitingHaptics.sync(isGenerating: true);
      _loadingCloud.show();
      onGenerationChanged?.call(true);
      onScrollToBottom?.call(force: true);
      if (!additionalGate.isCompleted) additionalGate.complete(approved);
      return;
    }

    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = approved;
    _pendingAccess = null;
    _pendingQuestion = null;
    notifyListeners();

    if (!approved) {
      unawaited(
        _liveRunner
            .denyAccess(accessId: access.id, locale: locale)
            .then((message) {
          if (_isDisposed || _chatTurns.isEmpty) return;
          if (message != null) {
            _chatTurns.last.response = message.content;
          }
          if (_chatTurns.last.generationStartedAt != null) {
            _chatTurns.last.duration =
                DateTime.now().difference(_chatTurns.last.generationStartedAt!);
          }
          _chatTurns.last.modelName ??=
              formatModelDisplayName(access.providerId, access.modelId) ??
                  _currentModelName;
          notifyListeners();
          unawaited(refreshTurnAccess(access.id));
          unawaited(_loadAssistantHistory());
          onScrollToBottom?.call();
        }).catchError((Object error) {
          if (!_isDisposed && _chatTurns.isNotEmpty) {
            _chatTurns.last.response = error.toString();
            notifyListeners();
          }
        }),
      );
      return;
    }

    final generationId = ++_activeGenerationId;
    _waitingHaptics.resetWordHaptics();
    _isGenerating = true;
    _permissionApproved = null;
    _hasCompletedResponse = false;
    _attentionPeekDismissed = false;
    if (_chatTurns.isNotEmpty) {
      _chatTurns.last.generationStartedAt = DateTime.now();
      _chatTurns.last.progressStatus = AssistantProgressStatus.thinking;
      _chatTurns.last.modelName ??=
          formatModelDisplayName(access.providerId, access.modelId) ??
              _currentModelName;
    }
    notifyListeners();

    unawaited(_resolveCurrentModelName().then((name) {
      if (_isDisposed) return;
      _currentModelName = name;
      if (_chatTurns.isNotEmpty) {
        _chatTurns.last.modelName ??= name;
      }
      notifyListeners();
    }));

    _loadingCloud.show();
    _waitingHaptics.sync(isGenerating: true);
    unawaited(HapticFeedbackService.instance.lightImpact());
    onGenerationChanged?.call(true);
    onScrollToBottom?.call(force: true);

    _liveRunner.streamBufferedAnswer(
      accessId: access.id,
      question: question,
      locale: locale,
      loadingCloud: _loadingCloud,
      isStillActive: () => !_isDisposed && _activeGenerationId == generationId,
      onAppendText: (chunk) {
        if (_chatTurns.isEmpty) return;
        _chatTurns.last.response += chunk;
        notifyListeners();
        _waitingHaptics.triggerWordHapticIfNeeded(_chatTurns.last.response);
        onScrollToBottom?.call();
      },
      onAdditionalAccess: (extraAccess) =>
          _waitForAdditionalAccess(extraAccess, question, generationId),
      onProgressStatus: (status) {
        if (_isDisposed ||
            _activeGenerationId != generationId ||
            _chatTurns.isEmpty) {
          return;
        }
        _chatTurns.last.progressStatus = status;
        notifyListeners();
      },
      onProposalAvailable: (messageId, proposal) {
        if (_chatTurns.isEmpty) return;
        final turn = _chatTurns.last;
        turn.assistantMessageId = messageId;
        turn.changeProposal = proposal;
        turn.proposalStatus = 'proposal_pending';
        notifyListeners();
      },
      onError: (error) {
        if (_chatTurns.isNotEmpty) {
          _chatTurns.last.response += '\n\n$error';
          notifyListeners();
        }
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
      },
      onDone: () {
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
        unawaited(_loadAssistantHistory());
      },
    );
  }

  Future<void> resolveChangeProposal(
    AiChatTurn turn, {
    required bool approved,
  }) async {
    final messageId = turn.assistantMessageId;
    if (messageId == null ||
        turn.proposalStatus != 'proposal_pending' ||
        turn.isApplyingProposal) {
      return;
    }
    turn.isApplyingProposal = true;
    notifyListeners();
    try {
      final message = await _liveRunner.resolveProposal(
        messageId: messageId,
        approved: approved,
        locale: localeGetter(),
      );
      if (_isDisposed || message == null) return;
      turn.proposalStatus = approved ? 'proposal_applied' : 'proposal_rejected';
      turn.response = message;
    } catch (error) {
      if (!_isDisposed) {
        turn.response = '${turn.changeProposal?.summary ?? ''}\n\n$error';
      }
    } finally {
      turn.isApplyingProposal = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> _waitForAdditionalAccess(
    AssistantAccessRecord access,
    String question,
    int generationId,
  ) async {
    if (_isDisposed || _activeGenerationId != generationId) return false;
    await _loadingCloud.hide();
    if (_isDisposed || _activeGenerationId != generationId) return false;
    final gate = Completer<bool>();
    _additionalAccessGate = gate;
    _pendingAccess = access;
    _pendingQuestion = question;
    _permissionPending = true;
    _showPermissionBadge = true;
    _permissionApproved = null;
    _isGenerating = false;
    _attentionPeekDismissed = false;
    notifyListeners();
    _waitingHaptics.sync(isGenerating: false);
    unawaited(HapticFeedbackService.instance.strongImpact());
    onGenerationChanged?.call(false);
    onScrollToBottom?.call(force: true);
    if (_autoApproveDataRequests) {
      scheduleMicrotask(() => resolvePermission(true));
    }
    return gate.future;
  }

  void _resolveDemoPermission(bool approved) {
    if (approved) {
      _demoRunner.cancelPermissionBadgeTimer();
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = true;
      _hasCompletedResponse = false;
      _attentionPeekDismissed = false;
      _isGenerating = true;
      notifyListeners();

      _waitingHaptics.sync(isGenerating: true);
      unawaited(HapticFeedbackService.instance.lightImpact());
      onGenerationChanged?.call(true);
      _demoRunner.startWordTicker(onWord: _handleDemoWordEmitted);
      _demoRunner.scheduleContinuationTimer(
          onComplete: _completeDemoGeneration);
      onScrollToBottom?.call();
      return;
    }

    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = false;
    _demoRunner.cancelPermissionBadgeTimer();
    notifyListeners();
    onScrollToBottom?.call();
  }

  Future<void> refreshTurnAccess(String accessId) async {
    final access = await _historyManager.getAccess(accessId);
    if (_isDisposed || access == null) return;
    final index =
        _chatTurns.indexWhere((turn) => turn.userMessageId == access.messageId);
    if (index >= 0) {
      _chatTurns[index].access = access;
      final modelDisplay =
          formatModelDisplayName(access.providerId, access.modelId);
      if (modelDisplay != null) {
        _chatTurns[index].modelName = modelDisplay;
      }
      notifyListeners();
    }
  }

  void _handleDemoWordEmitted(String wordSnippet) {
    if (_isDisposed || !_isGenerating || _chatTurns.isEmpty) {
      _demoRunner.stopWordTicker();
      return;
    }
    final turn = _chatTurns.last;
    turn.response += wordSnippet;
    notifyListeners();
    _waitingHaptics.triggerWordHapticIfNeeded(turn.response);
    onScrollToBottom?.call();
  }

  void stopGeneration() {
    if (!_isGenerating) return;
    ++_activeGenerationId;
    _demoRunner.stopWordTicker();
    _demoRunner.cancelContinuationTimer();
    _liveRunner.cancelActiveResponseSubscription();

    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null && lastTurn.duration == null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??= useLiveAi ? (_currentModelName ?? 'KI') : 'Demo';
      if (lastTurn.response.isEmpty) {
        final isDe = localeGetter().toLowerCase().startsWith('de');
        lastTurn.response = isDe
            ? 'Anfrage abgebrochen. Du kannst es erneut versuchen.'
            : 'Request interrupted. You can try again.';
      }
    }

    _isGenerating = false;
    notifyListeners();

    unawaited(_loadingCloud.hide(waitForEnter: false));
    _waitingHaptics.sync(isGenerating: false);
    onGenerationChanged?.call(false);
  }

  void _completeDemoGeneration() {
    if (!_isGenerating) return;
    // Invalidate callbacks from the completed generation before cancelling its
    // stream. A late token must not be appended to a later turn.
    ++_activeGenerationId;
    _demoRunner.stopWordTicker();
    _demoRunner.cancelContinuationTimer();
    _liveRunner.cancelActiveResponseSubscription();

    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??= useLiveAi ? (_currentModelName ?? 'KI') : 'Demo';
    }

    final wasDocked = isDockedSettledGetter();
    _isGenerating = false;
    _hasCompletedResponse = wasDocked;
    _permissionPending = false;
    _attentionPeekDismissed = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    _completionPulse = wasDocked;
    notifyListeners();

    unawaited(_loadingCloud.hide());
    _demoRunner.cancelPermissionBadgeTimer();
    _waitingHaptics.sync(isGenerating: false);
    unawaited(HapticFeedbackService.instance.strongImpact());
    onGenerationChanged?.call(false);
    onScrollToBottom?.call();
    if (_completionPulse) _scheduleCompletionPulseReset();
  }

  void finishDemoGeneration() => _completeDemoGeneration();

  void requestDemoPermission() {
    if (useLiveAi || !_isGenerating || _chatTurns.isEmpty) return;
    // Invalidate delayed demo startup work before changing the state. Otherwise
    // a fast approval can make an old startup callback look current again.
    ++_activeGenerationId;
    _demoRunner.stopWordTicker();

    _isGenerating = false;
    _hasCompletedResponse = false;
    _permissionPending = true;
    _attentionPeekDismissed = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    notifyListeners();

    unawaited(_loadingCloud.hide());
    _demoRunner.schedulePermissionBadge(
      onShowBadge: () {
        if (_isDisposed || !_permissionPending) return;
        _showPermissionBadge = true;
        notifyListeners();
      },
    );
    _waitingHaptics.sync(isGenerating: false);
    unawaited(HapticFeedbackService.instance.strongImpact());
    onGenerationChanged?.call(false);
    onScrollToBottom?.call();
  }

  void _scheduleCompletionPulseReset() {
    _completionPulseTimer?.cancel();
    _completionPulseTimer = Timer(const Duration(milliseconds: 260), () {
      if (!_isDisposed) {
        _completionPulse = false;
        notifyListeners();
      }
    });
  }

  void clearCompletedPulse() {
    _completionPulse = false;
    _hasCompletedResponse = false;
    notifyListeners();
  }

  void syncDemoWaitingHaptics() =>
      _waitingHaptics.sync(isGenerating: _isGenerating);

  Future<void> copyResponseMarkdown(AiChatTurn turn) async {
    await Clipboard.setData(ClipboardData(text: turn.response));
    unawaited(HapticFeedbackService.instance.selectionFeedback());
    _copiedTurn = turn;
    notifyListeners();

    _copiedTurnTimer?.cancel();
    _copiedTurnTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!_isDisposed) {
        _copiedTurn = null;
        notifyListeners();
      }
    });

    onShowMessage?.call(
      'Antwort im Markdown-Format kopiert',
      actionLabel: 'Gesamten Chat',
      onAction: copyFullChatMarkdown,
    );
  }

  Future<void> copyFullChatMarkdown() async {
    if (_chatTurns.isEmpty) return;
    final buffer = StringBuffer();
    for (var i = 0; i < _chatTurns.length; i++) {
      final t = _chatTurns[i];
      buffer.writeln('### Benutzer');
      buffer.writeln(t.prompt);
      buffer.writeln();
      buffer.writeln('### Assistent');
      buffer.writeln(t.response);
      if (i < _chatTurns.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    unawaited(HapticFeedbackService.instance.selectionFeedback());
    onShowMessage?.call('Kompletter Chat im Markdown-Format kopiert');
  }

  void retryTurnPrompt(
    AiChatTurn turn, {
    required ValueChanged<String> onFillPrompt,
  }) {
    if (_isGenerating) return;
    final prompt = turn.prompt.trim();
    if (prompt.isEmpty) return;
    final index = _chatTurns.indexOf(turn);
    if (index != -1 && !useLiveAi) {
      _chatTurns.removeRange(index, _chatTurns.length);
      notifyListeners();
    }
    onFillPrompt(prompt);
    sendPrompt(prompt);
  }

  @override
  void dispose() {
    _isDisposed = true;
    final gate = _additionalAccessGate;
    _additionalAccessGate = null;
    if (gate != null && !gate.isCompleted) gate.complete(false);
    AiService.instance.configurationRevision
        .removeListener(_handleAiConfigurationChanged);
    _liveRunner.dispose();
    _demoRunner.dispose();
    _waitingHaptics.dispose();
    _loadingCloud.dispose();
    _copiedTurnTimer?.cancel();
    _completionPulseTimer?.cancel();
    super.dispose();
  }
}
