import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/analytics/presentation/statistics_hub_view_model.dart';
import 'package:train_libre/features/analytics/presentation/widgets/body_metrics_section_card.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  testWidgets(
    'BodyMetricsSectionCard renders legend in Wrap without overflow on Dynamic Type XXL',
    (tester) async {
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final unitService = UnitService();

      await tester.pumpWidget(
        ChangeNotifierProvider<UnitService>.value(
          value: unitService,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BodyMetricsSectionCard(
                    state:
                        const SectionLoadState<BodyNutritionAnalyticsResult>(),
                    onRetry: () {},
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsOneWidget);
    },
  );
}
