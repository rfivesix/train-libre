import 'dart:ui' show SemanticsAction;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/workout/presentation/widgets/rpe_gradient_slider.dart';

void main() {
  testWidgets('tapping and dragging select discrete half steps', (
    tester,
  ) async {
    double current = 8;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 342,
              child: StatefulBuilder(
                builder: (context, setState) => RpeGradientSlider(
                  value: current,
                  onChanged: (v) => setState(() => current = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final slider = find.byType(RpeGradientSlider);
    final left = tester.getTopLeft(slider);
    // Track centers span 300 pixels; 187.5 pixels corresponds to RPE 8.5.
    await tester.tapAt(left + const Offset(21 + 187.5, 24));
    await tester.pump();
    expect(current, 8.5);
    await tester.dragFrom(
      left + const Offset(21 + 187.5, 24),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(current, 10);
  });

  testWidgets('screen readers can adjust the value', (tester) async {
    final semantics = tester.ensureSemantics();
    double current = 8;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RpeGradientSlider(
              value: current,
              semanticLabel: 'Effort',
              onChanged: (v) => setState(() => current = v),
            ),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(RpeGradientSlider));
    expect(node.label, 'Effort');
    expect(node.value, '8');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    node.owner!.performAction(
      node.id,
      SemanticsAction.increase,
    );
    await tester.pump();
    expect(current, 8.5);
    semantics.dispose();
  });
}
