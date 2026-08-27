import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/workout_morph_route.dart';
import 'package:train_libre/util/design_constants.dart';

void main() {
  testWidgets('morphs a page in and back out without leaving it behind',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('main')),
    ));

    navigatorKey.currentState!.push(
      WorkoutMorphRoute<void>(
        builder: (_) => const Scaffold(body: Text('workout')),
      ),
    );

    // Mid-transition the page is already mounted, clipped to the growing pill,
    // and the screen underneath is still painted.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('workout'), findsOneWidget);
    expect(find.text('main'), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('workout'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('workout'), findsNothing);
    expect(find.text('main'), findsOneWidget);
  });

  testWidgets('mid-flight the page is scaled and the screen behind is dimmed',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('main')),
    ));

    navigatorKey.currentState!.push(
      WorkoutMorphRoute<void>(
        builder: (_) => const Scaffold(body: Text('workout')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    // The content moves with the container rather than sitting still behind a
    // widening window — that is what separates a morph from a reveal.
    final transform = tester.widget<Transform>(
      find
          .ancestor(of: find.text('workout'), matching: find.byType(Transform))
          .first,
    );
    // The x scale specifically — `getMaxScaleOnAxis` maxes over all three axes
    // and would keep reporting the untouched z scale of 1.0.
    final scale = transform.transform.getRow(0).x;
    expect(scale, lessThan(1.0));
    expect(scale, greaterThan(0.5));

    // And the screen left behind is dimmed.
    final scrim = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(
      scrim.any((box) => box.color.a > 0.0 && box.color.a < 1.0),
      isTrue,
    );

    await tester.pumpAndSettle();
  });

  test('the overlay rect matches where the bar is positioned', () {
    const screen = Size(390, 844);
    final rect = DesignConstants.workoutOverlayRect(screen);

    expect(rect.left, DesignConstants.floatingBarHorizontalInset);
    expect(rect.width,
        screen.width - DesignConstants.floatingBarHorizontalInset * 2);
    expect(rect.height, DesignConstants.workoutOverlayHeight);
    expect(
        screen.height - rect.bottom, DesignConstants.workoutOverlayBottomInset);
  });
}
