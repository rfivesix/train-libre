import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/permission_dialogs.dart';
import '../../../diary/domain/repositories/diary_repository.dart';
import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../../profile/domain/repositories/goal_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../steps/data/steps_aggregation_repository.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../../../settings/presentation/ai_settings_screen.dart';
import '../../application/assistant_chat_service.dart';
import '../../../../services/voice/voice_dictation_service.dart';
import '../../data/assistant_diary_actions.dart';
import '../../data/assistant_database_snapshot_reader.dart';
import '../../data/assistant_health_actions.dart';
import '../../data/assistant_history_repository.dart';
import '../../data/assistant_training_actions.dart';
import '../../domain/assistant_data_action.dart';
import '../ai_global_cloud_presentation.dart';

import 'cloud_overlay/cloud_chat_coordinator.dart';
import 'cloud_overlay/ai_chat_camera_screen.dart';
import 'cloud_overlay/cloud_chat_turn_list_view.dart';
import 'cloud_overlay/cloud_docking_controller.dart';
import 'cloud_overlay/cloud_overlay_access_audit_modal.dart';
import 'cloud_overlay/cloud_overlay_composer.dart';
import 'cloud_overlay/cloud_overlay_geometry.dart';
import 'cloud_overlay/cloud_overlay_header_toolbar.dart';
import 'cloud_overlay/cloud_overlay_prompt_suggestions.dart';
import 'cloud_overlay/cloud_overlay_sidebar.dart';
import 'cloud_overlay/cloud_scroll_sidebar_controller.dart';
import 'cloud_overlay/cloud_voice_controller.dart';
import 'cloud_overlay/header_glass_button.dart';

export 'cloud_overlay/ai_chat_turn.dart';
export 'cloud_overlay/cloud_overlay_geometry.dart' show SafeSpaceCorner;
export 'cloud_overlay/cloud_overlay_header_toolbar.dart'
    show AssistantMenuAction;

class DraggableAiCloud extends StatefulWidget {
  final String semanticLabel;
  final String semanticHint;
  final double liveliness;
  final ValueChanged<bool>? onFullscreenChanged;
  final ValueChanged<bool>? onExpandedChanged;
  final ValueChanged<bool>? onGenerationChanged;
  final bool showResizeHandles;
  final bool openDirectlyFullscreen;
  final bool useLiveAi;
  final bool isGloballyVisible;
  final bool isLauncherEnabled;
  final AssistantModelClient? modelClient;
  final GlobalKey<NavigatorState>? navigatorKey;
  final NavigatorState? navigator;

  const DraggableAiCloud({
    super.key,
    required this.semanticLabel,
    required this.semanticHint,
    required this.liveliness,
    this.onFullscreenChanged,
    this.onExpandedChanged,
    this.onGenerationChanged,
    this.showResizeHandles = true,
    this.openDirectlyFullscreen = false,
    this.useLiveAi = false,
    this.isGloballyVisible = true,
    this.isLauncherEnabled = true,
    this.modelClient,
    this.navigatorKey,
    this.navigator,
  });

  @override
  DraggableAiCloudState createState() => DraggableAiCloudState();
}

