import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../util/design_constants.dart';
import 'cloud_overlay_geometry.dart';

/// Resolved layout geometry for the draggable AI cloud and expanded overlay panel.
class CloudOverlayLayout {
  final double width;
  final double viewportHeight;
  final double bottomOcclusion;
  final double minLeft;
  final double maxLeft;
  final double travelDistance;
  final double verticalTravelDistance;
  final double verticalPosition;
  final double left;
  final double top;
  final Offset cloudCenter;
  final Size viewportSize;
  final Rect panelRect;
  final Rect safeRect;
  final Rect fullscreenRect;
  final Rect activeSafeRect;
  final double position;

  const CloudOverlayLayout({
    required this.width,
    required this.viewportHeight,
    required this.bottomOcclusion,
    required this.minLeft,
    required this.maxLeft,
    required this.travelDistance,
    required this.verticalTravelDistance,
    required this.verticalPosition,
    required this.left,
    required this.top,
    required this.cloudCenter,
    required this.viewportSize,
    required this.panelRect,
    required this.safeRect,
    required this.fullscreenRect,
    required this.activeSafeRect,
    required this.position,
  });

  Offset handlePosition(
      Offset corner, Offset direction, MediaQueryData mediaQuery) {
    const handleOutset = 44.0;
    return Offset(
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
  }
}

/// Manages docking physics, drag gestures, resting coordinates, and panel resize bounds.
class CloudDockingController extends ChangeNotifier {
  static const horizontalInset = DesignConstants.spacingL;
  static const cloudSize = 160.0;
  static const visibleEdgeConst = 64.0;
  static const topGap = 2.0;
  static const topVisualInset = 28.0;
  static const snapThreshold = 48.0;

  final TickerProvider vsync;

  double? _horizontalPosition;
  double? _verticalPosition;
  double _rotationRadians = 0;
  double _scale = 1;
  bool _isDragging = false;
  double _safeLeft = 0.14;
  double _safeTop = 0.10;
  double _safeRight = 0.86;
  double _safeBottom = 0.90;

  late final AnimationController _initialDockController;
  Timer? _initialDockStartTimer;
  bool _initialDockScheduled = false;
  double _displayedHorizontalPosition = 0;
  bool _isDisposed = false;

