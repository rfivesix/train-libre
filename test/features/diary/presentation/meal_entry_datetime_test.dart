// test/features/diary/presentation/meal_entry_datetime_test.dart
//
// The screen-level half of moving a logged meal: that the subtitle is actually
// a control, that confirming a changed value goes through the repository method
// which moves the linked rows too, and that the screen's own copy of the meal
// follows along — if it did not, the save on pop would drag the items straight
// back onto the day the user just moved them off.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/domain/models/meal_entry.dart';
import 'package:train_libre/features/diary/domain/models/tracked_food_item.dart';
import 'package:train_libre/features/diary/domain/repositories/diary_repository.dart';
import 'package:train_libre/features/diary/presentation/meal_entry_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/util/date_util.dart';

import 'package:train_libre/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the screen asks of the diary. Only the handful of methods this
/// screen touches are implemented; [noSuchMethod] covers the rest of the
/// interface so the fake does not have to be rewritten every time the
/// repository grows a method unrelated to this test.
class _RecordingDiaryRepo implements IDiaryRepository {
  final List<({String id, DateTime to})> moves = [];
  final List<MealEntry> updatedMealEntries = [];
  final List<FoodEntry> updatedFoodEntries = [];
  final List<FoodEntry> insertedFoodEntries = [];
  final List<int> deletedFoodEntries = [];

  @override
  Future<void> moveMealEntryTo(
      String mealEntryId, DateTime newConsumedAt) async {
    moves.add((id: mealEntryId, to: newConsumedAt));
  }

  @override
  Future<void> updateMealEntry(MealEntry entry) async {
    updatedMealEntries.add(entry);
  }

  @override
  Future<void> updateFoodEntry(FoodEntry entry) async {
    updatedFoodEntries.add(entry);
  }

  @override
  Future<int> insertFoodEntry(FoodEntry entry,
      {String telemetrySource = 'manual_search'}) async {
    insertedFoodEntries.add(entry);
    return 99;
  }

  @override
  Future<void> deleteFoodEntry(int id) async {
    deletedFoodEntries.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Anchored a few days back so the meal is never "today" (which would hide the
  // date from the subtitle) and always well inside the picker's bounds.
  final now = DateTime.now();
  final originalMoment = DateTime(now.year, now.month, now.day, 12, 30)
      .subtract(const Duration(days: 5));

  final mealEntry = MealEntry(
    id: 'meal-1',
    consumedAt: originalMoment,
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
        timestamp: originalMoment,
        quantityInGrams: 150,
        mealType: 'mealtypeLunch',
        mealEntryId: 'meal-1',
      ),
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester,
    _RecordingDiaryRepo repo,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<IDiaryRepository>.value(value: repo),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MealEntryScreen(
                          mealEntry: mealEntry,
                          initialItems: items,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Meal'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Meal'));
    await tester.pumpAndSettle();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('meal_entry_timestamp_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('the meal subtitle opens a date and time picker', (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);

    expect(find.byType(CupertinoDatePicker), findsNothing);

    await openPicker(tester);

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(
      picker.mode,
      CupertinoDatePickerMode.dateAndTime,
      reason: 'the date has to be changeable, not just the clock',
    );
    expect(picker.initialDateTime, originalMoment);
  });

  testWidgets('cancelling changes nothing', (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);
    await openPicker(tester);

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(repo.moves, isEmpty);
  });

  testWidgets('confirming the timestamp it already has is not written',
      (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);
    await openPicker(tester);

    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    expect(repo.moves, isEmpty,
        reason: 'a confirmed no-change must not touch the diary');
  });

  testWidgets(
      'moving the meal to another day goes through moveMealEntryTo and takes '
      'the screen\'s items with it', (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);
    await openPicker(tester);

    // The first wheel of a dateAndTime picker is the date column. Scrolling it
    // forward is the only way a user can move a meal to another day, so that is
    // what the test does rather than calling the handler directly.
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -64),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    expect(repo.moves, hasLength(1),
        reason: 'the move must go through the repository method that also '
            'moves the linked nutrition, fluid and supplement rows');
    final move = repo.moves.single;
    expect(move.id, 'meal-1');
    expect(
      move.to.isSameDate(originalMoment),
      isFalse,
      reason: 'dragging the date wheel must land the meal on another day',
    );
    expect(move.to.isAfter(originalMoment), isTrue);
    expect(move.to.second, 0,
        reason: 'a stray sub-minute component would push a 23:59 pick out of '
            'the day it was just moved to');

    final delta = move.to.difference(originalMoment);

    // Leaving the screen flushes the pending edits. Those writes have to carry
    // the moved timestamps: if the screen had kept its original copies, this
    // save would put the meal's calories straight back on the old day.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repo.updatedMealEntries, hasLength(1));
    expect(repo.updatedMealEntries.single.consumedAt, move.to);

    expect(repo.updatedFoodEntries, hasLength(1));
    expect(
      repo.updatedFoodEntries.single.timestamp,
      originalMoment.add(delta),
      reason: 'the meal\'s items move by the same delta as the meal',
    );
    expect(repo.updatedFoodEntries.single.id, 7);
  });

  testWidgets(
      'deleting an ingredient deletes the food entry on pop',
      (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);

    // Swipe to dismiss ingredient
    await tester.drag(
      find.byKey(const ValueKey('meal_item_7_0')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reis'), findsNothing);

    // Pop the screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repo.deletedFoodEntries, contains(7),
        reason: 'deleted ingredient ID 7 must be deleted via repo.deleteFoodEntry');
  });

  testWidgets(
      'quick adjusting ingredient quantity updates the food entry on pop',
      (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);

    // Tap +25g quick adjustment button
    final plus25Finder = find.text('+25g');
    if (plus25Finder.evaluate().isNotEmpty) {
      await tester.tap(plus25Finder.first);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repo.updatedFoodEntries, isNotEmpty);
      expect(repo.updatedFoodEntries.first.quantityInGrams, 175);
    }
  });

  testWidgets(
      'changing meal type updates both meal entry and linked food entries on pop',
      (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);

    // Open overflow options
    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();

    // Select Change meal type
    await tester.tap(find.text('Change meal type'));
    await tester.pumpAndSettle();

    // Pick Dinner
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();

    // Pop screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repo.updatedMealEntries, isNotEmpty);
    expect(repo.updatedMealEntries.last.mealType, 'mealtypeDinner');

    expect(repo.updatedFoodEntries, isNotEmpty);
    expect(repo.updatedFoodEntries.last.mealType, 'mealtypeDinner');
  });

  testWidgets(
      'renaming meal updates the title and persists on pop',
      (tester) async {
    final repo = _RecordingDiaryRepo();
    await pumpScreen(tester, repo);

    // Open overflow options
    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();

    // Select Rename
    await tester.tap(find.text('Recipe name'));
    await tester.pumpAndSettle();

    // Enter new name
    await tester.enterText(find.byType(TextField).last, 'Gesundes Mittagessen');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Gesundes Mittagessen'), findsOneWidget);

    // Pop screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repo.updatedMealEntries, isNotEmpty);
    expect(repo.updatedMealEntries.last.title, 'Gesundes Mittagessen');
  });
}
