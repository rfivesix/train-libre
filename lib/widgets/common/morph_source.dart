import 'package:flutter/widgets.dart';

/// Signature of the callback a [MorphSourceScope] hands to its builder. Pass
/// it straight to `CardMorphRoute.onSourceVisibilityChanged`.
typedef MorphSourceVisibilityCallback = void Function(bool hidden);

/// Holds the "is a route currently flying a copy of me" state for one element
/// a `CardMorphRoute` morphs out of, and takes that element off screen for the
/// duration of the flight.
///
/// The route draws its own copy of the source inside the container, at the
/// container's position and scale, while the original stays where it is. Both
/// are then on screen at once — most visibly on the way back, where the
/// container's background has already faded out while it is still much larger
/// than the card, so the same card is drawn twice at two sizes until they
/// finally coincide.
///
/// The route flips the callback one frame after the push and back at the very
/// end of the collapse, while the copy still covers the original exactly, so
/// the two are never both absent and nothing blinks at the handover.
///
/// Scoped to the individual source rather than kept in the screen's state on
/// purpose: only this subtree rebuilds when the flight starts and ends, and
/// list items need no identity bookkeeping.
///
/// ```dart
/// MorphSourceScope(
///   builder: (context, setHidden) => Builder(
///     builder: (cardCtx) => Card(
///       onTap: () => Navigator.of(context).push(
///         CardMorphRoute(
///           sourceContext: cardCtx,
///           sourceBuilder: (_) => card,
///           onSourceVisibilityChanged: setHidden,
///           builder: (_) => const DetailScreen(),
///         ),
///       ),
///     ),
///   ),
/// )
/// ```
class MorphSourceScope extends StatefulWidget {
  const MorphSourceScope({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    MorphSourceVisibilityCallback setHidden,
  ) builder;

  @override
  State<MorphSourceScope> createState() => _MorphSourceScopeState();
}

class _MorphSourceScopeState extends State<MorphSourceScope> {
  bool _hidden = false;

  void _setHidden(bool hidden) {
    // Routes hand the source back from `dispose`, which can land after this
    // subtree is gone, and they can also report the same state twice.
    if (!mounted || _hidden == hidden) return;
    setState(() => _hidden = hidden);
  }

  @override
  Widget build(BuildContext context) => MorphSource(
        hidden: _hidden,
        child: widget.builder(context, _setHidden),
      );
}

/// Takes [child] off screen while a route flies a copy of it, without moving
/// anything around it.
///
/// Prefer [MorphSourceScope], which owns the flag; use this directly only when
/// the state has to live somewhere else already.
///
/// [Opacity] rather than [Visibility] on purpose: the original has to keep its
/// size and its place in the layout, or everything below it reflows the moment
/// the morph starts. Neither 0.0 nor 1.0 pushes a save layer, so this costs
/// nothing in either state.
///
/// The two wrappers are always built, even when nothing is hidden. Dropping
/// them in the visible case would change the shape of the tree every time a
/// flight starts and ends, which deactivates everything below and rebuilds it
/// against fresh elements — and a `sourceBuilder` that closed over a context
/// from that subtree would then be looking up a deactivated widget's ancestor
/// for the rest of the flight.
class MorphSource extends StatelessWidget {
  const MorphSource({
    super.key,
    required this.hidden,
    required this.child,
  });

  /// Whether a route is currently flying a copy of [child].
  final bool hidden;

  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: hidden ? 0.0 : 1.0,
        child: IgnorePointer(ignoring: hidden, child: child),
      );
}
