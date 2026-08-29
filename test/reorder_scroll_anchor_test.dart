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

  void startReorder() {
    if (!widget.isEditMode) return;
    setState(() => _isDragging = true);
    if (widget.controller.hasClients) {
      widget.controller.animateTo(
        0.0,
        duration: kReorderCardResizeDuration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void endReorder() {
    Future.delayed(kReorderDropSettleDuration, () {
      if (mounted) {
        setState(() => _isDragging = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          controller: widget.controller,
          itemCount: _items.length,
          itemBuilder: (context, i) {
            return AnimatedSize(
              key: ValueKey(_items[i]),
              duration: kReorderCardResizeDuration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _isDragging ? 50.0 : 150.0,
                width: double.infinity,
                child: Text(_items[i]),
              ),
            );
          },
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
      'reorder start scrolls list to top (0.0) without artificial headroom',
      (tester) async {
    await tester.pumpWidget(
      _TestWorkoutReorderList(
        controller: controller,
        isEditMode: true,
      ),
    );
    final state =
        tester.state<_TestWorkoutReorderListState>(find.byType(_TestWorkoutReorderList));

    // Scroll down to an offset
    controller.jumpTo(500.0);
    await tester.pump();
    expect(controller.offset, 500.0);

    // Trigger reorder collapse
    state.startReorder();
    await tester.pumpAndSettle();

    // List should be smoothly animated to 0.0
    expect(controller.offset, 0.0);
    expect(controller.position.minScrollExtent, 0.0);

    // There is no negative or extra headroom above the top
    expect(find.text('Exercise 0'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Exercise 0')).dy, 0.0);
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

    controller.jumpTo(300.0);
    await tester.pump();

    state.startReorder();
    await tester.pumpAndSettle();

    // In non-edit mode, scroll position stays unchanged and cards do not collapse
    expect(controller.offset, 300.0);
  });
}
