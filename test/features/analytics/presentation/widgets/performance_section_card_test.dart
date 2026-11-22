import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/analytics/presentation/statistics_hub_view_model.dart';
import 'package:train_libre/features/analytics/presentation/widgets/performance_section_card.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  testWidgets(
    'shows max-weight absolute top achievement instead of percentage',
    (tester) async {
      const state = SectionLoadState<PerformanceRecordsSectionData>(
        data: PerformanceRecordsSectionData(
          recentPrs: [],
          notableImprovements: [
            {
              'exerciseName': 'Bench press',
              'weightKg': 100.0,
              'reps': 12,
              'improvementPct': 17.9,
            },
            {
              'exerciseName': 'Squat',
              'weightKg': 120.0,
              'reps': 5,
              'improvementPct': 9.1,
            },
          ],
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<UnitService>(
          create: (_) => UnitService(),
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PerformanceSectionCard(
                state: state,
                chipText: 'Letzte 30 Tage',
                onRetry: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 neue Bestleistungen'), findsOneWidget);
      expect(find.text('Top: Bench press · 100 kg × 12'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    },
  );
}
