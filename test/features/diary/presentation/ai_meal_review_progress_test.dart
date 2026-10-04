import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/presentation/ai_meal_review_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/ai_meal_validation.dart';
import 'package:train_libre/services/ai_service.dart';
import 'package:train_libre/widgets/common/app_button.dart';

Future<AiValidationResult> _riceValidation(int grams) => AiMealValidationEngine(
        matchLoader: (_) async => [
              FoodItem(
                barcode: 'rice',
                name: 'Rice',
                calories: 130,
                protein: 3,
                carbs: 28,
                fat: 0.3,
                source: FoodItemSource.base,
              ),
            ]).validateMealCandidate(
      candidate: AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Rice', grams: grams)]),
      mode: AiValidationMode.capture,
    );

AppButton _saveButton(WidgetTester tester) => tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Save to Diary'),
        matching: find.byType(AppButton),
      ),
    );

Future<void> _pumpReview(
  WidgetTester tester,
  ValueNotifier<AiValidationResult?> preliminary,
  Future<AiValidationResult> finalResult,
) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AiMealReviewScreen(
      suggestions: [
        AiSuggestedItem(name: 'Rice', estimatedGrams: 100, confidence: 0.9),
      ],
      validationFuture: finalResult,
      progressiveValidation: preliminary,
      originalImages: const [],
    ),
  ));
  await tester.pump();
}

void main() {
  test('timeout has a closed telemetry code', () {
    expect(aiServiceErrorCode(const AiTimeoutException()), 'timeout');
  });

  testWidgets('shows first nutrition estimate, then final values before save',
      (tester) async {
    final preliminary = ValueNotifier<AiValidationResult?>(null);
    final finalResult = Completer<AiValidationResult>();
    await _pumpReview(tester, preliminary, finalResult.future);

    preliminary.value = await _riceValidation(100);
    await tester.pump();
    expect(find.text('130 kcal'), findsWidgets);
    expect(find.textContaining('Preliminary nutrition'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    finalResult.complete(await _riceValidation(200));
    await tester.pump();
    expect(find.text('260 kcal'), findsWidgets);
    expect(find.textContaining('Preliminary nutrition'), findsNothing);
    expect(_saveButton(tester).onPressed, isNotNull);
    preliminary.dispose();
  });

  testWidgets('timeout stops loading and keeps save disabled', (tester) async {
    final preliminary = ValueNotifier<AiValidationResult?>(null);
    final finalResult = Completer<AiValidationResult>();
    await _pumpReview(tester, preliminary, finalResult.future);

    preliminary.value = await _riceValidation(100);
    await tester.pump();
    finalResult.completeError(const AiTimeoutException());
    await tester.pump();
    expect(find.textContaining('request took too long'), findsOneWidget);
    expect(find.textContaining('Preliminary nutrition'), findsNothing);
    expect(_saveButton(tester).onPressed, isNull);
    preliminary.dispose();
  });

  testWidgets('failed scan without a match shows no fabricated nutrition',
      (tester) async {
    final preliminary = ValueNotifier<AiValidationResult?>(null);
    final finalResult = Completer<AiValidationResult>();
    await _pumpReview(tester, preliminary, finalResult.future);

    finalResult.completeError(const AiNetworkException());
    await tester.pump();
    expect(find.textContaining('could not be completed'), findsOneWidget);
    expect(find.text('0 kcal'), findsNothing);
    expect(find.text('550 kcal'), findsNothing);
    expect(_saveButton(tester).onPressed, isNull);
    preliminary.dispose();
  });
}
