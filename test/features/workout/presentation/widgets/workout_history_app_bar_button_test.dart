import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_history_app_bar_button.dart';
import 'package:train_libre/features/workout/presentation/workout_history_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/util/design_constants.dart';

class _FakeWorkoutRepository implements IWorkoutRepository {
  @override
  Stream<List<WorkoutLog>> watchFullWorkoutLogs() {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    Brightness brightness = Brightness.dark,
    VoidCallback? onPressed,
    IWorkoutRepository? repository,
  }) {
    return Provider<IWorkoutRepository>.value(
      value: repository ?? _FakeWorkoutRepository(),
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: brightness,
          colorScheme: brightness == Brightness.dark
              ? const ColorScheme.dark()
              : const ColorScheme.light(),
        ),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              WorkoutHistoryAppBarButton(onPressed: onPressed),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders calendar icon with correct tooltip and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify calendar icon
    final iconFinder = find.byIcon(Icons.calendar_month);
    expect(iconFinder, findsOneWidget);

    // Verify tooltip
    final tooltipFinder = find.byTooltip('Workout-Historie');
    expect(tooltipFinder, findsOneWidget);

    // Verify semantics
    final semanticsFinder = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.label == 'Workout-Historie' &&
          w.properties.button == true,
    );
    expect(semanticsFinder, findsOneWidget);
  });

  testWidgets('has 36x36 dimensions and spacing padding', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify sized box 36x36
    final sizedBoxFinder = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 36 && w.height == 36,
    );
    expect(sizedBoxFinder, findsOneWidget);

    // Verify right padding
    final paddingFinder = find.byWidgetPredicate(
      (w) =>
          w is Padding &&
          w.padding == const EdgeInsets.only(right: DesignConstants.spacingS),
    );
    expect(paddingFinder, findsOneWidget);

    // Verify circular shape on Material
    final materialFinder = find.byWidgetPredicate(
      (w) => w is Material && w.shape is CircleBorder,
    );
    expect(materialFinder, findsOneWidget);
  });

  testWidgets('applies onSurface background and surface icon matching profile button', (
    tester,
  ) async {
    // Dark mode
    await tester.pumpWidget(buildTestWidget(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    final darkMaterial = tester.widget<Material>(
      find.byWidgetPredicate((w) => w is Material && w.shape is CircleBorder),
    );
    expect(darkMaterial.color, equals(const ColorScheme.dark().onSurface));

    final darkIcon = tester.widget<Icon>(find.byIcon(Icons.calendar_month));
    expect(darkIcon.color, equals(const ColorScheme.dark().surface));

    // Light mode
    await tester.pumpWidget(buildTestWidget(brightness: Brightness.light));
    await tester.pumpAndSettle();

    final lightMaterial = tester.widget<Material>(
      find.byWidgetPredicate((w) => w is Material && w.shape is CircleBorder),
    );
    expect(lightMaterial.color, equals(const ColorScheme.light().onSurface));

    final lightIcon = tester.widget<Icon>(find.byIcon(Icons.calendar_month));
    expect(lightIcon.color, equals(const ColorScheme.light().surface));
  });

  testWidgets('calls custom onPressed callback when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildTestWidget(
        onPressed: () {
          tapped = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WorkoutHistoryAppBarButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('navigates to WorkoutHistoryScreen on tap by default', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WorkoutHistoryAppBarButton));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
  });
}