class DraggableAiCloudState extends State<DraggableAiCloud>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isClosing = false;
  bool _isClosingFromFullscreen = false;
  bool _showChatPreview = false;
  bool _isFullscreen = false;
  bool _assistantInitialized = false;
  Timer? _cloudHoldTimer;
  int? _cloudHoldPointer;
  Offset? _cloudHoldOrigin;
  bool _cloudPointerIsDown = false;
  bool _holdToTalkActivated = false;
  bool _holdToTalkPermissionFlow = false;
  bool _holdReleasedBeforeRecording = false;
  bool _holdToTalkConversationPending = false;
  DateTime? _chatClosedAt;
  bool _suppressNextOrbTap = false;
  final Stopwatch _holdRecordingDuration = Stopwatch();
  int _lastChatOpenRequest = 0;
  Offset? _quickChatOpenOriginCenter;
  Offset? _lastQuickChatActionCenter;
  Offset? _quickChatMenuExitGlobalCenter;
  bool _wasAddMenuOpen = false;
  bool _quickChatTargetWasAvailable = false;
  bool _isQuickChatTargetStaged = false;
  bool _isQuickChatMenuExitAnimating = false;

  void _handleAddMenuStateChanged() {
    if (!mounted) return;
    final isOpen = AiGlobalCloudPresentation.isAddMenuOpen.value;
    if (_wasAddMenuOpen &&
        !isOpen &&
        !widget.isLauncherEnabled &&
        _quickChatOpenOriginCenter == null) {
      _quickChatMenuExitGlobalCenter =
          AiGlobalCloudPresentation.quickChatActionCenter.value ??
          _lastQuickChatActionCenter;
      _isQuickChatMenuExitAnimating = _quickChatMenuExitGlobalCenter != null;
    } else if (isOpen) {
      _isQuickChatMenuExitAnimating = false;
      _quickChatMenuExitGlobalCenter = null;
    }
    _wasAddMenuOpen = isOpen;
    setState(() {});
  }

  void _handleQuickChatTargetChanged() {
    if (!mounted) return;
    final target = AiGlobalCloudPresentation.quickChatActionCenter.value;
    final targetIsAvailable = target != null;
    if (target != null) _lastQuickChatActionCenter = target;
    if (!widget.isLauncherEnabled &&
        targetIsAvailable &&
        !_quickChatTargetWasAvailable &&
        _quickChatOpenOriginCenter == null &&
        !_isExpanded) {
      // First align the invisible cloud to the action row, then reveal it on
      // the next frame. This keeps its entrance horizontal at the action's
      // height instead of animating from the old dock position.
      _isQuickChatTargetStaged = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isQuickChatTargetStaged) return;
        setState(() => _isQuickChatTargetStaged = false);
      });
    }
    _quickChatTargetWasAvailable = targetIsAvailable;
    setState(() {});
  }

  void _handleChatOpenRequest() {
    final requestCount = AiGlobalCloudPresentation.chatOpenRequests.value;
    if (requestCount == _lastChatOpenRequest) return;
    _lastChatOpenRequest = requestCount;
    if (mounted && !_isExpanded) _toggleExpanded();
  }

  static const Duration _holdToTalkDelay = Duration(milliseconds: 360);
  static const Duration _holdToTalkSafeWindow = Duration(milliseconds: 1500);

  final _chatInputController = TextEditingController();
  final _chatFocusNode = FocusNode(debugLabel: 'ai-overlay-composer');
  final _chatInputScrollController = ScrollController();
  final _chatAddImageButtonKey = GlobalKey();
  final List<File> _draftImageAttachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  AnimationController? _morphController;
  AnimationController? _fullscreenController;
  CurvedAnimation? _curvedMorphAnimation;

  late final CloudDockingController _dockingController;
  late final CloudVoiceController _voiceController;
  late final CloudScrollSidebarController _scrollSidebarController;
  late final CloudChatCoordinator _chatCoordinator;

  AnimationController get _morphAnimation =>
      _morphController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      )..addListener(_onMorphAnimationTick);

  AnimationController get _fullscreenAnimation =>
      _fullscreenController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      )..addListener(_onFullscreenAnimationTick);

  CurvedAnimation get _morphProgressAnimation =>
      _curvedMorphAnimation ??= CurvedAnimation(
        parent: _morphAnimation,
        curve: overlayMorphCurve,
        reverseCurve: overlayMorphCurve,
      );

  @override
  void initState() {
    super.initState();
    _lastChatOpenRequest = AiGlobalCloudPresentation.chatOpenRequests.value;
    _wasAddMenuOpen = AiGlobalCloudPresentation.isAddMenuOpen.value;
    _lastQuickChatActionCenter =
        AiGlobalCloudPresentation.quickChatActionCenter.value;
    _quickChatTargetWasAvailable = _lastQuickChatActionCenter != null;
    AiGlobalCloudPresentation.isAddMenuOpen.addListener(
      _handleAddMenuStateChanged,
    );
    AiGlobalCloudPresentation.quickChatActionCenter.addListener(
      _handleQuickChatTargetChanged,
    );
    AiGlobalCloudPresentation.chatOpenRequests.addListener(
      _handleChatOpenRequest,
    );

    _dockingController = CloudDockingController(vsync: this)
      ..addListener(_handleControllerTick);

    _scrollSidebarController = CloudScrollSidebarController(
      vsync: this,
      isFullscreenGetter: () => _isFullscreen,
      morphAnimationGetter: () => _morphAnimation,
      onUnfocus: () {
        _chatFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
        );
      },
      onToggleExpanded: _toggleExpanded,
    )..addListener(_handleControllerTick);

    _chatCoordinator = CloudChatCoordinator(
      vsync: this,
      useLiveAi: widget.useLiveAi,
      modelClient: widget.modelClient,
      onGenerationChanged: widget.onGenerationChanged,
      onScrollToBottom: ({bool force = false}) =>
          _scrollSidebarController.scrollChatToBottom(force: force),
      onShowMessage: (message, {actionLabel, onAction}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            action: actionLabel != null && onAction != null
                ? SnackBarAction(label: actionLabel, onPressed: onAction)
                : null,
          ),
        );
      },
      isExpandedGetter: () => _isExpanded,
      isDockedSettledGetter: () =>
          !_isExpanded && _morphAnimation.value <= 0.005,
      localeGetter: () =>
          mounted ? Localizations.localeOf(context).toLanguageTag() : 'de',
      canRestoreInitialConversation: () =>
          _chatInputController.text.trim().isEmpty &&
          _draftImageAttachments.isEmpty &&
          !_voiceController.isActive,
    )..addListener(_handleControllerTick);

    _voiceController = CloudVoiceController(
      vsync: this,
      onUnfocus: () {
        _chatFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
        );
      },
      getBaseText: () => _chatInputController.text,
      onCommitText: (text, {required bool sendNow}) {
        if (sendNow && _holdToTalkConversationPending) {
          _holdToTalkConversationPending = false;
          _chatCoordinator.startNewChat();
        }
        _chatInputController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        if (sendNow) _sendPromptFromComposer();
      },
      onShowMessage: (message) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(message)));
      },
    )..addListener(_handleControllerTick);
  }

  void _handleControllerTick() {
    if (mounted) setState(() {});
  }

  void _onFullscreenAnimationTick() {
    if (mounted) setState(() {});
  }

  void _onMorphAnimationTick() {
    if (mounted && _isFullscreen) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureAssistantInitialized();
  }

  void _ensureAssistantInitialized() {
    if (widget.useLiveAi && !_assistantInitialized) {
      try {
        final workouts = context.read<IWorkoutRepository>();
        final diary = context.read<IDiaryRepository>();
        final profile = context.read<IProfileRepository>();
        final goals = context.read<IGoalRepository>();

        _assistantInitialized = true;
        final database = DatabaseHelper.instance.dbInstance;
        final history = AssistantHistoryRepository(database);
        final assistant = AssistantChatService(
          history: history,
          data: AssistantDataGateway([
            AssistantComprehensiveDataAction(
              reader: AssistantDatabaseSnapshotReader(database),
              actions: [
                AssistantTrainingActions(
                  workouts: workouts,
                  database: database,
                ),
                AssistantDiaryActions(diary),
                AssistantHealthActions(
                  database: database,
                  steps: HealthStepsAggregationRepository(),
                  profile: profile,
                  goals: goals,
                ),
              ],
            ),
          ]),
          diaryRepository: diary,
          model: widget.modelClient ?? const ConfiguredAssistantModelClient(),
        );
        _chatCoordinator.initializeAssistant(assistant, history);
      } catch (e) {
        // Repositories may not be present in widget tests or minimal host trees.
        debugPrint(
          '[DraggableAiCloud] Assistant initialization postponed or skipped: $e',
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant DraggableAiCloud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useLiveAi != widget.useLiveAi) {
      if (widget.useLiveAi) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureAssistantInitialized();
        });
      }
      if (_chatCoordinator.isGenerating) {
        _chatCoordinator.stopGeneration();
      }
    }
  }

  @override
  void dispose() {
    AiGlobalCloudPresentation.isAddMenuOpen.removeListener(
      _handleAddMenuStateChanged,
    );
    AiGlobalCloudPresentation.quickChatActionCenter.removeListener(
      _handleQuickChatTargetChanged,
    );
    AiGlobalCloudPresentation.chatOpenRequests.removeListener(
      _handleChatOpenRequest,
    );
    _cloudHoldTimer?.cancel();
    _voiceController.dispose();
    _chatCoordinator.dispose();
    _scrollSidebarController.dispose();
    _dockingController.dispose();
    _chatInputController.dispose();
    _chatFocusNode.dispose();
    _chatInputScrollController.dispose();
    _curvedMorphAnimation?.dispose();
    _morphController?.dispose();
    _fullscreenController?.dispose();
    super.dispose();
  }

  /// Ends the current demo response without requesting more permissions.
  void finishDemoGeneration() => _chatCoordinator.finishDemoGeneration();

  /// Pauses the current demo response and shows a simulated permission request.
  void requestDemoPermission() => _chatCoordinator.requestDemoPermission();

  void _toggleExpanded() {
    _dockingController.stopInitialDock();
    final expanding = !_isExpanded;
    if (expanding &&
        _chatClosedAt != null &&
        DateTime.now().difference(_chatClosedAt!) >=
            CloudChatCoordinator.conversationInactivityLimit &&
        _chatInputController.text.trim().isEmpty &&
        _draftImageAttachments.isEmpty &&
        !_chatCoordinator.isGenerating &&
        !_chatCoordinator.isLoadingCloudVisible &&
        !_chatCoordinator.permissionPending &&
        !_voiceController.isActive) {
      _chatCoordinator.startNewChat();
    }
    if (!expanding) _chatClosedAt = DateTime.now();
    if (expanding && _chatCoordinator.hasCompletedResponse) {
      _chatCoordinator.clearCompletedPulse();
    }
    final wasFullscreen = _isFullscreen;
    final openFullscreen = expanding && widget.openDirectlyFullscreen;
    final hasExistingMessages = _chatCoordinator.chatTurns.isNotEmpty;
    final hasInsertedPrompt = _chatInputController.text.trim().isNotEmpty;
    final isWorking =
        _chatCoordinator.isGenerating ||
        _chatCoordinator.isLoadingCloudVisible ||
        _voiceController.isActive;
    final isNewChat = !hasExistingMessages && !hasInsertedPrompt && !isWorking;

    if (expanding) {
      if (!isNewChat) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      unawaited(_chatCoordinator.refreshCurrentModelName());
    } else {
      _chatFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    }
    setState(() {
      _isExpanded = expanding;
      _isClosing = !expanding;
      _isClosingFromFullscreen = !expanding && wasFullscreen;
      if (!expanding) _chatCoordinator.clearActiveAudit();
      _isFullscreen = expanding ? openFullscreen : wasFullscreen;
      _showChatPreview = expanding;
    });
    _dockingController.onExpandToggle(expanding: expanding);
    _chatCoordinator.syncDemoWaitingHaptics();
    if (expanding) {
      widget.onExpandedChanged?.call(true);
      widget.onFullscreenChanged?.call(openFullscreen);
      final morphOpening = _morphAnimation.forward();
      final fullscreenOpening = openFullscreen
          ? _fullscreenAnimation.forward(from: 0)
          : Future<void>.value();
      unawaited(
        Future.wait<void>([morphOpening, fullscreenOpening])
            .then((_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(_focusNewChatComposer());
              });
            })
            .catchError((_) {
              // Animation was cancelled or interrupted.
            }),
      );
    } else {
      _morphAnimation.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isClosing = false;
          if (!wasFullscreen) _quickChatOpenOriginCenter = null;
          if (wasFullscreen) _isFullscreen = false;
        });
        _scrollSidebarController.sidebarAnimation.value = 0;
        if (wasFullscreen) {
          _fullscreenAnimation.reverse().whenComplete(() {
            if (mounted) {
              setState(() {
                _isClosingFromFullscreen = false;
                _quickChatOpenOriginCenter = null;
              });
            }
          });
        }
        _chatFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
        );
        widget.onFullscreenChanged?.call(false);
        widget.onExpandedChanged?.call(false);
      });
    }
  }

  Future<void> _focusNewChatComposer() async {
    if (!mounted || !_isExpanded || _isClosing) return;
    if (_morphAnimation.value < 0.99) return;
    final hasExistingMessages = _chatCoordinator.chatTurns.isNotEmpty;
    final hasInsertedPrompt = _chatInputController.text.trim().isNotEmpty;
    final isWorking =
        _chatCoordinator.isGenerating ||
        _chatCoordinator.isLoadingCloudVisible ||
        _voiceController.isActive;
    final isNewChat = !hasExistingMessages && !hasInsertedPrompt && !isWorking;
    if (!isNewChat) return;

    // Wait for the composer to finish its current rebuild before requesting
    // focus. The focus change expands the TextField, so wait one more frame for
    // EditableText to attach its iOS input connection before explicitly showing
    // the keyboard. Don't toggle focus off when it is already focused: that
    // races the keyboard-dismiss animation on repeated New Chat taps.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_isExpanded || _isClosing) return;
    if (!_chatFocusNode.hasFocus) _chatFocusNode.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_isExpanded || _isClosing || !_chatFocusNode.hasFocus) {
      return;
    }
    final editableText = _chatFocusNode.context
        ?.findAncestorStateOfType<EditableTextState>();
    if (editableText != null) {
      editableText.requestKeyboard();
    } else {
      unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
    }
  }

  void _toggleFullscreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    final expand = !_isFullscreen;
    setState(() {
      _isFullscreen = expand;
      if (expand) {
        _isExpanded = true;
        _showChatPreview = true;
      }
    });
    if (expand) {
      widget.onExpandedChanged?.call(true);
      widget.onFullscreenChanged?.call(true);
      _morphAnimation.forward();
      _fullscreenAnimation.forward(from: _fullscreenAnimation.value);
    } else {
      _fullscreenAnimation.reverse().whenComplete(() {
        if (mounted) widget.onFullscreenChanged?.call(false);
      });
    }
  }

  void _handleCloudPointerDown(PointerDownEvent event) {
    if (_isExpanded || _cloudHoldPointer != null) return;
    _cloudHoldPointer = event.pointer;
    _cloudHoldOrigin = event.position;
    _cloudPointerIsDown = true;
    _holdToTalkActivated = false;
    _holdReleasedBeforeRecording = false;
    _cloudHoldTimer?.cancel();
    _cloudHoldTimer = Timer(_holdToTalkDelay, () {
      if (!mounted || !_cloudPointerIsDown || _holdToTalkActivated) return;
      _holdToTalkActivated = true;
      _holdToTalkConversationPending = true;
      unawaited(_startCloudHoldRecording(context));
    });
  }

  void _handleCloudPointerMove(PointerMoveEvent event) {
    if (event.pointer != _cloudHoldPointer || _holdToTalkActivated) return;
    final origin = _cloudHoldOrigin;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
      _cloudHoldTimer?.cancel();
    }
  }

  void _handleCloudPointerEnd(PointerEvent event, {required bool cancelled}) {
    if (event.pointer != _cloudHoldPointer) return;
    _cloudPointerIsDown = false;
    _cloudHoldTimer?.cancel();
    _cloudHoldTimer = null;
    _cloudHoldPointer = null;
    _cloudHoldOrigin = null;
    if (!_holdToTalkActivated) return;

    _suppressNextOrbTap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressNextOrbTap = false;
    });

    if (_holdToTalkPermissionFlow) {
      // Permission sheets interrupt the original pointer sequence. Once
      // permission is granted, keep recording in the expanded composer where
      // the user can see the transcript and explicitly send or cancel it.
      _holdReleasedBeforeRecording = true;
      return;
    }
    if (cancelled || _voiceController.isStarting) {
      _holdReleasedBeforeRecording = true;
      if (_voiceController.isStarting) return;
      unawaited(_voiceController.cancel());
      _resetHoldToTalk();
      return;
    }
    if (_voiceController.isRecording) {
      unawaited(_finishHoldToTalk());
    } else {
      _resetHoldToTalk();
    }
  }

  Future<void> _startCloudHoldRecording(BuildContext sourceContext) async {
    if (!sourceContext.mounted || !_holdToTalkActivated) return;
    final needsPermission = !await VoiceDictationService.instance
        .hasPermissions();
    if (!sourceContext.mounted) return;

    if (needsPermission) {
      _holdToTalkPermissionFlow = true;
      if (!_isExpanded) _toggleExpanded();
      final l10n = AppLocalizations.of(sourceContext)!;
      final proceed = await showPrePermissionDialog(
        context: sourceContext,
        title: l10n.voicePermissionTitle,
        body: l10n.voicePermissionBody,
        continueLabel: l10n.voicePermissionContinue,
        cancelLabel: l10n.cancel,
      );
      if (!sourceContext.mounted || !proceed) {
        _holdToTalkPermissionFlow = false;
        _resetHoldToTalk();
        return;
      }
    }

    await _voiceController.start(sourceContext);
    if (!mounted) return;
    _holdToTalkPermissionFlow = false;
    if (!_voiceController.isRecording) {
      _resetHoldToTalk();
      return;
    }
    _holdRecordingDuration
      ..reset()
      ..start();
    if (_holdReleasedBeforeRecording && !needsPermission) {
      // A release during recognizer startup is not a useful dictated prompt.
      await _voiceController.cancel();
      _resetHoldToTalk();
    } else if (needsPermission && !_isExpanded) {
      _toggleExpanded();
    }
  }

  Future<void> _finishHoldToTalk() async {
    _holdRecordingDuration.stop();
    if (_holdRecordingDuration.elapsed < _holdToTalkSafeWindow) {
      await _voiceController.cancel();
      _resetHoldToTalk();
      return;
    }

    await _voiceController.send();
    _resetHoldToTalk();
  }

  void _resetHoldToTalk() {
    _cloudHoldTimer?.cancel();
    _cloudHoldTimer = null;
    _cloudHoldPointer = null;
    _cloudHoldOrigin = null;
    _cloudPointerIsDown = false;
    _holdToTalkActivated = false;
    _holdToTalkPermissionFlow = false;
    _holdReleasedBeforeRecording = false;
    _holdToTalkConversationPending = false;
    _holdRecordingDuration.stop();
    _holdRecordingDuration.reset();
  }

  Future<void> _navigateFromOverlay(WidgetBuilder builder) async {
    final wasFullscreen = _isFullscreen;
    if (_isExpanded) {
      _toggleExpanded();
      await _morphAnimation.reverse();
      if (wasFullscreen) await _fullscreenAnimation.reverse();
    }
    if (!mounted) return;
    final routeNavigator =
        widget.navigatorKey?.currentState ?? widget.navigator;
    if (routeNavigator == null) return;
    await routeNavigator.push<void>(MaterialPageRoute<void>(builder: builder));
  }

  void _sendPromptFromComposer() {
    final typedText = _chatInputController.text;
    final images = List<File>.of(_draftImageAttachments);
    if (typedText.trim().isEmpty && images.isEmpty) return;
    final text = typedText.trim().isEmpty
        ? AppLocalizations.of(context)!.aiChatImageQuestion
        : typedText.trim();
    _chatFocusNode.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    _chatInputController.clear();
    setState(_draftImageAttachments.clear);
    _chatCoordinator.sendPrompt(
      text,
      imageFiles: images,
      onRetainedDraft: () {
        if (!mounted) return;
        if (_chatInputController.text.isEmpty && typedText.isNotEmpty) {
          _chatInputController.text = typedText;
        }
        setState(() {
          for (final image in images) {
            if (_draftImageAttachments.length >= 4) break;
            if (!_draftImageAttachments.any(
              (file) => file.path == image.path,
            )) {
              _draftImageAttachments.add(image);
            }
          }
        });
      },
    );
  }

  Future<void> _addChatImages(String source, Rect? sourceRect) async {
    if (_draftImageAttachments.length >= 4) {
      _showChatImageMessage(AppLocalizations.of(context)!.aiChatImageLimit);
      return;
    }
    try {
      final files = <File>[];
      if (source == 'photos') {
        final picked = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1600,
        );
        files.addAll(picked.map((image) => File(image.path)));
      } else if (Platform.isIOS) {
        // The global AI cloud is hosted in the app's root Overlay, outside the
        // Navigator's route Overlay. Insert the camera above that same layer so
        // presenting it does not transition away from (or hide) the chat.
        final overlay = Overlay.of(context, rootOverlay: true);
        final overlayObject = overlay.context.findRenderObject();
        final overlayBox = overlayObject is RenderBox ? overlayObject : null;
        final routeSourceRect = sourceRect != null && overlayBox != null
            ? Rect.fromPoints(
                overlayBox.globalToLocal(sourceRect.topLeft),
                overlayBox.globalToLocal(sourceRect.bottomRight),
              )
            : sourceRect;
        final capturedImage = Completer<File?>();
        late final OverlayEntry cameraOverlay;
        cameraOverlay = OverlayEntry(
          builder: (_) => AiChatCameraOverlay(
            sourceRect: routeSourceRect,
            onComplete: (file) {
              cameraOverlay.remove();
              if (!capturedImage.isCompleted) {
                capturedImage.complete(file);
              }
            },
          ),
        );
        overlay.insert(cameraOverlay);
        final file = await capturedImage.future;
        if (file != null) files.add(file);
      } else {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (picked != null) files.add(File(picked.path));
      }
      if (!mounted || files.isEmpty) return;
      final remaining = 4 - _draftImageAttachments.length;
      if (files.length > remaining) {
        _showChatImageMessage(AppLocalizations.of(context)!.aiChatImageLimit);
      }
      setState(() => _draftImageAttachments.addAll(files.take(remaining)));
    } catch (_) {
      _showChatImageMessage(
        AppLocalizations.of(context)!.aiChatCameraUnavailable,
      );
    }
  }

  void _removeChatImage(File file) {
    setState(() => _draftImageAttachments.remove(file));
  }

  void _showChatImageMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSelectStarterPrompt(String prompt) {
    _chatFocusNode.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    _chatInputController.clear();
    _chatCoordinator.sendPrompt(prompt);
  }

  String? get _askModelHint {
    final modelName = _chatCoordinator.composerModelName;
    if (modelName == null || modelName.isEmpty) return null;
    return AppLocalizations.of(context)!.aiAssistantAskModelHint(modelName);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isAddMenuOpen = AiGlobalCloudPresentation.isAddMenuOpen.value;
        final morphAnimation = _morphAnimation;
        final fullscreenProgress = overlayTransitionProgress(
          _fullscreenAnimation.value,
        );
        final rawMorphProgress = morphAnimation.value
            .clamp(0.0, 1.0)
            .toDouble();
        final morphProgress = _morphProgressAnimation.value;
        final openingClosingProgress = math.min(
          _fullscreenAnimation.value.clamp(0.0, 1.0).toDouble(),
          rawMorphProgress,
        );
        final isWholeCloudTransition =
            (_isFullscreen || _isClosingFromFullscreen) &&
            morphProgress < 0.999;
        final appearanceProgress = isWholeCloudTransition
            ? _isClosing
                  ? overlayTransitionProgress(openingClosingProgress)
                  : openingAppearanceProgress(openingClosingProgress)
            : fullscreenProgress;

        final hasAttentionState =
            _chatCoordinator.permissionPending ||
            _chatCoordinator.hasCompletedResponse;

        final layout = _dockingController.computeLayout(
          constraints: constraints,
          mediaQuery: mediaQuery,
          hasAttentionState: hasAttentionState,
          attentionPeekDismissed: _chatCoordinator.attentionPeekDismissed,
          fullscreenProgress: fullscreenProgress,
        );
        final globalQuickChatCenter =
            AiGlobalCloudPresentation.quickChatActionCenter.value ??
            _quickChatMenuExitGlobalCenter;
        final cloudRenderObject = context.findRenderObject();
        final quickChatCenter = globalQuickChatCenter == null
            ? null
            : cloudRenderObject is RenderBox
            ? cloudRenderObject.globalToLocal(globalQuickChatCenter)
            : globalQuickChatCenter;
        final isAtQuickChatAction =
            isAddMenuOpen && quickChatCenter != null && !_isExpanded;
        final hiddenLauncherCenter = Offset(
          constraints.maxWidth + CloudDockingController.cloudSize / 2 + 12,
          quickChatCenter?.dy ??
              _quickChatOpenOriginCenter?.dy ??
              layout.cloudCenter.dy,
        );
        final restingCloudCenter = widget.isLauncherEnabled
            ? layout.cloudCenter
            : hiddenLauncherCenter;
        final isCloudVisible =
            widget.isGloballyVisible &&
            (widget.isLauncherEnabled ||
                (isAtQuickChatAction && !_isQuickChatTargetStaged) ||
                _quickChatOpenOriginCenter != null ||
                _isQuickChatMenuExitAnimating ||
                _isExpanded ||
                _isClosing ||
                _isClosingFromFullscreen);
        final isReturningFromChat =
            (_isClosing || _isClosingFromFullscreen) &&
            _quickChatOpenOriginCenter != null;
        final activeCloudCenter = isReturningFromChat
            ? Offset.lerp(
                _quickChatOpenOriginCenter,
                restingCloudCenter,
                (1 - _morphProgressAnimation.value).clamp(0.0, 1.0),
              )!
            : _isQuickChatTargetStaged
            ? restingCloudCenter
            : _quickChatOpenOriginCenter ??
                  (isAtQuickChatAction ? quickChatCenter : restingCloudCenter);
        final useExplicitCloudCenter =
            !widget.isLauncherEnabled ||
            _quickChatOpenOriginCenter != null ||
            isAtQuickChatAction ||
            _isQuickChatMenuExitAnimating;
        final cloudLeft = useExplicitCloudCenter
            ? activeCloudCenter.dx - CloudDockingController.cloudSize / 2
            : layout.left;
        final cloudTop = useExplicitCloudCenter
            ? activeCloudCenter.dy - CloudDockingController.cloudSize / 2
            : layout.top;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dockingController.scheduleInitialDockIfNeeded(
            isExpanded: _isExpanded,
          );
        });

        final theme = Theme.of(context);
        final overlaySurface = overlaySurfaceColor(theme, appearanceProgress);
        final overlayForeground = overlayForegroundColor(
          theme,
          appearanceProgress,
        );

        return SizedBox.expand(
          child: AnimatedSlide(
            offset: widget.isGloballyVisible
                ? Offset.zero
                : Offset(layout.position < 0.5 ? -2 : 2, 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: IgnorePointer(
              ignoring: !isCloudVisible,
              child: ExcludeSemantics(
                excluding: !isCloudVisible,
                child: AnimatedOpacity(
                  opacity: isCloudVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: TweenAnimationBuilder<Offset>(
                          tween: Tween<Offset>(
                            begin: Offset(cloudLeft, cloudTop),
                            end: Offset(cloudLeft, cloudTop),
                          ),
                          duration:
                              !isCloudVisible ||
                                  _isQuickChatTargetStaged ||
                                  _isClosingFromFullscreen ||
                                  _dockingController.isDragging ||
                                  (_isClosing &&
                                      _quickChatOpenOriginCenter != null) ||
                                  _dockingController
                                      .initialDockAnimation
                                      .isAnimating
                              ? Duration.zero
                              : Duration(
                                  milliseconds:
                                      isAtQuickChatAction ||
                                          _isQuickChatMenuExitAnimating
                                      ? 380
                                      : 260,
                                ),
                          curve: Curves.easeOutCubic,
                          onEnd: () {
                            if (!mounted || !_isQuickChatMenuExitAnimating) {
                              return;
                            }
                            setState(() {
                              _isQuickChatMenuExitAnimating = false;
                              _quickChatMenuExitGlobalCenter = null;
                            });
                          },
                          builder: (context, animatedOffset, _) {
                            final animatedLeft = animatedOffset.dx;
                            final animatedTop = animatedOffset.dy;
                            final edgeHitSlop =
                                isCloudVisible &&
                                    morphAnimation.value <= 0.005 &&
                                    !isAtQuickChatAction &&
                                    !_dockingController.isDragging &&
                                    ((animatedLeft - layout.minLeft).abs() <
                                            1 ||
                                        (animatedLeft - layout.maxLeft).abs() <
                                            1)
                                ? 10.0
                                : 0.0;
                            final animatedCloudCenter = Offset(
                              animatedLeft +
                                  CloudDockingController.cloudSize / 2,
                              animatedTop +
                                  CloudDockingController.cloudSize / 2,
                            );
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedBuilder(
                                  animation: morphAnimation,
                                  builder: (context, _) {
                                    final isSettledOrb =
                                        !_isExpanded &&
                                        morphAnimation.value <= 0.005;
                                    // Keep the recording treatment strictly on the
                                    // settled compact orb. Disable it on the first frame
                                    // of opening and restore it only after closing ends.
                                    final showVoiceOrb =
                                        _voiceController.isActive &&
                                        isSettledOrb;
                                    final voiceOrbIntensity = showVoiceOrb
                                        ? 1.0
                                        : 0.0;
                                    final cloud = AiNeuralCloudOrbWidget(
                                      size:
                                          CloudDockingController.cloudSize *
                                          _dockingController.scale *
                                          (_chatCoordinator.completionPulse &&
                                                  isSettledOrb
                                              ? 1.12
                                              : 1.0),
                                      rotation:
                                          _dockingController.rotationRadians,
                                      canvasSize: isSettledOrb
                                          ? null
                                          : layout.viewportSize,
                                      cloudCenter: isSettledOrb
                                          ? null
                                          : animatedCloudCenter,
                                      frameRect: layout.activeSafeRect,
                                      baseColor: overlaySurface,
                                      // The painter applies the transition curve to this
                                      // raw progress itself. Passing the already-curved
                                      // animation here would ease the cloud frame twice
                                      // and make it lag behind the overlay content.
                                      frameMorphAnimation: morphAnimation,
                                      edgeBlurSigma: 4,
                                      showDetachedSatellite: false,
                                      flowSpeed: _dockingController.isDragging
                                          ? 1.55
                                          : _voiceController.isActive
                                          ? 0.55 +
                                                _voiceController
                                                    .latestVoiceLevel
                                          : _chatCoordinator.isGenerating
                                          ? 0.9
                                          : (1.0 *
                                                    widget.liveliness.clamp(
                                                      0.0,
                                                      1.0,
                                                    ))
                                                .clamp(0.1, 1.2),
                                      forceHighFrameRate:
                                          _dockingController.isDragging ||
                                          _chatCoordinator.isGenerating ||
                                          _voiceController.isActive ||
                                          _chatCoordinator.completionPulse ||
                                          !isSettledOrb,
                                      animate: !_isClosing,
                                      accentColor: showVoiceOrb
                                          ? DesignConstants.brandRedColor
                                          : _chatCoordinator
                                                    .permissionPending &&
                                                isSettledOrb
                                          ? Colors.amber.shade700
                                          : null,
                                      // Keep the normal organic cloud silhouette while
                                      // speaking; morph 0 collapses this widget to a circle.
                                      morph: 1,
                                      energy: showVoiceOrb
                                          ? _voiceController.latestVoiceLevel *
                                                voiceOrbIntensity
                                          : _chatCoordinator.completionPulse &&
                                                isSettledOrb
                                          ? 0.75
                                          : 0,
                                      tint: showVoiceOrb
                                          ? 0.4 * voiceOrbIntensity
                                          : !isSettledOrb
                                          ? null
                                          : _chatCoordinator.isGenerating
                                          ? 0.4
                                          : _chatCoordinator.permissionPending
                                          ? 0.62
                                          : _chatCoordinator
                                                .hasCompletedResponse
                                          ? 1.0
                                          : null,
                                      tintEnergyGain: showVoiceOrb
                                          ? 0.4 * voiceOrbIntensity
                                          : 0,
                                      showAmbientGlow: showVoiceOrb,
                                      enableInteraction: false,
                                      hitTestCloudShape: true,
                                      cloudHitTestPadding: edgeHitSlop,
                                    );
                                    return Positioned(
                                      left: isSettledOrb ? animatedLeft : 0,
                                      top: isSettledOrb ? animatedTop : 0,
                                      child: IgnorePointer(
                                        ignoring: morphAnimation.value > 0.001,
                                        child: Semantics(
                                          label: widget.semanticLabel,
                                          hint: widget.semanticHint,
                                          child: Listener(
                                            onPointerDown:
                                                _handleCloudPointerDown,
                                            onPointerMove:
                                                _handleCloudPointerMove,
                                            onPointerUp: (event) =>
                                                _handleCloudPointerEnd(
                                                  event,
                                                  cancelled: false,
                                                ),
                                            onPointerCancel: (event) =>
                                                _handleCloudPointerEnd(
                                                  event,
                                                  cancelled: true,
                                                ),
                                            child: GestureDetector(
                                              behavior:
                                                  HitTestBehavior.deferToChild,
                                              onTap:
                                                  morphAnimation.value > 0.001
                                                  ? null
                                                  : () {
                                                      if (_suppressNextOrbTap) {
                                                        _suppressNextOrbTap =
                                                            false;
                                                        return;
                                                      }
                                                      if (isAtQuickChatAction &&
                                                          AiGlobalCloudPresentation
                                                                  .onQuickChatTap !=
                                                              null) {
                                                        _quickChatOpenOriginCenter =
                                                            quickChatCenter;
                                                        setState(() {});
                                                        AiGlobalCloudPresentation
                                                            .onQuickChatTap!();
                                                      } else {
                                                        _toggleExpanded();
                                                      }
                                                    },
                                              onPanStart:
                                                  morphAnimation.value > 0.001
                                                  ? null
                                                  : (_) {
                                                      if (!_holdToTalkActivated) {
                                                        _cloudHoldTimer
                                                            ?.cancel();
                                                      }
                                                      _dockingController.handleDragStart(
                                                        initialHorizontalPosition:
                                                            layout.position,
                                                        initialVerticalPosition:
                                                            layout
                                                                .verticalPosition,
                                                        onTakeoverAttention: () {
                                                          if (_chatCoordinator
                                                                  .permissionPending ||
                                                              _chatCoordinator
                                                                  .hasCompletedResponse) {
                                                            _chatCoordinator
                                                                .markAttentionPeekDismissed();
                                                          }
                                                        },
                                                      );
                                                    },
                                              onPanUpdate:
                                                  morphAnimation.value > 0.001
                                                  ? null
                                                  : (
                                                      details,
                                                    ) => _dockingController
                                                        .handleDragUpdate(
                                                          details,
                                                          horizontalTravelDistance:
                                                              layout
                                                                  .travelDistance,
                                                          verticalTravelDistance:
                                                              layout
                                                                  .verticalTravelDistance,
                                                        ),
                                              onPanEnd:
                                                  morphAnimation.value > 0.001
                                                  ? null
                                                  : (_) => _dockingController
                                                        .handleDragEnd(
                                                          minLeft:
                                                              layout.minLeft,
                                                          maxLeft:
                                                              layout.maxLeft,
                                                          isExpanded:
                                                              _isExpanded,
                                                        ),
                                              onPanCancel:
                                                  morphAnimation.value > 0.001
                                                  ? null
                                                  : () => _dockingController
                                                        .handleDragEnd(
                                                          minLeft:
                                                              layout.minLeft,
                                                          maxLeft:
                                                              layout.maxLeft,
                                                          isExpanded:
                                                              _isExpanded,
                                                        ),
                                              child: AnimatedScale(
                                                scale: isAtQuickChatAction
                                                    ? 0.84
                                                    : 1,
                                                duration: const Duration(
                                                  milliseconds: 380,
                                                ),
                                                curve: Curves.easeInOutCubic,
                                                child: cloud,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      AnimatedBuilder(
                        animation: morphAnimation,
                        builder: (context, _) {
                          final isSettledOrb =
                              !_isExpanded && morphAnimation.value <= 0.005;
                          if (!_chatCoordinator.permissionPending ||
                              !_chatCoordinator.showPermissionBadge ||
                              !isSettledOrb ||
                              layout.width < 100) {
                            return const SizedBox.shrink();
                          }
                          final l10n = AppLocalizations.of(context)!;
                          const badgeSize = 48.0;
                          final badgeLeft =
                              activeCloudCenter.dx - badgeSize / 2;
                          final badgeTop =
                              (activeCloudCenter.dy - badgeSize / 2)
                                  .clamp(
                                    mediaQuery.padding.top + 4,
                                    layout.viewportHeight -
                                        mediaQuery.padding.bottom -
                                        badgeSize -
                                        4,
                                  )
                                  .toDouble();
                          return AnimatedPositioned(
                            duration:
                                _dockingController.isDragging ||
                                    _dockingController
                                        .initialDockAnimation
                                        .isAnimating
                                ? Duration.zero
                                : const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            left: badgeLeft,
                            top: badgeTop,
                            child: IgnorePointer(
                              child: Semantics(
                                label: l10n.aiOverlayDemoAssistantSection,
                                child: const SizedBox(
                                  width: badgeSize,
                                  height: badgeSize,
                                  child: Icon(
                                    LucideIcons.shield_alert,
                                    size: 38,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (widget.showResizeHandles &&
                          _fullscreenAnimation.value < 0.02) ...[
                        CloudResizeHandle(
                          corner: SafeSpaceCorner.topLeft,
                          position: layout.handlePosition(
                            layout.activeSafeRect.topLeft,
                            const Offset(-1, -1),
                            mediaQuery,
                          ),
                          panelSize: layout.panelRect.size,
                          isExpanded: _isExpanded,
                          morphAnimation: morphAnimation,
                          onPanUpdate: (details) =>
                              _dockingController.resizeSafeSpace(
                                SafeSpaceCorner.topLeft,
                                details,
                                layout.panelRect.size,
                              ),
                        ),
                        CloudResizeHandle(
                          corner: SafeSpaceCorner.topRight,
                          position: layout.handlePosition(
                            layout.activeSafeRect.topRight,
                            const Offset(1, -1),
                            mediaQuery,
                          ),
                          panelSize: layout.panelRect.size,
                          isExpanded: _isExpanded,
                          morphAnimation: morphAnimation,
                          onPanUpdate: (details) =>
                              _dockingController.resizeSafeSpace(
                                SafeSpaceCorner.topRight,
                                details,
                                layout.panelRect.size,
                              ),
                        ),
                        CloudResizeHandle(
                          corner: SafeSpaceCorner.bottomLeft,
                          position: layout.handlePosition(
                            layout.activeSafeRect.bottomLeft,
                            const Offset(-1, 1),
                            mediaQuery,
                          ),
                          panelSize: layout.panelRect.size,
                          isExpanded: _isExpanded,
                          morphAnimation: morphAnimation,
                          onPanUpdate: (details) =>
                              _dockingController.resizeSafeSpace(
                                SafeSpaceCorner.bottomLeft,
                                details,
                                layout.panelRect.size,
                              ),
                        ),
                        CloudResizeHandle(
                          corner: SafeSpaceCorner.bottomRight,
                          position: layout.handlePosition(
                            layout.activeSafeRect.bottomRight,
                            const Offset(1, 1),
                            mediaQuery,
                          ),
                          panelSize: layout.panelRect.size,
                          isExpanded: _isExpanded,
                          morphAnimation: morphAnimation,
                          onPanUpdate: (details) =>
                              _dockingController.resizeSafeSpace(
                                SafeSpaceCorner.bottomRight,
                                details,
                                layout.panelRect.size,
                              ),
                        ),
                      ],
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          morphAnimation,
                          _scrollSidebarController.sidebarAnimation,
                        ]),
                        builder: (context, _) {
                          final currentMorphProgress =
                              _morphProgressAnimation.value;
                          final revealProgress = currentMorphProgress;
                          final collapsedBounds = Rect.fromCenter(
                            center: activeCloudCenter,
                            width: 120,
                            height: 120,
                          );
                          final contentRevealBounds = Rect.lerp(
                            collapsedBounds,
                            layout.activeSafeRect.inflate(64),
                            revealProgress,
                          )!;
                          final sidebarWidth = _scrollSidebarController
                              .sidebarWidth(layout.width);

                          return Positioned.fill(
                            child: IgnorePointer(
                              ignoring: morphAnimation.value <= 0.001,
                              child: ClipRect(
                                clipper: CloudControlsClipper(
                                  contentRevealBounds,
                                ),
                                child: Opacity(
                                  opacity: revealProgress,
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: _scrollSidebarController
                                        .handleSidebarPointerDown,
                                    onPointerMove: (event) =>
                                        _scrollSidebarController
                                            .handleSidebarPointerMove(
                                              event,
                                              sidebarWidth,
                                            ),
                                    onPointerUp: _scrollSidebarController
                                        .finishSidebarPointer,
                                    onPointerCancel: _scrollSidebarController
                                        .finishSidebarPointer,
                                    child: Stack(
                                      children: [
                                        if (_scrollSidebarController
                                                .sidebarAnimation
                                                .value >
                                            0.001)
                                          CloudOverlaySidebar(
                                            viewportWidth: layout.width,
                                            sidebarProgress:
                                                _scrollSidebarController
                                                    .sidebarAnimation
                                                    .value,
                                            sidebarWidth: sidebarWidth,
                                            surfaceColor: overlaySurface,
                                            foregroundColor: overlayForeground,
                                            controlFill: overlayControlFill(
                                              theme,
                                              appearanceProgress,
                                            ),
                                            appearanceProgress:
                                                appearanceProgress,
                                            useLiveAi: widget.useLiveAi,
                                            conversations:
                                                _chatCoordinator.conversations,
                                            selectedIndex: _chatCoordinator
                                                .selectedSidebarExample,
                                            onSelectConversation: (index) {
                                              _scrollSidebarController
                                                  .closeSidebar();
                                              _chatCoordinator
                                                  .selectSidebarExample(index);
                                            },
                                            onToggleSidebar:
                                                _scrollSidebarController
                                                    .toggleSidebar,
                                          ),
                                        Positioned.fill(
                                          key: const ValueKey(
                                            'cloud-overlay-main-content',
                                          ),
                                          child: Transform.translate(
                                            offset: Offset(
                                              _scrollSidebarController
                                                      .sidebarAnimation
                                                      .value *
                                                  sidebarWidth,
                                              0,
                                            ),
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap:
                                                  _scrollSidebarController
                                                          .sidebarAnimation
                                                          .value >
                                                      0
                                                  ? _scrollSidebarController
                                                        .closeSidebar
                                                  : null,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      32 *
                                                          _scrollSidebarController
                                                              .sidebarAnimation
                                                              .value,
                                                    ),
                                                child: Transform.scale(
                                                  scale: currentMorphProgress,
                                                  alignment: Alignment(
                                                    2 *
                                                            activeCloudCenter
                                                                .dx /
                                                            layout
                                                                .viewportSize
                                                                .width -
                                                        1,
                                                    2 *
                                                            activeCloudCenter
                                                                .dy /
                                                            layout
                                                                .viewportSize
                                                                .height -
                                                        1,
                                                  ),
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      _buildChatContent(
                                                        layout: layout,
                                                        theme: theme,
                                                        fullscreenProgress:
                                                            fullscreenProgress,
                                                        appearanceProgress:
                                                            appearanceProgress,
                                                      ),
                                                      CloudOverlayHeaderToolbar(
                                                        safeRect: layout
                                                            .activeSafeRect,
                                                        fullscreenProgress:
                                                            fullscreenProgress,
                                                        appearanceProgress:
                                                            appearanceProgress,
                                                        surfaceColor:
                                                            overlaySurface,
                                                        foregroundColor:
                                                            overlayForeground,
                                                        controlFill:
                                                            overlayControlFill(
                                                              theme,
                                                              appearanceProgress,
                                                            ),
                                                        isExpanded: _isExpanded,
                                                        isFullscreen:
                                                            _isFullscreen,
                                                        hasChatTurns:
                                                            _chatCoordinator
                                                                .chatTurns
                                                                .isNotEmpty,
                                                        activeConversationTitle:
                                                            _chatCoordinator
                                                                .activeConversationTitle,
                                                        autoApproveDataRequests:
                                                            _chatCoordinator
                                                                .autoApproveDataRequests,
                                                        useStaticGlass:
                                                            _isClosing ||
                                                            (_isExpanded &&
                                                                morphAnimation
                                                                        .value <
                                                                    1),
                                                        onToggleSidebar:
                                                            _scrollSidebarController
                                                                .toggleSidebar,
                                                        onToggleFullscreen:
                                                            _toggleFullscreen,
                                                        onStartNewChat: () {
                                                          if (_scrollSidebarController
                                                                  .sidebarAnimation
                                                                  .value >
                                                              0) {
                                                            _scrollSidebarController
                                                                .closeSidebar();
                                                          }
                                                          _chatCoordinator
                                                              .startNewChat();
                                                          _chatInputController
                                                              .clear();
                                                          WidgetsBinding.instance.addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            if (!mounted ||
                                                                !_isExpanded) {
                                                              return;
                                                            }
                                                            if (_scrollSidebarController
                                                                .chatScrollController
                                                                .hasClients) {
                                                              _scrollSidebarController
                                                                  .chatScrollController
                                                                  .jumpTo(0);
                                                            }
                                                            unawaited(
                                                              _focusNewChatComposer(),
                                                            );
                                                          });
                                                        },
                                                        onToggleAutoApprove:
                                                            () => unawaited(
                                                              _chatCoordinator
                                                                  .toggleAutoApproveDataRequests(),
                                                            ),
                                                        onOpenSettings: () {
                                                          unawaited(
                                                            _navigateFromOverlay(
                                                              (_) =>
                                                                  const AiSettingsScreen(),
                                                            ),
                                                          );
                                                        },
                                                        onToggleExpanded:
                                                            _toggleExpanded,
                                                        onHeaderDragStart:
                                                            _scrollSidebarController
                                                                .handleHeaderDragStart,
                                                        onHeaderDragUpdate:
                                                            _scrollSidebarController
                                                                .handleHeaderDragUpdate,
                                                        onHeaderDragEnd:
                                                            _scrollSidebarController
                                                                .handleHeaderDragEnd,
                                                      ),
                                                      if (_scrollSidebarController
                                                              .sidebarAnimation
                                                              .value >
                                                          0)
                                                        Positioned.fill(
                                                          child: GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onTap:
                                                                _scrollSidebarController
                                                                    .closeSidebar,
                                                            child: ColoredBox(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha:
                                                                        0.55 *
                                                                        _scrollSidebarController
                                                                            .sidebarAnimation
                                                                            .value,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_chatCoordinator.activeAuditRecord != null)
                        CloudOverlayAccessAuditModal(
                          access: _chatCoordinator.activeAuditRecord!,
                          onClose: _chatCoordinator.clearActiveAudit,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatContent({
    required CloudOverlayLayout layout,
    required ThemeData theme,
    required double fullscreenProgress,
    required double appearanceProgress,
  }) {
    final appIsDark = theme.brightness == Brightness.dark;
    final contrastColor = overlayForegroundColor(theme, appearanceProgress);
    final surfaceColor = overlaySurfaceColor(theme, appearanceProgress);
    final selectionBlue = appIsDark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
    final cloudSurfaceDark = surfaceColor.computeLuminance() < 0.5;
    final softColor = contrastColor.withValues(
      alpha: cloudSurfaceDark ? 0.10 : 0.08,
    );
    final isGlassTransitioning =
        _isClosing || (_isExpanded && _morphAnimation.value < 1);
    const contentInset = 8.0;

    final chatBounds = Rect.lerp(
      layout.safeRect.inflate(44),
      layout.fullscreenRect.deflate(12),
      fullscreenProgress,
    )!;
    final contentLeft = chatBounds.left + contentInset;
    final contentRight =
        MediaQuery.sizeOf(context).width - chatBounds.right + contentInset;
    final composerLeft = chatBounds.left;
    final composerRight = MediaQuery.sizeOf(context).width - chatBounds.right;
    final fullscreenContentTop = MediaQuery.paddingOf(context).top + 70;
    final chatTop =
        layout.safeRect.top +
        16 +
        (fullscreenContentTop - layout.safeRect.top - 16) * fullscreenProgress;
    final scrollViewportTop = chatBounds.top;
    final toolbarTop =
        (layout.safeRect.top - 62) +
        (MediaQuery.paddingOf(context).top + 10 - (layout.safeRect.top - 62)) *
            fullscreenProgress;
    final toolbarButtonCenter = toolbarTop + 28;
    final topFadeEnd =
        toolbarButtonCenter +
        (chatTop - toolbarButtonCenter) * fullscreenProgress;
    final clippedTop = layout.safeRect.top - 64;
    final topFadeStart =
        clippedTop + (scrollViewportTop - clippedTop) * fullscreenProgress;
    final topFadeHoldStop = 0.45 * (1 - fullscreenProgress);
    final bottomFadeHeight = 104.0 * (1 - fullscreenProgress);
    final chatBottom = chatBounds.bottom - contentInset;
    final contentViewportBottom =
        chatBounds.bottom +
        (layout.viewportHeight - chatBounds.bottom) * fullscreenProgress;

    final composerBaseColor = appIsDark
        ? DesignConstants.glassNeutralTint(true)
        : Colors.black.withValues(alpha: 0.04);
    final composerTargetColor = appIsDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.04);
    final composerFillColor = Color.lerp(
      composerBaseColor,
      composerTargetColor,
      appearanceProgress,
    )!;
    final surfaceIsLight = surfaceColor.computeLuminance() >= 0.5;
    final sendButtonBackground = surfaceIsLight ? Colors.black : Colors.white;
    final sendButtonForeground = surfaceIsLight ? Colors.white : Colors.black;
    final controlFillColor = overlayControlFill(theme, appearanceProgress);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring:
            !_isExpanded ||
            !_showChatPreview ||
            _scrollSidebarController.sidebarAnimation.value > 0.001,
        child: Stack(
          children: [
            Positioned(
              left: contentLeft,
              right: contentRight,
              top: topFadeStart,
              bottom:
                  layout.bottomOcclusion +
                  layout.viewportHeight -
                  contentViewportBottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CloudChatTurnListView(
                      scrollController:
                          _scrollSidebarController.chatScrollController,
                      latestMessageEndKey:
                          _scrollSidebarController.latestMessageEndKey,
                      chatTurns: _chatCoordinator.chatTurns,
                      permissionPending: _chatCoordinator.permissionPending,
                      permissionApproved: _chatCoordinator.permissionApproved,
                      pendingAccess: _chatCoordinator.pendingAccess,
                      isGenerating: _chatCoordinator.isGenerating,
                      isLoadingCloudVisible:
                          _chatCoordinator.isLoadingCloudVisible,
                      loadingCloudAnimation:
                          _chatCoordinator.loadingCloudAnimation,
                      copiedTurn: _chatCoordinator.copiedTurn,
                      useLiveAi: widget.useLiveAi,
                      onNavigate: _navigateFromOverlay,
                      theme: theme,
                      contrastColor: contrastColor,
                      surfaceColor: surfaceColor,
                      softColor: softColor,
                      chatTop: chatTop,
                      topFadeStart: topFadeStart,
                      topFadeEnd: topFadeEnd,
                      topFadeHoldStop: topFadeHoldStop,
                      chatBottom: chatBottom,
                      bottomFadeHeight: bottomFadeHeight,
                      fullscreenProgress: fullscreenProgress,
                      onResolvePermission: _chatCoordinator.resolvePermission,
                      onCopyResponse: (turn) =>
                          _chatCoordinator.copyResponseMarkdown(turn),
                      onCopyFullChat: _chatCoordinator.copyFullChatMarkdown,
                      onRetryPrompt: (turn) {
                        _chatInputController.clear();
                        _chatCoordinator.retryTurnPrompt(turn);
                      },
                      onShowAccessAudit: _chatCoordinator.showAccessAudit,
                      onResolveProposal: _chatCoordinator.resolveChangeProposal,
                      onIncrementUserScrollRevision:
                          _scrollSidebarController.incrementUserScrollRevision,
                      onScrollMetricsChanged: _scrollSidebarController
                          .refreshChatScrollStateAfterLayout,
                      onPermissionCardSizeEnd: () {
                        if (_scrollSidebarController.followChatTail) {
                          _scrollSidebarController.scrollChatToBottom();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: composerLeft,
              right: composerRight,
              bottom:
                  layout.bottomOcclusion +
                  layout.viewportHeight -
                  chatBounds.bottom +
                  contentInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.bottomCenter,
                    child: _scrollSidebarController.showScrollToBottom
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: HeaderGlassButton(
                              icon: LucideIcons.arrow_down,
                              tooltip: 'Zum neuesten Beitrag',
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: controlFillColor,
                              foregroundColor: contrastColor,
                              useStaticGlass: isGlassTransitioning,
                              onPressed: _scrollSidebarController
                                  .scrollToLatestMessage,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _chatCoordinator,
                      _chatInputController,
                      _voiceController,
                    ]),
                    builder: (context, _) {
                      final showStarterPrompts =
                          _chatCoordinator.chatTurns.isEmpty &&
                          !_chatCoordinator.isGenerating &&
                          !_chatCoordinator.isLoadingCloudVisible &&
                          !_voiceController.isActive &&
                          _draftImageAttachments.isEmpty &&
                          _chatInputController.text.trim().isEmpty;

                      return AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        sizeCurve: Curves.easeOutCubic,
                        firstCurve: Curves.easeOut,
                        secondCurve: Curves.easeIn,
                        crossFadeState: showStarterPrompts
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: CloudOverlayPromptSuggestions(
                          contrastColor: contrastColor,
                          onSelectPrompt: _handleSelectStarterPrompt,
                        ),
                        secondChild: const SizedBox(
                          width: double.infinity,
                          height: 0,
                        ),
                      );
                    },
                  ),
                  CloudOverlayComposer(
                    key: const ValueKey('cloud-overlay-composer'),
                    chatInputController: _chatInputController,
                    chatFocusNode: _chatFocusNode,
                    chatInputScrollController: _chatInputScrollController,
                    voiceController: _voiceController,
                    isGenerating: _chatCoordinator.isGenerating,
                    isGlassTransitioning: isGlassTransitioning,
                    cloudSurfaceDark: cloudSurfaceDark,
                    surfaceIsLight: surfaceIsLight,
                    contrastColor: contrastColor,
                    composerFillColor: composerFillColor,
                    controlFillColor: controlFillColor,
                    sendButtonBackground: sendButtonBackground,
                    sendButtonForeground: sendButtonForeground,
                    selectionBlue: selectionBlue,
                    askModelHint: _askModelHint,
                    onSendPrompt: _sendPromptFromComposer,
                    onStopGeneration: _chatCoordinator.stopGeneration,
                    imageAttachments: _draftImageAttachments,
                    addImagesButtonKey: _chatAddImageButtonKey,
                    onAddImages: widget.useLiveAi ? _addChatImages : null,
                    onRemoveImage: _removeChatImage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
