import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';

void main() {
  testWidgets(
      'CardMorphRoute morphs a card to full-screen and collapses back cleanly',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final cardKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: cardKey,
              width: 200,
              height: 100,
              child: const Text('card_source'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('card_source'), findsOneWidget);

    navigatorKey.currentState!.push(
      CardMorphRoute<void>(
        sourceContext: cardKey.currentContext,
        builder: (_) => const Scaffold(body: Text('destination_page')),
      ),
    );

    // Mid-flight verification
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('destination_page'), findsOneWidget);
    expect(find.text('card_source'), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);

    // Fully settled at destination
    await tester.pumpAndSettle();
    expect(find.text('destination_page'), findsOneWidget);

    // Pop and collapse back
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('destination_page'), findsNothing);
    expect(find.text('card_source'), findsOneWidget);
  });

  testWidgets(
      'CardMorphRoute falls back gracefully when no source bounds are found',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );

    navigatorKey.currentState!.push(
      CardMorphRoute<void>(
        builder: (_) => const Scaffold(body: Text('destination')),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('destination'), findsOneWidget);
  });

  testWidgets('collapsing fades the card back in instead of switching it on',
      (tester) async {
    final harness = _MorphHarness(tester);
    await harness.pumpApp();
    harness.push();
    await tester.pumpAndSettle();

    harness.navigatorKey.currentState!.pop();
    final List<double> samples = await harness.sampleFlight();

    // The copy enters the frame invisible — fully covered by the page — and
    // only the page peeling off it brings it up. Switched on the way it used
    // to be, the first frame it exists on would already show it at full
    // density.
    expect(samples.first, lessThan(0.05),
        reason: 'the card appeared at ${samples.first} density out of nowhere');
    // Leading 0.0 for the frames before the copy is drawn at all, so the
    // moment it enters is measured as a step of the ramp like any other.
    _expectRamp(<double>[0.0, ...samples],
        reason: 'the collapse must dissolve');
    expect(samples.last, greaterThan(0.95),
        reason: 'the copy has to reach full density before it is handed over');

    await tester.pumpAndSettle();
    expect(find.text('card'), findsOneWidget);
  });

  testWidgets('expanding covers the card by the same ramp, in reverse',
      (tester) async {
    final harness = _MorphHarness(tester);
    await harness.pumpApp();
    harness.push();
    final List<double> samples = await harness.sampleFlight();

    // Opening is the mirror: the copy starts fully visible and the page
    // dissolves over it. The old threshold kept the copy at full density on
    // top of an already-opaque page and then removed it mid-flight, which is
    // the same pop seen from the other side.
    expect(samples.first, greaterThan(0.95));
    // Trailing 0.0 for the frames after the copy stops being built: dropping
    // it there has to be no larger a step than the ramp already takes, or the
    // copy is being yanked away while still visibly on screen.
    _expectRamp(<double>[...samples, 0.0], reason: 'the expand must dissolve');

    await tester.pumpAndSettle();
  });

  testWidgets('the copy is painted below the page, which is what fades it',
      (tester) async {
    final harness = _MorphHarness(tester);
    await harness.pumpApp();
    harness.push();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));

    expect(find.text('card'), findsOneWidget);
    expect(find.text('destination'), findsOneWidget);

    // Elements are walked depth-first in child order, and a Stack paints its
    // children in that same order — so the copy coming first means the page
    // is painted over it.
    //
    // This is the whole mechanism: the copy can never be faded itself (it may
    // be liquid glass, and a backdrop filter inside a save layer renders as
    // nothing), so the only thing that can bring it up or take it down is the
    // page dissolving on top of it. Put the copy back on top and there is
    // nothing left to fade it with, which is exactly how it came to be
    // switched on at full density.
    final List<Element> order = tester.allElements.toList();
    final int copyIndex = order.indexOf(find.text('card').evaluate().first);
    final int pageFadeIndex = order.indexOf(
      find
          .ancestor(
              of: find.text('destination'), matching: find.byType(Opacity))
          .evaluate()
          .first,
    );
    expect(copyIndex, greaterThanOrEqualTo(0));
    expect(pageFadeIndex, greaterThanOrEqualTo(0));
    expect(copyIndex, lessThan(pageFadeIndex),
        reason: 'the copy is painted on top of the page — nothing can fade it');

    await tester.pumpAndSettle();
  });

  testWidgets('the copy is never put under an Opacity', (tester) async {
    final harness = _MorphHarness(tester);
    await harness.pumpApp();
    harness.push();

    // The card may be liquid glass, and a backdrop filter renders as nothing
    // inside a save layer. So the copy must never sit under an Opacity, or it
    // would be flat for the whole hand-over and then snap in when the fade
    // ends.
    for (var i = 0; i < 40; i++) {
      await tester
          .pump(i == 0 ? Duration.zero : const Duration(milliseconds: 16));
      if (!harness.sourceHidden.value) continue;
      expect(
        find.ancestor(of: find.text('card'), matching: find.byType(Opacity)),
        findsNothing,
        reason: 'the copy is being faded by an Opacity at frame $i',
      );
    }
    await tester.pumpAndSettle();
  });

  testWidgets('the screen takes its card back while the copy still covers it',
      (tester) async {
    final harness = _MorphHarness(tester);
    await harness.pumpApp();
    harness.push();
    await tester.pumpAndSettle();
    expect(harness.sourceHidden.value, isTrue);

    harness.navigatorKey.currentState!.pop();

    var restoredWhileCopyStillDrawn = false;
    for (var i = 0; i < 60; i++) {
      await tester
          .pump(i == 0 ? Duration.zero : const Duration(milliseconds: 16));
      final bool routeStillUp =
          find.text('destination').evaluate().isNotEmpty ||
              harness.navigatorKey.currentState!.canPop();
      final int cards = find.text('card').evaluate().length;
      if (!harness.sourceHidden.value && cards == 2 && routeStillUp) {
        restoredWhileCopyStillDrawn = true;
      }
    }

    // Both the original and the copy on screen at once, in the same place —
    // that overlap is the hand-over. Restoring only on `dismissed` left the
    // real card to arrive on the very last frame with nothing having faded
    // it in.
    expect(restoredWhileCopyStillDrawn, isTrue,
        reason: 'the card came back only after the copy was already gone');

    await tester.pumpAndSettle();
    expect(harness.sourceHidden.value, isFalse);
    expect(find.text('card'), findsOneWidget);
  });
}

