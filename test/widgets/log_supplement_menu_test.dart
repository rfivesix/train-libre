import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/supplements/domain/models/supplement.dart';
import 'package:train_libre/features/supplements/domain/models/supplement_log.dart';
import 'package:train_libre/features/supplements/domain/repositories/supplement_repository.dart';
import 'package:train_libre/features/supplements/presentation/dialogs/log_supplement_menu.dart';
import 'package:train_libre/features/profile/presentation/measurements_screen.dart';
import 'package:train_libre/features/app/presentation/widgets/glass_bottom_menu.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/profile/domain/repositories/profile_repository.dart';
import 'package:train_libre/features/profile/domain/models/measurement_session.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/util/design_constants.dart';
import 'package:provider/provider.dart';

class _FakeSupplementRepo implements SupplementRepository {
  final List<Supplement> supplements;

  _FakeSupplementRepo(this.supplements);

  @override
  Future<List<Supplement>> getAllSupplements() async => supplements;

  @override
  Stream<List<Supplement>> watchAllSupplements() => Stream.value(supplements);

  @override
  Stream<List<Supplement>> watchSupplementsForDate(DateTime date) =>
      Stream.value(supplements);

  @override
  Stream<List<SupplementLog>> watchSupplementLogsForDate(DateTime date) =>
      Stream.value(const []);

  @override
  Future<List<Supplement>> getSupplementsForDate(DateTime date) async =>
      supplements;

  @override
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async =>
      const [];

  @override
  Future<int> insertSupplement(Supplement supplement) async => 1;

  @override
  Future<void> updateSupplement(Supplement supplement) async {}

  @override
  Future<void> deleteSupplement(int id) async {}

  @override
  Future<void> insertSupplementLog(SupplementLog log) async {}

  @override
  Future<void> updateSupplementLog(SupplementLog log) async {}

  @override
  Future<void> deleteSupplementLog(int id) async {}

  @override
  Future<void> deleteCaffeineLogByFoodEntryId(int foodEntryId) async {}

  @override
  Future<void> deleteCaffeineLogByFluidEntryId(int fluidEntryId) async {}
}

class _FakeProfileRepo implements IProfileRepository {
  @override
  Future<List<MeasurementSession>> getMeasurementSessions() async => const [];
  @override
  Future<DateTime?> getEarliestMeasurementDate() async => null;
  @override
  Future<void> deleteMeasurementSession(int sessionId) async {}
  @override
  Future<void> insertMeasurementSession(MeasurementSession session) async {}
  @override
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
          String type, DateTimeRange range) async =>
      const [];
  @override
  Stream<List<ChartDataPoint>> watchChartDataForTypeAndRange(
          String type, DateTimeRange range) =>
      Stream.value(const []);
  @override
  Future<db.Profile?> getUserProfile() async => null;
  @override
  Future<void> saveUserProfile(
      {required String name,
      required DateTime? birthday,
      required int? height,
      required String? gender}) async {}
  @override
  Future<db.AppSetting?> getAppSettings() async => null;
  @override
  Future<int> getCurrentTargetStepsOrDefault() async => 10000;
  @override
  Future<void> saveUserGoals(
      {required int calories,
      required int protein,
      required int carbs,
      required int fat,
      required int water,
      required int steps}) async {}
}

void main() {
  testWidgets('LogSupplementMenu renders supplement items with titleMedium font style',
      (tester) async {
    final fakeRepo = _FakeSupplementRepo([
      Supplement(
        id: 1,
        name: 'Creatine',
        code: 'creatine',
        defaultDose: 5.0,
        unit: 'g',
      ),
      Supplement(
        id: 2,
        name: 'Vitamin D',
        code: 'vitamin_d',
        defaultDose: 50.0,
        unit: 'mcg',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LogSupplementMenu(
            close: () {},
            repository: fakeRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Creatine'));
    expect(textWidget.style?.fontWeight, FontWeight.w600);
    expect(textWidget.style?.fontSize, 16.0); // titleMedium default size
  });

  testWidgets('MeasurementFormSheet uses Clip.none and top headroom padding on SingleChildScrollView',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UnitService>(
            create: (_) => UnitService(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: MeasurementFormSheet(
              repository: _FakeProfileRepo(),
              onSaved: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    final scrollView = tester.widget<SingleChildScrollView>(scrollViewFinder);
    expect(scrollView.clipBehavior, Clip.none);
    expect(
      scrollView.padding,
      const EdgeInsets.only(
        top: DesignConstants.spacingS,
        bottom: DesignConstants.spacingL,
      ),
    );
  });

  testWidgets('showGlassBottomMenu contentBuilder SingleChildScrollView uses Clip.none',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showGlassBottomMenu(
                  context: context,
                  title: 'Test Title',
                  contentBuilder: (ctx, close) => const Text('Inner Content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    final scrollView = tester.widget<SingleChildScrollView>(scrollViewFinder);
    expect(scrollView.clipBehavior, Clip.none);
    expect(
      scrollView.padding,
      const EdgeInsets.only(top: DesignConstants.spacingXS),
    );
  });
}
