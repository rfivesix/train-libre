import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Connects Android's predictive back events to a custom page route.
class PredictiveBackRouteGesture extends StatefulWidget {
  const PredictiveBackRouteGesture({
    super.key,
    required this.route,
    required this.child,
  });

  final ModalRoute<dynamic> route;
  final Widget child;

  @override
  State<PredictiveBackRouteGesture> createState() =>
      _PredictiveBackRouteGestureState();
}

class _PredictiveBackRouteGestureState extends State<PredictiveBackRouteGesture>
    with WidgetsBindingObserver {
  bool _inProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_inProgress) widget.route.navigator?.didStopUserGesture();
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent event) {
    if (event.isButtonEvent ||
        !widget.route.isCurrent ||
        !widget.route.popGestureEnabled) {
      return false;
    }
    _inProgress = true;
    widget.route.handleStartBackGesture(progress: 1 - event.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent event) {
    widget.route.handleUpdateBackGestureProgress(progress: 1 - event.progress);
  }

  @override
  void handleCancelBackGesture() {
    _inProgress = false;
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    _inProgress = false;
    final navigator = widget.route.navigator;
    if (widget.route.isCurrent) navigator?.pop();
    navigator?.didStopUserGesture();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
