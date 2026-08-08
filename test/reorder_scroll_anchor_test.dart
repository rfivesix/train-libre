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
    widget.anchor.capture(anchorId);
    setState(() => _collapsed = value);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.anchor.restore());
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
            child: SizedBox(
              height: _collapsed ? 50.0 : _expandedHeight(index),
              child: Text('item $index'),
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

  testWidgets('keeps the anchored item pinned while the list collapses',
      (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();
    final before = yOf(tester, anchorIndex);

    state.setCollapsed(true, anchorIndex);
    await tester.pump();
    await tester.pump();

    expect(yOf(tester, anchorIndex), closeTo(before, 0.5));
    // The correction has to actually move the viewport, otherwise the test
    // would also pass with a no-op anchor.
    expect(controller.offset, lessThan(1200));
  });

  testWidgets('keeps the anchored item pinned while the list expands again',
      (tester) async {
    final state = await pumpList(tester);

    controller.jumpTo(1200);
    await tester.pump();

    state.setCollapsed(true, anchorIndex);
    await tester.pump();
    await tester.pump();
    final collapsedY = yOf(tester, anchorIndex);

    state.setCollapsed(false, anchorIndex);
    await tester.pump();
    await tester.pump();

    expect(yOf(tester, anchorIndex), closeTo(collapsedY, 0.5));
    expect(controller.offset, closeTo(1200, 0.5));
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
