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

    testWidgets(
        'Step 0 displays preset choices and AppSegmentedControl for custom direction',
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

    testWidgets('Step 1 requires an explicit baseline without a 75 kg fallback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Proceed to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('goal_inline_baseline_input')), findsOneWidget);
      expect(find.textContaining('75.0'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '80.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How do you want to plan?'), findsOneWidget);
      expect(find.text('Open goal'), findsOneWidget);
      expect(find.text('Weekly rate'), findsOneWidget);
      expect(find.text('Target weight'), findsOneWidget);
    });

    testWidgets('Step 3 shows the controls for the selected weekly-rate mode',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '80.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly rate'), findsWidgets);
      expect(find.byType(AppRulerPicker), findsOneWidget);
    });

    testWidgets('motivation is the final step and contains activation preview',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '80.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Why is this important to you?'), findsOneWidget);
      expect(find.text('Review & Activate'), findsOneWidget);
      expect(find.text('Activate Goal'), findsOneWidget);
    });
  });
}
