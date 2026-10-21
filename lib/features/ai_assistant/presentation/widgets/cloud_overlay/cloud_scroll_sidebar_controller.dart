import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart';

import '../../../../../services/haptic_feedback_service.dart';

/// Manages sidebar animations, gesture-drag tracking, and chat scroll tail-following for the AI overlay.
class CloudScrollSidebarController extends ChangeNotifier {
  static const _scrollToBottomThreshold = 120.0;

  final TickerProvider vsync;
  final ValueGetter<bool> isFullscreenGetter;
  final VoidCallback? onUnfocus;
  final VoidCallback? onToggleExpanded;
  final AnimationController Function() morphAnimationGetter;

  late final AnimationController _sidebarController;
  final ScrollController chatScrollController = ScrollController();

  double _sidebarDragStartProgress = 0;
  Offset? _sidebarPointerStart;
  int? _sidebarPointerId;
  bool _sidebarPointerDragging = false;
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
    )..addListener(_onSidebarAnimationTick);
    chatScrollController.addListener(_handleChatScroll);
  }

  AnimationController get sidebarAnimation => _sidebarController;
  bool get followChatTail => _followChatTail;
  bool get showScrollToBottom => _showScrollToBottom;
  int get chatUserScrollRevision => _chatUserScrollRevision;
  void incrementUserScrollRevision() => _chatUserScrollRevision++;

  void _onSidebarAnimationTick() {
    if (!_isDisposed) notifyListeners();
  }

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
    _sidebarPointerId = event.pointer;
    _sidebarPointerStart = event.position;
    _sidebarDragStartProgress = _sidebarController.value;
    _sidebarDragStartScrollOffset = captureChatScrollOffset();
    _sidebarDragStartFollowChatTail = _followChatTail;
    _sidebarPointerDragging = false;
    _sidebarPastSnapPoint = _sidebarController.value >= 0.5;
    _sidebarController.stop();
  }

  void handleSidebarPointerMove(PointerMoveEvent event, double width) {
    if (event.pointer != _sidebarPointerId || !isFullscreenGetter()) return;
    final start = _sidebarPointerStart;
    if (start == null) return;
    final offset = event.position - start;
    if (!_sidebarPointerDragging) {
      if (offset.dx.abs() < gestures.kTouchSlop ||
          offset.dx.abs() < offset.dy.abs()) {
        return;
      }
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
      _sidebarController.animateTo(
        _sidebarController.value >= 0.5 ? 1 : 0,
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
    _sidebarPointerDragging = false;
    _sidebarDragStartScrollOffset = null;
    _sidebarDragStartFollowChatTail = true;
  }

  void _handleChatScroll() {
    _updateChatScrollState();
  }

  void refreshChatScrollStateAfterLayout() {
    if (_scrollStateRefreshScheduled || _isDisposed) return;
    _scrollStateRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollStateRefreshScheduled = false;
      if (!_isDisposed) _updateChatScrollState();
    });
  }

  void _updateChatScrollState() {
    if (!chatScrollController.hasClients) {
      _followChatTail = true;
      _setShowScrollToBottom(false);
      return;
    }
    final position = chatScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    _followChatTail = distanceToBottom < 80;
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
    _chatContentRevision++;
    _followChatTail = true;
    chatScrollController.animateTo(
      chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollChatToBottom({bool force = false}) {
    if (force) {
      _followChatTail = true;
      _chatContentRevision++;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !chatScrollController.hasClients || !_followChatTail) {
        return;
      }
      chatScrollController.jumpTo(
        chatScrollController.position.maxScrollExtent,
      );
    });
  }

  void handleHeaderDragStart(DragStartDetails details) {
    _headerDragDistance = 0;
    final morph = morphAnimationGetter();
    _headerDragStartProgress = morph.value;
    morph.stop();
  }

  void handleHeaderDragUpdate(DragUpdateDetails details) {
    _headerDragDistance += details.delta.dy;
    final morph = morphAnimationGetter();
    morph.value =
        (_headerDragStartProgress - _headerDragDistance / 250).clamp(0.0, 1.0);
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
