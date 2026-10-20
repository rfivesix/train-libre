import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/empty_states/cold_start_empty_state.dart';

void main() {
  testWidgets('ColdStartEmptyState does not overflow on small height or Dynamic Type XXL',
      (tester) async {
    // Test with small height (350px) and large text scale (2.0x)
    tester.view.physicalSize = const Size(375, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 400),
            textScaler: TextScaler.linear(2.0),
          ),
          child: const Scaffold(
            body: ColdStartEmptyState(
              icon: Icons.calendar_today,
              title: 'Trainingsplan erstellen',
              subtitle: 'Erstelle deinen ersten Plan, um strukturiert zu trainieren.',
              callToAction: 'Tippe auf das Plus-Symbol unten',
              showArrow: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Trainingsplan erstellen'), findsOneWidget);
  });

  testWidgets('ColdStartEmptyState ignores empty callToAction string without extra gap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ColdStartEmptyState(
            icon: Icons.history,
            title: 'Keine Einträge',
            subtitle: 'Bisher wurden keine Daten erfasst.',
            callToAction: '',
            showArrow: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Keine Einträge'), findsOneWidget);
  });

  testWidgets('ColdStartEmptyState renders CurvedArrow when height is sufficient',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ColdStartEmptyState(
            icon: Icons.calendar_today,
            title: 'Trainingsplan erstellen',
            subtitle: 'Erstelle deinen ersten Plan, um strukturiert zu trainieren.',
            callToAction: 'Tippe auf das Plus-Symbol unten',
            showArrow: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('cold_start_curved_arrow')), findsOneWidget);
  });
}
