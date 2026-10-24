import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
import '../../application/assistant_chat_service.dart';
import '../../../../services/voice/voice_dictation_service.dart';
import '../../data/assistant_diary_actions.dart';
import '../../data/assistant_database_snapshot_reader.dart';
import '../../data/assistant_health_actions.dart';
import '../../data/assistant_history_repository.dart';
import '../../data/assistant_training_actions.dart';
import '../../domain/assistant_data_action.dart';

import 'cloud_overlay/cloud_chat_coordinator.dart';
import 'cloud_overlay/cloud_chat_turn_list_view.dart';
import 'cloud_overlay/cloud_docking_controller.dart';
import 'cloud_overlay/cloud_overlay_access_audit_modal.dart';
import 'cloud_overlay/cloud_overlay_composer.dart';
import 'cloud_overlay/cloud_overlay_geometry.dart';
import 'cloud_overlay/cloud_overlay_header_toolbar.dart';
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
  bool _suppressNextOrbTap = false;
  final Stopwatch _holdRecordingDuration = Stopwatch();

  static const Duration _holdToTalkDelay = Duration(milliseconds: 360);
  static const Duration _holdToTalkSafeWindow = Duration(milliseconds: 1500);

  final _chatInputController = TextEditingController();
  final _chatFocusNode = FocusNode(debugLabel: 'ai-overlay-composer');
  final _chatInputScrollController = ScrollController();

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
        duration: const Duration(milliseconds: 900),
      )..addListener(_onMorphAnimationTick);

  AnimationController get _fullscreenAnimation =>
      _fullscreenController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 560),
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

    _dockingController = CloudDockingController(vsync: this)
      ..addListener(_handleControllerTick);

    _scrollSidebarController = CloudScrollSidebarController(
      vsync: this,
      isFullscreenGetter: () => _isFullscreen,
      morphAnimationGetter: () => _morphAnimation,
      onUnfocus: () => _chatFocusNode.unfocus(),
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
    )..addListener(_handleControllerTick);

    _voiceController = CloudVoiceController(
      vsync: this,
      onUnfocus: () => _chatFocusNode.unfocus(),
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
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(message)),
        );
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
                workouts: context.read<IWorkoutRepository>(),
                database: database,
              ),
              AssistantDiaryActions(context.read<IDiaryRepository>()),
              AssistantHealthActions(
                database: database,
                steps: HealthStepsAggregationRepository(),
                profile: context.read<IProfileRepository>(),
                goals: context.read<IGoalRepository>(),
              ),
            ],
          ),
        ]),
        model: widget.modelClient ?? const ConfiguredAssistantModelClient(),
      );
      _chatCoordinator.initializeAssistant(assistant, history);
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
    if (expanding && _chatCoordinator.hasCompletedResponse) {
      _chatCoordinator.clearCompletedPulse();
    }
    final wasFullscreen = _isFullscreen;
    final openFullscreen = expanding && widget.openDirectlyFullscreen;
    if (expanding) {
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(_chatCoordinator.refreshCurrentModelName());
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
      unawaited(Future.wait<void>([morphOpening, fullscreenOpening]));
    } else {
      _morphAnimation.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isClosing = false;
          if (wasFullscreen) _isFullscreen = false;
        });
        _scrollSidebarController.sidebarAnimation.value = 0;
        if (wasFullscreen) {
          _fullscreenAnimation.reverse().whenComplete(() {
            if (mounted) setState(() => _isClosingFromFullscreen = false);
          });
        }
        FocusManager.instance.primaryFocus?.unfocus();
        widget.onFullscreenChanged?.call(false);
        widget.onExpandedChanged?.call(false);
      });
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
    final needsPermission =
        !await VoiceDictationService.instance.hasPermissions();
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
    await routeNavigator.push<void>(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  void _sendPromptFromComposer() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    _chatFocusNode.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    _chatInputController.clear();
    _chatCoordinator.sendPrompt(text);
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
        final morphAnimation = _morphAnimation;
        final fullscreenProgress =
            overlayTransitionProgress(_fullscreenAnimation.value);
        final rawMorphProgress =
            morphAnimation.value.clamp(0.0, 1.0).toDouble();
        final morphProgress = _morphProgressAnimation.value;
        final openingClosingProgress = math.min(
          _fullscreenAnimation.value.clamp(0.0, 1.0).toDouble(),
          rawMorphProgress,
        );
        final isWholeCloudTransition =
            (_isFullscreen || _isClosingFromFullscreen) &&
                morphProgress < 0.999;
        final appearanceProgress = isWholeCloudTransition
            ? openingAppearanceProgress(openingClosingProgress)
            : fullscreenProgress;

        final hasAttentionState = _chatCoordinator.permissionPending ||
            _chatCoordinator.hasCompletedResponse;

        final layout = _dockingController.computeLayout(
          constraints: constraints,
          mediaQuery: mediaQuery,
          hasAttentionState: hasAttentionState,
          attentionPeekDismissed: _chatCoordinator.attentionPeekDismissed,
          fullscreenProgress: fullscreenProgress,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dockingController.scheduleInitialDockIfNeeded(
            isExpanded: _isExpanded,
          );
        });

        final theme = Theme.of(context);
        final overlaySurface = overlaySurfaceColor(theme, appearanceProgress);
        final overlayForeground =
            overlayForegroundColor(theme, appearanceProgress);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(
                  begin: Offset(layout.left, layout.top),
                  end: Offset(layout.left, layout.top),
                ),
                duration: _dockingController.isDragging ||
                        _dockingController.initialDockAnimation.isAnimating
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, animatedOffset, _) {
                  final animatedLeft = animatedOffset.dx;
                  final animatedTop = animatedOffset.dy;
                  final animatedCloudCenter = Offset(
                    animatedLeft + CloudDockingController.cloudSize / 2,
                    animatedTop + CloudDockingController.cloudSize / 2,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: morphAnimation,
                        builder: (context, _) {
                          final isSettledOrb =
                              !_isExpanded && morphAnimation.value <= 0.005;
                          // Keep the recording treatment strictly on the
                          // settled compact orb. Disable it on the first frame
                          // of opening and restore it only after closing ends.
                          final showVoiceOrb =
                              _voiceController.isActive && isSettledOrb;
                          final voiceOrbIntensity = showVoiceOrb ? 1.0 : 0.0;
                          final cloud = AiNeuralCloudOrbWidget(
                            size: CloudDockingController.cloudSize *
                                _dockingController.scale *
                                (_chatCoordinator.completionPulse &&
                                        isSettledOrb
                                    ? 1.12
                                    : 1.0),
                            rotation: _dockingController.rotationRadians,
                            canvasSize:
                                isSettledOrb ? null : layout.viewportSize,
                            cloudCenter:
                                isSettledOrb ? null : animatedCloudCenter,
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
                                    ? 0.55 + _voiceController.latestVoiceLevel
                                    : _chatCoordinator.isGenerating
                                        ? 0.9
                                        : (1.0 *
                                                widget.liveliness
                                                    .clamp(0.0, 1.0))
                                            .clamp(0.1, 1.2),
                            forceHighFrameRate: _dockingController.isDragging ||
                                _chatCoordinator.isGenerating ||
                                _voiceController.isActive ||
                                _chatCoordinator.completionPulse ||
                                !isSettledOrb,
                            animate: !_isClosing,
                            accentColor: showVoiceOrb
                                ? DesignConstants.brandRedColor
                                : _chatCoordinator.permissionPending &&
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
                            tintEnergyGain:
                                showVoiceOrb ? 0.4 * voiceOrbIntensity : 0,
                            showAmbientGlow: showVoiceOrb,
                            enableInteraction: false,
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
                                  onPointerDown: _handleCloudPointerDown,
                                  onPointerMove: _handleCloudPointerMove,
                                  onPointerUp: (event) =>
                                      _handleCloudPointerEnd(event,
                                          cancelled: false),
                                  onPointerCancel: (event) =>
                                      _handleCloudPointerEnd(event,
                                          cancelled: true),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: morphAnimation.value > 0.001
                                        ? null
                                        : () {
                                            if (_suppressNextOrbTap) {
                                              _suppressNextOrbTap = false;
                                              return;
                                            }
                                            _toggleExpanded();
                                          },
                                    onPanStart: morphAnimation.value > 0.001
                                        ? null
                                        : (_) {
                                            if (!_holdToTalkActivated) {
                                              _cloudHoldTimer?.cancel();
                                            }
                                            _dockingController.handleDragStart(
                                              initialHorizontalPosition:
                                                  layout.position,
                                              initialVerticalPosition:
                                                  layout.verticalPosition,
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
                                    onPanUpdate: morphAnimation.value > 0.001
                                        ? null
                                        : (details) =>
                                            _dockingController.handleDragUpdate(
                                              details,
                                              horizontalTravelDistance:
                                                  layout.travelDistance,
                                              verticalTravelDistance:
                                                  layout.verticalTravelDistance,
                                            ),
                                    onPanEnd: morphAnimation.value > 0.001
                                        ? null
                                        : (_) =>
                                            _dockingController.handleDragEnd(
                                              minLeft: layout.minLeft,
                                              maxLeft: layout.maxLeft,
                                              isExpanded: _isExpanded,
                                            ),
                                    onPanCancel: morphAnimation.value > 0.001
                                        ? null
                                        : () =>
                                            _dockingController.handleDragEnd(
                                              minLeft: layout.minLeft,
                                              maxLeft: layout.maxLeft,
                                              isExpanded: _isExpanded,
                                            ),
                                    child: cloud,
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
                final badgeLeft = layout.cloudCenter.dx - badgeSize / 2;
                final badgeTop = (layout.cloudCenter.dy - badgeSize / 2)
                    .clamp(
                      mediaQuery.padding.top + 4,
                      layout.viewportHeight -
                          mediaQuery.padding.bottom -
                          badgeSize -
                          4,
                    )
                    .toDouble();
                return AnimatedPositioned(
                  duration: _dockingController.isDragging ||
                          _dockingController.initialDockAnimation.isAnimating
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
                onPanUpdate: (details) => _dockingController.resizeSafeSpace(
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
                onPanUpdate: (details) => _dockingController.resizeSafeSpace(
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
                onPanUpdate: (details) => _dockingController.resizeSafeSpace(
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
                onPanUpdate: (details) => _dockingController.resizeSafeSpace(
                  SafeSpaceCorner.bottomRight,
                  details,
                  layout.panelRect.size,
                ),
              ),
            ],
            AnimatedBuilder(
              animation: morphAnimation,
              builder: (context, _) {
                final revealProgress = morphProgress;
                final collapsedBounds = Rect.fromCenter(
                  center: layout.cloudCenter,
                  width: 120,
                  height: 120,
                );
                final contentRevealBounds = Rect.lerp(
                  collapsedBounds,
                  layout.activeSafeRect.inflate(64),
                  revealProgress,
                )!;
                final sidebarWidth =
                    _scrollSidebarController.sidebarWidth(layout.width);

                return Positioned.fill(
                  child: IgnorePointer(
                    ignoring: morphAnimation.value <= 0.001,
                    child: ClipRect(
                      clipper: CloudControlsClipper(contentRevealBounds),
                      child: Opacity(
                        opacity: revealProgress,
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown:
                              _scrollSidebarController.handleSidebarPointerDown,
                          onPointerMove: (event) =>
                              _scrollSidebarController.handleSidebarPointerMove(
                            event,
                            sidebarWidth,
                          ),
                          onPointerUp:
                              _scrollSidebarController.finishSidebarPointer,
                          onPointerCancel:
                              _scrollSidebarController.finishSidebarPointer,
                          child: Stack(
                            children: [
                              if (_scrollSidebarController
                                      .sidebarAnimation.value >
                                  0.001)
                                CloudOverlaySidebar(
                                  viewportWidth: layout.width,
                                  sidebarProgress: _scrollSidebarController
                                      .sidebarAnimation.value,
                                  sidebarWidth: sidebarWidth,
                                  surfaceColor: overlaySurface,
                                  foregroundColor: overlayForeground,
                                  controlFill: overlayControlFill(
                                    theme,
                                    appearanceProgress,
                                  ),
                                  appearanceProgress: appearanceProgress,
                                  useLiveAi: widget.useLiveAi,
                                  conversations: _chatCoordinator.conversations,
                                  selectedIndex:
                                      _chatCoordinator.selectedSidebarExample,
                                  onSelectConversation: (index) {
                                    _scrollSidebarController.closeSidebar();
                                    _chatCoordinator
                                        .selectSidebarExample(index);
                                  },
                                  onToggleSidebar:
                                      _scrollSidebarController.toggleSidebar,
                                ),
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(
                                    _scrollSidebarController
                                            .sidebarAnimation.value *
                                        sidebarWidth,
                                    0,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _scrollSidebarController
                                                .sidebarAnimation.value >
                                            0
                                        ? _scrollSidebarController.closeSidebar
                                        : null,
                                    child: Transform.scale(
                                      scale: morphProgress,
                                      alignment: Alignment(
                                        2 *
                                                layout.cloudCenter.dx /
                                                layout.viewportSize.width -
                                            1,
                                        2 *
                                                layout.cloudCenter.dy /
                                                layout.viewportSize.height -
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
                                            safeRect: layout.activeSafeRect,
                                            fullscreenProgress:
                                                fullscreenProgress,
                                            appearanceProgress:
                                                appearanceProgress,
                                            surfaceColor: overlaySurface,
                                            foregroundColor: overlayForeground,
                                            controlFill: overlayControlFill(
                                              theme,
                                              appearanceProgress,
                                            ),
                                            isExpanded: _isExpanded,
                                            isFullscreen: _isFullscreen,
                                            hasChatTurns: _chatCoordinator
                                                .chatTurns.isNotEmpty,
                                            activeConversationTitle:
                                                _chatCoordinator
                                                    .activeConversationTitle,
                                            autoApproveDataRequests:
                                                _chatCoordinator
                                                    .autoApproveDataRequests,
                                            useStaticGlass: _isClosing ||
                                                (_isExpanded &&
                                                    morphAnimation.value < 1),
                                            onToggleSidebar:
                                                _scrollSidebarController
                                                    .toggleSidebar,
                                            onToggleFullscreen:
                                                _toggleFullscreen,
                                            onStartNewChat: () {
                                              _scrollSidebarController
                                                  .closeSidebar();
                                              _chatCoordinator.startNewChat();
                                              _chatInputController.clear();
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (_scrollSidebarController
                                                    .chatScrollController
                                                    .hasClients) {
                                                  _scrollSidebarController
                                                      .chatScrollController
                                                      .jumpTo(0);
                                                }
                                              });
                                            },
                                            onToggleAutoApprove: () =>
                                                unawaited(
                                              _chatCoordinator
                                                  .toggleAutoApproveDataRequests(),
                                            ),
                                            onToggleExpanded: _toggleExpanded,
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
                                        ],
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
    final selectionBlue =
        appIsDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
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
    final chatTop = layout.safeRect.top +
        16 +
        (fullscreenContentTop - layout.safeRect.top - 16) * fullscreenProgress;
    final scrollViewportTop = chatBounds.top;
    final toolbarTop = (layout.safeRect.top - 62) +
        (MediaQuery.paddingOf(context).top + 10 - (layout.safeRect.top - 62)) *
            fullscreenProgress;
    final toolbarButtonCenter = toolbarTop + 28;
    final topFadeEnd = toolbarButtonCenter +
        (chatTop - toolbarButtonCenter) * fullscreenProgress;
    final clippedTop = layout.safeRect.top - 64;
    final topFadeStart =
        clippedTop + (scrollViewportTop - clippedTop) * fullscreenProgress;
    final topFadeHoldStop = 0.45 * (1 - fullscreenProgress);
    final bottomFadeHeight = 104.0 * (1 - fullscreenProgress);
    final chatBottom = chatBounds.bottom - contentInset;
    final contentViewportBottom = chatBounds.bottom +
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
        ignoring: !_isExpanded ||
            !_showChatPreview ||
            _scrollSidebarController.sidebarAnimation.value > 0.001,
        child: Stack(
          children: [
            Positioned(
              left: contentLeft,
              right: contentRight,
              top: topFadeStart,
              bottom: layout.bottomOcclusion +
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
                      onRetryPrompt: (turn) => _chatCoordinator.retryTurnPrompt(
                        turn,
                        onFillPrompt: (p) => _chatInputController.text = p,
                      ),
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
              bottom: layout.bottomOcclusion +
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
                  CloudOverlayComposer(
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
