import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/analytics/presentation/widgets/training_heatmap.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapHeatmap({
    required DateTime start,
    required DateTime end,
    required Map<DateTime, int> dayCounts,
    required ValueChanged<DateTime> onDayTap,
    DateTime? selectedDay,
    Locale locale = const Locale('de'),
    double width = 340,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: TrainingHeatmap(
              startDate: start,
              endDate: end,
              dayCounts: dayCounts,
              selectedDay: selectedDay,
              onDayTap: onDayTap,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'adapts across 1M, 3M, 6M, and 1Y ranges without overflow and renders labels',
    (tester) async {
      final end = DateTime(2026, 11, 22);
      for (final days in [29, 89, 179, 364]) {
        final start = end.subtract(Duration(days: days));
        await tester.pumpWidget(
          wrapHeatmap(
            start: start,
            end: end,
            dayCounts: {
              end: 1,
              end.subtract(const Duration(days: 2)): 2,
              end.subtract(const Duration(days: 5)): 3,
            },
            onDayTap: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Mo'), findsOneWidget);
        expect(find.text('Mi'), findsOneWidget);
        expect(find.text('Fr'), findsOneWidget);
      }
    },
  );

  testWidgets('6M range shows every full month label without skipping Jun', (
    tester,
  ) async {
    // 180-day range starting late May (May 27 .. Nov 22, 2026)
    final end = DateTime(2026, 11, 22);
    final start = DateTime(2026, 5, 27);
    await tester.pumpWidget(
      wrapHeatmap(
        start: start,
        end: end,
        dayCounts: const {},
        onDayTap: (_) {},
        width: 360,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jun'), findsOneWidget);
    expect(find.text('Jul'), findsOneWidget);
    expect(find.text('Aug'), findsOneWidget);
    expect(find.text('Sep'), findsOneWidget);
    expect(find.text('Okt'), findsOneWidget);
    expect(find.text('Nov'), findsOneWidget);
  });

  testWidgets(
    '3M range shows all 7 weekday labels and non-overlapping months',
    (tester) async {
      final end = DateTime(2026, 11, 22);
      final start = DateTime(2026, 8, 25);
      await tester.pumpWidget(
        wrapHeatmap(
          start: start,
          end: end,
          dayCounts: const {},
          onDayTap: (_) {},
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      for (final day in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.text('Aug'), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Okt'), findsOneWidget);
      expect(find.text('Nov'), findsOneWidget);

      // Ensure Aug and Sep have clear horizontal separation and never touch
      final augRight = tester.getTopRight(find.text('Aug')).dx;
      final sepLeft = tester.getTopLeft(find.text('Sep')).dx;
      expect(sepLeft - augRight, greaterThanOrEqualTo(6.0));
    },
  );

  testWidgets('maps summer dates correctly across a daylight-saving change', (
    tester,
  ) async {
    DateTime? tapped;
    await tester.pumpWidget(
      wrapHeatmap(
        start: DateTime(2026, 3, 23),
        end: DateTime(2026, 4, 12),
        dayCounts: {DateTime(2026, 4, 6): 1},
        onDayTap: (day) => tapped = day,
        width: 340,
      ),
    );
    await tester.pumpAndSettle();
    final grid = find
        .descendant(
          of: find.byType(TrainingHeatmap),
          matching: find.byType(CustomPaint),
        )
        .last;
    final size = tester.getSize(grid);
    // Three weeks, with the final Monday in the third column.
    final pitch = (size.width + 5.0) / 3;
    final cell = (size.height - 6 * 5.0) / 7;
    await tester.tapAt(
      tester.getTopLeft(grid) + Offset(2 * pitch + cell / 2, cell / 2),
    );
    await tester.pump();
    expect(tapped, DateTime(2026, 4, 6));
  });

  testWidgets('tapping a grid cell fires onDayTap with the matching date', (
    tester,
  ) async {
    // Mon Nov 16 .. Sun Nov 22, 2026 -> exactly 1 week column (col 0)
    final start = DateTime(2026, 11, 16);
    final end = DateTime(2026, 11, 22);
    DateTime? tapped;

    await tester.pumpWidget(
      wrapHeatmap(
        start: start,
        end: end,
        dayCounts: {DateTime(2026, 11, 16): 1, DateTime(2026, 11, 18): 2},
        onDayTap: (d) => tapped = d,
      ),
    );
    await tester.pumpAndSettle();

    final customPaint = find
        .descendant(
          of: find.byType(TrainingHeatmap),
          matching: find.byType(CustomPaint),
        )
        .last;
    final topLeft = tester.getTopLeft(customPaint);

    // Tap first cell (Monday, Nov 16)
    await tester.tapAt(topLeft + const Offset(8, 8));
    await tester.pump();
    expect(tapped, DateTime(2026, 11, 16));
  });
}
