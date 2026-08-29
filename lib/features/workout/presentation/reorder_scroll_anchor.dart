// lib/features/workout/presentation/reorder_scroll_anchor.dart

/// How long an exercise card takes to collapse to its header and to expand
/// again during reorder.
///
/// Shared by the workout and routine screens' [AnimatedSize] and the scroll
/// animation to top.
const Duration kReorderCardResizeDuration = Duration(milliseconds: 280);

/// How long to wait after a drop before expanding the cards again.
///
/// [SliverReorderableList] animates the dropped card into place over 250ms and
/// only applies the reorder itself once that animation completes. Expanding the
/// cards any earlier fights both. One extra frame of slack keeps the expansion
/// strictly after the list has settled.
const Duration kReorderDropSettleDuration = Duration(milliseconds: 270);

