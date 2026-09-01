import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/morph_source.dart';

void main() {
  // Scoped to the widget under test: MaterialApp brings its own Opacity and
  // IgnorePointer ancestors along.
  Finder opacityInside() => find.descendant(
        of: find.byType(MorphSource),
        matching: find.byType(Opacity),
      );
  Finder ignorePointerInside() => find.descendant(
        of: find.byType(MorphSource),
        matching: find.byType(IgnorePointer),
      );

  group('MorphSource', () {
    testWidgets('draws the child fully opaque and hit-testable while nothing '
        'is in flight', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MorphSource(hidden: false, child: Text('card')),
      ));

      expect(find.text('card'), findsOneWidget);
      expect(tester.widget<Opacity>(opacityInside()).opacity, 1.0);
      expect(tester.widget<IgnorePointer>(ignorePointerInside()).ignoring,
          isFalse);
    });

    testWidgets('keeps the same element below it when the flag flips',
        (tester) async {
      // The shape of the tree must not change: a sourceBuilder that closed
      // over a context from this subtree keeps building for the whole flight,
      // and rebuilding against fresh elements would leave it pointing at a
      // deactivated one.
      Widget build(bool hidden) => MaterialApp(
            home: MorphSource(hidden: hidden, child: const Text('card')),
          );

      await tester.pumpWidget(build(false));
      final before = tester.element(find.text('card'));

      await tester.pumpWidget(build(true));
      expect(tester.element(find.text('card')), same(before));

      await tester.pumpWidget(build(false));
      expect(tester.element(find.text('card')), same(before));
    });

    testWidgets('takes the child off screen without unmounting it',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MorphSource(hidden: true, child: Text('card')),
      ));

      // Still in the tree — it keeps its size, so the layout around it does
      // not move while the route flies a copy.
      expect(find.text('card'), findsOneWidget);
      expect(tester.widget<Opacity>(opacityInside()).opacity, 0.0);
      expect(tester.widget<IgnorePointer>(ignorePointerInside()).ignoring,
          isTrue);
    });

    testWidgets('keeps the hidden child at its original size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Center(
          child: MorphSource(
            hidden: false,
            child: SizedBox(width: 120, height: 40, child: Text('card')),
          ),
        ),
      ));
      final visibleSize = tester.getSize(find.byType(SizedBox).first);

      await tester.pumpWidget(const MaterialApp(
        home: Center(
          child: MorphSource(
            hidden: true,
            child: SizedBox(width: 120, height: 40, child: Text('card')),
          ),
        ),
      ));

      expect(tester.getSize(find.byType(SizedBox).first), visibleSize);
    });
  });

  group('MorphSourceScope', () {
    testWidgets('hides and restores the source through its callback',
        (tester) async {
      late MorphSourceVisibilityCallback setHidden;

      await tester.pumpWidget(MaterialApp(
        home: MorphSourceScope(
          builder: (context, callback) {
            setHidden = callback;
            return const Text('card');
          },
        ),
      ));

      expect(tester.widget<Opacity>(opacityInside()).opacity, 1.0);

      setHidden(true);
      await tester.pump();
      expect(tester.widget<Opacity>(opacityInside()).opacity, 0.0);

      // The route hands the source back at the end of the collapse, while its
      // own copy still covers it exactly.
      setHidden(false);
      await tester.pump();
      expect(tester.widget<Opacity>(opacityInside()).opacity, 1.0);
    });

    testWidgets('survives being called after the source is gone',
        (tester) async {
      late MorphSourceVisibilityCallback setHidden;

      await tester.pumpWidget(MaterialApp(
        home: MorphSourceScope(
          builder: (context, callback) {
            setHidden = callback;
            return const Text('card');
          },
        ),
      ));

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Routes hand the source back from dispose, which can land after the
      // screen holding it is gone.
      expect(() => setHidden(false), returnsNormally);
      expect(tester.takeException(), isNull);
    });
  });
}
