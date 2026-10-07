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
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:train_libre/widgets/common/app_ruler_picker.dart';
import 'package:train_libre/widgets/common/app_segmented_control.dart';
import 'package:train_libre/widgets/common/platform_adaptive_switch_list_tile.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

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

    Widget createWidgetUnderTest({ThemeData? theme}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UnitService>(create: (_) => UnitService()),
        ],
        child: MaterialApp(
          theme: theme,
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
      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.byKey(const Key('goal_preset_loseWeight')), findsOneWidget);
      expect(find.byKey(const Key('goal_preset_gainWeight')), findsOneWidget);
      expect(
          find.byKey(const Key('goal_preset_maintainWeight')), findsOneWidget);

      // Select Custom Goal card
      final customCard = find.text('Custom Goal');
      expect(customCard, findsOneWidget);
      await tester.tap(customCard);
      await tester.pumpAndSettle();

      // Verify AppSegmentedControl is rendered for direction
      expect(find.byType(AppSegmentedControl<String>), findsOneWidget);
    });

    testWidgets('progress track remains visible in dark mode', (tester) async {
      final darkTheme = ThemeData.dark();
      await tester.pumpWidget(createWidgetUnderTest(theme: darkTheme));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.color, darkTheme.colorScheme.primary);
      expect(
        progress.backgroundColor,
        darkTheme.colorScheme.primary.withValues(alpha: 0.18),
      );
    });

    testWidgets(
        'baseline transitions to target weight before pace and timeline',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Proceed to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('goal_start_date_card')), findsOneWidget);
      expect(find.byKey(const Key('goal_baseline_card')), findsOneWidget);
      expect(
          find.byKey(const Key('goal_inline_baseline_input')), findsOneWidget);
      expect(find.textContaining('75.0'), findsNothing);

      // Entering baseline weight and continuing
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '80.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 is dedicated to the target weight.
      expect(find.text('What is your target weight?'), findsOneWidget);
      expect(find.byType(AppRulerPicker), findsWidgets);
      expect(find.text('Planned weekly rate'), findsNothing);
      expect(find.text('Target date'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 contains only pace and timeline planning.
      expect(find.text('Plan Pace & Target Date'), findsOneWidget);
      expect(find.text('Planned weekly rate'), findsOneWidget);
      expect(find.text('Target date'), findsWidgets);
      expect(find.text('What is your target weight?'), findsNothing);
    });

    testWidgets('Step 2 allows adjusting target weight without pace controls',
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

      // Step 2 is active
      expect(find.text('What is your target weight?'), findsOneWidget);
      expect(find.text('Start (Baseline)'), findsOneWidget);
      expect(find.text('Planned change'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);

      // Verify quick action chips are present for lose weight (-5.0 kg (75.0))
      expect(find.text('-5.0 kg (75.0)'), findsOneWidget);
      expect(find.text('Planned weekly rate'), findsNothing);
    });

    testWidgets(
        'Step 4 is dedicated motivation and Step 5 is Review & Activate',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '80.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3 (Pace & Timeline)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Plan Pace & Target Date'), findsOneWidget);

      // Step 3 -> Step 4 (Motivation)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Why is this important to you?'), findsOneWidget);
      expect(find.byKey(const ValueKey('reason_text_field')), findsOneWidget);
      // Motivation step does not have the review card
      expect(find.text('Review & Activate'), findsNothing);

      // Step 4 -> Step 5 (Review & Activate)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Review & Activate'), findsOneWidget);
      expect(find.text('Drives nutrition'), findsOneWidget);
      expect(find.text('Activate Goal'), findsOneWidget);
    });

    testWidgets(
        'Maintain weight goal shows corridor and duration without target deficit',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Select Maintain Weight preset
      await tester.tap(find.text('Maintain weight'));
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: enter baseline
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '70.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Maintain corridor screen
      expect(find.text('Maintain weight'), findsWidgets);
      expect(find.textContaining('± 1.0 kg'), findsWidgets);
      expect(find.text('No target date'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Plan Pace & Target Date'), findsOneWidget);
      expect(find.text('No target date'), findsOneWidget);
    });

    testWidgets(
        'Step 1 displays AppRulerPicker and Step 5 renders PlatformAdaptiveSwitchListTile',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify AppRulerPicker is present on Step 1 (Baseline Weight)
      expect(find.byType(AppRulerPicker), findsOneWidget);

      // Enter baseline and continue
      await tester.enterText(
        find.byKey(const Key('goal_inline_baseline_input')),
        '85.0',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3 (Pace & Timeline)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4 (Motivation)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4 -> Step 5 (Review)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify PlatformAdaptiveSwitchListTile is used on Step 5
      expect(find.byType(PlatformAdaptiveSwitchListTile), findsOneWidget);
    });

    testWidgets(
        'Step 1 baseline ruler picker is collapsed when baseline exists and appears only on edit; Step 5 rows have no calendar icons',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Insert an existing baseline weight measurement
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              type: 'weight',
              value: 92.2,
              unit: 'kg',
              date: DateTime.now(),
            ),
          );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1 (Start Date & Baseline Weight)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Baseline weight is displayed
      expect(find.text('92.2'), findsOneWidget);
      // Ruler picker is collapsed by default!
      expect(find.byType(AppRulerPicker), findsNothing);

      // Tap the edit button
      await tester.tap(find.byKey(const Key('goal_edit_baseline_button')));
      await tester.pumpAndSettle();

      // Now ruler picker is visible
      expect(find.byType(AppRulerPicker), findsOneWidget);

      // Tap again to finish editing
      await tester.tap(find.byKey(const Key('goal_edit_baseline_button')));
      await tester.pumpAndSettle();

      // Ruler picker collapses again
      expect(find.byType(AppRulerPicker), findsNothing);

      // Continue to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3 (Pace & Timeline)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4 (Motivation)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4 -> Step 5 (Review & Activate)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Review & Activate'), findsOneWidget);
      expect(find.text('Planned weekly rate'), findsOneWidget);
      expect(find.text('Target date'), findsOneWidget);

      // Step 5 review rows should not have any calendar icons
      expect(
        find.descendant(
          of: find.byType(SummaryCard).first,
          matching: find.byIcon(LucideIcons.calendar),
        ),
        findsNothing,
      );
    });
  });
}
