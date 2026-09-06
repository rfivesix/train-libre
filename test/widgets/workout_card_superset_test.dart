import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_card.dart';

BorderRadius _radiusOf(WidgetTester tester, Finder finder) {
  final decoration =
      tester.widget<Container>(finder).decoration as BoxDecoration;
  return decoration.borderRadius! as BorderRadius;
}

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required bool above,
    required bool below,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutCard(
            accentColor: Colors.teal,
            continuesSupersetAbove: above,
            continuesSupersetBelow: below,
            child: const Text('card'),
          ),
        ),
      ),
    );
  }

  Finder cardContainer() => find
      .ancestor(
        of: find.text('card'),
        matching: find.byType(Container),
      )
      .last;

  testWidgets('a lone card keeps all four corners rounded', (tester) async {
    await pumpCard(tester, above: false, below: false);
    final radius = _radiusOf(tester, cardContainer());
    expect(radius.topLeft, const Radius.circular(20));
    expect(radius.bottomLeft, const Radius.circular(20));
  });

  testWidgets('a middle member squares both edges facing its siblings',
      (tester) async {
    await pumpCard(tester, above: true, below: true);
    final radius = _radiusOf(tester, cardContainer());
    expect(radius.topLeft, Radius.zero);
    expect(radius.bottomLeft, Radius.zero);
  });

  testWidgets('the first member opens the bracket and carries it down',
      (tester) async {
    await pumpCard(tester, above: false, below: true);
    final radius = _radiusOf(tester, cardContainer());
    expect(radius.topLeft, const Radius.circular(20));
    expect(radius.bottomLeft, Radius.zero);

    // The tinted spacer keeps the group's rail unbroken between two cards.
    final spacer = tester.widgetList<Container>(find.byType(Container)).last;
    expect((spacer.decoration! as BoxDecoration).border, isNotNull);
  });

  testWidgets('the last member closes the bracket', (tester) async {
    await pumpCard(tester, above: true, below: false);
    final radius = _radiusOf(tester, cardContainer());
    expect(radius.topLeft, Radius.zero);
    expect(radius.bottomLeft, const Radius.circular(20));
  });
}
