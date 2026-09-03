import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/presentation/widgets/exercise_filter_sheet.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// The filter asks two questions, and has to look like two questions.
///
/// It was one flat list: body regions, then equipment, with nothing between
/// them — so "Cardio" and "Cardio machine" sat six rows apart meaning
/// different things, and nothing on screen said whether picking one of each
/// narrowed the results or replaced the other.
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

  testWidgets('every axis gets its own heading', (tester) async {
    await pump(tester);

    // AppSectionHeader upper-cases its title.
    expect(find.text('BODY REGION'), findsOneWidget);
    expect(find.text('EQUIPMENT'), findsOneWidget);
    expect(find.text('PURPOSE'), findsOneWidget);
  });

  testWidgets('the two "cardio" entries are not adjacent in one list',
      (tester) async {
    await pump(tester);

    final region = tester.getTopLeft(find.text('Cardio'));
    final machine = tester.getTopLeft(find.text('Cardio machine'));
    final heading = tester.getTopLeft(find.text('EQUIPMENT'));

    // The equipment heading sits between them, which is the whole point.
    expect(heading.dy, greaterThan(region.dy));
    expect(machine.dy, greaterThan(heading.dy));
  });

  testWidgets('how the sections combine is stated, not implied',
      (tester) async {
    await pump(tester);

    expect(find.textContaining('widen'), findsOneWidget);
    expect(find.textContaining('narrow'), findsOneWidget);
  });

  testWidgets('a pick in one section leaves the others alone', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Barbell'));
    await tester.pumpAndSettle();

    expect(regions, ['Chest']);
    expect(equipment, ['barbell'],
        reason: 'picking equipment cleared the body region');
    expect(tags, isEmpty);
    expect(changeCount, 2);
  });

  testWidgets('several picks within one section accumulate', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Cardio'));
    await tester.pumpAndSettle();

    expect(regions, ['Chest', 'Cardio']);
  });

  testWidgets('tapping a selected chip clears it', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();

    expect(regions, isEmpty);
  });

  testWidgets('reset appears only with a selection, and clears every axis',
      (tester) async {
    await pump(tester);
    expect(find.text('Reset'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Barbell'));
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(regions, isEmpty);
    expect(equipment, isEmpty);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('an empty section is left out entirely', (tester) async {
    // A pre-v2 catalog has no usage tags. An empty heading would be worse
    // than no heading.
    await pump(tester, usageOptions: const []);

    expect(find.text('PURPOSE'), findsNothing);
    expect(find.text('BODY REGION'), findsOneWidget);
  });
}
