import 'package:flutter/widgets.dart';

/// Keeps a single list item visually pinned while the list relayouts around it.
///
/// The workout screens collapse every exercise card down to its header while a
/// drag is in progress and expand them again afterwards. Both transitions change
/// the height of every card above the one the user is touching, which would
/// otherwise make the list jump under the finger.
///
/// [capture] remembers where the item currently sits on screen, and [restore]
/// — called from a post-frame callback once the relayout has happened — scrolls
/// by exactly the distance the item moved, so it ends up where it started. This
/// measures the real render objects instead of estimating card heights, so it
/// stays correct no matter how many sets or notes a card has.
class ReorderScrollAnchor {
  ReorderScrollAnchor(this._controller);

  final ScrollController _controller;
  final Map<Object, GlobalKey> _itemKeys = {};

  Object? _anchorId;
  double? _anchorY;

  /// The key that must be attached to the card representing [id] for the anchor
  /// to be able to measure it.
  GlobalKey keyFor(Object id) =>
      _itemKeys.putIfAbsent(id, () => GlobalKey(debugLabel: 'anchor_$id'));

  /// Drops any pending measurement without acting on it.
  void discard() {
    _anchorId = null;
    _anchorY = null;
  }

  /// Records the on-screen position of [id]'s card.
  ///
  /// Call this immediately before the `setState` that changes the card heights.
  void capture(Object? id) {
    _anchorId = id;
    _anchorY = id == null ? null : _globalY(id);
  }

  /// Scrolls by the distance the captured card moved during the relayout.
  ///
  /// Does nothing if no measurement was captured, or if the card is no longer
  /// mounted (for example because it scrolled out of the cache extent).
  void restore() {
    final Object? id = _anchorId;
    final double? anchorY = _anchorY;
    discard();
    if (id == null || anchorY == null || !_controller.hasClients) return;

    final double? currentY = _globalY(id);
    if (currentY == null) return;

    final double delta = currentY - anchorY;
    if (delta.abs() < 0.5) return;

    final ScrollPosition position = _controller.position;
    _controller.jumpTo((position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  double? _globalY(Object id) {
    final RenderObject? renderObject =
        _itemKeys[id]?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero).dy;
  }
}

/// How long to wait after a drop before expanding the cards again.
///
/// [SliverReorderableList] animates the dropped card into place over 250ms and
/// only applies the reorder itself once that animation completes. Expanding the
/// cards any earlier fights both. One extra frame of slack keeps the expansion
/// strictly after the list has settled.
const Duration kReorderDropSettleDuration = Duration(milliseconds: 270);
