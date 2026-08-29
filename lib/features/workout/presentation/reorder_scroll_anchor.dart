// lib/features/workout/presentation/reorder_scroll_anchor.dart

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Keeps a single list item visually pinned while the list relayouts around it.
///
/// The workout screens collapse every exercise card down to its header while a
/// drag is in progress and expand them again afterwards. Both transitions change
/// the height of every card above the one the user is touching, which would
/// otherwise make the list jump under the finger.
///
/// The cards resize through an [AnimatedSize], so the relayout is spread over
/// [kReorderCardResizeDuration] rather than landing in a single frame. A
/// one-shot correction would therefore measure the item before it has moved and
/// do nothing at all. [pin] instead re-measures on *every* frame of the
/// animation and scrolls by the distance the item has drifted since the pin
/// started, so the card stays locked under the finger for the whole transition
/// and the drag proxy spawns exactly on top of it.
///
/// The measurements come from the real render objects instead of estimated card
/// heights, so they stay correct no matter how many sets or notes a card has.
class ReorderScrollAnchor {
  ReorderScrollAnchor(this._controller);

  final ScrollController _controller;
  final Map<Object, GlobalKey> _itemKeys = {};

  Object? _anchorId;
  double? _anchorY;

  bool _pinActive = false;
  Duration? _pinStartStamp;
  Duration _pinDuration = Duration.zero;
  bool _pinFrameScheduled = false;
  double _lastResidual = 0.0;
  double _lastTravel = 0.0;
  double _lastCorrection = 0.0;

  /// Corrections below this many logical pixels are left alone — they are below
  /// the visible threshold and jumping for them only creates scroll churn.
  static const double _tolerance = 0.5;

  /// The key that must be attached to the card representing [id] for the anchor
  /// to be able to measure it.
  GlobalKey keyFor(Object id) =>
      _itemKeys.putIfAbsent(id, () => GlobalKey(debugLabel: 'anchor_$id'));

