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

  const DraggableAiCloud({
    super.key,
    required this.semanticLabel,
    required this.semanticHint,
  });

  @override
  State<DraggableAiCloud> createState() => _DraggableAiCloudState();
}

class _DraggableAiCloudState extends State<DraggableAiCloud> {
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              child: Semantics(
                label: widget.semanticLabel,
                hint: widget.semanticHint,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _handleDragStart(
                    initialHorizontalPosition: defaultPosition,
                    initialVerticalPosition: verticalPosition,
                  ),
                  onPanUpdate: (details) => _handleDragUpdate(
                    details,
                    horizontalTravelDistance: travelDistance,
                    verticalTravelDistance: verticalTravelDistance,
                  ),
                  onPanEnd: (_) =>
                      _handleDragEnd(minLeft: minLeft, maxLeft: maxLeft),
                  onPanCancel: () =>
                      _handleDragEnd(minLeft: minLeft, maxLeft: maxLeft),
                  child: AnimatedRotation(
                    turns: _rotationRadians / (2 * math.pi),
                    duration: const Duration(milliseconds: 110),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: _scale,
                      duration: const Duration(milliseconds: 130),
                      curve: Curves.easeOutBack,
                      child: AiNeuralCloudOrbWidget(
                        size: _cloudSize,
                        showDetachedSatellite: false,
                        flowSpeed: _isDragging ? 1.55 : 0.24,
                        enableInteraction: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
