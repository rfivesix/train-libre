import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/presentation/add_food_screen.dart';
import 'package:train_libre/features/diary/presentation/general_food_selection_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';

class _InactiveWorkout extends ChangeNotifier implements LiveWorkoutViewModel {
  @override
  bool get isActive => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final picker in <String, Widget>{
    'diary': const AddFoodScreen(selectionMode: true),
    'general': const GeneralFoodSelectionScreen(),
  }.entries) {
    testWidgets(
        '${picker.key} searches without OFF and preserves relevance order',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final database = db.AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(database);
      final products = ProductLocalDataSource.forTesting(database);
      addTearDown(DatabaseHelper.closeAndResetDriftDb);
      await tester.runAsync(() async {
        await database
            .into(database.foodCategories)
            .insert(const db.FoodCategoriesCompanion(
              key: drift.Value('test'),
              nameDe: drift.Value('Lebensmittel'),
              nameEn: drift.Value('Foods'),
            ));
        for (final item in [
          FoodItem(
              barcode: 'base',
              name: 'Weizen Bier',
              nameDe: 'Weizen Bier',
              calories: 40,
              protein: 1,
              carbs: 4,
              fat: 0,
              source: FoodItemSource.base),
          FoodItem(
              barcode: 'own',
              name: 'Bierschinken',
              nameDe: 'Bierschinken',
              calories: 200,
              protein: 20,
              carbs: 1,
              fat: 15,
              source: FoodItemSource.user),
        ]) {
          await products.insertProduct(item);
        }
      });
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider<LiveWorkoutViewModel>(
              create: (_) => _InactiveWorkout()),
        ],
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: picker.value),
      ));
      Future<void> settleDatabase() async {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pumpAndSettle();
      }

      await settleDatabase();
      final field = find.byType(TextField).first;
      expect(
          field, findsOneWidget); // no OFF installation or version preference
      await tester.enterText(field, 'Bier');
      await tester.pump(const Duration(milliseconds: 310));
      await settleDatabase();
      expect(find.text('Grundnahrungsmittel'), findsOneWidget);
      expect(find.text('Weizen Bier'), findsOneWidget);
      expect(find.text('Eigene Lebensmittel'), findsOneWidget);
      expect(find.text('Bierschinken'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Grundnahrungsmittel')).dy,
          lessThan(tester.getTopLeft(find.text('Weizen Bier')).dy));
      expect(tester.getTopLeft(find.text('Weizen Bier')).dy,
          lessThan(tester.getTopLeft(find.text('Eigene Lebensmittel')).dy));
      expect(tester.getTopLeft(find.text('Eigene Lebensmittel')).dy,
          lessThan(tester.getTopLeft(find.text('Bierschinken')).dy));
      await tester.enterText(field, 'NichtsPassendes');
      await tester.pump(const Duration(milliseconds: 310));
      await settleDatabase();
      expect(find.text('Weizen Bier'), findsNothing);
      expect(find.text('Bierschinken'), findsNothing);
      // A pending debounced search is cancelled by the clear action.
      await tester.enterText(field, 'Bier');
      await tester.pump();
      final l10n = AppLocalizations.of(tester.element(field))!;
      await tester.tap(find.byTooltip(l10n.clearSearch));
      await tester.pump(const Duration(milliseconds: 310));
      await settleDatabase();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.text('Weizen Bier'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        '${picker.key} renders all three sections in order without displacement from >50 OFF items',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final database = db.AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(database);
      final products = ProductLocalDataSource.forTesting(database);
      addTearDown(DatabaseHelper.closeAndResetDriftDb);
      await tester.runAsync(() async {
        await database
            .into(database.foodCategories)
            .insert(const db.FoodCategoriesCompanion(
              key: drift.Value('test'),
              nameDe: drift.Value('Lebensmittel'),
              nameEn: drift.Value('Foods'),
            ));
        await products.insertProduct(FoodItem(
            barcode: 'bls_orange',
            name: 'Orange roh',
            nameDe: 'Orange roh',
            calories: 47,
            protein: 1,
            carbs: 12,
            fat: 0,
            source: FoodItemSource.base));
        await products.insertProduct(FoodItem(
            barcode: 'user_orange',
            name: 'Eigene Orange',
            nameDe: 'Eigene Orange',
            calories: 50,
            protein: 1,
            carbs: 12,
            fat: 0,
            source: FoodItemSource.user));
        for (var i = 0; i < 60; i++) {
          await products.insertProduct(FoodItem(
              barcode: 'off_orange_$i',
              name: 'Orange Saft $i',
              nameDe: 'Orange Saft $i',
              calories: 45,
              protein: 0,
              carbs: 10,
              fat: 0,
              source: FoodItemSource.off));
        }
      });
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider<LiveWorkoutViewModel>(
              create: (_) => _InactiveWorkout()),
        ],
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: picker.value),
      ));
      Future<void> settleDatabase() async {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pumpAndSettle();
      }

      await settleDatabase();
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'Orange');
      await tester.pump(const Duration(milliseconds: 310));
      await settleDatabase();

      // Section headers are present
      expect(find.text('Grundnahrungsmittel'), findsOneWidget);
      expect(find.text('Orange roh'), findsOneWidget);
      expect(find.text('Eigene Lebensmittel'), findsOneWidget);
      expect(find.text('Eigene Orange'), findsOneWidget);
      expect(find.text('Weitere Treffer'), findsOneWidget);

      // Vertical hierarchy: Grundnahrungsmittel < Orange roh < Eigene Lebensmittel < Eigene Orange < Weitere Treffer
      expect(tester.getTopLeft(find.text('Grundnahrungsmittel')).dy,
          lessThan(tester.getTopLeft(find.text('Orange roh')).dy));
      expect(tester.getTopLeft(find.text('Orange roh')).dy,
          lessThan(tester.getTopLeft(find.text('Eigene Lebensmittel')).dy));
      expect(tester.getTopLeft(find.text('Eigene Lebensmittel')).dy,
          lessThan(tester.getTopLeft(find.text('Eigene Orange')).dy));
      expect(tester.getTopLeft(find.text('Eigene Orange')).dy,
          lessThan(tester.getTopLeft(find.text('Weitere Treffer')).dy));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
