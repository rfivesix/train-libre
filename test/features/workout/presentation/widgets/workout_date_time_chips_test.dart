import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_date_time_chips.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders date and time SummaryCards on one line with time aligned right',
    (tester) async {
      final start = DateTime(2026, 11, 23, 0, 33);
      final end = DateTime(2026, 11, 23, 1, 47);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              // Wide enough for the Ahem test font so both cards fit on one row.
              child: SizedBox(
                width: 640,
                child: WorkoutDateTimeChips(startTime: start, endTime: end),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = find.byType(SummaryCard);
      expect(cards, findsNWidgets(2));
      expect(find.textContaining('23.'), findsOneWidget);
      expect(find.text('00:33 – 01:47'), findsOneWidget);

      final dateRect = tester.getRect(cards.at(0));
      final timeRect = tester.getRect(cards.at(1));
      final containerRect = tester.getRect(find.byType(WorkoutDateTimeChips));

      expect(dateRect.top, closeTo(timeRect.top, 0.5));
      expect(dateRect.left, closeTo(containerRect.left, 0.5));
      expect(timeRect.right, closeTo(containerRect.right, 0.5));
      expect(timeRect.left - dateRect.right, greaterThan(8.0));
    },
  );

  testWidgets(
    'stacks date above right-aligned time SummaryCard when space is narrow',
    (tester) async {
      final start = DateTime(2026, 11, 23, 0, 33);
      final end = DateTime(2026, 11, 23, 1, 47);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: WorkoutDateTimeChips(startTime: start, endTime: end),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = find.byType(SummaryCard);
      expect(cards, findsNWidgets(2));

      final dateRect = tester.getRect(cards.at(0));
      final timeRect = tester.getRect(cards.at(1));
      final containerRect = tester.getRect(find.byType(WorkoutDateTimeChips));

      expect(timeRect.top, greaterThanOrEqualTo(dateRect.bottom));
      expect(dateRect.left, closeTo(containerRect.left, 0.5));
      expect(dateRect.right, lessThan(containerRect.right));
      expect(timeRect.right, closeTo(containerRect.right, 0.5));
    },
  );

  testWidgets('invokes onDateTap and onTimeTap when cards are tapped', (
    tester,
  ) async {
    var dateTapped = false;
    var timeTapped = false;
    final start = DateTime(2026, 11, 23, 0, 33);
    final end = DateTime(2026, 11, 23, 1, 47);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              child: WorkoutDateTimeChips(
                startTime: start,
                endTime: end,
                onDateTap: () => dateTapped = true,
                onTimeTap: () => timeTapped = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(SummaryCard);
    await tester.tap(cards.at(0));
    await tester.tap(cards.at(1));

    expect(dateTapped, isTrue);
    expect(timeTapped, isTrue);
  });
}
