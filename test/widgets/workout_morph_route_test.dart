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
