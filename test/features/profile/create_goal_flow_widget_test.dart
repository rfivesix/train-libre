import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/presentation/create_goal_flow.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/app_ruler_picker.dart';
import 'package:train_libre/widgets/common/app_segmented_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateGoalFlow UI & Ruler Tests', () {
    late AppDatabase db;
    late GoalRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
      db = AppDatabase(NativeDatabase.memory());
      repository = GoalRepositoryImpl(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UnitService>(create: (_) => UnitService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CreateGoalFlow(repository: repository),
          ),
        ),
      );
    }

    testWidgets('Step 0 displays preset choices and AppSegmentedControl for custom direction',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify preset cards are present
      expect(find.text('Set New Goal'), findsOneWidget);

      // Select Custom Goal card
      final customCard = find.text('Custom Goal');
      expect(customCard, findsOneWidget);
      await tester.tap(customCard);
      await tester.pumpAndSettle();

      // Verify AppSegmentedControl is rendered for direction
      expect(find.byType(AppSegmentedControl<String>), findsOneWidget);
    });

    testWidgets('Step 1 and Step 2 display AppRulerPicker.weight', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Proceed to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Switch to manual baseline if button exists
      final switchManual = find.text('Enter manually instead');
      if (switchManual.evaluate().isNotEmpty) {
        await tester.tap(switchManual);
        await tester.pumpAndSettle();
      }

      // Verify AppRulerPicker is in Step 1
      expect(find.byType(AppRulerPicker), findsOneWidget);

      // Proceed to Step 2 (Target Weight)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 question
      expect(find.text('What is your target weight?'), findsOneWidget);

      // Step 2 should display AppRulerPicker.weight
      expect(find.byType(AppRulerPicker), findsOneWidget);
    });

    testWidgets('Step 3 shows trajectory card, pace dropdown, and duration dropdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: switch to manual if button exists
      final switchManual = find.text('Enter manually instead');
      if (switchManual.evaluate().isNotEmpty) {
        await tester.tap(switchManual);
        await tester.pumpAndSettle();
      }

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 questions
      expect(find.text('Plan Pace & Target Date'), findsOneWidget);

      // Verify dropdown keys exist
      expect(find.byKey(const ValueKey('rate_dropdown_moderate')), findsOneWidget);
      expect(find.byKey(const ValueKey('duration_dropdown_custom')), findsOneWidget);
    });
  });
}
