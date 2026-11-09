import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_scroll_sidebar_controller.dart';

void main() {
  testWidgets('fast short swipes open and close the sidebar', (tester) async {
    final morph = AnimationController(vsync: tester);
    final controller = CloudScrollSidebarController(
      vsync: tester,
      isFullscreenGetter: () => true,
      morphAnimationGetter: () => morph,
    );
    addTearDown(() {
      controller.dispose();
      morph.dispose();
    });

    void swipe(double start, double end) {
      controller.handleSidebarPointerDown(
        PointerDownEvent(
          pointer: 1,
          position: Offset(start, 0),
          timeStamp: Duration.zero,
        ),
      );
      controller.handleSidebarPointerMove(
        PointerMoveEvent(
          pointer: 1,
          position: Offset(end, 0),
          timeStamp: const Duration(milliseconds: 40),
        ),
        300,
      );
      controller.finishSidebarPointer(
        PointerUpEvent(
          pointer: 1,
          position: Offset(end, 0),
          timeStamp: const Duration(milliseconds: 45),
        ),
      );
    }

    swipe(0, 60);
    await tester.pumpAndSettle();
    expect(controller.sidebarAnimation.value, 1);
    swipe(100, 40);
    await tester.pumpAndSettle();
    expect(controller.sidebarAnimation.value, 0);
  });

  testWidgets('vertical scrolling cannot turn into a sidebar drag', (
    tester,
  ) async {
    final morph = AnimationController(vsync: tester);
    final controller = CloudScrollSidebarController(
      vsync: tester,
      isFullscreenGetter: () => true,
      morphAnimationGetter: () => morph,
    );
    addTearDown(() {
      controller.dispose();
      morph.dispose();
    });
    controller.handleSidebarPointerDown(const PointerDownEvent(pointer: 1));
    controller.handleSidebarPointerMove(
      const PointerMoveEvent(pointer: 1, position: Offset(2, 30)),
      300,
    );
    controller.handleSidebarPointerMove(
      const PointerMoveEvent(pointer: 1, position: Offset(200, 35)),
      300,
    );
    controller.finishSidebarPointer(const PointerUpEvent(pointer: 1));
    expect(controller.sidebarAnimation.value, 0);
  });
  testWidgets('header drag honors upward velocity and cancel restores the chat', (tester) async {
    final morph = AnimationController(vsync: tester, duration: const Duration(milliseconds: 100), value: 1);
    var closed = false;
    final controller = CloudScrollSidebarController(
      vsync: tester,
      isFullscreenGetter: () => false,
      morphAnimationGetter: () => morph,
      onToggleExpanded: () => closed = true,
    );
    addTearDown(() { controller.dispose(); morph.dispose(); });
    controller.handleHeaderDragStart(DragStartDetails());
    controller.handleHeaderDragUpdate(DragUpdateDetails(globalPosition: Offset.zero, delta: const Offset(0, 150)));
    controller.handleHeaderDragEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(0, -1000))));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(morph.value, 1);
    controller.handleHeaderDragStart(DragStartDetails());
    controller.handleHeaderDragUpdate(DragUpdateDetails(globalPosition: Offset.zero, delta: const Offset(0, 100)));
    controller.handleHeaderDragCancel();
    await tester.pumpAndSettle();
    expect(morph.value, 1);
  });

}
