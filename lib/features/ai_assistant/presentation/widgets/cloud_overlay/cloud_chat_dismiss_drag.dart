import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Hands a downward drag at the top of the chat to the overlay dismiss gesture.
/// Pointer observation lets the list retain its normal scrolling and controls.
class CloudChatDismissDrag extends StatefulWidget {
  const CloudChatDismissDrag({
    super.key,
    required this.scrollController,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.child,
  });

  final ScrollController scrollController;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;
  final Widget child;

  @override
  State<CloudChatDismissDrag> createState() => _CloudChatDismissDragState();
}

class _CloudChatDismissDragState extends State<CloudChatDismissDrag> {
  int? _pointer;
  Offset _distance = Offset.zero;
  bool _dragging = false;
  bool _rejected = false;
  VelocityTracker? _velocity;

  bool get _atTop =>
      !widget.scrollController.hasClients ||
      widget.scrollController.position.pixels <=
          widget.scrollController.position.minScrollExtent + 0.5;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _distance = Offset.zero;
    _dragging = false;
    _rejected = false;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer || _rejected) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    if (!_dragging) {
      if (!_atTop) {
        _distance = Offset.zero;
        return;
      }
      _distance += event.delta;
      if (_distance.dx.abs() > 12 && _distance.dx.abs() > _distance.dy.abs()) {
        _rejected = true;
        return;
      }
      if (_distance.dy <= 12 || _distance.dy <= _distance.dx.abs()) return;
      _dragging = true;
      widget.onStart(DragStartDetails(globalPosition: event.position));
      widget.onUpdate(DragUpdateDetails(
        globalPosition: event.position,
        delta: Offset(0, _distance.dy - 12),
      ));
      return;
    }
    widget.onUpdate(DragUpdateDetails(
      globalPosition: event.position,
      delta: Offset(0, event.delta.dy),
    ));
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    if (_dragging) {
      widget.onEnd(
          DragEndDetails(velocity: _velocity?.getVelocity() ?? Velocity.zero));
    }
    _reset();
  }

  void _cancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    if (_dragging) widget.onCancel();
    _reset();
  }

  void _reset() {
    _pointer = null;
    _velocity = null;
    _dragging = false;
    _rejected = false;
    _distance = Offset.zero;
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: widget.child,
      );
}