/// Drives a morph out of a 200x120 card labelled `card`, whose copy during
/// flight carries the same label — so counting `card` counts both.
class _MorphHarness {
  _MorphHarness(this.tester);

  final WidgetTester tester;
  final GlobalKey cardKey = GlobalKey();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<bool> sourceHidden = ValueNotifier<bool>(false);

  Future<void> pumpApp() async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: cardKey,
              width: 200,
              height: 120,
              child: ValueListenableBuilder<bool>(
                valueListenable: sourceHidden,
                builder: (context, hidden, _) =>
                    hidden ? const SizedBox.shrink() : const Text('card'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void push() {
    navigatorKey.currentState!.push(
      CardMorphRoute<void>(
        sourceContext: cardKey.currentContext,
        sourceBuilder: (_) => const Text('card'),
        onSourceVisibilityChanged: (hidden) => sourceHidden.value = hidden,
        builder: (_) => const Scaffold(body: Text('destination')),
      ),
    );
  }

  /// How much of the source copy the eye actually gets on this frame.
  ///
  /// The copy is never faded itself — it is the page dissolving over it that
  /// makes it appear — so what is left of it is whatever the page is not. If
  /// the copy is painted *above* the page instead, nothing is covering it and
  /// it reads at full density however far along the page's own fade is; that
  /// is measured here too rather than assumed away, because it is precisely
  /// the shape of the bug.
  ///
  /// Returns null on frames where no copy is drawn at all.
  double? sourceVisibility() {
    if (!sourceHidden.value) return null;
    final Iterable<Element> copy = find.text('card').evaluate();
    if (copy.isEmpty) return null;
    if (find.text('destination').evaluate().isEmpty) return 1.0;
    final Finder fadeFinder = find.ancestor(
      of: find.text('destination'),
      matching: find.byType(Opacity),
    );
    final Iterable<Element> fade = fadeFinder.evaluate();
    if (fade.isEmpty) return 0.0;
    // Elements are walked depth-first in child order, and a Stack paints its
    // children in that order — so a copy that comes last is painted last.
    final List<Element> order = tester.allElements.toList();
    if (order.indexOf(copy.first) > order.indexOf(fade.first)) return 1.0;
    return 1.0 - tester.widget<Opacity>(fadeFinder.first).opacity;
  }

  /// Steps frame by frame rather than sampling at fixed offsets: a route's
  /// clock only starts on its first tick, so any fixed offset silently means a
  /// different point in the animation than it reads as.
  Future<List<double>> sampleFlight({int frames = 60}) async {
    final List<double> samples = <double>[];
    for (var i = 0; i < frames; i++) {
      await tester
          .pump(i == 0 ? Duration.zero : const Duration(milliseconds: 16));
      final double? visibility = sourceVisibility();
      if (visibility != null) samples.add(visibility);
    }
    return samples;
  }
}

void _expectRamp(List<double> samples, {required String reason}) {
  expect(samples.length, greaterThanOrEqualTo(5),
      reason: '$reason — only ${samples.length} frames to do it in');
  double biggestStep = 0.0;
  for (var i = 1; i < samples.length; i++) {
    biggestStep = math.max(biggestStep, (samples[i] - samples[i - 1]).abs());
  }
  // A hard switch shows up as a single step covering most of the range; a
  // dissolve never moves more than a slice of it per frame.
  expect(biggestStep, lessThan(0.3), reason: '$reason — jumped $biggestStep');
  // And it genuinely passes through the middle instead of clipping across it.
  expect(
    samples.where((v) => v > 0.1 && v < 0.9).length,
    greaterThanOrEqualTo(3),
    reason: '$reason — barely any intermediate frames: $samples',
  );
}
