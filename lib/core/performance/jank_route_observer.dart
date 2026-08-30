import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'jank_recorder.dart';

/// Feeds the current screen name to the [JankRecorder].
///
/// The app pushes its routes as plain `MaterialPageRoute`s without
/// `RouteSettings.name`, so there is nothing to read off the route itself.
/// Rather than touching a hundred navigation call sites, the label is derived
/// from the widget that the route actually mounted: the first descendant whose
/// type name reads like a screen. A route that does carry an explicit name
/// keeps it, so naming a route later simply overrides the guess.
/// Shared instance, mirroring `appRouteObserver`.
final JankRouteObserver jankRouteObserver = JankRouteObserver();

class JankRouteObserver extends NavigatorObserver {
  JankRouteObserver({JankRecorder? recorder})
      : _recorder = recorder ?? JankRecorder.instance;

  final JankRecorder _recorder;
  final List<_TrackedRoute> _stack = <_TrackedRoute>[];

  static final RegExp _screenNamePattern = RegExp(r'(Screen|Page|View|Sheet)$');

  /// Widgets that merely wrap a screen and would win the search by sitting
  /// higher in the tree without saying anything about where the user is.
  static const Set<String> _uninformativeNames = <String>{
    'View',
    'PageView',
    'PageStorage',
    'CustomScrollView',
    'ListView',
    'GridView',
    'TabBarView',
    'NestedScrollView',
    'SingleChildScrollView',
    'BottomSheet',
    'DraggableScrollableSheet',
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _push(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _stack.removeWhere((tracked) => identical(tracked.route, oldRoute));
    }
    if (newRoute != null) {
      _push(newRoute);
    } else {
      _applyTop();
    }
  }

  void _push(Route<dynamic> route) {
    if (route is! PageRoute) return;

    final tracked = _TrackedRoute(route, _explicitName(route) ?? 'Screen');
    tracked.isPinned = _explicitName(route) != null;
    _stack.add(tracked);
    _applyTop();

    if (_explicitName(route) != null) return;

    // The subtree does not exist yet inside didPush, and visiting elements is
    // illegal during build — so resolve one frame later.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_stack.contains(tracked) || tracked.isPinned) return;
      final derived = _deriveName(route);
      if (derived == null) return;
      tracked.label = derived;
      _applyTop();
    });
  }

  void _remove(Route<dynamic> route) {
    _stack.removeWhere((tracked) => identical(tracked.route, route));
    _applyTop();
  }

  /// Lets a screen name its own route, overriding the derived guess.
  ///
  /// The tab shell uses this: switching tabs never reaches the navigator, so
  /// without it the four main tabs — where the user spends most of their
  /// time — would all be recorded under one label.
  void setLabelForRoute(Route<dynamic>? route, String label) {
    if (route == null) return;
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    for (final tracked in _stack) {
      if (!identical(tracked.route, route)) continue;
      tracked.label = trimmed;
      tracked.isPinned = true;
      _applyTop();
      return;
    }
  }

  void _applyTop() {
    if (_stack.isEmpty) {
      _recorder.setScreen(rootScreenLabel);
      return;
    }
    _recorder.setScreen(_stack.last.label);
  }

  /// Fallback label for the window between launch and the first tracked route.
  static const String rootScreenLabel = 'App';

  String? _explicitName(Route<dynamic> route) {
    final name = route.settings.name?.trim();
    if (name == null || name.isEmpty || name == '/') return null;
    return name;
  }

  String? _deriveName(Route<dynamic> route) {
    if (route is! ModalRoute) return null;
    final context = route.subtreeContext;
    if (context == null || !context.mounted) return null;

    String? found;

    void visit(Element element, int depth) {
      if (found != null || depth > 14) return;
      final name = element.widget.runtimeType.toString();
      if (!name.startsWith('_') &&
          !_uninformativeNames.contains(name) &&
          _screenNamePattern.hasMatch(name)) {
        found = name;
        return;
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    try {
      context.visitChildElements((child) => visit(child, 1));
    } catch (_) {
      return null;
    }

    return found;
  }
}

class _TrackedRoute {
  _TrackedRoute(this.route, this.label);

  final Route<dynamic> route;
  String label;

  /// Set once a screen named itself, so the derived guess cannot overwrite it.
  bool isPinned = false;
}
