// The card a morph route flies a copy of has to look like that copy.
//
// The copy is built fresh by the route and is therefore always collapsed. An
// expanded original would flash its whole sub-item list in the frames at the
// end of the collapse where the two overlap, so the card folds itself away for
// the duration of the flight — while it is off screen — and stays folded.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/domain/models/meal_entry.dart';
import 'package:train_libre/features/diary/domain/models/tracked_food_item.dart';
import 'package:train_libre/features/diary/presentation/widgets/meal_entry_card.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final moment = DateTime(2026, 3, 1, 12, 30);

  final mealEntry = MealEntry(
    id: 'meal-1',
    consumedAt: moment,
    mealType: 'mealtypeLunch',
    title: 'Reisschale',
    source: 'aiPhoto',
  );

  final items = [
    TrackedFoodItem(
      item: FoodItem(
        barcode: '1001',
        name: 'Reis',
        calories: 200,
        protein: 10,
        carbs: 20,
        fat: 5,
      ),
      entry: FoodEntry(
        id: 7,
        barcode: '1001',
        timestamp: moment,
        quantityInGrams: 150,
        mealType: 'mealtypeLunch',
        mealEntryId: 'meal-1',
      ),
    ),
  ];

  Future<void> pumpCard(WidgetTester tester, {required bool collapsed}) =>
      tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MealEntryCard(
            mealEntry: mealEntry,
            items: items,
            collapsed: collapsed,
          ),
        ),
      ));

  // The sub-item list is what shows the ingredient's own name.
  Finder subItem() => find.text('Reis');

  testWidgets('folds an expanded card away when a flight starts',
      (tester) async {
    await pumpCard(tester, collapsed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.chevron_down));
    await tester.pumpAndSettle();
    expect(subItem(), findsOneWidget, reason: 'expanded by the tap');

    await pumpCard(tester, collapsed: true);
    await tester.pumpAndSettle();

    expect(subItem(), findsNothing);
  });

  testWidgets('stays folded when the card comes back', (tester) async {
    await pumpCard(tester, collapsed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.chevron_down));
    await tester.pumpAndSettle();

    await pumpCard(tester, collapsed: true);
    await tester.pumpAndSettle();

    // The route hands the card back at the end of the collapse. It must not
    // spring open again in that frame.
    await pumpCard(tester, collapsed: false);
    await tester.pump();
    expect(subItem(), findsNothing);

    await tester.pumpAndSettle();
    expect(subItem(), findsNothing);
  });

  testWidgets('leaves a collapsed card alone', (tester) async {
    await pumpCard(tester, collapsed: false);
    await tester.pumpAndSettle();
    expect(subItem(), findsNothing);

    await pumpCard(tester, collapsed: true);
    await tester.pumpAndSettle();
    expect(subItem(), findsNothing);
  });
}
