// test/features/diary/presentation/meal_analysis_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/meal_analysis_screen.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealAnalysisScreen', () {
    testWidgets('renders all visual elements and transitions through phases',
        (tester) async {
      final controller = MealAnalysisController();
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealAnalysisScreen(
            controller: controller,
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Initial State: Preparing
      expect(find.byType(AiNeuralCloudOrbWidget), findsOneWidget);
      expect(find.text('Aufnahme wird vorbereitet'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);

      // 2. Transition to Analyzing
      controller.value = MealAnalysisPhase.analyzing;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mahlzeit wird analysiert'), findsOneWidget);

      // 3. Transition to Matching
      controller.value = MealAnalysisPhase.matching;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Zutaten werden abgeglichen'), findsOneWidget);

      // 4. Transition to Failed
      controller.value = MealAnalysisPhase.failed;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);

      // 5. Test Cancel
      await tester.tap(find.text('Abbrechen'));
      await tester.pump();
      expect(cancelled, isTrue);

      controller.dispose();
    });
  });
}
