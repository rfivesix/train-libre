import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({double width = 400, double height = 800}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: const EdgeInsets.only(top: 48, bottom: 34),
        ),
        child: const Scaffold(
          body: SizedBox.expand(
            child: DraggableAiCloud(
              semanticLabel: 'KI-Wolke',
              semanticHint: 'Tippen',
              liveliness: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'cloud default position is bottom-left and docks to left screen edge',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(width: 400, height: 800));
      await tester.pump();

      // Find the cloud semantics and render box
      final semanticsFinder = find.bySemanticsLabel('KI-Wolke');
      expect(semanticsFinder, findsOneWidget);

      final cloudBox = tester.renderObject<RenderBox>(semanticsFinder);
      final initialPos = cloudBox.localToGlobal(Offset.zero);

      // Initially at bottom-left:
      // defaultLeft = 16.0 (aligned with cards)
      // top = maxTop (bottom)
      expect(initialPos.dx, equals(16.0));
      expect(initialPos.dy, greaterThan(500.0)); // bottom of screen

      // Wait for dock timer (650ms) and animation (420ms)
      await tester.pump(const Duration(milliseconds: 650));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 45));
      }
      await tester.pump(const Duration(milliseconds: 300));

      // After docking to left edge:
      // minLeft = 64 - 160 = -96.0
      // 64 pixels visible on-screen (x = 0 to 64)
      final dockedPos = cloudBox.localToGlobal(Offset.zero);
      expect(dockedPos.dx, equals(-96.0));
      expect(dockedPos.dy, equals(initialPos.dy));

      // Tap on the visible on-screen region of the cloud (e.g. x = 15)
      final visibleTapPoint = Offset(15, dockedPos.dy + 80);

      final hitResult = tester.hitTestOnBinding(visibleTapPoint);
      final hitTargets = hitResult.path.map((entry) => entry.target).toList();
      expect(
        hitTargets.any((target) => target == cloudBox),
        isTrue,
        reason: 'Tap on visible left cloud edge must reach the cloud RenderBox',
      );

      // Tap on the visible cloud
      await tester.tapAt(visibleTapPoint);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The cloud must have expanded (TextField appears)
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('cloud hitbox matches painted cloud during left dock animation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestApp(width: 400, height: 800));
    await tester.pump();

    // Wait 650ms for initial dock timer to fire and pump mid-animation
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 200));

    final semanticsFinder = find.bySemanticsLabel('KI-Wolke');
    final cloudBox = tester.renderObject<RenderBox>(semanticsFinder);
    final currentPos = cloudBox.localToGlobal(Offset.zero);

    // Position should be between 16.0 and -96.0
    expect(currentPos.dx, lessThan(16.0));
    expect(currentPos.dx, greaterThan(-96.0));

    // Tap during dock animation on the visible part (e.g. x = 30)
    final midAnimTapPoint = Offset(30, currentPos.dy + 80);
    final hitResult = tester.hitTestOnBinding(midAnimTapPoint);
    final hitTargets = hitResult.path.map((entry) => entry.target).toList();
    expect(
      hitTargets.any((target) => target == cloudBox),
      isTrue,
      reason: 'During left dock animation, hitbox must match current animated position',
    );

    // Tap to expand mid-animation
    await tester.tapAt(midAnimTapPoint);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'dragging cloud from bottom-left to right moves hitbox and snaps cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(width: 400, height: 800));
      await tester.pump();

      // Wait until docked at the left edge
      await tester.pump(const Duration(milliseconds: 650));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 45));
      }
      await tester.pump(const Duration(milliseconds: 300));

      final semanticsFinder = find.bySemanticsLabel('KI-Wolke');
      final cloudBox = tester.renderObject<RenderBox>(semanticsFinder);
      final dockedPos = cloudBox.localToGlobal(Offset.zero);
      expect(dockedPos.dx, equals(-96.0));

      // Drag right from visible part (x = 15) to the right
      await tester.timedDragFrom(
        Offset(15.0, dockedPos.dy + 80),
        const Offset(250.0, 0.0),
        const Duration(milliseconds: 300),
      );
      await tester.pump();

      final draggedBox = tester.renderObject<RenderBox>(semanticsFinder);
      final draggedPos = draggedBox.localToGlobal(Offset.zero);
      expect(draggedPos.dx, greaterThan(-96.0));

      // After settling, tapping works
      await tester.pump(const Duration(milliseconds: 400));
      final settledPos = draggedBox.localToGlobal(Offset.zero);
      final tapPoint = Offset(
        settledPos.dx < 0 ? 30 : settledPos.dx + 40,
        settledPos.dy + 80,
      );
      await tester.tapAt(tapPoint);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
