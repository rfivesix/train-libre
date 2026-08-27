import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';

void main() {
  testWidgets('CardMorphRoute morphs a card to full-screen and collapses back cleanly',
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

  testWidgets('CardMorphRoute falls back gracefully when no source bounds are found',
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
}
