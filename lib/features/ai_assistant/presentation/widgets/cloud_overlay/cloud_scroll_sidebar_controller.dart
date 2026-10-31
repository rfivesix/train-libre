import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart';

import '../../../../../services/haptic_feedback_service.dart';
import 'cloud_chat_scroll_constants.dart';

/// Manages sidebar animations, gesture-drag tracking, and chat scroll tail-following for the AI overlay.
class CloudScrollSidebarController extends ChangeNotifier {
  static const _scrollToBottomThreshold = 120.0;
  static const _followChatTailThreshold = cloudChatBottomContentInset + 8.0;

  final TickerProvider vsync;
  final ValueGetter<bool> isFullscreenGetter;
  final VoidCallback? onUnfocus;
  final VoidCallback? onToggleExpanded;
  final AnimationController Function() morphAnimationGetter;

  late final AnimationController _sidebarController;
  final ScrollController chatScrollController = ScrollController();
  final GlobalKey latestMessageEndKey = GlobalKey();

  double _sidebarDragStartProgress = 0;
  Offset? _sidebarPointerStart;
  Duration? _sidebarPointerStartTime;
  Duration? _sidebarLastMoveTime;
  int? _sidebarPointerId;
  bool _sidebarPointerDragging = false;
  bool _sidebarPointerRejected = false;
  gestures.VelocityTracker? _sidebarVelocityTracker;
  int _sidebarVelocitySamples = 0;
  bool _sidebarPastSnapPoint = false;
  double? _sidebarDragStartScrollOffset;
  bool _sidebarDragStartFollowChatTail = true;

  double _headerDragDistance = 0;
  double _headerDragStartProgress = 1;

  bool _followChatTail = true;
  bool _showScrollToBottom = false;
  bool _scrollStateRefreshScheduled = false;
  int _chatUserScrollRevision = 0;
  int _chatContentRevision = 0;
  int _latestScrollRequestRevision = 0;
  bool _manualLatestScrollInProgress = false;
  bool _isDisposed = false;

