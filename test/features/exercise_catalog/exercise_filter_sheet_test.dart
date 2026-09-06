import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/presentation/widgets/exercise_filter_sheet.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/platform_adaptive_dropdown.dart';

/// The filter asks three questions, and each is its own collapsed field.
///
/// It began as one flat list — body regions, then equipment, nothing between
/// them — so "Cardio" and "Cardio machine" sat six rows apart meaning
/// different things. Naming the sections fixed the ambiguity but not the
/// length; eight regions and two implements as open lists is a sheet you
/// scroll past rather than read.
void main() {
  late List<String> regions;
  late List<String> equipment;
  late List<String> tags;
  late int changeCount;

  setUp(() {
    regions = [];
    equipment = [];
    tags = [];
    changeCount = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    List<ExerciseFilterOption> usageOptions = const [
      ExerciseFilterOption(value: 'main_lift', label: 'Main Lift'),
    ],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseFilterSheet(
              onChanged: () => changeCount++,
              sections: [
                ExerciseFilterSection(
                  title: 'Body region',
                  selection: regions,
                  options: const [
                    ExerciseFilterOption(value: 'Cardio', label: 'Cardio'),
                    ExerciseFilterOption(value: 'Chest', label: 'Chest'),
                  ],
                ),
                ExerciseFilterSection(
                  title: 'Equipment',
                  selection: equipment,
                  options: const [
                    ExerciseFilterOption(
                        value: 'cardio_machine', label: 'Cardio machine'),
                    ExerciseFilterOption(value: 'barbell', label: 'Barbell'),
                  ],
                ),
                ExerciseFilterSection(
                  title: 'Purpose',
                  selection: tags,
                  options: usageOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the collapsed field carrying [label].
  ///
  /// Taps the field, not its label: the label is the InputDecorator's floating
  /// text and sits outside the tap target.
  Future<void> open(WidgetTester tester, String label) async {
    await tester.tap(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(PlatformAdaptiveMultiSelectField<String>),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String option) async {
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  group('structure', () {
    testWidgets('each axis is its own collapsed field', (tester) async {
      expect(
          find.byType(PlatformAdaptiveMultiSelectField<String>), findsNothing);
      await pump(tester);

      expect(
        find.byType(PlatformAdaptiveMultiSelectField<String>),
        findsNWidgets(3),
      );
      expect(find.text('Body region'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Purpose'), findsOneWidget);
    });

    testWidgets('the options are not on screen until a field is opened',
        (tester) async {
      // The point of collapsing: fourteen implements do not sit between the
      // user and the rest of the sheet.
      await pump(tester);

      expect(find.text('Cardio machine'), findsNothing);
      expect(find.text('Barbell'), findsNothing);
    });

    testWidgets('the two "cardio" entries never appear in one list',
        (tester) async {
      await pump(tester);

      await open(tester, 'Body region');
      expect(find.text('Cardio'), findsWidgets);
      expect(find.text('Cardio machine'), findsNothing,
          reason: 'the equipment belongs to a different question');
    });

    testWidgets('how the sections combine is stated, not implied',
        (tester) async {
      await pump(tester);

      expect(find.textContaining('widen'), findsOneWidget);
      expect(find.textContaining('narrow'), findsOneWidget);
    });

    testWidgets('an empty section is left out entirely', (tester) async {
      // A pre-v2 catalog has no usage tags. An empty field would be worse
      // than no field.
      await pump(tester, usageOptions: const []);

      expect(find.text('Purpose'), findsNothing);
      expect(find.text('Body region'), findsOneWidget);
      expect(
        find.byType(PlatformAdaptiveMultiSelectField<String>),
        findsNWidgets(2),
      );
    });
  });

  group('selecting', () {
    testWidgets('a pick in one field leaves the others alone', (tester) async {
      await pump(tester);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');
      await open(tester, 'Equipment');
      await pick(tester, 'Barbell');

      expect(regions, ['Chest']);
      expect(equipment, ['barbell'],
          reason: 'picking equipment cleared the body region');
      expect(tags, isEmpty);
      expect(changeCount, 2);
    });

    testWidgets('several picks in one field accumulate', (tester) async {
      // The reason this is a multi-select field and not the plain dropdown
      // beside it: "chest or back" is a legitimate filter.
      //
      // Reopened between picks because GlassMenu closes itself after every
      // item tap and offers no way to stay up — the one cost of using the
      // app's existing menu instead of building a second one.
      await pump(tester);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');
      await open(tester, 'Body region');
      await pick(tester, 'Cardio');

      expect(regions, ['Chest', 'Cardio']);
    });

    testWidgets('picking a selected option clears it', (tester) async {
      await pump(tester);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');
      await open(tester, 'Body region');
      await pick(tester, 'Chest');

      expect(regions, isEmpty);
    });

    testWidgets('the collapsed field says what is picked', (tester) async {
      await pump(tester);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');

      expect(find.text('Chest'), findsWidgets,
          reason: 'the collapsed field should name the selection');
    });
  });

  group('reset', () {
    testWidgets('is always present, and inert while nothing is selected',
        (tester) async {
      // It used to appear on first selection and push everything above it
      // down, so the sheet shifted under the finger that had just tapped.
      await pump(tester);

      TextButton resetButton() => tester.widget<TextButton>(find.ancestor(
            of: find.text('Reset'),
            matching: find.byType(TextButton),
          ));

      expect(find.text('Reset'), findsOneWidget);
      expect(resetButton().onPressed, isNull);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');

      expect(resetButton().onPressed, isNotNull);
    });

    testWidgets('clears every axis at once', (tester) async {
      await pump(tester);

      await open(tester, 'Body region');
      await pick(tester, 'Chest');
      await open(tester, 'Equipment');
      await pick(tester, 'Barbell');

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(regions, isEmpty);
      expect(equipment, isEmpty);
      expect(find.text('Reset'), findsOneWidget);
    });
  });
}
