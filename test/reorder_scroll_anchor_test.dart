import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/reorder_scroll_anchor.dart';

class _TestWorkoutReorderList extends StatefulWidget {
  const _TestWorkoutReorderList({
    required this.controller,
    required this.isEditMode,
  });

  final ScrollController controller;
  final bool isEditMode;

  @override
  State<_TestWorkoutReorderList> createState() =>
      _TestWorkoutReorderListState();
}

class _TestWorkoutReorderListState extends State<_TestWorkoutReorderList> {
  bool _isDragging = false;
  final List<String> _items = List.generate(15, (i) => 'Exercise $i');
  late final ReorderScrollAnchor _anchor =
      ReorderScrollAnchor(widget.controller);

  void startReorder(Object anchorId) {
    if (!widget.isEditMode) return;
    _anchor.pin(
      anchorId,
      () => setState(() => _isDragging = true),
    );
  }

  void endReorder(Object anchorId) {
    _anchor.pin(
      anchorId,
      () => setState(() => _isDragging = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: widget.controller,
          scrollCacheExtent: const ScrollCacheExtent.pixels(1500.0),
          children: [
            for (int i = 0; i < _items.length; i++)
              KeyedSubtree(
                key: _anchor.keyFor(_items[i]),
                child: AnimatedSize(
                  duration: kReorderCardResizeDuration,
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: _isDragging ? 50.0 : 150.0,
                    width: double.infinity,
                    child: Text(_items[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late ScrollController controller;

  setUp(() {
    controller = ScrollController();
  });

  tearDown(() => controller.dispose());

  testWidgets(
      'ReorderScrollAnchor pins items and bounds strictly without empty headroom',
      (tester) async {
    await tester.pumpWidget(
      _TestWorkoutReorderList(
        controller: controller,
        isEditMode: true,
      ),
    );
    final state =
        tester.state<_TestWorkoutReorderListState>(find.byType(_TestWorkoutReorderList));

    // Scroll to offset 600
    controller.jumpTo(600.0);
    await tester.pump();

    final initialY = tester.getTopLeft(find.text('Exercise 6')).dy;

    // Trigger reorder pinned on Exercise 6
    state.startReorder('Exercise 6');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // After collapse, Exercise 6 remains pinned at its Y position and minScrollExtent is strictly 0.0
    final afterCollapseY = tester.getTopLeft(find.text('Exercise 6')).dy;
    expect((afterCollapseY - initialY).abs(), lessThan(5.0));
    expect(controller.position.minScrollExtent, 0.0);
  });

  testWidgets('non-edit mode ignores reorder start', (tester) async {
    await tester.pumpWidget(
      _TestWorkoutReorderList(
        controller: controller,
        isEditMode: false,
      ),
    );
    final state =
        tester.state<_TestWorkoutReorderListState>(find.byType(_TestWorkoutReorderList));

    final initialY = tester.getTopLeft(find.text('Exercise 3')).dy;
    state.startReorder('Exercise 3');
    await tester.pumpAndSettle();

    // In non-edit mode, cards do not collapse
    expect(tester.getTopLeft(find.text('Exercise 3')).dy, initialY);
  });

  testWidgets('calculateDynamicReorderHeadroom calculates exact needed gap',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [
              SizedBox(height: 50, child: Text('Header')),
            ],
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Header'));

    // Item 0 at Y = 200 (viewportTop = 0): headroom is 200 - 0 = 200
    final headroom0 = calculateDynamicReorderHeadroom(
      context: context,
      scrollController: controller,
      pointerGlobalY: 200.0,
      itemIndex: 0,
      collapsedItemHeight: 60.0,
    );
    expect(headroom0, 200.0);

    // Item 2 at Y = 300: headroom is 300 - (2 * 60) = 180
    final headroom2 = calculateDynamicReorderHeadroom(
      context: context,
      scrollController: controller,
      pointerGlobalY: 300.0,
      itemIndex: 2,
      collapsedItemHeight: 60.0,
    );
    expect(headroom2, 180.0);

    // Item 5 at Y = 200: headroom is max(0, 200 - (5 * 60) = -100) = 0.0
    final headroom5 = calculateDynamicReorderHeadroom(
      context: context,
      scrollController: controller,
      pointerGlobalY: 200.0,
      itemIndex: 5,
      collapsedItemHeight: 60.0,
    );
    expect(headroom5, 0.0);
  });
}


