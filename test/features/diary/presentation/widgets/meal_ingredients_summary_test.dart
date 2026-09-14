import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/widgets/meal_ingredients_summary.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('shows compact ingredient cards and opens editing explicitly',
      (tester) async {
    var editRequested = false;
    int? openedIngredient;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MealIngredientsSummary(
            ingredients: const [
              MealIngredientSummaryItem(name: 'Reis', grams: 180, kcal: 234),
              MealIngredientSummaryItem(
                  name: 'Hähnchen', grams: 150, kcal: 248),
              MealIngredientSummaryItem(name: 'Brokkoli', grams: 100, kcal: 34),
              MealIngredientSummaryItem(name: 'Öl', grams: 10, kcal: 90),
            ],
            onEdit: () => editRequested = true,
            onIngredientTap: (index) => openedIngredient = index,
          ),
        ),
      ),
    );

    expect(find.text('4 Zutaten'), findsOneWidget);
    expect(find.text('Reis'), findsOneWidget);
    expect(find.text('234 kcal'), findsOneWidget);
    expect(find.text('180 g'), findsOneWidget);
    expect(find.text('Bearbeiten'), findsOneWidget);
    expect(find.text('Öl'), findsOneWidget);

    await tester.tap(find.text('Reis'));
    expect(openedIngredient, 0);

    await tester.tap(find.text('Bearbeiten'));

    expect(editRequested, isTrue);
  });
}
