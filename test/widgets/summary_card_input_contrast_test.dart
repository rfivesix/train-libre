import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/util/design_constants.dart';
import 'package:train_libre/widgets/common/platform_adaptive_dropdown.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    cardColor: Colors.white,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
    ),
  );

  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardColor: const Color(0xFF1C1C1E),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2E),
    ),
  );

  group('SummaryCard nested input & dropdown contrast', () {
    testWidgets(
        'light mode: inputs and dropdowns on white SummaryCard get secondary surface fill color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                // Outside card (on scaffold)
                const TextField(
                  key: Key('scaffold_textfield'),
                ),
                PlatformAdaptiveDropdownFormField<String>(
                  key: const Key('scaffold_dropdown'),
                  value: 'a',
                  items: const [
                    DropdownMenuItem(value: 'a', child: Text('Option A')),
                  ],
                  onChanged: (_) {},
                ),
                // Inside white SummaryCard
                SummaryCard(
                  child: Column(
                    children: [
                      const TextField(
                        key: Key('card_textfield'),
                      ),
                      PlatformAdaptiveDropdownFormField<String>(
                        key: const Key('card_dropdown'),
                        value: 'b',
                        items: const [
                          DropdownMenuItem(value: 'b', child: Text('Option B')),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify scaffold TextField has white fill
      final scaffoldInputDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('scaffold_textfield')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(scaffoldInputDecorator.decoration.fillColor, Colors.white);

      // Verify scaffold dropdown has white fill
      final scaffoldDropdownDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('scaffold_dropdown')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(scaffoldDropdownDecorator.decoration.fillColor, Colors.white);

      // Verify card TextField has contrasting secondary surface fill (0xFFF2F2F7)
      final cardInputDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('card_textfield')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(cardInputDecorator.decoration.fillColor,
          DesignConstants.summaryCardSecondaryLightMode);

      // Verify card dropdown has contrasting secondary surface fill (0xFFF2F2F7)
      final cardDropdownDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('card_dropdown')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(cardDropdownDecorator.decoration.fillColor,
          DesignConstants.summaryCardSecondaryLightMode);
    });

    testWidgets(
        'light mode: inputs on secondary surface SummaryCard invert to white fill color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: SummaryCard(
              useSecondarySurface: true,
              child: const TextField(
                key: Key('secondary_card_textfield'),
              ),
            ),
          ),
        ),
      );

      final cardInputDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('secondary_card_textfield')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(cardInputDecorator.decoration.fillColor, Colors.white);
    });

    testWidgets(
        'dark mode: inputs both inside and outside SummaryCard preserve dark fill color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Column(
              children: [
                const TextField(key: Key('scaffold_dark_textfield')),
                SummaryCard(
                  child: PlatformAdaptiveDropdownFormField<String>(
                    key: const Key('card_dark_dropdown'),
                    value: 'd',
                    items: const [
                      DropdownMenuItem(value: 'd', child: Text('Dark Option')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final scaffoldDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('scaffold_dark_textfield')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(scaffoldDecorator.decoration.fillColor, const Color(0xFF2C2C2E));

      final cardDropdownDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const Key('card_dark_dropdown')),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(
          cardDropdownDecorator.decoration.fillColor, const Color(0xFF2C2C2E));
    });
  });
}
