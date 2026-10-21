import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../services/ai_service.dart';
import '../../../../../services/haptic_feedback_service.dart';
import '../../../application/assistant_chat_service.dart';
import '../../../data/assistant_history_repository.dart';
import 'ai_chat_turn.dart';
import 'cloud_overlay_access_audit_modal.dart' show formatModelDisplayName;

/// Coordinates chat turns, live AI and demo responses, permissions, and history for the AI overlay.
class CloudChatCoordinator extends ChangeNotifier {
  static const _demoWords = <String>[
    '**Lorem',
    'ipsum**',
    'dolor',
    'sit',
    '*amet*,',
    'consectetur',
    '`adipiscing`',
    'elit,',
    'sed',
    'do',
    'eiusmod',
    'tempor',
    'incididunt',
    'ut',
    'labore',
    'et',
    'dolore',
    'magna',
    'aliqua.',
  ];

  static final RegExp _wordPattern = RegExp(r'\S+');

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

  final List<AiChatTurn> _chatTurns = [];
  AssistantChatService? _assistant;
  AssistantHistoryRepository? _history;
  String? _conversationId;
  List<AssistantConversation> _conversations = const [];
  AssistantAccessRecord? _pendingAccess;
  AssistantAccessRecord? _activeAuditRecord;
  String? _pendingQuestion;
  bool _assistantInitialized = false;

  Timer? _responseTimer;
  StreamSubscription<String>? _liveResponseSubscription;
  Future<void>? _activeGenerationCancellation;
  int _activeGenerationId = 0;

  bool _isLoadingCloudVisible = false;
  Future<void>? _loadingCloudEnterFuture;
  late final AnimationController _loadingCloudController;

  AiChatTurn? _copiedTurn;
  Timer? _copiedTurnTimer;
  Timer? _permissionContinuationTimer;
  Timer? _completionPulseTimer;
  Timer? _permissionBadgeDelayTimer;
  Timer? _collapsedWaitingHapticTimer;
  int _lastHapticWordCount = 0;
  DateTime? _lastWordHapticAt;

