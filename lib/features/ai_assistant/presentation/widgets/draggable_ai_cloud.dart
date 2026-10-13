import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';
import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

/// The existing animated AI cloud, made draggable for the overlay demo.
///
/// Its horizontal and vertical position is interactive and resets when the
/// demo screen is opened again.
class DraggableAiCloud extends StatefulWidget {
  final String semanticLabel;
  final String semanticHint;
  final double liveliness;
  final ValueChanged<double> onLivelinessChanged;

  const DraggableAiCloud({
    super.key,
    required this.semanticLabel,
    required this.semanticHint,
    required this.liveliness,
    required this.onLivelinessChanged,
  });

  @override
  State<DraggableAiCloud> createState() => _DraggableAiCloudState();
}

class _DraggableAiCloudState extends State<DraggableAiCloud>
    with TickerProviderStateMixin {
  static const _horizontalInset = DesignConstants.spacingL;
  static const _cloudSize = 160.0;
  static const _visibleEdge = 64.0;
  static const _topGap = 2.0;
  static const _topVisualInset = 28.0;
  // Release within this many logical pixels of a card edge docks the cloud.
  static const _snapThreshold = 48.0;

  double? _horizontalPosition;
  double? _verticalPosition;
  double _rotationRadians = 0;
  double _scale = 1;
  bool _isDragging = false;
  bool _isExpanded = false;
  double _safeLeft = 0.14;
  double _safeTop = 0.10;
  double _safeRight = 0.86;
  double _safeBottom = 0.90;
  AnimationController? _morphController;

  AnimationController get _morphAnimation =>
      _morphController ??= AnimationController(
          vsync: this, duration: const Duration(milliseconds: 760));

  @override
  void dispose() {
    _morphController?.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final expanding = !_isExpanded;
    setState(() {
      _isExpanded = expanding;
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
    });
    if (expanding) {
      _morphAnimation.forward();
    } else {
      _morphAnimation.reverse();
    }
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
    setState(() {
      _horizontalPosition ??= initialHorizontalPosition;
      _verticalPosition ??= initialVerticalPosition;
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
        final position = _horizontalPosition ?? defaultPosition;
        final left = minLeft + position * travelDistance;
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
        const handleOutset = 36.0;
        final cloudCenter = Offset(left + _cloudSize / 2, top + _cloudSize / 2);
        final morphAnimation = _morphAnimation;
        final theme = Theme.of(context);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildExpandedBackdrop(panelRect, theme),
            Positioned.fill(
              child: IgnorePointer(
                child: AiNeuralCloudOrbWidget(
                  size: _cloudSize * _scale,
                  rotation: _rotationRadians,
                  canvasSize: viewportSize,
                  cloudCenter: cloudCenter,
                  frameRect: safeRect,
                  frameMorphAnimation: morphAnimation,
                  showDetachedSatellite: false,
                  flowSpeed: _isDragging
                      ? 1.55
                      : _isExpanded
                          ? 2.0 * widget.liveliness.clamp(0.0, 1.0)
                          : 0.24,
                  enableInteraction: false,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _isDragging
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
                                  initialHorizontalPosition: defaultPosition,
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
            _buildLivelinessControl(safeRect, theme),
            _buildResizeHandle(
              _SafeSpaceCorner.topLeft,
              safeRect.topLeft + const Offset(-handleOutset, -handleOutset),
              panelRect.size,
              theme,
            ),
            _buildResizeHandle(
              _SafeSpaceCorner.topRight,
              safeRect.topRight + const Offset(handleOutset, -handleOutset),
              panelRect.size,
              theme,
            ),
            _buildResizeHandle(
              _SafeSpaceCorner.bottomLeft,
              safeRect.bottomLeft + const Offset(-handleOutset, handleOutset),
              panelRect.size,
              theme,
            ),
            _buildResizeHandle(
              _SafeSpaceCorner.bottomRight,
              safeRect.bottomRight + const Offset(handleOutset, handleOutset),
              panelRect.size,
              theme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedBackdrop(Rect panelRect, ThemeData theme) {
    final scrimColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _morphAnimation,
        builder: (context, _) {
          final progress = _morphAnimation.value;
          return IgnorePointer(
            ignoring: progress <= 0.001,
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: panelRect,
                  child: ColoredBox(
                    color: scrimColor.withValues(alpha: 0.42 * progress),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleExpanded,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLivelinessControl(Rect safeRect, ThemeData theme) {
    final contrastColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Positioned(
      left: safeRect.left + DesignConstants.spacingS,
      right: MediaQuery.sizeOf(context).width -
          safeRect.right +
          DesignConstants.spacingS,
      top: safeRect.bottom - 88,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: FadeTransition(
          opacity: _morphAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Wolken-Lebhaftigkeit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: contrastColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.liveliness * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: contrastColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: contrastColor,
                  inactiveTrackColor: contrastColor.withValues(alpha: 0.28),
                  thumbColor: contrastColor,
                  overlayColor: contrastColor.withValues(alpha: 0.12),
                  trackHeight: 2.5,
                ),
                child: Slider(
                  value: widget.liveliness.clamp(0.0, 1.0).toDouble(),
                  onChanged: widget.onLivelinessChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  Icons.open_in_full,
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

enum _SafeSpaceCorner { topLeft, topRight, bottomLeft, bottomRight }
