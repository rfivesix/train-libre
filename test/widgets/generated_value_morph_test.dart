import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/generated_value_morph.dart';

class _MorphState {
  final String value;
  final String? suggestionKey;

  const _MorphState(this.value, this.suggestionKey);
}

void main() {
  testWidgets('pixel morph survives a generated-value replacement',
      (tester) async {
    final state = ValueNotifier(const _MorphState('10', null));
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          // A live workout puts its rows in a sliver and only constrains their
          // height through the input itself. This catches accidental expanding
          // Stack/CustomPaint layouts that a fixed test box would hide.
          body: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<_MorphState>(
                      valueListenable: state,
                      builder: (context, current, _) => GeneratedValueMorph(
                        suggestionKey: current.suggestionKey,
                        value: current.value,
                        accentColor: Colors.green,
                        restingColor: Colors.white,
                        morphTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        childBuilder: (color) => TextFormField(
                          initialValue: current.value,
                          style: TextStyle(color: color),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    state.value = const _MorphState('11', 'first-suggestion');
    await tester.pump();
    // The first phase proves that the old glyph's pixels are actually visible
    // while travelling into the shared circle.
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/generated_value_morph_pixels.png'),
    );
    // At 400 ms the cloud is in its fully formed, flowing middle state rather
    // than either circle edge.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/generated_value_morph_midpoint.png'),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    // At rest only the real TextFormField remains. A retained pixel painter
    // would render a second, vertically offset copy of the number.
    expect(
      find.byKey(const ValueKey('generated-value-morph-outgoing')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('generated-value-morph-incoming')),
      findsNothing,
    );
  });
}
