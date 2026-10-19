import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/voice/voice_dictation_service.dart';
import '../../../../services/voice/voice_dictation_settings.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../data/ai_overlay_live_chat_service.dart';

/// The existing animated AI cloud, made draggable for the overlay demo.
///
/// Its horizontal and vertical position is interactive and resets when the
/// demo screen is opened again.
enum _AssistantMenuAction { newChat, chatHistory }

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
  });

  @override
  DraggableAiCloudState createState() => DraggableAiCloudState();
}

class DraggableAiCloudState extends State<DraggableAiCloud>
    with TickerProviderStateMixin {
  static const _horizontalInset = DesignConstants.spacingL;
  static const _cloudSize = 160.0;
  static const _visibleEdge = 64.0;
  static const _topGap = 2.0;
  static const _topVisualInset = 28.0;
  // Release within this many logical pixels of a card edge docks the cloud.
  static const _snapThreshold = 48.0;
  static const _scrollToBottomThreshold = 120.0;
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

  double? _horizontalPosition;
  double? _verticalPosition;
  double _rotationRadians = 0;
  double _scale = 1;
  bool _isDragging = false;
  bool _isExpanded = false;
  bool _isClosing = false;
  bool _isClosingFromFullscreen = false;
  bool _showChatPreview = false;
  bool _isFullscreen = false;
  int _selectedSidebarExample = 0;
  double _headerDragDistance = 0;
  double _headerDragStartProgress = 1;
  double _sidebarDragStartProgress = 0;
  Offset? _sidebarPointerStart;
  int? _sidebarPointerId;
  bool _sidebarPointerDragging = false;
  bool _sidebarPastSnapPoint = false;
  double? _sidebarDragStartScrollOffset;
  bool _sidebarDragStartFollowChatTail = true;
  final _chatInputController = TextEditingController();
  final _chatFocusNode = FocusNode(debugLabel: 'ai-overlay-composer');
  final _chatInputScrollController = ScrollController();
  final _chatScrollController = ScrollController();
  final List<_DemoChatTurn> _chatTurns = [];
  Timer? _responseTimer;
  StreamSubscription<String>? _liveResponseSubscription;
  Timer? _liveChunkFlushTimer;
  final List<String> _pendingLiveChunks = <String>[];
  bool _liveStreamCompleted = false;
  String? _pendingLiveError;
  int _activeGenerationId = 0;
  bool _isLoadingCloudVisible = false;
  bool _isLoadingCloudDismissing = false;
  Future<void>? _loadingCloudEnterFuture;
  _DemoChatTurn? _copiedTurn;
  Timer? _copiedTurnTimer;
  Timer? _permissionContinuationTimer;
  Timer? _completionPulseTimer;
  Timer? _permissionBadgeDelayTimer;
  Timer? _collapsedWaitingHapticTimer;
  int _lastHapticWordCount = 0;
  DateTime? _lastWordHapticAt;
  bool _isGenerating = false;
  bool _voiceStarting = false;
  bool _voiceRecording = false;
  bool _voiceStopping = false;
  bool _voiceSimulation = false;
  bool _voiceFinalizing = false;
  bool _sendVoiceAfterStop = false;
  int _voiceSessionId = 0;
  String _voiceBaseText = '';
  String _voiceTranscript = '';
  final List<_VoiceWaveSample> _voiceLevelHistory = <_VoiceWaveSample>[];
  Timer? _voiceSimulationTimer;
  double _latestVoiceLevel = 0;
  int _lastVoiceWaveSampleIndex = 0;
  late final Ticker _voiceWaveTicker;
  late final ValueNotifier<double> _voiceWaveOffset;
  Future<bool>? _iosSimulatorCheck;
  bool _hasCompletedResponse = false;
  bool _permissionPending = false;
  bool _showPermissionBadge = false;
  bool _attentionPeekDismissed = false;
  bool? _permissionApproved;
  bool _expandedWaitingHapticsActive = false;
  bool _completionPulse = false;
  bool _followChatTail = true;
  bool _showScrollToBottom = false;
  int _chatUserScrollRevision = 0;
  int _chatContentRevision = 0;
  int _demoWordIndex = 0;
  double _safeLeft = 0.14;
  double _safeTop = 0.10;
  double _safeRight = 0.86;
  double _safeBottom = 0.90;
  AnimationController? _morphController;
  AnimationController? _fullscreenController;
  late final AnimationController _sidebarController;
  late final AnimationController _initialDockController;
  late final AnimationController _loadingCloudController;
  Timer? _initialDockStartTimer;
  bool _initialDockScheduled = false;
  double _displayedHorizontalPosition = 0;
  String? _currentModelName;

  AnimationController get _morphAnimation =>
      _morphController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 760),
      )..addListener(_onMorphAnimationTick);

  AnimationController get _fullscreenAnimation =>
      _fullscreenController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      )..addListener(_onFullscreenAnimationTick);

  @override
  void initState() {
    super.initState();
    unawaited(_resolveCurrentModelName().then((name) {
      if (mounted) setState(() => _currentModelName = name);
    }));
    _chatScrollController.addListener(_handleChatScroll);
    _initialDockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_handleInitialDockAnimationTick);
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onSidebarAnimationTick);
    _loadingCloudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 460),
    );
    _voiceWaveOffset = ValueNotifier<double>(0);
    _voiceWaveTicker = createTicker((elapsed) {
      const sampleSpacing = 6.0;
      // Scroll continuously at a fixed speed. Samples are placed on exact
      // spacing boundaries derived from this same monotonic position.
      final position = elapsed.inMicroseconds * 0.000045;
      _voiceWaveOffset.value = position;
      final sampleIndex = (position / sampleSpacing).floor();
      if (sampleIndex > _lastVoiceWaveSampleIndex &&
          mounted &&
          (_voiceRecording || _voiceStarting)) {
        setState(() {
          for (var index = _lastVoiceWaveSampleIndex + 1;
              index <= sampleIndex;
              index++) {
            _appendVoiceLevel(_latestVoiceLevel, index * sampleSpacing);
          }
          _lastVoiceWaveSampleIndex = sampleIndex;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableAiCloud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useLiveAi != widget.useLiveAi) {
      if (_isGenerating) {
        _stopDemoGeneration();
      }
      if (widget.useLiveAi &&
          (_permissionPending ||
              _showPermissionBadge ||
              _permissionApproved != null)) {
        _permissionBadgeDelayTimer?.cancel();
        _permissionBadgeDelayTimer = null;
        _permissionContinuationTimer?.cancel();
        _permissionContinuationTimer = null;
        setState(() {
          _permissionPending = false;
          _showPermissionBadge = false;
          _permissionApproved = null;
          _attentionPeekDismissed = false;
        });
      }
    }
  }

  Future<bool> _isIosSimulator() {
    if (!kDebugMode || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future<bool>.value(false);
    }
    return _iosSimulatorCheck ??= DeviceInfoPlugin()
        .iosInfo
        .then((info) => !info.isPhysicalDevice)
        .catchError((Object _) => false);
  }

  Future<void> _startSimulatedVoiceInput(int sessionId) async {
    // Simulate partial speech results and microphone levels only in debug
    // builds running on the iOS Simulator. Physical devices always use the
    // platform recognizer.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || sessionId != _voiceSessionId) return;

    _voiceSimulation = true;
    setState(() {
      _voiceStarting = false;
      _voiceRecording = true;
    });
    _startVoiceWaveAnimation();

    const sample = 'Das ist eine simulierte Spracheingabe im iOS-Simulator.';
    var elapsedMs = 0;
    _voiceSimulationTimer?.cancel();
    _voiceSimulationTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (timer) {
        if (!mounted || sessionId != _voiceSessionId || !_voiceSimulation) {
          timer.cancel();
          return;
        }
        elapsedMs += 80;
        final transcriptCharacters =
            ((elapsedMs - 450) / 34).floor().clamp(0, sample.length);
        final pulse = (math.sin(elapsedMs / 170) + 1) / 2;
        final variation = (math.sin(elapsedMs / 73) + 1) / 2;
        final level = 0.12 + pulse * 0.58 + variation * 0.22;
        setState(() {
          _latestVoiceLevel = level;
          _voiceTranscript = sample.substring(0, transcriptCharacters);
        });
      },
    );
  }

  Future<void> _startVoiceInput() async {
    if (_voiceStarting || _voiceRecording || _voiceStopping) return;

    final sessionId = ++_voiceSessionId;
    _chatFocusNode.unfocus();
    _voiceBaseText = _chatInputController.text.trim();
    _voiceTranscript = '';
    _voiceLevelHistory.clear();
    _latestVoiceLevel = 0;
    _sendVoiceAfterStop = false;
    setState(() {
      _voiceStarting = true;
      _voiceStopping = false;
    });

    final simulateVoice = await _isIosSimulator();
    if (!mounted || sessionId != _voiceSessionId) return;
    if (simulateVoice) {
      await _startSimulatedVoiceInput(sessionId);
      return;
    }

    final service = VoiceDictationService.instance;
    final availability = await service.prepare();
    if (!mounted || sessionId != _voiceSessionId) return;
    if (!availability.available) {
      setState(() => _voiceStarting = false);
      final l10n = AppLocalizations.of(context)!;
      final message = switch (availability.reason) {
        VoiceUnavailableReason.permissionDenied =>
          l10n.voiceUnavailablePermission,
        VoiceUnavailableReason.unsupported => l10n.voiceUnavailableUnsupported,
        _ => l10n.voiceUnavailableFailed,
      };
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final localeId = await VoiceDictationSettings.instance.localeId();
    if (!mounted || sessionId != _voiceSessionId) return;
    final started = await service.start(
      localeId: localeId,
      onPartial: (text) {
        if (!mounted || sessionId != _voiceSessionId) return;
        setState(() => _voiceTranscript = text);
      },
      onFinal: (text) {
        if (!mounted || sessionId != _voiceSessionId) return;
        setState(() => _voiceTranscript = text);
      },
      onSoundLevel: (level) {
        if (!mounted || sessionId != _voiceSessionId) return;
        setState(() {
          _latestVoiceLevel = level;
        });
      },
      onStopped: () => unawaited(_stopVoiceInput(sessionId)),
    );
    if (!mounted || sessionId != _voiceSessionId) {
      if (started) unawaited(service.cancel());
      return;
    }
    if (!started) {
      setState(() => _voiceStarting = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.voiceUnavailableFailed),
        ),
      );
      return;
    }
    if (!service.isListening) {
      unawaited(_stopVoiceInput(sessionId));
      return;
    }
    setState(() {
      _voiceStarting = false;
      _voiceRecording = true;
    });
    _startVoiceWaveAnimation();
    if (service.lastRunUsedNetwork) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.voiceNetworkNotice),
        ),
      );
    }
  }

  Future<void> _stopVoiceInput([int? requestedSessionId]) async {
    final sessionId = requestedSessionId ?? _voiceSessionId;
    if (sessionId != _voiceSessionId || _voiceFinalizing) return;
    if (!_voiceStarting && !_voiceRecording) return;

    _voiceFinalizing = true;
    setState(() {
      _voiceStarting = false;
      _voiceStopping = true;
    });
    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.stop();
    if (!_voiceSimulation) {
      await VoiceDictationService.instance.stop();
    }
    await Future<void>.delayed(
      Duration(milliseconds: _voiceSimulation ? 120 : 450),
    );
    if (!mounted || sessionId != _voiceSessionId) return;

    final dictatedText = _voiceTranscript.trim();
    final combinedText = [
      if (_voiceBaseText.isNotEmpty) _voiceBaseText,
      if (dictatedText.isNotEmpty) dictatedText,
    ].join(' ');
    _chatInputController.value = TextEditingValue(
      text: combinedText,
      selection: TextSelection.collapsed(offset: combinedText.length),
    );
    setState(() {
      _voiceRecording = false;
      _voiceStopping = false;
      _voiceSimulation = false;
    });
    _voiceFinalizing = false;
    final shouldSend = _sendVoiceAfterStop;
    _sendVoiceAfterStop = false;
    if (shouldSend) _sendDemoPrompt();
  }

  void _appendVoiceLevel(double level, double position) {
    _voiceLevelHistory.add(
      _VoiceWaveSample(
        position: position,
        level: level.clamp(0.0, 1.0).toDouble(),
      ),
    );
    if (_voiceLevelHistory.length > 120) _voiceLevelHistory.removeAt(0);
  }

  void _startVoiceWaveAnimation() {
    _voiceWaveOffset.value = 0;
    _voiceLevelHistory.clear();
    _lastVoiceWaveSampleIndex = 0;
    _appendVoiceLevel(_latestVoiceLevel, 0);
    _voiceWaveTicker.start();
  }

  Future<void> _sendVoiceInput() async {
    if (_voiceStopping || (!_voiceStarting && !_voiceRecording)) return;
    if (_voiceFinalizing) {
      _sendVoiceAfterStop = true;
      return;
    }
    _sendVoiceAfterStop = true;
    await _stopVoiceInput();
  }

  Future<void> _cancelVoiceInput() async {
    if (!_voiceStarting && !_voiceRecording && !_voiceStopping) return;
    ++_voiceSessionId;
    _voiceFinalizing = false;
    _sendVoiceAfterStop = false;
    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.stop();
    final wasSimulating = _voiceSimulation;
    setState(() {
      _voiceStarting = false;
      _voiceRecording = false;
      _voiceStopping = false;
      _latestVoiceLevel = 0;
      _voiceTranscript = '';
      _voiceSimulation = false;
    });
    if (!wasSimulating) await VoiceDictationService.instance.cancel();
  }

  @override
  void dispose() {
    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.dispose();
    _voiceWaveOffset.dispose();
    if ((_voiceStarting || _voiceRecording || _voiceStopping) &&
        !_voiceSimulation) {
      unawaited(VoiceDictationService.instance.cancel());
    }
    _responseTimer?.cancel();
    _liveResponseSubscription?.cancel();
    _liveChunkFlushTimer?.cancel();
    _copiedTurnTimer?.cancel();
    _permissionContinuationTimer?.cancel();
    _completionPulseTimer?.cancel();
    _permissionBadgeDelayTimer?.cancel();
    _collapsedWaitingHapticTimer?.cancel();
    if (_expandedWaitingHapticsActive) {
      HapticFeedbackService.instance.stopAiWaiting();
    }
    _chatInputController.dispose();
    _chatFocusNode.dispose();
    _chatInputScrollController.dispose();
    _chatScrollController.dispose();
    _initialDockStartTimer?.cancel();
    _initialDockController.dispose();
    _sidebarController.dispose();
    _loadingCloudController.dispose();
    _morphController?.dispose();
    _fullscreenController?.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    _initialDockStartTimer?.cancel();
    _initialDockStartTimer = null;
    _initialDockController.stop();
    final expanding = !_isExpanded;
    final wasFullscreen = _isFullscreen;
    final openFullscreen = expanding && widget.openDirectlyFullscreen;
    if (expanding) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _horizontalPosition ??= _displayedHorizontalPosition;
      _isExpanded = expanding;
      _isClosing = !expanding;
      _isClosingFromFullscreen = !expanding && wasFullscreen;
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
      _isFullscreen = expanding ? openFullscreen : wasFullscreen;
      _showChatPreview = expanding;
      _hasCompletedResponse = false;
      _completionPulse = false;
    });
    _syncDemoWaitingHaptics();
    if (expanding) {
      widget.onExpandedChanged?.call(true);
      widget.onFullscreenChanged?.call(openFullscreen);
      final morphOpening = _morphAnimation.forward();
      final fullscreenOpening = openFullscreen
          ? _fullscreenAnimation.forward(from: 0)
          : Future<void>.value();
      unawaited(
        Future.wait<void>([morphOpening, fullscreenOpening]),
      );
    } else {
      _morphAnimation.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isClosing = false;
          if (wasFullscreen) _isFullscreen = false;
        });
        _sidebarController.value = 0;
        if (wasFullscreen) {
          _fullscreenAnimation.reverse().whenComplete(() {
            if (mounted) setState(() => _isClosingFromFullscreen = false);
          });
        }
        FocusManager.instance.primaryFocus?.unfocus();
        if (_hasCompletedResponse) {
          setState(() => _completionPulse = true);
          _scheduleCompletionPulseReset();
        }
        widget.onFullscreenChanged?.call(false);
        widget.onExpandedChanged?.call(false);
      });
    }
  }

  void _syncDemoWaitingHaptics() {
    final haptics = HapticFeedbackService.instance;
    if (!_isGenerating) {
      _collapsedWaitingHapticTimer?.cancel();
      _collapsedWaitingHapticTimer = null;
      if (_expandedWaitingHapticsActive) {
        _expandedWaitingHapticsActive = false;
        haptics.stopAiWaiting();
      }
      return;
    }

    if (_isExpanded) {
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

  static final RegExp _wordPattern = RegExp(r'\S+');

  void _triggerWordHapticIfNeeded(String responseText) {
    final wordCount = _wordPattern.allMatches(responseText).length;
    if (wordCount <= _lastHapticWordCount) return;
    _lastHapticWordCount = wordCount;
    if (!_isExpanded) return;
    final now = DateTime.now();
    final last = _lastWordHapticAt;
    if (last != null && now.difference(last).inMilliseconds < 28) {
      return;
    }
    _lastWordHapticAt = now;
    unawaited(HapticFeedbackService.instance.selectionFeedback());
  }

  /// Ends the current demo response without requesting more permissions.
  void finishDemoGeneration() => _completeDemoGeneration();

  /// Pauses the current demo response and shows a simulated permission request.
  void requestDemoPermission() => _requestDemoPermission();

  void _onFullscreenAnimationTick() {
    if (mounted) setState(() {});
  }

  void _onMorphAnimationTick() {
    if (mounted && _isFullscreen) setState(() {});
  }

  void _onSidebarAnimationTick() {
    if (mounted) setState(() {});
  }

  double _sidebarWidth(double viewportWidth) =>
      math.min(viewportWidth * 0.82, 340.0);

  double _openingAppearanceProgress(double progress) {
    const transitionRange = 0.5;
    final transitionProgress =
        (progress / transitionRange).clamp(0.0, 1.0).toDouble();
    return Curves.easeInOutCubic.transform(transitionProgress);
  }

  Color _overlaySurfaceColor(ThemeData theme, double appearanceProgress) {
    final appIsDark = theme.brightness == Brightness.dark;
    final cloudSurface = appIsDark ? Colors.white : Colors.black;
    return Color.lerp(
      cloudSurface,
      theme.scaffoldBackgroundColor,
      appearanceProgress,
    )!;
  }

  Color _overlayForegroundColor(ThemeData theme, double appearanceProgress) {
    final appIsDark = theme.brightness == Brightness.dark;
    final cloudForeground = appIsDark ? Colors.black : Colors.white;
    return Color.lerp(
      cloudForeground,
      theme.colorScheme.onSurface,
      appearanceProgress,
    )!;
  }

  Color _overlayControlFill(ThemeData theme, double appearanceProgress) {
    final appIsDark = theme.brightness == Brightness.dark;
    final cloudFill = appIsDark
        ? DesignConstants.glassNeutralTint(true)
        : Colors.black.withValues(alpha: 0.04);
    final appFill = appIsDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.04);
    return Color.lerp(cloudFill, appFill, appearanceProgress)!;
  }

  void _openSidebar() {
    if (!_isFullscreen) return;
    final chatScrollOffset = _captureChatScrollOffset();
    final shouldFollowChatTail = _followChatTail;
    _chatFocusNode.unfocus();
    _sidebarController.animateTo(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _restoreChatScrollOffsetAfterLayout(
      chatScrollOffset,
      shouldFollowChatTail: shouldFollowChatTail,
    );
  }

  void _toggleSidebar() {
    if (_sidebarController.value > 0.5) {
      final chatScrollOffset = _captureChatScrollOffset();
      final shouldFollowChatTail = _followChatTail;
      _sidebarController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      _restoreChatScrollOffsetAfterLayout(
        chatScrollOffset,
        shouldFollowChatTail: shouldFollowChatTail,
      );
    } else {
      _openSidebar();
    }
  }

  double? _captureChatScrollOffset() => _chatScrollController.hasClients
      ? _chatScrollController.position.pixels
      : null;

  void _restoreChatScrollOffsetAfterLayout(
    double? offset, {
    bool? shouldFollowChatTail,
  }) {
    if (offset == null) return;
    final userScrollRevision = _chatUserScrollRevision;
    final contentRevision = _chatContentRevision;
    final shouldFollowTail = shouldFollowChatTail ?? _followChatTail;

    void restore() {
      if (!mounted ||
          !_chatScrollController.hasClients ||
          _chatUserScrollRevision != userScrollRevision ||
          _chatContentRevision != contentRevision) {
        return;
      }
      final position = _chatScrollController.position;
      final target = shouldFollowTail
          ? position.maxScrollExtent
          : offset
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble();
      if ((position.pixels - target).abs() > 0.5) {
        _chatScrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      restore();
      // The keyboard and the safe-area layout can finish resizing after the
      // sidebar starts moving. Reapply once the viewport has settled too.
      Future<void>.delayed(const Duration(milliseconds: 420), restore);
    });
  }

  void _handleSidebarPointerDown(PointerDownEvent event) {
    if (!_isFullscreen) return;
    _sidebarPointerId = event.pointer;
    _sidebarPointerStart = event.position;
    _sidebarDragStartProgress = _sidebarController.value;
    _sidebarDragStartScrollOffset = _captureChatScrollOffset();
    _sidebarDragStartFollowChatTail = _followChatTail;
    _sidebarPointerDragging = false;
    _sidebarPastSnapPoint = _sidebarController.value >= 0.5;
    _sidebarController.stop();
  }

  void _handleSidebarPointerMove(PointerMoveEvent event, double width) {
    if (event.pointer != _sidebarPointerId || !_isFullscreen) return;
    final start = _sidebarPointerStart;
    if (start == null) return;
    final offset = event.position - start;
    if (!_sidebarPointerDragging) {
      if (offset.dx.abs() < gestures.kTouchSlop ||
          offset.dx.abs() < offset.dy.abs()) {
        return;
      }
      _sidebarPointerDragging = true;
      _chatFocusNode.unfocus();
    }
    final nextProgress = (_sidebarDragStartProgress + offset.dx / width)
        .clamp(0.0, 1.0)
        .toDouble();
    final isPastSnapPoint = nextProgress >= 0.5;
    if (isPastSnapPoint != _sidebarPastSnapPoint) {
      _sidebarPastSnapPoint = isPastSnapPoint;
      unawaited(HapticFeedbackService.instance.selectionFeedback());
    }
    _sidebarController.value = nextProgress;
  }

  void _finishSidebarPointer(PointerEvent event) {
    if (event.pointer != _sidebarPointerId) return;
    if (_sidebarPointerDragging) {
      _sidebarController.animateTo(
        _sidebarController.value >= 0.5 ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      _restoreChatScrollOffsetAfterLayout(
        _sidebarDragStartScrollOffset,
        shouldFollowChatTail: _sidebarDragStartFollowChatTail,
      );
    }
    _sidebarPointerId = null;
    _sidebarPointerStart = null;
    _sidebarPointerDragging = false;
    _sidebarDragStartScrollOffset = null;
    _sidebarDragStartFollowChatTail = true;
  }

  void _selectSidebarExample(int index) {
    final chatScrollOffset = _captureChatScrollOffset();
    final shouldFollowChatTail = _followChatTail;
    setState(() => _selectedSidebarExample = index);
    _sidebarController.reverse();
    _restoreChatScrollOffsetAfterLayout(
      chatScrollOffset,
      shouldFollowChatTail: shouldFollowChatTail,
    );
  }

  void _closeSidebar() {
    final chatScrollOffset = _captureChatScrollOffset();
    final shouldFollowChatTail = _followChatTail;
    _sidebarController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    _restoreChatScrollOffsetAfterLayout(
      chatScrollOffset,
      shouldFollowChatTail: shouldFollowChatTail,
    );
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

  void _handleHeaderDragStart(DragStartDetails details) {
    _headerDragDistance = 0;
    _headerDragStartProgress = _morphAnimation.value;
    _morphAnimation.stop();
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    _headerDragDistance += details.delta.dy;
    _morphAnimation.value =
        (_headerDragStartProgress - _headerDragDistance / 250).clamp(0.0, 1.0);
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    final shouldCollapse = _morphAnimation.value < 0.55 ||
        details.velocity.pixelsPerSecond.dy > 900;
    if (shouldCollapse) {
      _toggleExpanded();
    } else {
      _morphAnimation.forward();
    }
    _headerDragDistance = 0;
  }

  void _resizeSafeSpace(
    _SafeSpaceCorner corner,
    DragUpdateDetails details,
    Size size,
  ) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    const minWidth = 0.34;
    const minHeight = 0.42;
    const edgeInset = 0.04;

    setState(() {
      switch (corner) {
        case _SafeSpaceCorner.topLeft:
          _safeLeft = (_safeLeft + dx)
              .clamp(edgeInset, _safeRight - minWidth)
              .toDouble();
          _safeTop = (_safeTop + dy)
              .clamp(edgeInset, _safeBottom - minHeight)
              .toDouble();
        case _SafeSpaceCorner.topRight:
          _safeRight = (_safeRight + dx)
              .clamp(_safeLeft + minWidth, 1 - edgeInset)
              .toDouble();
          _safeTop = (_safeTop + dy)
              .clamp(edgeInset, _safeBottom - minHeight)
              .toDouble();
        case _SafeSpaceCorner.bottomLeft:
          _safeLeft = (_safeLeft + dx)
              .clamp(edgeInset, _safeRight - minWidth)
              .toDouble();
          _safeBottom = (_safeBottom + dy)
              .clamp(_safeTop + minHeight, 1 - edgeInset)
              .toDouble();
        case _SafeSpaceCorner.bottomRight:
          _safeRight = (_safeRight + dx)
              .clamp(_safeLeft + minWidth, 1 - edgeInset)
              .toDouble();
          _safeBottom = (_safeBottom + dy)
              .clamp(_safeTop + minHeight, 1 - edgeInset)
              .toDouble();
      }
    });
  }

  void _handleDragStart({
    required double initialHorizontalPosition,
    required double initialVerticalPosition,
  }) {
    _initialDockStartTimer?.cancel();
    _initialDockStartTimer = null;
    _initialDockController.stop();
    setState(() {
      _horizontalPosition = initialHorizontalPosition;
      _verticalPosition = initialVerticalPosition;
      if (_permissionPending || _hasCompletedResponse) {
        // A manual drag takes over from the automatic attention peek. This
        // lets the user park the cloud at either edge without it sliding back.
        _attentionPeekDismissed = true;
      }
      _isDragging = true;
      _rotationRadians = 0;
      _scale = 1.035;
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details, {
    required double horizontalTravelDistance,
    required double verticalTravelDistance,
  }) {
    if (horizontalTravelDistance <= 0 && verticalTravelDistance <= 0) return;

    setState(() {
      if (horizontalTravelDistance > 0) {
        _horizontalPosition = ((_horizontalPosition ?? 0) +
                details.delta.dx / horizontalTravelDistance)
            .clamp(0.0, 1.0)
            .toDouble();
      }
      if (verticalTravelDistance > 0) {
        _verticalPosition = ((_verticalPosition ?? 1) -
                details.delta.dy / verticalTravelDistance)
            .clamp(0.0, 1.0)
            .toDouble();
      }
      _rotationRadians = (_rotationRadians +
              (details.delta.dx + details.delta.dy * 0.35) * 0.0024)
          .clamp(-0.16, 0.16)
          .toDouble();
      final movement = math.max(
        details.delta.dx.abs(),
        details.delta.dy.abs(),
      );
      _scale = 1.035 + math.min(movement / 1000, 0.025).toDouble();
    });
  }

  void _handleInitialDockAnimationTick() {
    if (mounted) setState(() {});
  }

  void _handleDragEnd({required double minLeft, required double maxLeft}) {
    if (_isExpanded) return;

    setState(() {
      final position = _horizontalPosition;
      if (position != null) {
        final currentLeft = minLeft + position * (maxLeft - minLeft);
        if (currentLeft - minLeft <= _snapThreshold) {
          _horizontalPosition = 0;
        } else if (maxLeft - currentLeft <= _snapThreshold) {
          _horizontalPosition = 1;
        }
      }
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom + DesignConstants.spacingL;
    final topBoundary = mediaQuery.padding.top + kToolbarHeight + _topGap;
    final panelTop =
        mediaQuery.padding.top + kToolbarHeight + DesignConstants.spacingS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(0.0, constraints.maxWidth).toDouble();
        final viewportHeight = math
            .min(
              constraints.maxHeight,
              mediaQuery.size.height - mediaQuery.viewInsets.bottom,
            )
            .clamp(0.0, double.infinity)
            .toDouble();
        final bottomOcclusion = constraints.maxHeight - viewportHeight;
        final visibleEdge = math.min(_visibleEdge, width / 2).toDouble();
        final minLeft = visibleEdge - _cloudSize;
        final maxLeft = math.max(minLeft, width - visibleEdge).toDouble();
        final travelDistance = math.max(0.0, maxLeft - minLeft).toDouble();

        // Start with the full cloud visible and align its resting position
        // with the cards. At either stop, a small part remains on screen.
        final defaultLeft = (width - _horizontalInset - _cloudSize)
            .clamp(minLeft, maxLeft)
            .toDouble();
        final defaultPosition = travelDistance == 0
            ? 0.0
            : ((defaultLeft - minLeft) / travelDistance)
                .clamp(0.0, 1.0)
                .toDouble();
        if (!_initialDockScheduled) {
          _initialDockScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                _isExpanded ||
                _isDragging ||
                _horizontalPosition != null) {
              return;
            }
            _initialDockStartTimer = Timer(
              const Duration(milliseconds: 650),
              () {
                _initialDockStartTimer = null;
                if (!mounted ||
                    _isExpanded ||
                    _isDragging ||
                    _horizontalPosition != null) {
                  return;
                }
                _initialDockController.forward();
              },
            );
          });
        }
        final dockProgress = Curves.easeOutCubic.transform(
          _initialDockController.value,
        );
        final requestedPosition = _horizontalPosition ??
            (defaultPosition + (1 - defaultPosition) * dockProgress);
        final requestedLeft = minLeft + requestedPosition * travelDistance;
        final hasAttentionState = _permissionPending || _hasCompletedResponse;
        // An attention state temporarily peeks the cloud out from its dock.
        // Keep the requested/drag position untouched; only offset the display
        // position, and allow the cloud to extend past the screen edge.
        const attentionPeekInset = 20.0;
        final isDockedLeft = requestedLeft <= minLeft + 8;
        final isDockedRight = requestedLeft >= maxLeft - 8;
        final left =
            hasAttentionState && !_attentionPeekDismissed && width > _cloudSize
                ? isDockedLeft
                    ? -attentionPeekInset
                    : isDockedRight
                        ? width - _cloudSize + attentionPeekInset
                        : requestedLeft
                : requestedLeft;
        final position = travelDistance == 0
            ? 0.0
            : ((left - minLeft) / travelDistance).clamp(0.0, 1.0).toDouble();
        _displayedHorizontalPosition = position;
        final minTop =
            math.min(topBoundary - _topVisualInset, viewportHeight).toDouble();
        final maxTop = math
            .max(minTop, viewportHeight - bottomInset - _cloudSize)
            .toDouble();
        final verticalTravelDistance =
            math.max(0.0, maxTop - minTop).toDouble();
        final verticalPosition =
            (_verticalPosition ?? 1.0).clamp(0.0, 1.0).toDouble();
        final top = maxTop - verticalPosition * verticalTravelDistance;
        final viewportSize = Size(width, viewportHeight);
        final panelRect = Rect.fromLTRB(
          DesignConstants.spacingS,
          panelTop,
          width - DesignConstants.spacingS,
          viewportHeight - mediaQuery.padding.bottom - DesignConstants.spacingS,
        );
        final safeRect = Rect.fromLTRB(
          panelRect.left + panelRect.width * _safeLeft,
          panelRect.top + panelRect.height * _safeTop,
          panelRect.left + panelRect.width * _safeRight,
          panelRect.top + panelRect.height * _safeBottom,
        );
        final fullscreenRect = Rect.fromLTRB(
          0,
          0,
          width,
          viewportHeight,
        );
        final morphAnimation = _morphAnimation;
        final fullscreenProgress = Curves.easeInOutCubic.transform(
          _fullscreenAnimation.value,
        );
        // Keep the half-expanded cloud unchanged. For a direct fullscreen
        // opening, keep its palette in step with whichever animation is still
        // running. During close the morph reverses first, so it also drives the
        // palette smoothly back to the cloud colors.
        final morphProgress = morphAnimation.value.clamp(0.0, 1.0).toDouble();
        final openingClosingProgress = math.min(
          _fullscreenAnimation.value.clamp(0.0, 1.0).toDouble(),
          morphProgress,
        );
        final isWholeCloudTransition =
            (_isFullscreen || _isClosingFromFullscreen) &&
                morphProgress < 0.999;
        final appearanceProgress = isWholeCloudTransition
            ? _openingAppearanceProgress(openingClosingProgress)
            : fullscreenProgress;
        final activeSafeRect =
            Rect.lerp(safeRect, fullscreenRect, fullscreenProgress)!;
        const handleOutset = 44.0;
        final cloudCenter = Offset(left + _cloudSize / 2, top + _cloudSize / 2);
        final theme = Theme.of(context);
        final overlaySurfaceColor =
            _overlaySurfaceColor(theme, appearanceProgress);
        final overlayForegroundColor =
            _overlayForegroundColor(theme, appearanceProgress);
        Offset handlePosition(Offset corner, Offset direction) => Offset(
              (corner.dx + direction.dx * handleOutset)
                  .clamp(28.0, width - 28.0)
                  .toDouble(),
              (corner.dy + direction.dy * handleOutset)
                  .clamp(
                    mediaQuery.padding.top + 28.0,
                    viewportHeight - mediaQuery.padding.bottom - 28.0,
                  )
                  .toDouble(),
            );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: left, end: left),
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, animatedLeft, _) {
                  final animatedCloudCenter =
                      Offset(animatedLeft + _cloudSize / 2, cloudCenter.dy);
                  return AnimatedBuilder(
                    animation: morphAnimation,
                    builder: (context, _) {
                      final isSettledOrb =
                          !_isExpanded && morphAnimation.value <= 0.005;
                      return IgnorePointer(
                        child: AiNeuralCloudOrbWidget(
                          size: _cloudSize *
                              _scale *
                              (_completionPulse && isSettledOrb ? 1.12 : 1.0),
                          rotation: _rotationRadians,
                          canvasSize: viewportSize,
                          cloudCenter: animatedCloudCenter,
                          frameRect: activeSafeRect,
                          baseColor: overlaySurfaceColor,
                          frameMorphAnimation: morphAnimation,
                          showAmbientGlow: false,
                          edgeBlurSigma: 4,
                          showDetachedSatellite: false,
                          flowSpeed: _isDragging
                              ? 1.55
                              : _isGenerating
                                  ? 0.9
                                  : 2.0 * widget.liveliness.clamp(0.0, 1.0),
                          animate: !_isClosing,
                          accentColor: _permissionPending && isSettledOrb
                              ? Colors.amber.shade700
                              : null,
                          tint: !isSettledOrb
                              ? null
                              : _isGenerating
                                  ? 0.4
                                  : _permissionPending
                                      ? 0.62
                                      : _hasCompletedResponse
                                          ? 1.0
                                          : null,
                          energy: _completionPulse && isSettledOrb ? 0.75 : 0,
                          enableInteraction: false,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            AnimatedPositioned(
              duration: _isDragging || _initialDockController.isAnimating
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              child: AnimatedBuilder(
                animation: morphAnimation,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: morphAnimation.value > 0.001,
                    child: Semantics(
                      label: widget.semanticLabel,
                      hint: widget.semanticHint,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: morphAnimation.value > 0.001
                            ? null
                            : _toggleExpanded,
                        onPanStart: morphAnimation.value > 0.001
                            ? null
                            : (_) => _handleDragStart(
                                  initialHorizontalPosition: position,
                                  initialVerticalPosition: verticalPosition,
                                ),
                        onPanUpdate: morphAnimation.value > 0.001
                            ? null
                            : (details) => _handleDragUpdate(
                                  details,
                                  horizontalTravelDistance: travelDistance,
                                  verticalTravelDistance:
                                      verticalTravelDistance,
                                ),
                        onPanEnd: morphAnimation.value > 0.001
                            ? null
                            : (_) => _handleDragEnd(
                                  minLeft: minLeft,
                                  maxLeft: maxLeft,
                                ),
                        onPanCancel: morphAnimation.value > 0.001
                            ? null
                            : () => _handleDragEnd(
                                  minLeft: minLeft,
                                  maxLeft: maxLeft,
                                ),
                        child: const SizedBox(
                          width: _cloudSize,
                          height: _cloudSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: morphAnimation,
              builder: (context, _) {
                final isSettledOrb =
                    !_isExpanded && morphAnimation.value <= 0.005;
                if (!_permissionPending ||
                    !_showPermissionBadge ||
                    !isSettledOrb ||
                    width < 100) {
                  return const SizedBox.shrink();
                }
                final l10n = AppLocalizations.of(context)!;
                const badgeSize = 48.0;
                // This follows the cloud's actual center, even when the icon
                // itself is clipped by the screen edge while the cloud is
                // docked there.
                final badgeLeft = cloudCenter.dx - badgeSize / 2;
                final badgeTop = (cloudCenter.dy - badgeSize / 2)
                    .clamp(
                      mediaQuery.padding.top + 4,
                      viewportHeight -
                          mediaQuery.padding.bottom -
                          badgeSize -
                          4,
                    )
                    .toDouble();
                return AnimatedPositioned(
                  duration: _isDragging || _initialDockController.isAnimating
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: badgeLeft,
                  top: badgeTop,
                  child: IgnorePointer(
                    child: Semantics(
                      label: l10n.aiOverlayDemoAssistantSection,
                      child: SizedBox(
                        width: badgeSize,
                        height: badgeSize,
                        child: const Icon(
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
              _buildResizeHandle(
                _SafeSpaceCorner.topLeft,
                handlePosition(activeSafeRect.topLeft, const Offset(-1, -1)),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.topRight,
                handlePosition(activeSafeRect.topRight, const Offset(1, -1)),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.bottomLeft,
                handlePosition(
                  activeSafeRect.bottomLeft,
                  const Offset(-1, 1),
                ),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.bottomRight,
                handlePosition(
                  activeSafeRect.bottomRight,
                  const Offset(1, 1),
                ),
                panelRect.size,
                theme,
              ),
            ],
            AnimatedBuilder(
              animation: morphAnimation,
              builder: (context, _) {
                final revealProgress = Curves.easeInOutCubic.transform(
                  morphAnimation.value.clamp(0.0, 1.0),
                );
                final collapsedBounds = Rect.fromCenter(
                  center: cloudCenter,
                  width: 120,
                  height: 120,
                );
                final contentRevealBounds = Rect.lerp(
                  collapsedBounds,
                  activeSafeRect.inflate(64),
                  revealProgress,
                )!;
                return Positioned.fill(
                  child: ClipRect(
                    clipper: _CloudControlsClipper(contentRevealBounds),
                    child: Transform.scale(
                      // Keep the transform origin on the orb so the contents
                      // contract into it instead of sliding toward the top.
                      alignment: Alignment(
                        width <= 0 ? 0 : cloudCenter.dx / width * 2 - 1,
                        viewportHeight <= 0
                            ? 0
                            : cloudCenter.dy / viewportHeight * 2 - 1,
                      ),
                      scale: revealProgress,
                      child: Opacity(
                        opacity: revealProgress,
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: _handleSidebarPointerDown,
                          onPointerMove: (event) => _handleSidebarPointerMove(
                            event,
                            _sidebarWidth(width),
                          ),
                          onPointerUp: _finishSidebarPointer,
                          onPointerCancel: _finishSidebarPointer,
                          child: Stack(
                            children: [
                              if (_sidebarController.value > 0.001)
                                _buildDemoSidebar(
                                  theme,
                                  width,
                                  appearanceProgress: appearanceProgress,
                                ),
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(
                                    _sidebarController.value *
                                        _sidebarWidth(width),
                                    0,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _sidebarController.value > 0
                                        ? _closeSidebar
                                        : null,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildChatPreview(
                                          activeSafeRect,
                                          theme,
                                          viewportHeight,
                                          bottomOcclusion: bottomOcclusion,
                                          fullscreenProgress:
                                              fullscreenProgress,
                                          appearanceProgress:
                                              appearanceProgress,
                                        ),
                                        _buildExpandedToolbar(
                                          activeSafeRect,
                                          theme,
                                          fullscreenProgress:
                                              fullscreenProgress,
                                          appearanceProgress:
                                              appearanceProgress,
                                          surfaceColor: overlaySurfaceColor,
                                          foregroundColor:
                                              overlayForegroundColor,
                                        ),
                                      ],
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
          ],
        );
      },
    );
  }

  Widget _buildExpandedToolbar(
    Rect safeRect,
    ThemeData theme, {
    required double fullscreenProgress,
    required double appearanceProgress,
    required Color surfaceColor,
    required Color foregroundColor,
  }) {
    final surfaceIsLight = surfaceColor.computeLuminance() >= 0.5;
    final controlFill = _overlayControlFill(theme, appearanceProgress);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final safeSpaceOutset = 44.0 * (1 - fullscreenProgress);
    final fullscreenInset = 12.0 * fullscreenProgress;
    final expandedToolbarTop = safeRect.top - 62;
    final fullscreenToolbarTop = MediaQuery.paddingOf(context).top + 10;
    final toolbarTop = expandedToolbarTop +
        (fullscreenToolbarTop - expandedToolbarTop) * fullscreenProgress;

    return Positioned(
      left: safeRect.left - safeSpaceOutset + fullscreenInset,
      right: viewportWidth - safeRect.right - safeSpaceOutset + fullscreenInset,
      top: toolbarTop,
      height: 52,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildHeaderGlassButton(
                icon: _isFullscreen
                    ? LucideIcons.panel_left
                    : LucideIcons.maximize_2,
                tooltip: _isFullscreen ? 'Seitenleiste' : 'Vollbild',
                isDarkSurface: !surfaceIsLight,
                foregroundColor: foregroundColor,
                backgroundColor: controlFill,
                onPressed: _isFullscreen ? _toggleSidebar : _toggleFullscreen,
              ),
            ),
            if (!_isFullscreen)
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: _handleHeaderDragStart,
                    onVerticalDragUpdate: _handleHeaderDragUpdate,
                    onVerticalDragEnd: _handleHeaderDragEnd,
                    child: SizedBox(
                      width: 72,
                      height: 56,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: foregroundColor.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isFullscreen) const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PlatformAdaptivePopupMenu<_AssistantMenuAction>(
                icon: _buildHeaderGlassButton(
                  icon: LucideIcons.ellipsis,
                  tooltip: 'Chat-Menü',
                  isDarkSurface: !surfaceIsLight,
                  foregroundColor: foregroundColor,
                  backgroundColor: controlFill,
                ),
                menuWidth: 230,
                items: [
                  PlatformAdaptivePopupMenuItem(
                    value: _AssistantMenuAction.newChat,
                    label: AppLocalizations.of(context)!.aiOverlayNewChat,
                    icon: LucideIcons.square_pen,
                  ),
                  PlatformAdaptivePopupMenuItem(
                    value: _AssistantMenuAction.chatHistory,
                    label: AppLocalizations.of(context)!.aiOverlayChatHistory,
                    icon: LucideIcons.rotate_ccw,
                  ),
                ],
                onSelected: _handleAssistantMenuAction,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8),
              child: _buildHeaderGlassButton(
                icon: LucideIcons.x,
                tooltip: 'Schließen',
                isDarkSurface: !surfaceIsLight,
                foregroundColor: foregroundColor,
                backgroundColor: controlFill,
                onPressed: _toggleExpanded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderGlassButton({
    required IconData icon,
    required String tooltip,
    required bool isDarkSurface,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    bool showBorder = true,
  }) {
    final theme = Theme.of(context);
    final foreground =
        foregroundColor ?? (isDarkSurface ? Colors.white : Colors.black);
    // The cloud can have the opposite appearance from the app while it opens
    // or closes. Let the glass renderer use the cloud's current surface too.
    final glassTheme = theme.copyWith(
      brightness: isDarkSurface ? Brightness.dark : Brightness.light,
    );
    final settings = DesignConstants.liquidGlassSettings(isDarkSurface);
    final buttonSurface = Container(
      decoration: BoxDecoration(
        color: showBorder
            ? backgroundColor ??
                (isDarkSurface
                    ? DesignConstants.glassNeutralTint(true)
                    : Colors.black.withValues(alpha: 0.04))
            : Colors.transparent,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: foreground.withValues(alpha: 0.14), width: 0.5)
            : null,
      ),
      child: Center(child: Icon(icon, size: 20, color: foreground)),
    );
    final useStaticGlass =
        _isClosing || (_isExpanded && _morphAnimation.value < 1);
    final glassContent = !showBorder || useStaticGlass
        ? buttonSurface
        : Theme(
            data: glassTheme,
            child: GlassAdaptiveScope(
              maxQuality: DesignConstants.defaultGlassQuality,
              minQuality: DesignConstants.minGlassQuality,
              child: AdaptiveGlass(
                settings: settings,
                quality: DesignConstants.defaultGlassQuality,
                useOwnLayer: true,
                allowElevation: false,
                shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                child: GlassGlow(
                  glowColor: Colors.white.withValues(
                    alpha: isDarkSurface ? 0.24 : 0.18,
                  ),
                  glowRadius: 1,
                  child: buttonSurface,
                ),
              ),
            ),
          );
    final button = SizedBox.square(
      dimension: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow:
              showBorder ? DesignConstants.glassShadow(isDarkSurface) : null,
        ),
        child: glassContent,
      ),
    );
    // This widget is also mounted through a root OverlayEntry, whose subtree
    // does not consistently expose an Overlay ancestor on every platform.
    // Tooltip tries to insert a RawTooltip entry and throws in that case.
    return Semantics(
      button: onPressed != null,
      label: tooltip,
      child: onPressed == null
          ? button
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: button,
            ),
    );
  }

  Widget _buildVoiceRecordingContent(Color foregroundColor) {
    if (_voiceStarting) {
      return Center(
        child: SizedBox(
          width: 96,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: foregroundColor.withValues(alpha: 0.72),
            backgroundColor: foregroundColor.withValues(alpha: 0.16),
          ),
        ),
      );
    }
    if (_voiceStopping) {
      return Center(
        child: SizedBox(
          width: 96,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: foregroundColor.withValues(alpha: 0.72),
            backgroundColor: foregroundColor.withValues(alpha: 0.16),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      width: double.infinity,
      child: CustomPaint(
        painter: _VoiceWaveformPainter(
          samples: List<_VoiceWaveSample>.of(_voiceLevelHistory),
          color: foregroundColor.withValues(alpha: 0.82),
          scrollOffset: _voiceWaveOffset,
        ),
        willChange: true,
      ),
    );
  }

  void _handleAssistantMenuAction(_AssistantMenuAction action) {
    switch (action) {
      case _AssistantMenuAction.newChat:
        _sidebarController.reverse();
        _startNewDemoChat();
      case _AssistantMenuAction.chatHistory:
        _toggleSidebar();
    }
  }

  void _startNewDemoChat() {
    _activeGenerationId++;
    _responseTimer?.cancel();
    _responseTimer = null;
    _liveResponseSubscription?.cancel();
    _liveResponseSubscription = null;
    _liveChunkFlushTimer?.cancel();
    _liveChunkFlushTimer = null;
    _pendingLiveChunks.clear();
    _liveStreamCompleted = false;
    _pendingLiveError = null;
    _loadingCloudEnterFuture = null;
    _loadingCloudController.value = 0;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    _permissionBadgeDelayTimer?.cancel();
    _completionPulseTimer?.cancel();
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;
    setState(() {
      _chatTurns.clear();
      _isLoadingCloudVisible = false;
      _isLoadingCloudDismissing = false;
      _isGenerating = false;
      _hasCompletedResponse = false;
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _attentionPeekDismissed = false;
      _completionPulse = false;
      _showScrollToBottom = false;
      _followChatTail = true;
      _demoWordIndex = 0;
      _selectedSidebarExample = -1;
      _chatInputController.clear();
    });
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(0);
      }
    });
  }

  Widget _buildSidebarChatButton({
    required ThemeData theme,
    required bool isDark,
    required Color foregroundColor,
    required double appearanceProgress,
  }) {
    final glassTheme = theme.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    final radius = 24.0;
    final settings = DesignConstants.liquidGlassSettings(isDark);
    final button = Container(
      height: 48,
      decoration: BoxDecoration(
        color: _overlayControlFill(theme, appearanceProgress),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(LucideIcons.square_pen, size: 19, color: foregroundColor),
          const SizedBox(width: 12),
          Text(
            'Chat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: DesignConstants.glassShadow(isDark),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleSidebar,
          child: Theme(
            data: glassTheme,
            child: GlassAdaptiveScope(
              maxQuality: DesignConstants.defaultGlassQuality,
              minQuality: DesignConstants.minGlassQuality,
              child: AdaptiveGlass(
                settings: settings,
                quality: DesignConstants.defaultGlassQuality,
                useOwnLayer: true,
                allowElevation: false,
                shape: LiquidRoundedSuperellipse(borderRadius: radius),
                child: GlassGlow(
                  glowColor: Colors.white.withValues(
                    alpha: isDark ? 0.24 : 0.18,
                  ),
                  glowRadius: 1,
                  child: button,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSidebar(
    ThemeData theme,
    double viewportWidth, {
    required double appearanceProgress,
  }) {
    final surfaceColor = _overlaySurfaceColor(theme, appearanceProgress);
    final foregroundColor = _overlayForegroundColor(theme, appearanceProgress);
    final surfaceIsLight = surfaceColor.computeLuminance() >= 0.5;
    final drawerWidth = _sidebarWidth(viewportWidth);

    return Positioned(
      // Keep the drawer's trailing edge attached to the chat pane while the
      // user drags. At progress 0 it is fully offscreen; at 1 it is settled
      // against the translated chat surface.
      left: -drawerWidth * (1 - _sidebarController.value),
      top: 0,
      bottom: 0,
      width: drawerWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            right: BorderSide(
              color: foregroundColor.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chats',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: foregroundColor.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        MediaQuery.paddingOf(context).bottom + 84,
                      ),
                      itemCount: 16,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final selected = index == _selectedSidebarExample;
                        return Material(
                          color: selected
                              ? foregroundColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectSidebarExample(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Example ${index + 1}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: foregroundColor,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 12,
                      bottom: MediaQuery.paddingOf(context).bottom + 12,
                      child: _buildSidebarChatButton(
                        theme: theme,
                        isDark: !surfaceIsLight,
                        foregroundColor: foregroundColor,
                        appearanceProgress: appearanceProgress,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPreview(
    Rect safeRect,
    ThemeData theme,
    double viewportHeight, {
    required double bottomOcclusion,
    required double fullscreenProgress,
    required double appearanceProgress,
  }) {
    final appIsDark = theme.brightness == Brightness.dark;
    final contrastColor = _overlayForegroundColor(theme, appearanceProgress);
    final surfaceColor = _overlaySurfaceColor(theme, appearanceProgress);
    final selectionBlue = theme.brightness == Brightness.dark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
    final cloudSurfaceDark = surfaceColor.computeLuminance() < 0.5;
    final softColor = contrastColor.withValues(
      alpha: cloudSurfaceDark ? 0.10 : 0.08,
    );
    final composerGlassSettings =
        DesignConstants.liquidGlassSettings(cloudSurfaceDark);
    final glassTheme = theme.copyWith(
      brightness: cloudSurfaceDark ? Brightness.dark : Brightness.light,
    );
    final isGlassTransitioning =
        _isClosing || (_isExpanded && _morphAnimation.value < 1);
    const contentInset = 8.0;
    const permissionCardKey = ValueKey<String>('ai-overlay-permission-card');
    final chatBounds = Rect.lerp(
      safeRect.inflate(44),
      safeRect.deflate(12),
      fullscreenProgress,
    )!;
    final contentLeft = chatBounds.left + contentInset;
    final contentRight =
        MediaQuery.sizeOf(context).width - chatBounds.right + contentInset;
    final composerLeft = chatBounds.left;
    final composerRight = MediaQuery.sizeOf(context).width - chatBounds.right;
    final fullscreenContentTop = MediaQuery.paddingOf(context).top + 70;
    final chatTop = safeRect.top +
        16 +
        (fullscreenContentTop - safeRect.top - 16) * fullscreenProgress;
    // Keep the scroll viewport flush with the animated chat window's outer
    // top edge so messages can scroll right up to it without painting beyond.
    final scrollViewportTop = chatBounds.top;
    final toolbarTop = (safeRect.top - 62) +
        (MediaQuery.paddingOf(context).top + 10 - (safeRect.top - 62)) *
            fullscreenProgress;
    final toolbarButtonCenter = toolbarTop + 28;
    final topFadeEnd = toolbarButtonCenter +
        (chatTop - toolbarButtonCenter) * fullscreenProgress;
    final clippedTop = safeRect.top - 64;
    final topFadeStart =
        clippedTop + (scrollViewportTop - clippedTop) * fullscreenProgress;
    final topFadeHoldStop = 0.45 * (1 - fullscreenProgress);
    final bottomFadeHeight = 104.0 * (1 - fullscreenProgress);
    final chatBottom = chatBounds.bottom - contentInset;
    final contentViewportBottom = chatBounds.bottom +
        (viewportHeight - chatBounds.bottom) * fullscreenProgress;
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
    final controlFillColor = _overlayControlFill(theme, appearanceProgress);
    final composerSurface = AnimatedBuilder(
      animation: Listenable.merge([
        _chatInputController,
        _chatFocusNode,
        _chatInputScrollController,
      ]),
      builder: (context, _) {
        final inputValue = _chatInputController.value;
        final hasText = inputValue.text.trim().isNotEmpty;
        final inputIsScrolled = _chatInputScrollController.hasClients &&
            _chatInputScrollController.offset > 0.5;
        final recording = _voiceStarting || _voiceRecording || _voiceStopping;
        final expandedInput = hasText || _chatFocusNode.hasFocus;

        Widget voiceButton({bool filled = false}) => _buildHeaderGlassButton(
              icon: recording ? LucideIcons.x : LucideIcons.mic,
              tooltip: recording
                  ? AppLocalizations.of(context)!.cancel
                  : AppLocalizations.of(context)!.voiceTapToRecord,
              isDarkSurface: !surfaceIsLight,
              foregroundColor: filled ? sendButtonForeground : contrastColor,
              backgroundColor: filled ? sendButtonBackground : controlFillColor,
              showBorder: recording || filled,
              onPressed: recording ? _cancelVoiceInput : _startVoiceInput,
            );

        Widget sendButton() => _buildHeaderGlassButton(
              icon: _isGenerating ? LucideIcons.square : LucideIcons.arrow_up,
              tooltip: _isGenerating ? 'Stopp' : 'Senden',
              isDarkSurface: !surfaceIsLight,
              backgroundColor: sendButtonBackground,
              foregroundColor: sendButtonForeground,
              onPressed: _isGenerating ? _stopDemoGeneration : _sendDemoPrompt,
            );

        Widget messageField({required bool compact}) => Scrollbar(
              controller: _chatInputScrollController,
              thumbVisibility: !compact,
              thickness: 2,
              radius: const Radius.circular(2),
              child: TextSelectionTheme(
                data: TextSelectionThemeData(
                  cursorColor: selectionBlue,
                  selectionColor: selectionBlue.withValues(alpha: 0.32),
                  selectionHandleColor: selectionBlue,
                ),
                child: TextField(
                  controller: _chatInputController,
                  scrollController: _chatInputScrollController,
                  focusNode: _chatFocusNode,
                  keyboardType: TextInputType.text,
                  onTapOutside: (_) => _chatFocusNode.unfocus(),
                  onTap: () {
                    if (!_voiceStarting &&
                        !_voiceRecording &&
                        !_voiceStopping) {
                      _chatFocusNode.requestFocus();
                      unawaited(
                        SystemChannels.textInput.invokeMethod<void>(
                          'TextInput.show',
                        ),
                      );
                    }
                  },
                  textAlign: TextAlign.start,
                  textAlignVertical: TextAlignVertical.top,
                  minLines: 1,
                  maxLines: (!compact || inputValue.text.isEmpty) ? 6 : 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!_isGenerating) _sendDemoPrompt();
                  },
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contrastColor,
                  ),
                  cursorColor: selectionBlue,
                  decoration: InputDecoration(
                    hintText: _askModelHint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: contrastColor.withValues(alpha: 0.52),
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      top: inputIsScrolled ? 0 : 8,
                    ),
                  ),
                ),
              ),
            );

        return TextFieldTapRegion(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              // TextField's internal scroll viewport can paint at its rounded
              // top edge. Clip the entire composer so content always follows the
              // card's outer contour, including its rounded corners.
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  color: composerFillColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: contrastColor.withValues(alpha: 0.14),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(recording ? 6 : 10, 6, 6, 6),
                  child: recording
                      ? Row(
                          children: [
                            voiceButton(),
                            const SizedBox(width: 6),
                            Expanded(
                                child:
                                    _buildVoiceRecordingContent(contrastColor)),
                            const SizedBox(width: 6),
                            _buildHeaderGlassButton(
                              icon: LucideIcons.square,
                              tooltip: AppLocalizations.of(context)!
                                  .voiceTapToFinish,
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: controlFillColor,
                              foregroundColor: contrastColor,
                              onPressed:
                                  _voiceStopping ? null : _stopVoiceInput,
                            ),
                            const SizedBox(width: 6),
                            _buildHeaderGlassButton(
                              icon: LucideIcons.arrow_up,
                              tooltip: 'Senden',
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: sendButtonBackground,
                              foregroundColor: sendButtonForeground,
                              onPressed:
                                  _voiceStopping ? null : _sendVoiceInput,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isGenerating)
                              Row(
                                children: [
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 156),
                                      child: messageField(
                                        compact: !expandedInput,
                                      ),
                                    ),
                                  ),
                                  if (!expandedInput) ...[
                                    const SizedBox(width: 6),
                                    // With an empty draft the mic occupies the
                                    // send button's usual trailing position and
                                    // uses its exact filled circular treatment.
                                    voiceButton(filled: true),
                                  ],
                                ],
                              ),
                            if (expandedInput || _isGenerating)
                              Row(
                                children: [
                                  if (!_isGenerating)
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _chatFocusNode.requestFocus();
                                          unawaited(
                                            SystemChannels.textInput
                                                .invokeMethod<void>(
                                              'TextInput.show',
                                            ),
                                          );
                                        },
                                        child: const SizedBox(height: 44),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (!_isGenerating) ...[
                                    voiceButton(),
                                    const SizedBox(width: 6),
                                  ],
                                  sendButton(),
                                ],
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

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isExpanded ||
            !_showChatPreview ||
            _sidebarController.value > 0.001,
        child: Stack(
          children: [
            Positioned(
              left: contentLeft,
              right: contentRight,
              top: topFadeStart,
              bottom: bottomOcclusion + viewportHeight - contentViewportBottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) {
                        final topFadeEndStop =
                            ((topFadeEnd - topFadeStart) / bounds.height)
                                .clamp(0.0, 1.0)
                                .toDouble();
                        final topFadeOpaqueStartStop =
                            (topFadeEndStop * topFadeHoldStop)
                                .clamp(0.0, topFadeEndStop)
                                .toDouble();
                        final bottomFadeStartStop =
                            ((chatBottom - bottomFadeHeight - topFadeStart) /
                                    bounds.height)
                                .clamp(topFadeEndStop, 1.0)
                                .toDouble();
                        if (fullscreenProgress >= 0.999) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.white,
                              Colors.white,
                            ],
                            stops: [
                              0,
                              topFadeOpaqueStartStop,
                              topFadeEndStop,
                              1,
                            ],
                          ).createShader(bounds);
                        }
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [
                            0,
                            topFadeOpaqueStartStop,
                            topFadeEndStop,
                            bottomFadeStartStop,
                            1,
                          ],
                        ).createShader(bounds);
                      },
                      child: _chatTurns.isEmpty
                          ? const SizedBox.shrink()
                          : NotificationListener<UserScrollNotification>(
                              onNotification: (notification) {
                                if (notification.direction !=
                                    ScrollDirection.idle) {
                                  _chatUserScrollRevision++;
                                }
                                return false;
                              },
                              child: ListView.builder(
                                key: const PageStorageKey<String>(
                                  'ai-overlay-chat-history',
                                ),
                                controller: _chatScrollController,
                                findChildIndexCallback: (key) {
                                  if (key == permissionCardKey) {
                                    return _chatTurns.length + 1;
                                  }
                                  if (key is ValueKey<_DemoChatTurn>) {
                                    final turnIndex =
                                        _chatTurns.indexOf(key.value);
                                    return turnIndex < 0 ? null : turnIndex + 1;
                                  }
                                  return null;
                                },
                                padding: const EdgeInsets.only(bottom: 104),
                                itemCount: _chatTurns.length + 2,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return SizedBox(
                                      height: math.max(
                                        0.0,
                                        chatTop - topFadeStart + 16,
                                      ),
                                    );
                                  }
                                  if (index == _chatTurns.length + 1) {
                                    return KeyedSubtree(
                                      key: permissionCardKey,
                                      child: _buildDemoPermissionCard(
                                        theme: theme,
                                        contrastColor: contrastColor,
                                        surfaceColor: surfaceColor,
                                        isVisible: !widget.useLiveAi &&
                                            (_permissionPending ||
                                                _permissionApproved != null),
                                      ),
                                    );
                                  }
                                  final turn = _chatTurns[index - 1];
                                  final isLastTurn = index == _chatTurns.length;
                                  return KeyedSubtree(
                                    key: ValueKey<_DemoChatTurn>(turn),
                                    child: _buildChatTurn(
                                      turn,
                                      theme: theme,
                                      contrastColor: contrastColor,
                                      softColor: softColor,
                                      isStreaming: _isGenerating && isLastTurn,
                                      showLoadingCloud: isLastTurn &&
                                          _isLoadingCloudVisible &&
                                          turn.response.isEmpty,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: composerLeft,
              right: composerRight,
              bottom: bottomOcclusion +
                  viewportHeight -
                  chatBounds.bottom +
                  contentInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.bottomCenter,
                    child: _showScrollToBottom
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildHeaderGlassButton(
                              icon: LucideIcons.arrow_down,
                              tooltip: 'Zum neuesten Beitrag',
                              isDarkSurface: !surfaceIsLight,
                              backgroundColor: controlFillColor,
                              foregroundColor: contrastColor,
                              onPressed: _scrollToLatestMessage,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: DesignConstants.glassShadow(cloudSurfaceDark),
                    ),
                    child: isGlassTransitioning
                        ? composerSurface
                        : Theme(
                            data: glassTheme,
                            child: GlassAdaptiveScope(
                              maxQuality: DesignConstants.defaultGlassQuality,
                              minQuality: DesignConstants.minGlassQuality,
                              child: AdaptiveGlass(
                                settings: composerGlassSettings,
                                quality: DesignConstants.defaultGlassQuality,
                                useOwnLayer: true,
                                allowElevation: false,
                                shape: const LiquidRoundedSuperellipse(
                                  borderRadius: 28,
                                ),
                                child: GlassGlow(
                                  glowColor:
                                      contrastColor.withValues(alpha: 0.12),
                                  glowRadius: 1,
                                  child: composerSurface,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTurn(
    _DemoChatTurn turn, {
    required ThemeData theme,
    required Color contrastColor,
    required Color softColor,
    required bool isStreaming,
    required bool showLoadingCloud,
  }) {
    final isCompactPrompt = turn.prompt.trim().runes.length <= 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                minWidth: isCompactPrompt ? 56 : 0,
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isCompactPrompt
                  ? Center(
                      widthFactor: 1,
                      child: Text(
                        turn.prompt,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: contrastColor,
                        ),
                      ),
                    )
                  : Text(
                      turn.prompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: contrastColor,
                      ),
                    ),
            ),
          ),
          if (showLoadingCloud)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: AnimatedBuilder(
                animation: _loadingCloudController,
                builder: (context, _) {
                  // 0.0 -> 0.44: nichts -> Kreis (sizeFactor 0 -> 1, morph 0)
                  // 0.44 -> 1.0: Kreis -> Wolke (sizeFactor 1, morph 0 -> 1)
                  // Reverse runs Wolke -> Kreis -> nichts.
                  const split = 0.44;
                  final progress =
                      _loadingCloudController.value.clamp(0.0, 1.0);
                  final circleScale = progress <= split
                      ? Curves.easeInOutCubic.transform(
                          (progress / split).clamp(0.0, 1.0),
                        )
                      : 1.0;
                  final cloudMorph = progress <= split
                      ? 0.0
                      : Curves.easeInOutCubic.transform(
                          ((progress - split) / (1.0 - split)).clamp(0.0, 1.0),
                        );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AiNeuralCloudOrbWidget(
                      size: 68,
                      canvasSize: const Size(42, 42),
                      cloudCenter: const Offset(21, 21),
                      sizeFactor: circleScale,
                      morph: 0,
                      instantaneousMorph: cloudMorph,
                      baseColor: contrastColor,
                      showAmbientGlow: false,
                      enableInteraction: false,
                    ),
                  );
                },
              ),
            )
          else if (turn.response.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: _buildMarkdownResponse(
                turn.response,
                theme: theme,
                contrastColor: contrastColor,
                softColor: softColor,
                isStreaming: isStreaming,
              ),
            ),
            if (!isStreaming)
              _buildChatTurnActionBar(
                turn,
                theme: theme,
                contrastColor: contrastColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarkdownResponse(
    String rawResponse, {
    required ThemeData theme,
    required Color contrastColor,
    required Color softColor,
    required bool isStreaming,
  }) {
    final normalized = _normalizeStreamingMarkdown(
      rawResponse,
      isStreaming: isStreaming,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: contrastColor,
      height: 1.5,
    );
    final codeStyle = bodyStyle?.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
      color: contrastColor,
      backgroundColor: softColor,
    );

    return MarkdownBody(
      data: normalized,
      selectable: false,
      onTapLink: (text, href, title) {
        if (href == null || href.trim().isEmpty) return;
        final uri = Uri.tryParse(href.trim());
        if (uri != null) {
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: bodyStyle,
        pPadding: const EdgeInsets.only(bottom: 8),
        h1: theme.textTheme.titleLarge?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h2: theme.textTheme.titleMedium?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        h3: theme.textTheme.titleSmall?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h4: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        h5: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
        h6: bodyStyle?.copyWith(
          fontWeight: FontWeight.w600,
          color: contrastColor.withValues(alpha: 0.82),
        ),
        strong: bodyStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: contrastColor,
        ),
        em: bodyStyle?.copyWith(
          fontStyle: FontStyle.italic,
          color: contrastColor,
        ),
        del: bodyStyle?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: contrastColor.withValues(alpha: 0.72),
        ),
        a: bodyStyle?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        listBullet: bodyStyle,
        listIndent: 18,
        code: codeStyle,
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: contrastColor.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        blockquote: bodyStyle?.copyWith(
          color: contrastColor.withValues(alpha: 0.84),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: contrastColor.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
        ),
        tableHead: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        tableBody: bodyStyle,
        tableBorder: TableBorder.all(
          color: contrastColor.withValues(alpha: 0.18),
          width: 0.5,
          borderRadius: BorderRadius.circular(8),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: contrastColor.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
        ),
      ),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: bodyStyle,
        ),
      },
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          LatexBlockSyntax(),
        ],
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          LatexInlineSyntax(),
        ],
      ),
    );
  }

  String _normalizeStreamingMarkdown(String raw, {required bool isStreaming}) {
    if (!isStreaming || raw.isEmpty) return raw;
    var text = raw;
    // Strip a lone trailing '**' before the first character of the bold span
    // arrives so raw syntax markers never flash for a frame.
    if (text.endsWith('**') && !text.endsWith('***')) {
      final withoutTrailing = text.substring(0, text.length - 2);
      if ('**'.allMatches(withoutTrailing).length.isEven) {
        return withoutTrailing;
      }
    }
    // Auto-close an active '**bold**' span while words are streaming inside it.
    final boldMatches = '**'.allMatches(text).length;
    if (boldMatches.isOdd) {
      final trimmed = text.trimRight();
      if (!trimmed.endsWith('*')) {
        text = '$trimmed**';
      }
    }
    // Auto-close an active inline '`code`' span when not inside a fenced block.
    final fenceMatches = '```'.allMatches(text).length;
    if (fenceMatches.isEven) {
      final withoutFences = text.replaceAll('```', '');
      final backtickMatches = '`'.allMatches(withoutFences).length;
      if (backtickMatches.isOdd) {
        final trimmed = text.trimRight();
        if (trimmed.endsWith('`')) {
          text = trimmed.substring(0, trimmed.length - 1);
        } else {
          text = '$trimmed`';
        }
      }
    }
    return text;
  }

  Widget _buildChatTurnActionBar(
    _DemoChatTurn turn, {
    required ThemeData theme,
    required Color contrastColor,
  }) {
    final isCopied = _copiedTurn == turn;
    final subtleColor = contrastColor.withValues(alpha: 0.52);
    final modelLabel = turn.modelName;
    final durationLabel = turn.duration != null
        ? _formatGenerationDuration(turn.duration!)
        : null;

    final metaText = [
      if (modelLabel != null && modelLabel.isNotEmpty) modelLabel,
      if (durationLabel != null) durationLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIconButton(
            icon: isCopied ? LucideIcons.check : LucideIcons.copy,
            tooltip: 'Antwort kopieren (Lange drücken: Gesamten Chat kopieren)',
            onTap: () => _copyResponseMarkdown(turn),
            onLongPress: _copyFullChatMarkdown,
            foregroundColor: isCopied
                ? (theme.brightness == Brightness.dark
                    ? Colors.greenAccent
                    : Colors.green.shade700)
                : subtleColor,
          ),
          const SizedBox(width: 4),
          _buildActionIconButton(
            icon: LucideIcons.rotate_cw,
            tooltip: 'Erneut versuchen',
            onTap: _isGenerating ? null : () => _retryTurnPrompt(turn),
            foregroundColor: subtleColor,
          ),
          if (metaText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              metaText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: subtleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    required Color foregroundColor,
  }) {
    return Semantics(
      button: onTap != null,
      label: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatGenerationDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000.0;
    if (seconds < 10) {
      return '${seconds.toStringAsFixed(1).replaceAll('.', ',')} s';
    } else {
      return '${seconds.toStringAsFixed(0)} s';
    }
  }

  Future<void> _copyResponseMarkdown(_DemoChatTurn turn) async {
    await Clipboard.setData(ClipboardData(text: turn.response));
    unawaited(HapticFeedbackService.instance.selectionFeedback());
    setState(() => _copiedTurn = turn);
    _copiedTurnTimer?.cancel();
    _copiedTurnTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copiedTurn = null);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Antwort im Markdown-Format kopiert'),
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Gesamten Chat',
          onPressed: _copyFullChatMarkdown,
        ),
      ),
    );
  }

  Future<void> _copyFullChatMarkdown() async {
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kompletter Chat im Markdown-Format kopiert'),
        duration: Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _retryTurnPrompt(_DemoChatTurn turn) {
    if (_isGenerating) return;
    final prompt = turn.prompt.trim();
    if (prompt.isEmpty) return;
    final index = _chatTurns.indexOf(turn);
    if (index != -1) {
      setState(() {
        _chatTurns.removeRange(index, _chatTurns.length);
      });
    }
    _chatInputController.text = prompt;
    _sendDemoPrompt();
  }

  Future<String> _resolveCurrentModelName() async {
    if (!widget.useLiveAi) return 'Demo';
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

  String? get _composerModelName => !widget.useLiveAi
      ? 'Demo'
      : (_chatTurns.isNotEmpty ? _chatTurns.last.modelName : null) ??
          _currentModelName;

  String? get _askModelHint {
    final modelName = _composerModelName;
    if (modelName == null || modelName.isEmpty) return null;
    return AppLocalizations.of(context)!.aiAssistantAskModelHint(modelName);
  }

  Widget _buildDemoPermissionCard({
    required ThemeData theme,
    required Color contrastColor,
    required Color surfaceColor,
    required bool isVisible,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkSurface = surfaceColor.computeLuminance() < 0.5;
    final cardTextColor = contrastColor;
    final actionColor =
        isDarkSurface ? Colors.amber.shade300 : Colors.amber.shade700;
    final glassTheme = theme.copyWith(
      brightness: isDarkSurface ? Brightness.dark : Brightness.light,
    );
    const radius = 18.0;
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: DesignConstants.glassShadow(isDarkSurface),
        ),
        child: Theme(
          data: glassTheme,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(
                alpha: isDarkSurface ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.amber.withValues(
                  alpha: isDarkSurface ? 0.48 : 0.34,
                ),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiOverlayDemoRequestLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cardTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionScope(
                  l10n.aiOverlayDemoScope,
                  theme,
                  cardTextColor,
                ),
                const SizedBox(height: 4),
                _buildPermissionScope(
                  l10n.aiOverlayDemoScopeDetails,
                  theme,
                  cardTextColor,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.aiOverlayDemoPurpose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cardTextColor.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 10),
                if (_permissionPending)
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => _resolveDemoPermission(false),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              cardTextColor.withValues(alpha: 0.72),
                        ),
                        child: Text(l10n.aiOverlayDemoDeny),
                      ),
                      FilledButton(
                        onPressed: () => _resolveDemoPermission(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(l10n.aiOverlayDemoAllowOnce),
                      ),
                    ],
                  )
                else
                  Text(
                    _permissionApproved == true
                        ? l10n.aiOverlayDemoApprovedFeedback
                        : l10n.aiOverlayDemoDeniedFeedback,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cardTextColor.withValues(alpha: 0.72),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      onEnd: () {
        if (_followChatTail) _scrollChatToBottom();
      },
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: isVisible ? 1 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: ExcludeSemantics(
              excluding: !isVisible,
              child: card,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionScope(
    String text,
    ThemeData theme,
    Color contrastColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 9),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: contrastColor.withValues(alpha: 0.76),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: contrastColor),
            ),
          ),
        ],
      ),
    );
  }

  void _sendDemoPrompt() {
    if (_isGenerating) return;
    final prompt = _chatInputController.text.trim();
    if (prompt.isEmpty) return;

    final history = <AiOverlayLiveChatTurn>[
      if (widget.useLiveAi)
        for (final turn in _chatTurns)
          if (turn.prompt.trim().isNotEmpty && turn.response.trim().isNotEmpty)
            AiOverlayLiveChatTurn(prompt: turn.prompt, response: turn.response),
    ];

    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    _liveResponseSubscription?.cancel();
    _liveResponseSubscription = null;
    _liveChunkFlushTimer?.cancel();
    _liveChunkFlushTimer = null;
    _pendingLiveChunks.clear();
    _liveStreamCompleted = false;
    _pendingLiveError = null;
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;

    final turn = _DemoChatTurn(prompt)
      ..generationStartedAt = DateTime.now()
      ..modelName = widget.useLiveAi ? null : 'Demo';

    setState(() {
      _permissionBadgeDelayTimer?.cancel();
      _chatTurns.add(turn);
      _isLoadingCloudVisible = true;
      _isLoadingCloudDismissing = false;
      _isGenerating = true;
      _hasCompletedResponse = false;
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _followChatTail = true;
      _demoWordIndex = 0;
      _chatInputController.clear();
    });
    if (widget.useLiveAi) {
      unawaited(_resolveCurrentModelName().then((name) {
        if (mounted && turn.modelName == null) {
          setState(() => turn.modelName = name);
        }
      }));
    }
    _loadingCloudEnterFuture = _loadingCloudController.forward(from: 0.0);
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(true);
    _scrollChatToBottom(force: true);

    if (widget.useLiveAi) {
      _liveResponseSubscription = AiOverlayLiveChatService.instance
          .streamChat(prompt: prompt, history: history)
          .listen(
        (chunk) {
          if (!mounted ||
              _activeGenerationId != generationId ||
              !_isGenerating ||
              _chatTurns.isEmpty) {
            return;
          }
          if (_isLoadingCloudVisible ||
              _liveChunkFlushTimer != null ||
              _pendingLiveChunks.isNotEmpty) {
            _pendingLiveChunks.add(chunk);
            if (_isLoadingCloudVisible && !_isLoadingCloudDismissing) {
              unawaited(_dismissLoadingCloudAndStartStreaming(generationId));
            }
            return;
          }
          setState(() {
            _chatTurns.last.response += chunk;
          });
          _triggerWordHapticIfNeeded(_chatTurns.last.response);
          _scrollChatToBottom();
        },
        onError: (Object error) {
          _liveResponseSubscription = null;
          if (!mounted || _activeGenerationId != generationId) return;
          _pendingLiveError = error.toString();
          if (_isLoadingCloudVisible) {
            if (!_isLoadingCloudDismissing) {
              unawaited(_dismissLoadingCloudAndStartStreaming(generationId));
            }
            return;
          }
          if (_liveChunkFlushTimer == null) {
            _applyPendingLiveErrorAndFinish();
          }
        },
        onDone: () {
          _liveResponseSubscription = null;
          if (!mounted ||
              _activeGenerationId != generationId ||
              !_isGenerating) {
            return;
          }
          _liveStreamCompleted = true;
          if (_isLoadingCloudVisible) {
            if (!_isLoadingCloudDismissing) {
              unawaited(_dismissLoadingCloudAndStartStreaming(generationId));
            }
            return;
          }
          if (_liveChunkFlushTimer == null && _pendingLiveChunks.isEmpty) {
            _completeDemoGeneration();
          }
        },
      );
      return;
    }

    unawaited(_startDemoStreamingAfterLoadingCloud(generationId));
  }

  Future<void> _startDemoStreamingAfterLoadingCloud(int generationId) async {
    try {
      final enterFuture = _loadingCloudEnterFuture;
      if (enterFuture != null) {
        await enterFuture;
      }
      if (!mounted || _activeGenerationId != generationId || !_isGenerating) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 360));
      if (!mounted || _activeGenerationId != generationId || !_isGenerating) {
        return;
      }
      _isLoadingCloudDismissing = true;
      await _loadingCloudController.reverse();
    } catch (_) {
      // Animation disposed or interrupted.
    }
    if (!mounted || _activeGenerationId != generationId || !_isGenerating) {
      return;
    }
    setState(() {
      _isLoadingCloudVisible = false;
      _isLoadingCloudDismissing = false;
    });
    _startDemoResponseTicker();
  }

  Future<void> _dismissLoadingCloudAndStartStreaming(int generationId) async {
    if (_isLoadingCloudDismissing) return;
    _isLoadingCloudDismissing = true;
    try {
      final enterFuture = _loadingCloudEnterFuture;
      if (enterFuture != null && _loadingCloudController.isAnimating) {
        await enterFuture;
        if (!mounted || _activeGenerationId != generationId) return;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (!mounted || _activeGenerationId != generationId) return;
      await _loadingCloudController.reverse();
    } catch (_) {
      // Animation disposed or interrupted.
    }
    if (!mounted || _activeGenerationId != generationId) return;
    setState(() {
      _isLoadingCloudVisible = false;
      _isLoadingCloudDismissing = false;
    });
    _startFlushingPendingLiveChunks(generationId);
  }

  void _startFlushingPendingLiveChunks(int generationId) {
    if (!mounted || _activeGenerationId != generationId) return;
    if (_pendingLiveChunks.isEmpty) {
      if (_pendingLiveError != null) {
        _applyPendingLiveErrorAndFinish();
      } else if (_liveStreamCompleted && _isGenerating) {
        _completeDemoGeneration();
      }
      return;
    }

    void emitNextBufferedChunk() {
      if (!mounted ||
          _activeGenerationId != generationId ||
          _chatTurns.isEmpty ||
          _pendingLiveChunks.isEmpty) {
        return;
      }
      final nextChunk = _pendingLiveChunks.removeAt(0);
      setState(() {
        _chatTurns.last.response += nextChunk;
      });
      _triggerWordHapticIfNeeded(_chatTurns.last.response);
      _scrollChatToBottom();
    }

    emitNextBufferedChunk();
    if (_pendingLiveChunks.isEmpty) {
      if (_pendingLiveError != null) {
        _applyPendingLiveErrorAndFinish();
      } else if (_liveStreamCompleted && _isGenerating) {
        _completeDemoGeneration();
      }
      return;
    }

    _liveChunkFlushTimer?.cancel();
    _liveChunkFlushTimer = Timer.periodic(
      const Duration(milliseconds: 24),
      (timer) {
        if (!mounted ||
            _activeGenerationId != generationId ||
            !_isGenerating ||
            _chatTurns.isEmpty) {
          timer.cancel();
          _liveChunkFlushTimer = null;
          return;
        }
        emitNextBufferedChunk();
        if (_pendingLiveChunks.isEmpty) {
          timer.cancel();
          _liveChunkFlushTimer = null;
          if (_pendingLiveError != null) {
            _applyPendingLiveErrorAndFinish();
          } else if (_liveStreamCompleted && _isGenerating) {
            _completeDemoGeneration();
          }
        }
      },
    );
  }

  void _applyPendingLiveErrorAndFinish() {
    final errorText = _pendingLiveError;
    _pendingLiveError = null;
    if (!mounted) return;
    setState(() {
      if (errorText != null && _chatTurns.isNotEmpty) {
        if (_chatTurns.last.response.trim().isEmpty) {
          _chatTurns.last.response = errorText;
        } else {
          _chatTurns.last.response += '\n\n[$errorText]';
        }
      }
      if (_chatTurns.isNotEmpty) {
        final lastTurn = _chatTurns.last;
        if (lastTurn.generationStartedAt != null) {
          lastTurn.duration =
              DateTime.now().difference(lastTurn.generationStartedAt!);
        }
        lastTurn.modelName ??= widget.useLiveAi ? 'KI' : 'Demo';
      }
      _isGenerating = false;
    });
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(false);
    _scrollChatToBottom();
  }

  Future<void> _reverseLoadingCloudToNothing(int generationId) async {
    if (!_isLoadingCloudVisible) return;
    _isLoadingCloudDismissing = true;
    try {
      if (_loadingCloudController.value > 0.001) {
        await _loadingCloudController.reverse();
      }
    } catch (_) {
      // Animation disposed or interrupted.
    }
    if (!mounted || _activeGenerationId != generationId) return;
    setState(() {
      _isLoadingCloudVisible = false;
      _isLoadingCloudDismissing = false;
    });
  }

  void _stopDemoGeneration() {
    if (!_isGenerating) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    _liveResponseSubscription?.cancel();
    _liveResponseSubscription = null;
    _liveChunkFlushTimer?.cancel();
    _liveChunkFlushTimer = null;
    _pendingLiveChunks.clear();
    _liveStreamCompleted = false;
    _pendingLiveError = null;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null && lastTurn.duration == null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??= widget.useLiveAi ? 'KI' : 'Demo';
    }
    setState(() => _isGenerating = false);
    if (_isLoadingCloudVisible) {
      unawaited(_reverseLoadingCloudToNothing(generationId));
    }
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(false);
  }

  void _completeDemoGeneration() {
    if (!_isGenerating) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    _liveResponseSubscription?.cancel();
    _liveResponseSubscription = null;
    _liveChunkFlushTimer?.cancel();
    _liveChunkFlushTimer = null;
    _pendingLiveChunks.clear();
    _liveStreamCompleted = false;
    _pendingLiveError = null;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    if (_chatTurns.isNotEmpty) {
      final lastTurn = _chatTurns.last;
      if (lastTurn.generationStartedAt != null) {
        lastTurn.duration =
            DateTime.now().difference(lastTurn.generationStartedAt!);
      }
      lastTurn.modelName ??= widget.useLiveAi ? 'KI' : 'Demo';
    }
    final wasDocked = !_isExpanded && _morphAnimation.value <= 0.005;
    setState(() {
      _isGenerating = false;
      _hasCompletedResponse = wasDocked;
      _permissionPending = false;
      _attentionPeekDismissed = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _completionPulse = wasDocked;
    });
    if (_isLoadingCloudVisible) {
      unawaited(_reverseLoadingCloudToNothing(generationId));
    }
    _permissionBadgeDelayTimer?.cancel();
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.strongImpact());
    widget.onGenerationChanged?.call(false);
    _scrollChatToBottom();
    if (_completionPulse) _scheduleCompletionPulseReset();
  }

  void _requestDemoPermission() {
    if (widget.useLiveAi || !_isGenerating || _chatTurns.isEmpty) return;
    final generationId = ++_activeGenerationId;
    _responseTimer?.cancel();
    _responseTimer = null;
    setState(() {
      _isGenerating = false;
      _hasCompletedResponse = false;
      _permissionPending = true;
      _attentionPeekDismissed = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
    });
    if (_isLoadingCloudVisible) {
      unawaited(_reverseLoadingCloudToNothing(generationId));
    }
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        if (!mounted || !_permissionPending) return;
        setState(() => _showPermissionBadge = true);
      },
    );
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.strongImpact());
    widget.onGenerationChanged?.call(false);
    _scrollChatToBottom();
  }

  void _resolveDemoPermission(bool approved) {
    if (approved) {
      _permissionBadgeDelayTimer?.cancel();
      _permissionBadgeDelayTimer = null;
      setState(() {
        _permissionPending = false;
        _showPermissionBadge = false;
        _permissionApproved = true;
        _hasCompletedResponse = false;
        _attentionPeekDismissed = false;
        _isGenerating = true;
      });
      _syncDemoWaitingHaptics();
      unawaited(HapticFeedbackService.instance.lightImpact());
      widget.onGenerationChanged?.call(true);
      _startDemoResponseTicker();
      _permissionContinuationTimer = Timer(
        const Duration(seconds: 3),
        _completeDemoGeneration,
      );
      _scrollChatToBottom();
      return;
    }

    setState(() {
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = false;
    });
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = null;
    _scrollChatToBottom();
  }

  void _startDemoResponseTicker() {
    _responseTimer?.cancel();
    _responseTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (!mounted || !_isGenerating || _chatTurns.isEmpty) {
        timer.cancel();
        return;
      }
      setState(() {
        final turn = _chatTurns.last;
        turn.response += '${_demoWords[_demoWordIndex]} ';
        _demoWordIndex = (_demoWordIndex + 1) % _demoWords.length;
        if (_demoWordIndex == 0) turn.response += '\n\n';
      });
      _triggerWordHapticIfNeeded(_chatTurns.last.response);
      _scrollChatToBottom();
    });
  }

  void _scheduleCompletionPulseReset() {
    _completionPulseTimer?.cancel();
    _completionPulseTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _completionPulse = false);
    });
  }

  void _handleChatScroll() {
    if (!_chatScrollController.hasClients) return;
    final position = _chatScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    _followChatTail = distanceToBottom < 80;
    final showButton = distanceToBottom > _scrollToBottomThreshold;
    if (_showScrollToBottom != showButton && mounted) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  void _scrollToLatestMessage() {
    if (!_chatScrollController.hasClients) return;
    _chatContentRevision++;
    _followChatTail = true;
    _chatScrollController.animateTo(
      _chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollChatToBottom({bool force = false}) {
    if (force) {
      _followChatTail = true;
      _chatContentRevision++;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients || !_followChatTail) {
        return;
      }
      _chatScrollController.jumpTo(
        _chatScrollController.position.maxScrollExtent,
      );
    });
  }

  Widget _buildResizeHandle(
    _SafeSpaceCorner corner,
    Offset position,
    Size size,
    ThemeData theme,
  ) {
    const hitTargetSize = 40.0;
    final handleColor = theme.colorScheme.primary;

    return Positioned(
      left: position.dx - hitTargetSize / 2,
      top: position.dy - hitTargetSize / 2,
      width: hitTargetSize,
      height: hitTargetSize,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: FadeTransition(
          opacity: _morphAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onPanUpdate: (details) => _resizeSafeSpace(corner, details, size),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: handleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.maximize_2,
                  size: 10,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoChatTurn {
  _DemoChatTurn(this.prompt);

  final String prompt;
  String response = '';
  String? modelName;
  Duration? duration;
  DateTime? generationStartedAt;
}

class _CloudControlsClipper extends CustomClipper<Rect> {
  const _CloudControlsClipper(this.revealBounds);

  final Rect revealBounds;

  @override
  Rect getClip(Size size) => revealBounds.intersect(Offset.zero & size);

  @override
  bool shouldReclip(covariant _CloudControlsClipper oldClipper) =>
      oldClipper.revealBounds != revealBounds;
}

class _VoiceWaveformPainter extends CustomPainter {
  const _VoiceWaveformPainter({
    required this.samples,
    required this.color,
    required this.scrollOffset,
  }) : super(repaint: scrollOffset);

  final List<_VoiceWaveSample> samples;
  final Color color;
  final ValueListenable<double> scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    const rightInset = 3.5;
    const fadeWidth = 30.0;
    final centerY = size.height / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final currentPosition = scrollOffset.value;

    // A single moving waveform; no stationary baseline remains behind it.
    for (final sample in samples) {
      final age = currentPosition - sample.position;
      if (age < 0 || age > size.width) continue;
      final x = size.width - rightInset - age;
      if (x < 2) continue;
      final halfHeight = 2.0 + sample.level * (size.height * 0.42);
      final leftFade = ((x - 2) / fadeWidth).clamp(0.0, 1.0);
      final rightFade = ((size.width - x) / fadeWidth).clamp(0.0, 1.0);
      paint.color = color.withValues(
        alpha: color.a * math.min(leftFade, rightFade),
      );
      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) =>
      oldDelegate.color != color ||
      !listEquals(oldDelegate.samples, samples) ||
      oldDelegate.scrollOffset != scrollOffset;
}

class _VoiceWaveSample {
  const _VoiceWaveSample({required this.position, required this.level});

  final double position;
  final double level;
}

enum _SafeSpaceCorner { topLeft, topRight, bottomLeft, bottomRight }