  CloudDockingController({required this.vsync}) {
    _initialDockController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 420),
    )..addListener(_handleInitialDockTick);
  }

  double? get horizontalPosition => _horizontalPosition;
  double? get verticalPosition => _verticalPosition;
  double get rotationRadians => _rotationRadians;
  double get scale => _scale;
  bool get isDragging => _isDragging;
  double get safeLeft => _safeLeft;
  double get safeTop => _safeTop;
  double get safeRight => _safeRight;
  double get safeBottom => _safeBottom;
  double get displayedHorizontalPosition => _displayedHorizontalPosition;
  AnimationController get initialDockAnimation => _initialDockController;

  void _handleInitialDockTick() {
    if (!_isDisposed) notifyListeners();
  }

  void stopInitialDock() {
    _initialDockStartTimer?.cancel();
    _initialDockStartTimer = null;
    _initialDockController.stop();
  }

  void cancelInitialDockTimer() {
    _initialDockStartTimer?.cancel();
    _initialDockStartTimer = null;
  }

  void scheduleInitialDockIfNeeded({
    required bool isExpanded,
  }) {
    if (_initialDockScheduled) return;
    _initialDockScheduled = true;
    _initialDockStartTimer = Timer(
      const Duration(milliseconds: 650),
      () {
        _initialDockStartTimer = null;
        if (!_isDisposed &&
            !isExpanded &&
            !_isDragging &&
            _horizontalPosition == null) {
          _initialDockController.forward();
        }
      },
    );
  }

  void handleDragStart({
    required double initialHorizontalPosition,
    required double initialVerticalPosition,
    required VoidCallback onTakeoverAttention,
  }) {
    stopInitialDock();
    _horizontalPosition = initialHorizontalPosition;
    _verticalPosition = initialVerticalPosition;
    _isDragging = true;
    _rotationRadians = 0;
    _scale = 1.035;
    onTakeoverAttention();
    notifyListeners();
  }

  void handleDragUpdate(
    DragUpdateDetails details, {
    required double horizontalTravelDistance,
    required double verticalTravelDistance,
  }) {
    if (horizontalTravelDistance <= 0 && verticalTravelDistance <= 0) return;

    if (horizontalTravelDistance > 0) {
      _horizontalPosition = ((_horizontalPosition ?? 0.0) +
              details.delta.dx / horizontalTravelDistance)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    if (verticalTravelDistance > 0) {
      _verticalPosition = ((_verticalPosition ?? 0.0) -
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
    notifyListeners();
  }

  void handleDragEnd({
    required double minLeft,
    required double maxLeft,
    required bool isExpanded,
  }) {
    if (isExpanded) return;

    final position = _horizontalPosition;
    if (position != null) {
      final currentLeft = minLeft + position * (maxLeft - minLeft);
      if (currentLeft - minLeft <= snapThreshold) {
        _horizontalPosition = 0;
      } else if (maxLeft - currentLeft <= snapThreshold) {
        _horizontalPosition = 1;
      }
    }
    _isDragging = false;
    _rotationRadians = 0;
    _scale = 1;
    notifyListeners();
  }

  void resizeSafeSpace(
    SafeSpaceCorner corner,
    DragUpdateDetails details,
    Size size,
  ) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    const minWidth = 0.34;
    const minHeight = 0.42;
    const edgeInset = 0.04;

    switch (corner) {
      case SafeSpaceCorner.topLeft:
        _safeLeft =
            (_safeLeft + dx).clamp(edgeInset, _safeRight - minWidth).toDouble();
        _safeTop = (_safeTop + dy)
            .clamp(edgeInset, _safeBottom - minHeight)
            .toDouble();
      case SafeSpaceCorner.topRight:
        _safeRight = (_safeRight + dx)
            .clamp(_safeLeft + minWidth, 1 - edgeInset)
            .toDouble();
        _safeTop = (_safeTop + dy)
            .clamp(edgeInset, _safeBottom - minHeight)
            .toDouble();
      case SafeSpaceCorner.bottomLeft:
        _safeLeft =
            (_safeLeft + dx).clamp(edgeInset, _safeRight - minWidth).toDouble();
        _safeBottom = (_safeBottom + dy)
            .clamp(_safeTop + minHeight, 1 - edgeInset)
            .toDouble();
      case SafeSpaceCorner.bottomRight:
        _safeRight = (_safeRight + dx)
            .clamp(_safeLeft + minWidth, 1 - edgeInset)
            .toDouble();
        _safeBottom = (_safeBottom + dy)
            .clamp(_safeTop + minHeight, 1 - edgeInset)
            .toDouble();
    }
    notifyListeners();
  }

  void onExpandToggle({required bool expanding}) {
    stopInitialDock();
    _horizontalPosition ??= _displayedHorizontalPosition;
    _verticalPosition ??= 0.0;
    _isDragging = false;
    _rotationRadians = 0;
    _scale = 1;
    notifyListeners();
  }

  CloudOverlayLayout computeLayout({
    required BoxConstraints constraints,
    required MediaQueryData mediaQuery,
    required bool hasAttentionState,
    required bool attentionPeekDismissed,
    required double fullscreenProgress,
  }) {
    final width = math.max(0.0, constraints.maxWidth).toDouble();
    final viewportHeight = math
        .min(
          constraints.maxHeight,
          mediaQuery.size.height - mediaQuery.viewInsets.bottom,
        )
        .clamp(0.0, double.infinity)
        .toDouble();
    final bottomOcclusion = constraints.maxHeight - viewportHeight;
    final visibleEdge = math.min(visibleEdgeConst, width / 2).toDouble();
    final minLeft = visibleEdge - cloudSize;
    final maxLeft = math.max(minLeft, width - visibleEdge).toDouble();
    final travelDistance = math.max(0.0, maxLeft - minLeft).toDouble();

    final defaultLeft = horizontalInset.clamp(minLeft, maxLeft).toDouble();
    final defaultPosition = travelDistance == 0
        ? 0.0
        : ((defaultLeft - minLeft) / travelDistance).clamp(0.0, 1.0).toDouble();

    final dockProgress = Curves.easeOutCubic.transform(
      _initialDockController.value,
    );
    final requestedPosition = _horizontalPosition ??
        (defaultPosition + (0.0 - defaultPosition) * dockProgress);
    final requestedLeft = minLeft + requestedPosition * travelDistance;

    const attentionPeekInset = 20.0;
    final isDockedLeft = requestedLeft <= minLeft + 8;
    final isDockedRight = requestedLeft >= maxLeft - 8;
    final left =
        hasAttentionState && !attentionPeekDismissed && width > cloudSize
            ? isDockedLeft
                ? -attentionPeekInset
                : isDockedRight
                    ? width - cloudSize + attentionPeekInset
                    : requestedLeft
            : requestedLeft;

    final position = travelDistance == 0
        ? 0.0
        : ((left - minLeft) / travelDistance).clamp(0.0, 1.0).toDouble();
    _displayedHorizontalPosition = position;

    final topBoundary = mediaQuery.padding.top + kToolbarHeight + topGap;
    final panelTop =
        mediaQuery.padding.top + kToolbarHeight + DesignConstants.spacingS;
    final bottomInset = mediaQuery.padding.bottom + DesignConstants.spacingL;

    final minTop =
        math.min(topBoundary - topVisualInset, viewportHeight).toDouble();
    final maxTop =
        math.max(minTop, viewportHeight - bottomInset - cloudSize).toDouble();
    final verticalTravelDistance = math.max(0.0, maxTop - minTop).toDouble();
    final verticalPos = (_verticalPosition ?? 0.0).clamp(0.0, 1.0).toDouble();
    final top = maxTop - verticalPos * verticalTravelDistance;
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
    final fullscreenRect = Rect.fromLTRB(0, 0, width, viewportHeight);
    final activeSafeRect =
        Rect.lerp(safeRect, fullscreenRect, fullscreenProgress)!;
    final cloudCenter = Offset(left + cloudSize / 2, top + cloudSize / 2);

    return CloudOverlayLayout(
      width: width,
      viewportHeight: viewportHeight,
      bottomOcclusion: bottomOcclusion,
      minLeft: minLeft,
      maxLeft: maxLeft,
      travelDistance: travelDistance,
      verticalTravelDistance: verticalTravelDistance,
      verticalPosition: verticalPos,
      left: left,
      top: top,
      cloudCenter: cloudCenter,
      viewportSize: viewportSize,
      panelRect: panelRect,
      safeRect: safeRect,
      fullscreenRect: fullscreenRect,
      activeSafeRect: activeSafeRect,
      position: position,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _initialDockStartTimer?.cancel();
    _initialDockController.dispose();
    super.dispose();
  }
}
