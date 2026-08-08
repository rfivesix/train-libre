import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/glass_progress_bar.dart';

void main() {
  // Regression guard: NutritionSummaryWidget lays these bars out inside an
  // IntrinsicHeight. Anything in GlassProgressBar's build that does not support
  // intrinsic dimensions (a LayoutBuilder at the root, for example) makes the
  // intrinsic height resolve to 0 and silently collapses the whole grid.
  testWidgets('keeps its height inside an IntrinsicHeight row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: const [
                      Expanded(
                        child: GlassProgressBar(
                          label: 'Calories',
                          unit: 'kcal',
                          value: 2734,
                          target: 2986,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: GlassProgressBar(
                          label: 'Water',
                          unit: 'ml',
                          value: 4900,
                          target: 4500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(GlassProgressBar).first);
    expect(size.height, greaterThan(0));
    expect(size.width, greaterThan(0));
  });
}
