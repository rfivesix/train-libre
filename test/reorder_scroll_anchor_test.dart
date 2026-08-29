import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/reorder_scroll_anchor.dart';

/// A list whose items collapse to a header-sized box, mirroring what the
/// workout screens do while an exercise is being dragged.
class _CollapsibleList extends StatefulWidget {
  const _CollapsibleList({required this.controller, required this.anchor});

  final ScrollController controller;
  final ReorderScrollAnchor anchor;

  @override
  State<_CollapsibleList> createState() => _CollapsibleListState();
}

class _CollapsibleListState extends State<_CollapsibleList> {
  bool _collapsed = false;

  /// Heights differ per item so a uniform-height shortcut cannot pass by luck.
  double _expandedHeight(int index) => 120.0 + index * 40.0;

  /// Collapses/expands with the anchor holding [anchorId] in place.
  void setCollapsed(bool value, int anchorId) {
    widget.anchor.pin(anchorId, () => setState(() => _collapsed = value));
  }

  /// Collapses/expands without capturing an anchor.
  void setCollapsedUnanchored(bool value) {
    setState(() => _collapsed = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          controller: widget.controller,
          scrollCacheExtent: const ScrollCacheExtent.pixels(5000.0),
          // Mirrors the extra room the workout screens keep while collapsed, so
          // the scroll offset does not get clamped away.
          padding: EdgeInsets.only(bottom: _collapsed ? 800.0 : 0.0),
          itemCount: 20,
          itemBuilder: (context, index) => KeyedSubtree(
            key: widget.anchor.keyFor(index),
            // Mirrors the workout cards: the resize is animated, so the item
            // drifts across many frames instead of landing in a single one.
            child: AnimatedSize(
              duration: kReorderCardResizeDuration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _collapsed ? 50.0 : _expandedHeight(index),
                width: double.infinity,
                child: Text('item $index'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  late ScrollController controller;
  late ReorderScrollAnchor anchor;

  // Sits inside the viewport at scroll offset 1200 in the expanded list.
  const anchorIndex = 6;

  setUp(() {
    controller = ScrollController();
    anchor = ReorderScrollAnchor(controller);
  });

  tearDown(() => controller.dispose());

  Future<_CollapsibleListState> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      _CollapsibleList(controller: controller, anchor: anchor),
    );
    return tester.state<_CollapsibleListState>(find.byType(_CollapsibleList));
  }

  double yOf(WidgetTester tester, int index) =>
      tester.getTopLeft(find.text('item $index')).dy;

  /// Pumps the whole resize animation, returning the worst drift the anchored
  /// item showed on any frame. A one-shot correction passes the endpoints and
  /// fails badly here, which is exactly the regression this guards.
  Future<double> worstDriftWhilePumping(
    WidgetTester tester,
    double expected,
  ) async {
    double worst = 0.0;
    const step = Duration(milliseconds: 16);
    for (Duration t = Duration.zero;
        t < kReorderCardResizeDuration + const Duration(milliseconds: 120);
        t += step) {
      await tester.pump(step);
      final drift = (yOf(tester, anchorIndex) - expected).abs();
      if (drift > worst) worst = drift;
    }
    return worst;
  }

  testWidgets('keeps the anchored item pinned across the whole collapse',
      (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();
    final before = yOf(tester, anchorIndex);

    state.setCollapsed(true, anchorIndex);
    final worst = await worstDriftWhilePumping(tester, before);

    // Everything above the anchor sheds 1020px in this list, and a one-shot
    // correction lets the card trail the animation by up to 157px of that. The
    // sustained, look-ahead-corrected pin keeps it inside a small fraction.
    expect(worst, lessThan(45.0));
    // ...and it has to land exactly on the anchor once the animation settles,
    // because that is the position the drag proxy spawns onto.
    expect(yOf(tester, anchorIndex), closeTo(before, 0.5));
    // The correction has to actually move the viewport, otherwise the test
    // would also pass with a no-op anchor.
    expect(controller.offset, lessThan(1200));
  });

  testWidgets('keeps the anchored item pinned across the whole expansion',
      (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();

    state.setCollapsed(true, anchorIndex);
    await tester.pumpAndSettle();
    final collapsedY = yOf(tester, anchorIndex);

    state.setCollapsed(false, anchorIndex);
    final worst = await worstDriftWhilePumping(tester, collapsedY);

    expect(worst, lessThan(45.0));
    expect(yOf(tester, anchorIndex), closeTo(collapsedY, 0.5));
    expect(controller.offset, closeTo(1200, 0.5));
  });

  testWidgets('the pin releases itself once the resize is over',
      (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();

    state.setCollapsed(true, anchorIndex);
    await tester.pumpAndSettle();
    final settled = controller.offset;

    // A scroll made after the pin expired must stick — the anchor is no longer
    // entitled to drag the viewport back.
    controller.jumpTo(settled + 120);
    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(settled + 120, 0.5));
  });

  testWidgets('discard stops an in-flight pin', (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();

    state.setCollapsed(true, anchorIndex);
    await tester.pump(const Duration(milliseconds: 16));
    anchor.discard();
    final afterDiscard = controller.offset;

    await tester.pumpAndSettle();

    // The collapse runs to completion, but the anchor no longer touches the
    // viewport, so the offset is frozen where discard() left it.
    expect(controller.offset, closeTo(afterDiscard, 0.5));
  });

  testWidgets('restore without a capture leaves the scroll offset alone',
      (tester) async {
    await pumpList(tester);

    controller.jumpTo(600);
    await tester.pump();

    anchor.restore();
    await tester.pump();

    expect(controller.offset, 600);
  });

  testWidgets('discard drops a pending capture', (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(600);
    await tester.pump();

    anchor.capture(anchorIndex);
    anchor.discard();

    state.setCollapsedUnanchored(true);
    await tester.pump();
    anchor.restore();
    await tester.pump();

    expect(controller.offset, 600);
  });
}
