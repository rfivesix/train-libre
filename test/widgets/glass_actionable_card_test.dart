import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/glass_actionable_card.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  testWidgets('GlassActionableCard renders child widget correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassActionableCard(
            child: SummaryCard(
              child: Text('Test Card Content'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test Card Content'), findsOneWidget);
  });

  testWidgets('GlassActionableCard triggers onTap when pressed', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassActionableCard(
            onTap: () {
              tapped = true;
            },
            child: const SummaryCard(
              child: Text('Tappable Card'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tappable Card'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('GlassActionableCard triggers context menu on long press', (tester) async {
    bool editCalled = false;
    bool deleteCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassActionableCard(
            editLabel: 'Bearbeiten',
            deleteLabel: 'Löschen',
            onEdit: () {
              editCalled = true;
            },
            onDelete: () {
              deleteCalled = true;
            },
            child: const SummaryCard(
              child: Text('Long Press Card'),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Long Press Card'));
    await tester.pumpAndSettle();

    // Verify context menu overlay options are rendered
    expect(find.text('Bearbeiten'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);

    // Tap 'Bearbeiten' action in context menu
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
    expect(deleteCalled, isFalse);
  });
}
