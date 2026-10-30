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
      controller.handleSidebarPointerDown(PointerDownEvent(
        pointer: 1,
        position: Offset(start, 0),
        timeStamp: Duration.zero,
      ));
      controller.handleSidebarPointerMove(
          PointerMoveEvent(
            pointer: 1,
            position: Offset(end, 0),
            timeStamp: const Duration(milliseconds: 40),
          ),
          300);
      controller.finishSidebarPointer(PointerUpEvent(
        pointer: 1,
        position: Offset(end, 0),
        timeStamp: const Duration(milliseconds: 45),
      ));
    }

    swipe(0, 60);
    await tester.pumpAndSettle();
    expect(controller.sidebarAnimation.value, 1);
    swipe(100, 40);
    await tester.pumpAndSettle();
    expect(controller.sidebarAnimation.value, 0);
  });

  testWidgets('vertical scrolling cannot turn into a sidebar drag',
      (tester) async {
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
}
