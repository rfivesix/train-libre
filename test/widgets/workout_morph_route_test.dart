import 'dart:math' as math;

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
    await tester.pump(Duration.zero);
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
    await tester.pump(Duration.zero);
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

  testWidgets('collapsing hands over to the real bar by fading, not by a swap',
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
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop();

    // Stepped frame by frame rather than sampled at one timestamp: a route's
    // clock only starts on its first tick, so any fixed offset silently means
    // a different point in the animation than it reads as.
    var lowest = 1.0;
    for (var i = 0; i < 45; i++) {
      await tester
          .pump(i == 0 ? Duration.zero : const Duration(milliseconds: 16));
      if (find.text('workout').evaluate().isEmpty) break;
      final fades = tester.widgetList<Opacity>(find.ancestor(
        of: find.text('workout'),
        matching: find.byType(Opacity),
      ));
      if (fades.isNotEmpty) lowest = math.min(lowest, fades.first.opacity);
    }

    // The page must have faded out before it is taken away, so what is left
    // standing is the real bar rather than a stand-in swapped out on the
    // final frame.
    expect(lowest, lessThan(0.15));
    expect(find.text('main'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('workout'), findsNothing);
  });

  testWidgets('the bar it grew out of travels with it and hands over',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: workoutMorphSourceHidden,
          builder: (context, hidden, _) =>
              hidden ? const SizedBox.shrink() : const Text('bar'),
        ),
      ),
    ));
    expect(find.text('bar'), findsOneWidget);

    navigatorKey.currentState!.push(
      WorkoutMorphRoute<void>(
        builder: (_) => const Scaffold(body: Text('workout')),
        sourceBuilder: (_) => const Text('bar'),
      ),
    );
    // The screen keeps its bar until the route's copy is actually in the tree,
    // so there is never a frame without one.
    await tester.pump();
    expect(find.text('bar'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 16));
    expect(workoutMorphSourceHidden.value, isTrue);
    expect(find.text('bar'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));

    // Both contents are on screen at once, each carried by the container —
    // that overlap is what makes it a morph rather than one thing fading out
    // while another fades in somewhere else.
    expect(find.text('bar'), findsOneWidget);
    expect(find.text('workout'), findsOneWidget);
    final barTransform = tester.widget<Transform>(
      find
          .ancestor(of: find.text('bar'), matching: find.byType(Transform))
          .first,
    );
    expect(barTransform.transform.getRow(0).x, greaterThan(1.0));

    // The bar is liquid glass, and a glass backdrop filter renders as nothing
    // inside a save layer. So it must never sit under an Opacity, or it would
    // be flat for the whole hand-over and then snap in when the fade ends.
    expect(
      find.ancestor(of: find.text('bar'), matching: find.byType(Opacity)),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(find.text('bar'), findsNothing);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    // And the screen takes its bar back once the route is gone.
    expect(workoutMorphSourceHidden.value, isFalse);
    expect(find.text('bar'), findsOneWidget);
  });

  testWidgets('there is never a frame without a bar, at either end',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: workoutMorphSourceHidden,
          builder: (context, hidden, _) =>
              hidden ? const SizedBox.shrink() : const Text('bar'),
        ),
      ),
    ));

    Future<void> stepThrough(int frames) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.text('bar'),
          findsWidgets,
          reason: 'no bar on screen at frame $i — it blinks out',
        );
      }
    }

    // Mid-collapse the bar is legitimately absent from the tree: the page is
    // still fully opaque and covering it, so the copy is not built. Only the
    // two hand-over moments have to be gap-free.
    Future<void> skipTo(int ms) async {
      var elapsed = 0;
      await tester.pump(Duration.zero);
      while (elapsed < ms) {
        await tester.pump(const Duration(milliseconds: 16));
        elapsed += 16;
      }
    }

    navigatorKey.currentState!.push(
      WorkoutMorphRoute<void>(
        builder: (_) => const Scaffold(body: Text('workout')),
        sourceBuilder: (_) => const Text('bar'),
      ),
    );
    // Opening: the copy has to be in the tree before the screen drops its own.
    await tester.pump();
    await stepThrough(8);
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop();
    await tester.pump();
    await skipTo(450);
    // Landing: the screen has to have its bar back before the copy goes.
    await stepThrough(14);
    await tester.pumpAndSettle();
    expect(find.text('bar'), findsOneWidget);
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