  CloudScrollSidebarController({
    required this.vsync,
    required this.isFullscreenGetter,
    required this.morphAnimationGetter,
    this.onUnfocus,
    this.onToggleExpanded,
  }) {
    _sidebarController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 320),
    );
    chatScrollController.addListener(_handleChatScroll);
  }

  AnimationController get sidebarAnimation => _sidebarController;
  bool get followChatTail => _followChatTail;
  bool get showScrollToBottom => _showScrollToBottom;
  int get chatUserScrollRevision => _chatUserScrollRevision;
  void incrementUserScrollRevision() => _chatUserScrollRevision++;

  double sidebarWidth(double viewportWidth) =>
      math.min(viewportWidth * 0.82, 340.0);

  double? captureChatScrollOffset() => chatScrollController.hasClients
      ? chatScrollController.position.pixels
      : null;

  void restoreChatScrollOffsetAfterLayout(
    double? offset, {
    bool? shouldFollowChatTail,
  }) {
    if (offset == null) return;
    final userScrollRevision = _chatUserScrollRevision;
    final contentRevision = _chatContentRevision;
    final shouldFollowTail = shouldFollowChatTail ?? _followChatTail;

    void restore() {
      if (_isDisposed ||
          !chatScrollController.hasClients ||
          _chatUserScrollRevision != userScrollRevision ||
          _chatContentRevision != contentRevision) {
        return;
      }
      final position = chatScrollController.position;
      final target = shouldFollowTail
          ? position.maxScrollExtent
          : offset
                .clamp(position.minScrollExtent, position.maxScrollExtent)
                .toDouble();
      if ((position.pixels - target).abs() > 0.5) {
        chatScrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      restore();
      Future<void>.delayed(const Duration(milliseconds: 420), restore);
    });
  }

  void openSidebar() {
    if (!isFullscreenGetter()) return;
    final chatScrollOffset = captureChatScrollOffset();
    final shouldFollowTail = _followChatTail;
    onUnfocus?.call();
    _sidebarController.animateTo(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    restoreChatScrollOffsetAfterLayout(
      chatScrollOffset,
      shouldFollowChatTail: shouldFollowTail,
    );
  }

  void toggleSidebar() {
    if (_sidebarController.value > 0.5) {
      final chatScrollOffset = captureChatScrollOffset();
      final shouldFollowTail = _followChatTail;
      _sidebarController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      restoreChatScrollOffsetAfterLayout(
        chatScrollOffset,
        shouldFollowChatTail: shouldFollowTail,
      );
    } else {
      openSidebar();
    }
  }

  void closeSidebar() {
    final chatScrollOffset = captureChatScrollOffset();
    final shouldFollowTail = _followChatTail;
    _sidebarController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    restoreChatScrollOffsetAfterLayout(
      chatScrollOffset,
      shouldFollowChatTail: shouldFollowTail,
    );
  }

  void handleSidebarPointerDown(PointerDownEvent event) {
    if (!isFullscreenGetter()) return;
    if (_sidebarPointerId != null) return;
    _sidebarPointerId = event.pointer;
    _sidebarVelocityTracker = gestures.VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _sidebarPointerRejected = false;
    _sidebarVelocitySamples = 1;
    _sidebarPointerStart = event.position;
    _sidebarPointerStartTime = event.timeStamp;
    _sidebarLastMoveTime = event.timeStamp;
    _sidebarDragStartProgress = _sidebarController.value;
    _sidebarDragStartScrollOffset = captureChatScrollOffset();
    _sidebarDragStartFollowChatTail = _followChatTail;
    _sidebarPointerDragging = false;
    _sidebarPastSnapPoint = _sidebarController.value >= 0.5;
  }

  void handleSidebarPointerMove(PointerMoveEvent event, double width) {
    if (event.pointer != _sidebarPointerId || !isFullscreenGetter()) return;
    final start = _sidebarPointerStart;
    if (start == null) return;
    _sidebarVelocityTracker?.addPosition(event.timeStamp, event.position);
    _sidebarVelocitySamples++;
    _sidebarLastMoveTime = event.timeStamp;
    final offset = event.position - start;
    if (_sidebarPointerRejected) return;
    if (!_sidebarPointerDragging) {
      if (offset.distance < gestures.kTouchSlop) return;
      if (offset.dx.abs() <= offset.dy.abs() ||
          (_sidebarDragStartProgress == 0 && offset.dx < 0) ||
          (_sidebarDragStartProgress == 1 && offset.dx > 0)) {
        _sidebarPointerRejected = true;
        return;
      }
      _sidebarController.stop();
      _sidebarPointerDragging = true;
      onUnfocus?.call();
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

  void finishSidebarPointer(PointerEvent event) {
    if (event.pointer != _sidebarPointerId) return;
    if (_sidebarPointerDragging) {
      final estimate = _sidebarVelocitySamples >= 3
          ? _sidebarVelocityTracker?.getVelocityEstimate()
          : null;
      final elapsed =
          event.timeStamp - (_sidebarPointerStartTime ?? event.timeStamp);
      final velocity =
          event.timeStamp - _sidebarLastMoveTime! >
              const Duration(milliseconds: 100)
          ? 0.0
          : estimate?.pixelsPerSecond.dx ??
                (elapsed.inMilliseconds > 0 && elapsed.inMilliseconds <= 100
                    ? (event.position.dx - _sidebarPointerStart!.dx) /
                          (elapsed.inMicroseconds /
                              Duration.microsecondsPerSecond)
                    : 0.0);
      final target = event is PointerCancelEvent
          ? (_sidebarDragStartProgress >= 0.5 ? 1.0 : 0.0)
          : velocity.abs() >= 500
          ? (velocity > 0 ? 1.0 : 0.0)
          : (_sidebarController.value >= 0.5 ? 1.0 : 0.0);
      _sidebarController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      restoreChatScrollOffsetAfterLayout(
        _sidebarDragStartScrollOffset,
        shouldFollowChatTail: _sidebarDragStartFollowChatTail,
      );
    }
    _sidebarPointerId = null;
    _sidebarPointerStart = null;
    _sidebarPointerStartTime = null;
    _sidebarLastMoveTime = null;
    _sidebarVelocityTracker = null;
    _sidebarPointerRejected = false;
    _sidebarPointerDragging = false;
    _sidebarDragStartScrollOffset = null;
    _sidebarDragStartFollowChatTail = true;
  }

  void _handleChatScroll() {
    _updateChatScrollState(updateFollowIntent: true);
  }

  void refreshChatScrollStateAfterLayout() {
    if (_scrollStateRefreshScheduled || _isDisposed) return;
    _scrollStateRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollStateRefreshScheduled = false;
      if (!_isDisposed) _updateChatScrollState(updateFollowIntent: false);
    });
  }

  void _updateChatScrollState({required bool updateFollowIntent}) {
    if (!chatScrollController.hasClients) {
      _followChatTail = true;
      _setShowScrollToBottom(false);
      return;
    }
    final position = chatScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    // A growing response changes maxScrollExtent without user movement.
    // Keep the user's tail-follow choice until their scroll position changes.
    if (updateFollowIntent) {
      _followChatTail = distanceToBottom < _followChatTailThreshold;
    }
    _setShowScrollToBottom(distanceToBottom > _scrollToBottomThreshold);
  }

  void _setShowScrollToBottom(bool showButton) {
    if (_showScrollToBottom != showButton && !_isDisposed) {
      _showScrollToBottom = showButton;
      notifyListeners();
    }
  }

  void scrollToLatestMessage() {
    if (!chatScrollController.hasClients) return;
    final requestRevision = ++_latestScrollRequestRevision;
    final userScrollRevision = _chatUserScrollRevision;
    _chatContentRevision++;
    _manualLatestScrollInProgress = true;
    unawaited(
      _settleScrollAtLatestMessage(
        requestRevision: requestRevision,
        userScrollRevision: userScrollRevision,
      ),
    );
  }

  Future<void> _settleScrollAtLatestMessage({
    required int requestRevision,
    required int userScrollRevision,
  }) async {
    double? previousMaxScrollExtent;

    try {
      // ListView.builder can estimate maxScrollExtent beyond the rendered
      // content end. Materialize the end marker if needed, then reveal that
      // exact render object above the composer instead of targeting the estimate.
      for (var attempt = 0; attempt < 6; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        if (_isDisposed ||
            requestRevision != _latestScrollRequestRevision ||
            userScrollRevision != _chatUserScrollRevision ||
            !chatScrollController.hasClients) {
          return;
        }

        final position = chatScrollController.position;
        final maxScrollExtent = position.maxScrollExtent;
        final latestMessageContext = latestMessageEndKey.currentContext;
        if (latestMessageContext == null) {
          // Materialize a lazy-built latest turn. If the estimated extent
          // carried us past the rendered end, back up one viewport to reveal it.
          var target = maxScrollExtent - position.viewportDimension * 0.7;
          if ((target - position.pixels).abs() <= 1) {
            target = position.pixels - position.viewportDimension * 0.5;
          }
          target = target
              .clamp(position.minScrollExtent, maxScrollExtent)
              .toDouble();
          if ((target - position.pixels).abs() > 1) {
            await chatScrollController.animateTo(
              target,
              duration: Duration(milliseconds: attempt == 0 ? 280 : 180),
              curve: Curves.easeOutCubic,
            );
            continue;
          }
          return;
        }
        if (!latestMessageContext.mounted) continue;

        final alignment =
            ((position.viewportDimension - cloudChatBottomContentInset) /
                    position.viewportDimension)
                .clamp(0.0, 1.0)
                .toDouble();
        await Scrollable.ensureVisible(
          latestMessageContext,
          alignment: alignment,
          duration: Duration(milliseconds: attempt == 0 ? 280 : 180),
          curve: Curves.easeOutCubic,
        );
        await WidgetsBinding.instance.endOfFrame;
        if (_isDisposed ||
            requestRevision != _latestScrollRequestRevision ||
            userScrollRevision != _chatUserScrollRevision ||
            !chatScrollController.hasClients) {
          return;
        }
        final settledMaxScrollExtent =
            chatScrollController.position.maxScrollExtent;
        if (previousMaxScrollExtent != null &&
            (settledMaxScrollExtent - previousMaxScrollExtent).abs() <= 0.5) {
          return;
        }
        previousMaxScrollExtent = settledMaxScrollExtent;
      }
    } finally {
      if (requestRevision == _latestScrollRequestRevision) {
        _manualLatestScrollInProgress = false;
        _updateChatScrollState(updateFollowIntent: true);
      }
    }
  }

  void scrollChatToBottom({bool force = false}) {
    if (force) {
      _latestScrollRequestRevision++;
      _manualLatestScrollInProgress = false;
      _followChatTail = true;
      _chatContentRevision++;
    } else if (_manualLatestScrollInProgress) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed ||
          _manualLatestScrollInProgress ||
          !chatScrollController.hasClients ||
          !_followChatTail) {
        return;
      }
      _jumpToLatestMessageEnd();
    });
  }

  void _jumpToLatestMessageEnd() {
    if (!chatScrollController.hasClients) return;
    final context = latestMessageEndKey.currentContext;
    if (context == null) {
      chatScrollController.jumpTo(
        chatScrollController.position.maxScrollExtent,
      );
      return;
    }
    final viewportDimension = chatScrollController.position.viewportDimension;
    final alignment =
        ((viewportDimension - cloudChatBottomContentInset) / viewportDimension)
            .clamp(0.0, 1.0)
            .toDouble();
    unawaited(
      Scrollable.ensureVisible(
        context,
        alignment: alignment,
        duration: Duration.zero,
      ),
    );
  }

  void handleHeaderDragStart(DragStartDetails details) {
    _headerDragDistance = 0;
    final morph = morphAnimationGetter();
    _headerDragStartProgress = morph.value;
    morph.stop();
    onUnfocus?.call();
  }

  void handleHeaderDragUpdate(DragUpdateDetails details) {
    _headerDragDistance += details.delta.dy;
    final morph = morphAnimationGetter();
    morph.value = (_headerDragStartProgress - _headerDragDistance / 250).clamp(
      0.0,
      1.0,
    );
  }

  void handleHeaderDragEnd(DragEndDetails details) {
    final morph = morphAnimationGetter();
    final shouldCollapse =
        morph.value < 0.55 || details.velocity.pixelsPerSecond.dy > 900;
    if (shouldCollapse) {
      onToggleExpanded?.call();
    } else {
      morph.forward();
    }
    _headerDragDistance = 0;
  }

  @override
  void dispose() {
    _isDisposed = true;
    chatScrollController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }
}
