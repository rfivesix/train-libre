import 'package:flutter/material.dart';
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
          cacheExtent: 1500.0,
          children: [
            ReorderHeadroom(isDragging: _isDragging),
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
      'ReorderScrollAnchor keeps touched item pinned while list collapses',
      (tester) async {
    await tester.pumpWidget(
      _TestWorkoutReorderList(
        controller: controller,
        isEditMode: true,
      ),
    );
    final state =
        tester.state<_TestWorkoutReorderListState>(find.byType(_TestWorkoutReorderList));

    // Initially, Exercise 3 is at Y = 3 * 150 = 450
    final initialY = tester.getTopLeft(find.text('Exercise 3')).dy;
    expect(initialY, 450.0);

    // Trigger reorder pinned on Exercise 3
    state.startReorder('Exercise 3');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // After collapse and settle with headroom, Exercise 3 stays pinned close to initial position
    final afterCollapseY = tester.getTopLeft(find.text('Exercise 3')).dy;
    expect((afterCollapseY - initialY).abs(), lessThan(5.0));
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
}

