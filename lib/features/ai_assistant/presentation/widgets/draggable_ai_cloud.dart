import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

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
    'Lorem',
    'ipsum',
    'dolor',
    'sit',
    'amet,',
    'consectetur',
    'adipiscing',
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
  final _chatInputController = TextEditingController();
  final _chatFocusNode = FocusNode();
  final _chatScrollController = ScrollController();
  final List<_DemoChatTurn> _chatTurns = [];
  Timer? _responseTimer;
  Timer? _permissionContinuationTimer;
  Timer? _completionPulseTimer;
  Timer? _permissionBadgeDelayTimer;
  Timer? _collapsedWaitingHapticTimer;
  bool _isGenerating = false;
  bool _hasCompletedResponse = false;
  bool _permissionPending = false;
  bool _showPermissionBadge = false;
  bool _attentionPeekDismissed = false;
  bool? _permissionApproved;
  bool _expandedWaitingHapticsActive = false;
  bool _completionPulse = false;
  bool _followChatTail = true;
  bool _showScrollToBottom = false;
  int _demoWordIndex = 0;
  double _safeLeft = 0.14;
  double _safeTop = 0.10;
  double _safeRight = 0.86;
  double _safeBottom = 0.90;
  AnimationController? _morphController;
  AnimationController? _fullscreenController;
  late final AnimationController _sidebarController;
  late final AnimationController _initialDockController;
  Timer? _initialDockStartTimer;
  bool _initialDockScheduled = false;
  double _displayedHorizontalPosition = 0;

  AnimationController get _morphAnimation =>
      _morphController ??= AnimationController(
          vsync: this, duration: const Duration(milliseconds: 760));

  AnimationController get _fullscreenAnimation =>
      _fullscreenController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      )..addListener(_onFullscreenAnimationTick);

  @override
  void initState() {
    super.initState();
    _chatScrollController.addListener(_handleChatScroll);
    _initialDockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_handleInitialDockAnimationTick);
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onSidebarAnimationTick);
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _permissionContinuationTimer?.cancel();
    _completionPulseTimer?.cancel();
    _permissionBadgeDelayTimer?.cancel();
    _collapsedWaitingHapticTimer?.cancel();
    if (_expandedWaitingHapticsActive) {
      HapticFeedbackService.instance.stopAiWaiting();
    }
    _chatInputController.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    _initialDockStartTimer?.cancel();
    _initialDockController.dispose();
    _sidebarController.dispose();
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
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
      _isFullscreen = expanding ? openFullscreen : wasFullscreen;
      _showChatPreview = expanding;
      if (expanding) {
        // A completed response stays highlighted on the minimized orb until
        // the chat is opened again.
        _hasCompletedResponse = false;
        _completionPulse = false;
      }
    });
    _syncDemoWaitingHaptics();
    if (expanding) {
      widget.onExpandedChanged?.call(true);
      widget.onFullscreenChanged?.call(openFullscreen);
      _morphAnimation.forward();
      if (openFullscreen) {
        _fullscreenAnimation.forward(from: 0);
      }
      if (_chatTurns.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isExpanded && _showChatPreview) {
            _chatFocusNode.requestFocus();
          }
        });
      }
    } else {
      _morphAnimation.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isClosing = false;
          if (wasFullscreen) _isFullscreen = false;
        });
        _sidebarController.value = 0;
        if (wasFullscreen) _fullscreenAnimation.reverse();
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
      if (!_expandedWaitingHapticsActive) {
        _expandedWaitingHapticsActive = true;
        haptics.startAiWaiting();
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

  /// Ends the current demo response without requesting more permissions.
  void finishDemoGeneration() => _completeDemoGeneration();

  /// Pauses the current demo response and shows a simulated permission request.
  void requestDemoPermission() => _requestDemoPermission();

  void _onFullscreenAnimationTick() {
    if (mounted) setState(() {});
  }

  void _onSidebarAnimationTick() {
    if (mounted) setState(() {});
  }

  double _sidebarWidth(double viewportWidth) =>
      math.min(viewportWidth * 0.82, 340.0);

  void _openSidebar() {
    if (!_isFullscreen) return;
    _chatFocusNode.unfocus();
    _sidebarController.animateTo(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSidebar() {
    if (_sidebarController.value > 0.5) {
      _sidebarController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _openSidebar();
    }
  }

  void _handleSidebarPointerDown(PointerDownEvent event) {
    if (!_isFullscreen) return;
    _sidebarPointerId = event.pointer;
    _sidebarPointerStart = event.position;
    _sidebarDragStartProgress = _sidebarController.value;
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
    }
    _sidebarPointerId = null;
    _sidebarPointerStart = null;
    _sidebarPointerDragging = false;
  }

  void _selectSidebarExample(int index) {
    setState(() => _selectedSidebarExample = index);
    _sidebarController.reverse();
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
        final minTop = math
            .min(topBoundary - _topVisualInset, constraints.maxHeight)
            .toDouble();
        final maxTop = math
            .max(minTop, constraints.maxHeight - bottomInset - _cloudSize)
            .toDouble();
        final verticalTravelDistance =
            math.max(0.0, maxTop - minTop).toDouble();
        final verticalPosition =
            (_verticalPosition ?? 1.0).clamp(0.0, 1.0).toDouble();
        final top = maxTop - verticalPosition * verticalTravelDistance;
        final viewportSize = Size(width, constraints.maxHeight);
        final panelRect = Rect.fromLTRB(
          DesignConstants.spacingS,
          panelTop,
          width - DesignConstants.spacingS,
          constraints.maxHeight -
              mediaQuery.padding.bottom -
              DesignConstants.spacingS,
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
          constraints.maxHeight,
        );
        final fullscreenProgress = Curves.easeInOutCubic.transform(
          _fullscreenAnimation.value,
        );
        final activeSafeRect =
            Rect.lerp(safeRect, fullscreenRect, fullscreenProgress)!;
        const handleOutset = 44.0;
        final cloudCenter = Offset(left + _cloudSize / 2, top + _cloudSize / 2);
        final morphAnimation = _morphAnimation;
        final theme = Theme.of(context);
        Offset handlePosition(Offset corner, Offset direction) => Offset(
              (corner.dx + direction.dx * handleOutset)
                  .clamp(28.0, width - 28.0)
                  .toDouble(),
              (corner.dy + direction.dy * handleOutset)
                  .clamp(
                    mediaQuery.padding.top + 28.0,
                    constraints.maxHeight - mediaQuery.padding.bottom - 28.0,
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
                      constraints.maxHeight -
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
                    child: Tooltip(
                      message: l10n.aiOverlayDemoAssistantSection,
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
                        constraints.maxHeight <= 0
                            ? 0
                            : cloudCenter.dy / constraints.maxHeight * 2 - 1,
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
                                _buildDemoSidebar(theme, width),
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
                                        ? () => _sidebarController.animateTo(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 240,
                                              ),
                                              curve: Curves.easeOutCubic,
                                            )
                                        : null,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildChatPreview(
                                          activeSafeRect,
                                          theme,
                                          constraints.maxHeight,
                                          fullscreenProgress:
                                              fullscreenProgress,
                                        ),
                                        _buildExpandedToolbar(
                                          activeSafeRect,
                                          theme,
                                          fullscreenProgress:
                                              fullscreenProgress,
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
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final contrastColor = isDark ? Colors.black : Colors.white;
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
                isDark: isDark,
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
                            color: contrastColor.withValues(alpha: 0.24),
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
                  isDark: isDark,
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
                isDark: isDark,
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
    required bool isDark,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final foreground =
        foregroundColor ?? (isDark ? Colors.black : Colors.white);
    final cloudIsDark = !isDark;
    // The cloud's surface is inverted from the app theme: white in dark mode
    // and black in light mode. Tune the glass against that actual backdrop.
    final settings = DesignConstants.liquidGlassSettings(!isDark).copyWith(
      thickness: 18,
      blur: 1.5,
    );
    final rimColor = foreground.withValues(alpha: 0.14);
    final buttonSurface = Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (cloudIsDark
                ? DesignConstants.glassNeutralTint(true)
                : Colors.black.withValues(alpha: 0.04)),
        shape: BoxShape.circle,
        border: Border.all(color: rimColor, width: 0.5),
      ),
      child: Center(child: Icon(icon, size: 20, color: foreground)),
    );
    final useStaticGlass =
        _isClosing || (_isExpanded && _morphAnimation.value < 1);
    final glassContent = useStaticGlass
        ? buttonSurface
        : InheritedLiquidGlass(
            settings: settings,
            isBlurProvidedByAncestor: true,
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
                  glowColor: foreground.withValues(alpha: 0.12),
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
          boxShadow: DesignConstants.glassShadow(cloudIsDark),
        ),
        child: glassContent,
      ),
    );
    return Tooltip(
      message: tooltip,
      child: onPressed == null
          ? button
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: button,
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
    _responseTimer?.cancel();
    _responseTimer = null;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    _permissionBadgeDelayTimer?.cancel();
    _completionPulseTimer?.cancel();
    setState(() {
      _chatTurns.clear();
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
  }) {
    final cloudIsDark = !isDark;
    final radius = 24.0;
    final settings = DesignConstants.liquidGlassSettings(!isDark).copyWith(
      thickness: 18,
      blur: 1.5,
    );
    final button = Container(
      height: 48,
      decoration: BoxDecoration(
        color: cloudIsDark
            ? DesignConstants.glassNeutralTint(true)
            : Colors.black.withValues(alpha: 0.04),
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
          boxShadow: DesignConstants.glassShadow(cloudIsDark),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleSidebar,
          child: InheritedLiquidGlass(
            settings: settings,
            isBlurProvidedByAncestor: true,
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
                  glowColor: foregroundColor.withValues(alpha: 0.12),
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

  Widget _buildDemoSidebar(ThemeData theme, double viewportWidth) {
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? Colors.white : Colors.black;
    final foregroundColor = isDark ? Colors.black : Colors.white;
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
                        isDark: isDark,
                        foregroundColor: foregroundColor,
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
    required double fullscreenProgress,
  }) {
    final contrastColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    final selectionBlue = theme.brightness == Brightness.dark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
    final softColor = contrastColor.withValues(alpha: 0.08);
    final cloudSurfaceDark = theme.brightness != Brightness.dark;
    final composerGlassSettings =
        DesignConstants.liquidGlassSettings(cloudSurfaceDark).copyWith(
      thickness: 18,
      blur: 1.5,
    );
    final isGlassTransitioning =
        _isClosing || (_isExpanded && _morphAnimation.value < 1);
    const contentInset = 8.0;
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
    final scrollViewportTop =
        math.min(chatTop, MediaQuery.paddingOf(context).top + 8);
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
    final composerSurface = Container(
      decoration: BoxDecoration(
        color: cloudSurfaceDark
            ? DesignConstants.glassNeutralTint(true)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: contrastColor.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextSelectionTheme(
                data: TextSelectionThemeData(
                  cursorColor: selectionBlue,
                  selectionColor: selectionBlue.withValues(alpha: 0.32),
                  selectionHandleColor: selectionBlue,
                ),
                child: TextField(
                  controller: _chatInputController,
                  focusNode: _chatFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!_isGenerating) _sendDemoPrompt();
                  },
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contrastColor,
                  ),
                  cursorColor: selectionBlue,
                  decoration: InputDecoration(
                    hintText: 'Nachricht schreiben …',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildHeaderGlassButton(
              icon: _isGenerating ? LucideIcons.square : LucideIcons.arrow_up,
              tooltip: _isGenerating ? 'Stopp' : 'Senden',
              isDark: theme.brightness == Brightness.dark,
              backgroundColor: cloudSurfaceDark ? Colors.white : Colors.black,
              foregroundColor: cloudSurfaceDark ? Colors.black : Colors.white,
              onPressed: _isGenerating ? _stopDemoGeneration : _sendDemoPrompt,
            ),
          ],
        ),
      ),
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
              bottom: viewportHeight - contentViewportBottom,
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
                          ? Center(
                              child: Text(
                                'Schreib eine Nachricht …',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: contrastColor.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _chatScrollController,
                              padding: EdgeInsets.only(
                                top: chatTop - topFadeStart + 8,
                                bottom: 104,
                              ),
                              itemCount: _chatTurns.length +
                                  (_permissionPending ||
                                          _permissionApproved != null
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == _chatTurns.length) {
                                  return _buildDemoPermissionCard(
                                    theme: theme,
                                    contrastColor: contrastColor,
                                  );
                                }
                                return _buildChatTurn(
                                  _chatTurns[index],
                                  theme: theme,
                                  contrastColor: contrastColor,
                                  softColor: softColor,
                                  isStreaming: _isGenerating &&
                                      index == _chatTurns.length - 1,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: composerLeft,
              right: composerRight,
              bottom: viewportHeight - chatBounds.bottom + contentInset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: DesignConstants.glassShadow(cloudSurfaceDark),
                ),
                child: isGlassTransitioning
                    ? composerSurface
                    : InheritedLiquidGlass(
                        settings: composerGlassSettings,
                        isBlurProvidedByAncestor: true,
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
                              glowColor: contrastColor.withValues(alpha: 0.12),
                              glowRadius: 1,
                              child: composerSurface,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: viewportHeight - chatBounds.bottom + 100,
              child: IgnorePointer(
                ignoring: !_showScrollToBottom,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _showScrollToBottom ? 1 : 0,
                  child: Center(
                    child: _buildHeaderGlassButton(
                      icon: LucideIcons.arrow_down,
                      tooltip: 'Zum neuesten Beitrag',
                      isDark: theme.brightness == Brightness.dark,
                      onPressed: _scrollToLatestMessage,
                    ),
                  ),
                ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                turn.prompt,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: contrastColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16),
            child: Text(
              turn.response,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: contrastColor,
                height: 1.5,
              ),
            ),
          ),
          if (isStreaming && turn.response.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 14),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contrastColor.withValues(alpha: 0.58),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemoPermissionCard({
    required ThemeData theme,
    required Color contrastColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasLightCloudSurface = contrastColor == Colors.black;
    final warningColor =
        hasLightCloudSurface ? Colors.orange.shade800 : Colors.amber.shade200;
    final cardTextColor = hasLightCloudSurface ? Colors.black : Colors.white;
    final actionColor =
        hasLightCloudSurface ? Colors.amber.shade700 : Colors.amber.shade300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasLightCloudSurface
              ? const Color(0xFFFFF6E5)
              : const Color(0xFF593A0D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasLightCloudSurface
                ? Colors.amber.shade400
                : Colors.amber.shade600,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.shield_alert, size: 17, color: warningColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aiOverlayDemoRequestLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cardTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPermissionScope(
                l10n.aiOverlayDemoScope, theme, cardTextColor),
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
                      foregroundColor: cardTextColor.withValues(alpha: 0.72),
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

    setState(() {
      _permissionBadgeDelayTimer?.cancel();
      _chatTurns.add(_DemoChatTurn(prompt));
      _isGenerating = true;
      _hasCompletedResponse = false;
      _permissionPending = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _followChatTail = true;
      _demoWordIndex = 0;
      _chatInputController.clear();
    });
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(true);
    _scrollChatToBottom(force: true);

    _responseTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final turn = _chatTurns.last;
        turn.response += '${_demoWords[_demoWordIndex]} ';
        _demoWordIndex = (_demoWordIndex + 1) % _demoWords.length;
        if (_demoWordIndex == 0) turn.response += '\n\n';
      });
      _scrollChatToBottom();
    });
  }

  void _stopDemoGeneration() {
    if (!_isGenerating) return;
    _responseTimer?.cancel();
    _responseTimer = null;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    setState(() => _isGenerating = false);
    _syncDemoWaitingHaptics();
    widget.onGenerationChanged?.call(false);
  }

  void _completeDemoGeneration() {
    if (!_isGenerating) return;
    _responseTimer?.cancel();
    _responseTimer = null;
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
    setState(() {
      _isGenerating = false;
      _hasCompletedResponse = true;
      _permissionPending = false;
      _attentionPeekDismissed = false;
      _showPermissionBadge = false;
      _permissionApproved = null;
      _completionPulse = !_isExpanded && _morphAnimation.value <= 0.005;
    });
    _permissionBadgeDelayTimer?.cancel();
    _syncDemoWaitingHaptics();
    unawaited(HapticFeedbackService.instance.strongImpact());
    widget.onGenerationChanged?.call(false);
    _scrollChatToBottom();
    if (_completionPulse) _scheduleCompletionPulseReset();
  }

  void _requestDemoPermission() {
    if (!_isGenerating || _chatTurns.isEmpty) return;
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
    _followChatTail = true;
    _chatScrollController.animateTo(
      _chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollChatToBottom({bool force = false}) {
    if (force) _followChatTail = true;
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

enum _SafeSpaceCorner { topLeft, topRight, bottomLeft, bottomRight }