  bool _isGenerating = false;
  bool _hasCompletedResponse = false;
  bool _permissionPending = false;
  bool _showPermissionBadge = false;
  bool _attentionPeekDismissed = false;
  bool? _permissionApproved;
  bool _expandedWaitingHapticsActive = false;
  bool _completionPulse = false;
  int _demoWordIndex = 0;
  int _selectedSidebarExample = 0;
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
    _loadingCloudController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    );
    AiService.instance.configurationRevision
        .addListener(_handleAiConfigurationChanged);
    unawaited(refreshCurrentModelName());
  }

  // --- Getters ---
  List<AiChatTurn> get chatTurns => _chatTurns;
  List<AssistantConversation> get conversations => _conversations;
  String? get conversationId => _conversationId;
  int get selectedSidebarExample => _selectedSidebarExample;
  AssistantAccessRecord? get pendingAccess => _pendingAccess;
  AssistantAccessRecord? get activeAuditRecord => _activeAuditRecord;
  bool get isGenerating => _isGenerating;
  bool get isLoadingCloudVisible => _isLoadingCloudVisible;
  AnimationController get loadingCloudAnimation => _loadingCloudController;
  bool get hasCompletedResponse => _hasCompletedResponse;
  bool get permissionPending => _permissionPending;
  bool get showPermissionBadge => _showPermissionBadge;
  bool get attentionPeekDismissed => _attentionPeekDismissed;
  bool? get permissionApproved => _permissionApproved;
  bool get completionPulse => _completionPulse;
  bool get autoApproveDataRequests => _autoApproveDataRequests;
  String? get currentModelName => _currentModelName;
  AiChatTurn? get copiedTurn => _copiedTurn;

  String get activeConversationTitle {
    if (!useLiveAi || _conversationId == null) return '';
    for (final conversation in _conversations) {
      if (conversation.id == _conversationId) return conversation.title;
    }
    return '';
  }

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

  void initializeAssistant(AssistantChatService assistant, AssistantHistoryRepository history) {
    if (_assistantInitialized) return;
    _assistantInitialized = true;
    _assistant = assistant;
    _history = history;
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
    if (_history == null) return;
    try {
      final loaded = await _history!.conversations();
      if (_isDisposed) return;
      _conversations = loaded;
      notifyListeners();
      if (_conversationId == null && loaded.isNotEmpty) {
        await openConversation(loaded.first.id);
      }
    } catch (error) {
      if (!_isDisposed) debugPrint('[Assistant] Could not load history: $error');
    }
  }

  Future<void> openConversation(String id) async {
    stopGeneration();
    final cancellation = _activeGenerationCancellation;
    if (cancellation != null) await cancellation;
    if (_isDisposed || _history == null) return;

    final locale = localeGetter();
    await _history!.recoverInterruptedConversation(id, locale: locale);
    var messages = await _history!.messages(id);
    var pending = await _history!.latestAccess(id, status: 'pending');
    if (pending != null &&
        DateTime.now().toUtc().difference(pending.requestedAt) >
            AssistantChatService.approvalLifetime) {
      final isDe = locale.toLowerCase().startsWith('de');
      await _history!.expireAccess(pending.id);
      await _history!.addMessage(
        conversationId: id,
        role: 'assistant',
        content: isDe
            ? 'Die Datenanfrage ist abgelaufen. Es wurden keine App-Daten gesendet.'
            : 'Data request expired. No app data was sent.',
        status: 'complete',
      );
      messages = await _history!.messages(id);
      pending = null;
    }
    final accesses = await _history!.accessForConversation(id);
    final accessByMessage = {
      for (final access in accesses) access.messageId: access,
    };
    if (_isDisposed) return;

    final turns = <AiChatTurn>[];
    for (final message in messages) {
      if (message.role == 'user') {
        turns.add(AiChatTurn(message.content)
          ..userMessageId = message.id
          ..access = accessByMessage[message.id]);
      } else if (turns.isNotEmpty) {
        turns.last.response = message.content;
        turns.last.modelName =
            formatModelDisplayName(message.providerId, message.modelId);
        turns.last.assistantMessageId = message.id;
      }
    }

    final restoredPending = pending;
    _conversationId = id;
    _activeAuditRecord = null;
    _chatTurns
      ..clear()
      ..addAll(turns);
    _pendingAccess = restoredPending;
    _pendingQuestion = restoredPending == null
        ? null
        : turns
            .where((turn) => turn.userMessageId == restoredPending.messageId)
            .map((turn) => turn.prompt)
            .firstOrNull;
    _permissionPending = restoredPending != null;
    _showPermissionBadge = restoredPending != null;
    _permissionApproved = null;
    _selectedSidebarExample =
        _conversations.indexWhere((item) => item.id == id);
    notifyListeners();
    onScrollToBottom?.call(force: true);
  }

  void selectSidebarExample(int index) {
    if (useLiveAi) {
      if (index >= 0 && index < _conversations.length) {
        unawaited(openConversation(_conversations[index].id));
      }
      return;
    }
    _selectedSidebarExample = index;
    notifyListeners();
  }

  void startNewChat() {
    if (useLiveAi) {
      _conversationId = null;
      _pendingAccess = null;
      _pendingQuestion = null;
    }
    _activeGenerationId++;
    _responseTimer?.cancel();
    _responseTimer = null;
    _cancelActiveResponseSubscription();
    _loadingCloudEnterFuture = null;
    _loadingCloudController.value = 0;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    _permissionBadgeDelayTimer?.cancel();
    _completionPulseTimer?.cancel();
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;

    _chatTurns.clear();
    _isLoadingCloudVisible = false;
    _isGenerating = false;
    _hasCompletedResponse = false;
    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    _attentionPeekDismissed = false;
    _completionPulse = false;
    _demoWordIndex = 0;
    _selectedSidebarExample = -1;
    notifyListeners();

    _syncDemoWaitingHaptics();
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
    _responseTimer?.cancel();
    _responseTimer = null;
    _cancelActiveResponseSubscription();
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;

    final turn = AiChatTurn(prompt)
      ..generationStartedAt = DateTime.now()
      ..modelName = 'Demo';

    _permissionBadgeDelayTimer?.cancel();
    _chatTurns.add(turn);
    _isLoadingCloudVisible = true;
    _isGenerating = true;
    _hasCompletedResponse = false;
    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    _demoWordIndex = 0;
    notifyListeners();

    _loadingCloudEnterFuture = _loadingCloudController.forward(from: 0.0);
    _syncDemoWaitingHaptics();
    onGenerationChanged?.call(true);
    onScrollToBottom?.call(force: true);

    unawaited(_startDemoStreamingAfterLoadingCloud(generationId));
  }

  Future<void> _sendAssistantPrompt(String prompt) async {
    if (_isGenerating) stopGeneration();
    final service = _assistant;
    if (service == null) return;
    final locale = localeGetter();
    final isDe = locale.toLowerCase().startsWith('de');

    if (_permissionPending) {
      final skippedAccess = _pendingAccess;
      _pendingAccess = null;
      _pendingQuestion = null;
      _permissionPending = false;
      _showPermissionBadge = false;
      if (skippedAccess != null) {
        unawaited(
          service
              .deny(skippedAccess.id, locale: locale)
              .then((_) => refreshTurnAccess(skippedAccess.id))
              .catchError((Object _) {}),
        );
      }
    }

    final generationId = ++_activeGenerationId;
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;
    final turn = AiChatTurn(prompt)
      ..generationStartedAt = DateTime.now()
      ..modelName = _currentModelName;

    _activeAuditRecord = null;
    _chatTurns.add(turn);
    _isGenerating = true;
    _isLoadingCloudVisible = true;
    _hasCompletedResponse = false;
    _permissionApproved = null;
    notifyListeners();

    unawaited(_resolveCurrentModelName().then((name) {
      if (_isDisposed) return;
      _currentModelName = name;
      turn.modelName ??= name;
      notifyListeners();
    }));

    _syncDemoWaitingHaptics();
    onGenerationChanged?.call(true);
    _loadingCloudEnterFuture = _loadingCloudController.forward(from: 0.0);
    onScrollToBottom?.call(force: true);

    try {
      final submission = await service.submit(
        prompt,
        conversationId: _conversationId,
        now: DateTime.now(),
        locale: locale,
      );
      if (_isDisposed || _activeGenerationId != generationId) return;

      turn.userMessageId = submission.userMessage.id;
      turn.access = submission.access;
      turn.modelName =
          formatModelDisplayName(submission.providerId, submission.modelId) ??
              _currentModelName ??
              turn.modelName;

      await _reverseLoadingCloudToNothing(generationId);
      if (_isDisposed || _activeGenerationId != generationId) return;

      if (submission.access != null) {
        _conversationId = submission.conversationId;
        _pendingAccess = submission.access;
        _pendingQuestion = prompt;
        _permissionPending = true;
        _showPermissionBadge = true;
        _attentionPeekDismissed = false;
        _isGenerating = false;
        _isLoadingCloudVisible = false;
        notifyListeners();

        _syncDemoWaitingHaptics();
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
      await _reverseLoadingCloudToNothing(generationId);
      if (_isDisposed || _activeGenerationId != generationId) return;

      turn.response = isDe
          ? 'Diese Anfrage konnte nicht verarbeitet werden: $error'
          : 'Could not save this question: $error';
      _isGenerating = false;
      _isLoadingCloudVisible = false;
      notifyListeners();

      _syncDemoWaitingHaptics();
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
    if (access == null || question == null || _assistant == null) return;
    final locale = localeGetter();

    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = approved;
    _pendingAccess = null;
    _pendingQuestion = null;
    notifyListeners();

    if (!approved) {
      unawaited(
        _assistant!.deny(access.id, locale: locale).then((message) {
          if (_isDisposed || _chatTurns.isEmpty) return;
          _chatTurns.last.response = message.content;
          if (_chatTurns.last.generationStartedAt != null) {
            _chatTurns.last.duration = DateTime.now()
                .difference(_chatTurns.last.generationStartedAt!);
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
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;
    _isGenerating = true;
    _isLoadingCloudVisible = true;
    _permissionApproved = null;
    _hasCompletedResponse = false;
    _attentionPeekDismissed = false;
    if (_chatTurns.isNotEmpty) {
      _chatTurns.last.generationStartedAt = DateTime.now();
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

    _loadingCloudEnterFuture = _loadingCloudController.forward(from: 0.0);
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.lightImpact());
    onGenerationChanged?.call(true);
    onScrollToBottom?.call(force: true);

    final bufferedChunks = <String>[];
    var dismissingCloud = false;
    var streamDone = false;
    Object? streamError;

    Future<void> flushAfterCloudDismiss() async {
      if (dismissingCloud) return;
      dismissingCloud = true;
      try {
        await _reverseLoadingCloudToNothing(generationId);
      } finally {
        dismissingCloud = false;
      }
      if (_isDisposed || _activeGenerationId != generationId) return;

      if (bufferedChunks.isNotEmpty && _chatTurns.isNotEmpty) {
        _chatTurns.last.response += bufferedChunks.join();
        bufferedChunks.clear();
        notifyListeners();
        _triggerWordHapticIfNeeded(_chatTurns.last.response);
        onScrollToBottom?.call();
      }
      if (streamError != null) {
        if (_chatTurns.isNotEmpty) {
          _chatTurns.last.response += '\n\n$streamError';
          notifyListeners();
        }
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
      } else if (streamDone) {
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
        unawaited(_loadAssistantHistory());
      }
    }

    _liveResponseSubscription = _assistant!
        .approveAndAnswer(access.id, question, locale: locale)
        .listen(
      (chunk) {
        if (_isDisposed ||
            _activeGenerationId != generationId ||
            _chatTurns.isEmpty) {
          return;
        }
        if (_isLoadingCloudVisible || dismissingCloud) {
          bufferedChunks.add(chunk);
          unawaited(flushAfterCloudDismiss());
          return;
        }
        _chatTurns.last.response += chunk;
        notifyListeners();
        _triggerWordHapticIfNeeded(_chatTurns.last.response);
        onScrollToBottom?.call();
      },
      onError: (Object error) {
        if (_isDisposed ||
            _activeGenerationId != generationId ||
            _chatTurns.isEmpty) {
          return;
        }
        streamError = error;
        if (_isLoadingCloudVisible || dismissingCloud) {
          unawaited(flushAfterCloudDismiss());
          return;
        }
        _chatTurns.last.response += '\n\n$error';
        notifyListeners();
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
      },
      onDone: () {
        if (_isDisposed || _activeGenerationId != generationId) return;
        streamDone = true;
        if (_isLoadingCloudVisible || dismissingCloud) {
          unawaited(flushAfterCloudDismiss());
          return;
        }
        _completeDemoGeneration();
        unawaited(refreshTurnAccess(access.id));
        unawaited(_loadAssistantHistory());
      },
    );
  }

  void _resolveDemoPermission(bool approved) {
    if (approved) {
      _permissionBadgeDelayTimer?.cancel();
      _permissionBadgeDelayTimer = null;
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = true;
      _hasCompletedResponse = false;
      _attentionPeekDismissed = false;
      _isGenerating = true;
      notifyListeners();

      _syncDemoWaitingHaptics();
      unawaited(HapticFeedbackService.instance.lightImpact());
      onGenerationChanged?.call(true);
      _startDemoResponseTicker();
      _permissionContinuationTimer = Timer(
        const Duration(seconds: 3),
        _completeDemoGeneration,
      );
      onScrollToBottom?.call();
      return;
    }

    _permissionPending = false;
    _showPermissionBadge = false;
    _permissionApproved = false;
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = null;
    notifyListeners();
    onScrollToBottom?.call();
  }

  Future<void> refreshTurnAccess(String accessId) async {
    final access = await _history?.access(accessId);
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

  Future<void> _startDemoStreamingAfterLoadingCloud(int generationId) async {
    try {
      final enterFuture = _loadingCloudEnterFuture;
      if (enterFuture != null) await enterFuture;
      if (_isDisposed || _activeGenerationId != generationId || !_isGenerating) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 360));
      if (_isDisposed || _activeGenerationId != generationId || !_isGenerating) {
        return;
      }
      await _loadingCloudController.reverse();
    } catch (_) {}
    if (_isDisposed || _activeGenerationId != generationId || !_isGenerating) {
      return;
    }
    _isLoadingCloudVisible = false;
    notifyListeners();
    _startDemoResponseTicker();
  }

  Future<void> _reverseLoadingCloudToNothing(
    int generationId, {
    bool waitForEnter = true,
  }) async {
    if (!_isLoadingCloudVisible) return;
    try {
      if (_loadingCloudController.value > 0.001) {
        final enterFuture = _loadingCloudEnterFuture;
        if (waitForEnter && enterFuture != null) await enterFuture;
        if (_isDisposed || _activeGenerationId != generationId) return;
        await _loadingCloudController.reverse();
      } else {
        _loadingCloudController.stop();
        _loadingCloudController.value = 0;
      }
    } catch (_) {}
    if (_isDisposed || _activeGenerationId != generationId) return;
    _isLoadingCloudVisible = false;
    notifyListeners();
  }

  void stopGeneration() {
    if (!_isGenerating) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    _cancelActiveResponseSubscription();
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;

    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null && lastTurn.duration == null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??=
          useLiveAi ? (_currentModelName ?? 'KI') : 'Demo';
      if (lastTurn.response.isEmpty) {
        final isDe = localeGetter().toLowerCase().startsWith('de');
        lastTurn.response = isDe
            ? 'Anfrage abgebrochen. Du kannst es erneut versuchen.'
            : 'Request interrupted. You can try again.';
      }
    }

    _isGenerating = false;
    notifyListeners();

    if (_isLoadingCloudVisible) {
      unawaited(
        _reverseLoadingCloudToNothing(generationId, waitForEnter: false),
      );
    }
    _syncDemoWaitingHaptics();
    onGenerationChanged?.call(false);
  }

  void _completeDemoGeneration() {
    if (!_isGenerating) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    _cancelActiveResponseSubscription();
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;

    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??=
          useLiveAi ? (_currentModelName ?? 'KI') : 'Demo';
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

    if (_isLoadingCloudVisible) {
      unawaited(_reverseLoadingCloudToNothing(generationId));
    }
    _permissionBadgeDelayTimer?.cancel();
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.strongImpact());
    onGenerationChanged?.call(false);
    onScrollToBottom?.call();
    if (_completionPulse) _scheduleCompletionPulseReset();
  }

  void finishDemoGeneration() => _completeDemoGeneration();

  void requestDemoPermission() {
    if (useLiveAi || !_isGenerating || _chatTurns.isEmpty) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;

    _isGenerating = false;
    _hasCompletedResponse = false;
    _permissionPending = true;
    _attentionPeekDismissed = false;
    _showPermissionBadge = false;
    _permissionApproved = null;
    notifyListeners();

    if (_isLoadingCloudVisible) {
      unawaited(_reverseLoadingCloudToNothing(generationId));
    }
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        if (_isDisposed || !_permissionPending) return;
        _showPermissionBadge = true;
        notifyListeners();
      },
    );
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.strongImpact());
    onGenerationChanged?.call(false);
    onScrollToBottom?.call();
  }

  void _startDemoResponseTicker() {
    _responseTimer?.cancel();
    _responseTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (_isDisposed || !_isGenerating || _chatTurns.isEmpty) {
        timer.cancel();
        return;
      }
      final turn = _chatTurns.last;
      turn.response += '${_demoWords[_demoWordIndex]} ';
      _demoWordIndex = (_demoWordIndex + 1) % _demoWords.length;
      if (_demoWordIndex == 0) turn.response += '\n\n';
      notifyListeners();

      _triggerWordHapticIfNeeded(turn.response);
      onScrollToBottom?.call();
    });
  }

  void _cancelActiveResponseSubscription() {
    final subscription = _liveResponseSubscription;
    _liveResponseSubscription = null;
    if (subscription != null) {
      _activeGenerationCancellation =
          subscription.cancel().catchError((Object _) {});
    }
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

  void syncDemoWaitingHaptics() => _syncDemoWaitingHaptics();

  void _syncDemoWaitingHaptics() {
    final haptics = HapticFeedbackService.instance;
    final isExpanded = isExpandedGetter();

    if (!_isGenerating || isExpanded) {
      _collapsedWaitingHapticTimer?.cancel();
      _collapsedWaitingHapticTimer = null;
      if (_expandedWaitingHapticsActive) {
        _expandedWaitingHapticsActive = false;
        haptics.stopAiWaiting();
      }
      return;
    }

    if (_expandedWaitingHapticsActive) {
      _expandedWaitingHapticsActive = false;
      haptics.stopAiWaiting();
    }
    if (_collapsedWaitingHapticTimer == null) {
      unawaited(haptics.lightImpact());
      _collapsedWaitingHapticTimer = Timer.periodic(
        const Duration(milliseconds: 1450),
        (_) => unawaited(haptics.lightImpact()),
      );
    }
  }

  void _triggerWordHapticIfNeeded(String responseText) {
    final wordCount = _wordPattern.allMatches(responseText).length;
    if (wordCount <= _lastHapticWordCount) return;
    _lastHapticWordCount = wordCount;
    if (!isExpandedGetter()) return;
    final now = DateTime.now();
    final last = _lastWordHapticAt;
    if (last != null && now.difference(last).inMilliseconds < 28) {
      return;
    }
    _lastWordHapticAt = now;
    unawaited(HapticFeedbackService.instance.selectionFeedback());
  }

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

  void retryTurnPrompt(AiChatTurn turn, {required ValueChanged<String> onFillPrompt}) {
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
    AiService.instance.configurationRevision
        .removeListener(_handleAiConfigurationChanged);
    _responseTimer?.cancel();
    _cancelActiveResponseSubscription();
    _copiedTurnTimer?.cancel();
    _permissionContinuationTimer?.cancel();
    _completionPulseTimer?.cancel();
    _permissionBadgeDelayTimer?.cancel();
    _collapsedWaitingHapticTimer?.cancel();
    if (_expandedWaitingHapticsActive) {
      HapticFeedbackService.instance.stopAiWaiting();
    }
    _loadingCloudController.dispose();
    super.dispose();
  }
}