  /// Drops any pending measurement without acting on it, and stops an active
  /// [pin].
  ///
  /// Call this as soon as something else takes over the scroll offset — most
  /// importantly when the reorder drag itself starts, because from that moment
  /// the list is allowed to move the item around under the drag proxy.
  void discard() {
    _anchorId = null;
    _anchorY = null;
    _pinActive = false;
    _pinStartStamp = null;
    _pinDuration = Duration.zero;
    _resetPrediction();
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
  ///
  /// This is the one-shot form, correct only when the relayout lands in a
  /// single frame. Anything that resizes with an animation wants [pin].
  void restore() {
    _correct(lookAhead: false);
    discard();
  }

  /// Holds [id] exactly where it is while [relayout] changes the card heights.
  ///
  /// [relayout] is the `setState` that collapses or expands the cards. The
  /// anchor measures [id] before running it and then keeps re-correcting the
  /// scroll offset every frame for [duration], which must cover the resize
  /// animation. The item therefore never drifts away from the pointer, not even
  /// mid-animation.
  ///
  /// The pin releases itself early if the item disappears, if the scroll view
  /// loses its clients, or if the user starts scrolling — the anchor should
  /// never fight a real gesture.
  void pin(
    Object? id,
    VoidCallback relayout, {
    Duration duration = kReorderCardResizeDuration,
  }) {
    capture(id);
    relayout();

    if (_anchorId == null || _anchorY == null) {
      discard();
      return;
    }

    _pinDuration = duration + _pinSlack;
    _pinActive = true;
    _pinStartStamp = null;
    _resetPrediction();
    _schedulePinFrame();
  }

  void _resetPrediction() {
    _lastResidual = 0.0;
    _lastTravel = 0.0;
    _lastCorrection = 0.0;
  }

  /// One extra beat past the resize animation, so the final frame — where the
  /// curve has settled but the layout may still be one frame behind — is
  /// corrected too.
  static const Duration _pinSlack = Duration(milliseconds: 60);

  void _schedulePinFrame() {
    if (_pinFrameScheduled) return;
    _pinFrameScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _pinFrameScheduled = false;
      _onPinFrame(timeStamp);
    });
    // The correction itself may be the only thing left to do in a frame, so ask
    // for one instead of waiting on the resize animation to produce it.
    SchedulerBinding.instance.scheduleFrame();
  }

  void _onPinFrame(Duration timeStamp) {
    // discard() ran while the frame was in flight.
    if (_anchorId == null || !_pinActive) return;
    _pinStartStamp ??= timeStamp;

    if (!_controller.hasClients) {
      discard();
      return;
    }
    // A real scroll gesture outranks the anchor. Our own jumps leave the
    // direction idle, so anything else here came from the user.
    if (_controller.position.userScrollDirection != ScrollDirection.idle) {
      discard();
      return;
    }

    // The look-ahead is switched off for the final frames so the card settles
    // exactly on the anchor rather than on a prediction — that settled position
    // is what the drag proxy spawns onto.
    final Duration elapsed = timeStamp - _pinStartStamp!;
    final bool lookAhead = elapsed + _lookAheadCutoff < _pinDuration;
    if (!_correct(lookAhead: lookAhead)) {
      // The card is gone (unmounted or scrolled out of the cache extent) and
      // cannot be measured again.
      discard();
      return;
    }

    if (elapsed >= _pinDuration) {
      discard();
      return;
    }
    _schedulePinFrame();
  }

  /// Stops predicting this long before the pin expires — two frames at 60Hz.
  static const Duration _lookAheadCutoff = Duration(milliseconds: 34);

  /// How much of the frame-to-frame change in speed to carry into the
  /// prediction. Tuned against a worst-case collapse — a full card height of
  /// shrinkage on every card above the anchor — where it holds the card within
  /// a few percent of the distance the list travels; 0 (constant speed) and 1
  /// (full extrapolation) both leave noticeably more behind.
  static const double _speedChangeCarry = 0.6;

  /// Applies one correction. Returns false when the card can no longer be
  /// measured, which is the signal to stop pinning.
  ///
  /// A scroll offset written from a post-frame callback only reaches the screen
  /// on the *next* frame, by which time the resize animation has moved the card
  /// on again. Correcting by exactly the drift just measured therefore always
  /// trails the animation by one frame's travel, and that travel peaks in the
  /// middle of the collapse where the curve is fastest — the card visibly sags
  /// away from the finger and comes back. [lookAhead] adds the frame that is
  /// about to happen to the correction so it lands in step instead of behind.
  bool _correct({required bool lookAhead}) {
    final Object? id = _anchorId;
    final double? anchorY = _anchorY;
    if (id == null || anchorY == null) return false;
    if (!_controller.hasClients) return false;

    final double? currentY = _globalY(id);
    if (currentY == null) return false;

    // Everything left over after the previous correction landed.
    final double residual = currentY - anchorY;

    // How far the resize actually moved the card during the last frame. This is
    // not the residual: once the look-ahead starts working the residual falls to
    // near zero, so feeding it back as a speed estimate would make the
    // prediction collapse and then oscillate. Undoing the correction that was
    // already applied recovers the card's real travel.
    final double travel = residual - _lastResidual + _lastCorrection;

    double correction = residual;
    // Only predict once a previous frame has been measured, and only while the
    // card keeps moving the same way — predicting across a direction change
    // would lead the animation the wrong way.
    if (lookAhead && _lastTravel != 0.0 && travel.sign == _lastTravel.sign) {
      // The resize curve eases in and out, so the next frame is not simply a
      // repeat of the last one; carrying part of the change in speed across
      // tracks the curve far more closely than a constant-speed guess. Only
      // part of it, because the ease is not a straight ramp either and a full
      // extrapolation overshoots around the curve's inflection.
      correction += travel + _speedChangeCarry * (travel - _lastTravel);
    }

    _lastResidual = residual;
    _lastTravel = travel;

    if (correction.abs() < _tolerance) {
      _lastCorrection = 0.0;
      return true;
    }

    final ScrollPosition position = _controller.position;
    final double target = (position.pixels + correction)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    // What the viewport will really move by, which is what the next frame has
    // to subtract back out — a clamped jump moves less than we asked for.
    _lastCorrection = target - position.pixels;
    if (_lastCorrection.abs() >= _tolerance) {
      _controller.jumpTo(target);
    }
    return true;
  }

  double? _globalY(Object id) {
    final RenderObject? renderObject =
        _itemKeys[id]?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero).dy;
  }
}

/// How long an exercise card takes to collapse to its header and to expand
/// again during reorder.
///
/// Shared by the workout and routine screens' [AnimatedSize] and the scroll
/// anchor.
const Duration kReorderCardResizeDuration = Duration(milliseconds: 280);

/// Slack kept at both ends of the list while the cards are collapsed.
///
/// The anchor pins a card by scrolling, so it can only hold one that has room
/// to scroll into. A card near the top of the list has none: everything above
/// it shrinks, the card rides up with it, and the correction is clamped away at
/// [ScrollPosition.minScrollExtent] — the list simply cannot scroll past its own
/// beginning. The screens therefore grow this much empty space at the *top* of
/// the content while collapsed, which is what the correction then scrolls
/// through, and the same amount at the bottom so the collapsed list keeps enough
/// extent for the drag to move around in.
const double kReorderCollapseHeadroom = 800.0;

/// How long to wait after a drop before expanding the cards again.
///
/// [SliverReorderableList] animates the dropped card into place over 250ms and
/// only applies the reorder itself once that animation completes. Expanding the
/// cards any earlier fights both. One extra frame of slack keeps the expansion
/// strictly after the list has settled.
const Duration kReorderDropSettleDuration = Duration(milliseconds: 270);

/// The empty space the workout screens grow at the top of their list while the
/// cards are collapsed, so [ReorderScrollAnchor] always has somewhere to scroll.
///
/// Belongs at the very start of the scrollable content — as a
/// [ReorderableListView.header], which is its own sliver ahead of the
/// reorderable one, or as the first child of the enclosing list.
class ReorderHeadroom extends StatelessWidget {
  const ReorderHeadroom({super.key, required this.isDragging});

  /// Whether the cards are collapsed for reordering.
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: kReorderCardResizeDuration,
      curve: Curves.easeInOutCubic,
      height: isDragging ? kReorderCollapseHeadroom : 0.0,
    );
  }
}

