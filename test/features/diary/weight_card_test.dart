import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/presentation/widgets/weight_card.dart';
import 'package:train_libre/features/diary/presentation/widgets/weight_ruler.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';
import 'package:train_libre/features/profile/presentation/measurements_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/util/design_constants.dart';

class _NavigationObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRoute = route;
  }
}

class _FailingSource extends ProfileLocalDataSource {
  _FailingSource(super.database);
  @override
  Future<void> saveWeightKg(double weightKg, {required DateTime date}) async {
    throw StateError('test write failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late ProfileLocalDataSource source;
  late UnitService units;
  final today = DateUtils.dateOnly(DateTime.now());

  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('packages/flutter_lucide/lucide');
    icons.addFont(
        rootBundle.load('packages/flutter_lucide/lib/fonts/lucide.ttf'));
    await icons.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    units = UnitService();
    await units.reload();
    database = AppDatabase(NativeDatabase.memory());
    source = ProfileLocalDataSource(database);
  });

  tearDown(() async {
    units.dispose();
  });

  void cardTest(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
        await tester.runAsync(database.close);
      }
    });
  }

  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
    Brightness brightness = Brightness.light,
    String language = 'de',
    DateTime? date,
    NavigatorObserver? observer,
    ProfileLocalDataSource? dataSource,
  }) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: units,
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: false,
          brightness: brightness,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: DesignConstants.brandAccentColor,
            brightness: brightness,
          ).copyWith(
              primary: DesignConstants.brandAccentColor,
              onPrimary: Colors.black),
        ),
        navigatorObservers: [if (observer != null) observer],
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: const ValueKey('capture'),
                child: WeightCard(
                  key: const ValueKey('card'),
                  date: date ?? today,
                  dataSource: dataSource ?? source,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Drift native queries complete on the real event loop.
    await tester.runAsync(() async {
      await source
          .watchLatestWeightBefore(today.add(const Duration(days: 1)))
          .first;
    });
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('WEIGHT_QA')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/weight-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<List<Measurement>> rows(WidgetTester tester) async => (await tester
      .runAsync(() => database.select(database.measurements).get()))!;

  Future<void> seed(WidgetTester tester, double kg, DateTime date) async {
    await tester.runAsync(() => source.saveWeightKg(kg, date: date));
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Speichern'));
    await tester.runAsync(() async {
      // A queued database read waits behind the save transaction.
      await database.select(database.measurements).get();
    });
    await tester.pumpAndSettle();
  }

  cardTest('never weighed: pitch, wide action and neutral draft',
      (tester) async {
    await mount(tester);
    expect(find.text('Gewicht eintragen'), findsOneWidget);
    expect(find.textContaining('Kalorienempfehlung'), findsOneWidget);
    expect(find.byKey(const ValueKey('weight-value')), findsNothing);
    await capture(tester, 'empty');
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    expect(find.text('75,0'), findsOneWidget);
    expect(find.byType(WeightRuler), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Speichern'), findsOneWidget);
    expect(await rows(tester), isEmpty);
  });

  cardTest('matches the sleep score value and existing chevron styles',
      (tester) async {
    await seed(tester, 84.2, today);
    await mount(tester);

    final colorScheme =
        Theme.of(tester.element(find.byType(WeightCard))).colorScheme;
    final label = tester.widget<Text>(find.text('Gewicht'));
    final value =
        tester.widget<Text>(find.byKey(const ValueKey('weight-value')));
    final unit = tester.widget<Text>(find.text('kg'));

    expect(
        label.style?.fontSize,
        Theme.of(tester.element(find.byType(WeightCard)))
            .textTheme
            .bodyMedium
            ?.fontSize);
    expect(
        value.style?.fontSize,
        Theme.of(tester.element(find.byType(WeightCard)))
            .textTheme
            .titleLarge
            ?.fontSize);
    expect(value.style?.color, colorScheme.onSurface);
    expect(unit.style?.color, colorScheme.onSurface.withValues(alpha: .64));
    final chevron = tester.widget<Icon>(find.byIcon(LucideIcons.chevron_right));
    expect(chevron.size, isNull);
    expect(chevron.color, colorScheme.onSurface);
  });

  cardTest('ruler moves continuously while the displayed value stays decimal',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(WeightRuler));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-3, 0));
    await tester.pump();

    final ruler = tester.widget<WeightRuler>(find.byType(WeightRuler));
    expect(ruler.value, greaterThan(75));
    expect(ruler.value, lessThan(75.1));
    expect(find.text('75,0'), findsOneWidget);

    await gesture.moveBy(const Offset(-4, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('75,1'), findsOneWidget);
    expect(await rows(tester), isEmpty);
  });

  cardTest('stale value shows calendar age and preselects latest weight',
      (tester) async {
    await seed(
        tester, 85.1, DateTime(today.year, today.month, today.day - 3, 23));
    await mount(tester);
    expect(find.text('85,1'), findsOneWidget);
    expect(find.text('vor 3 Tagen'), findsOneWidget);
    await capture(tester, 'stale');
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    expect(tester.widget<WeightRuler>(find.byType(WeightRuler)).value, 85.1);
  });

  cardTest('today shows latest daily value and opens weight history',
      (tester) async {
    await seed(tester, 84.8, today.add(const Duration(hours: 7)));
    await seed(tester, 84.2, today.add(const Duration(hours: 8)));
    final observer = _NavigationObserver();
    await mount(tester, observer: observer);
    expect(find.text('84,2'), findsOneWidget);
    expect(find.text('heute'), findsOneWidget);
    await capture(tester, 'today');
    expect(find.text('Eintragen'), findsNothing);
    await tester.tap(find.text('84,2'));
    final route = observer.lastRoute! as MaterialPageRoute<void>;
    final destination = route.builder(tester.element(find.byType(WeightCard)));
    expect(destination, isA<MeasurementsScreen>());
    expect(
        (destination as MeasurementsScreen).initialMeasurementType, 'weight');
    // Navigation is checked without starting the unrelated profile screen.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final imperial in [false, true]) {
    cardTest('drag and save persists kg with imperial=$imperial',
        (tester) async {
      if (imperial) await units.setUnitSystem(UnitSystem.imperial);
      await mount(tester);
      await tester.tap(find.text('Gewicht eintragen'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(WeightRuler), const Offset(-70, 0));
      await tester.pumpAndSettle();
      final displayed =
          tester.widget<WeightRuler>(find.byType(WeightRuler)).value;
      expect(displayed, greaterThan(imperial ? 165.3 : 75.0));
      await capture(tester, imperial ? 'edit-lbs' : 'edit-kg');
      expect(await rows(tester), isEmpty, reason: 'release must never save');
      await save(tester);
      final saved = await rows(tester);
      expect(saved, hasLength(1));
      expect(saved.single.type, 'weight');
      expect(saved.single.unit, 'kg');
      expect(saved.single.value,
          closeTo(imperial ? UnitService.lbsToKg(displayed) : displayed, 1e-8));
      expect(DateUtils.isSameDay(saved.single.date, today), isTrue);
      expect(find.text('heute'), findsOneWidget);
    });
  }

  cardTest('expansion completes in 300 ms and never saves during animation',
      (tester) async {
    await seed(tester, 81.3, today.subtract(const Duration(days: 1)));
    await mount(tester);
    final card = find.byKey(const ValueKey('card'));
    final collapsedHeight = tester.getSize(card).height;
    await tester.tap(find.text('Eintragen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediateHeight = tester.getSize(card).height;
    expect(intermediateHeight, greaterThan(collapsedHeight));
    await tester.pump(const Duration(milliseconds: 200));
    final expandedHeight = tester.getSize(card).height;
    expect(expandedHeight, greaterThan(intermediateHeight));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(card).height, expandedHeight);
    expect(await rows(tester), hasLength(1));
  });

  cardTest('external measurements update the card reactively', (tester) async {
    await mount(tester);
    await seed(tester, 82.6, today);
    await tester.pumpAndSettle();
    expect(find.text('82,6'), findsOneWidget);
    expect(find.text('heute'), findsOneWidget);
  });

  cardTest('cancel discards drag; reopening restores persisted value',
      (tester) async {
    await seed(tester, 81.3, today.subtract(const Duration(days: 1)));
    await mount(tester);
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(WeightRuler), const Offset(-140, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect((await rows(tester)).single.value, 81.3);
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    expect(tester.widget<WeightRuler>(find.byType(WeightRuler)).value, 81.3);
  });

  cardTest('imperial setting change while editing preserves physical weight',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await units.setUnitSystem(UnitSystem.imperial);
    await tester.pumpAndSettle();
    expect(find.text('165,3'), findsOneWidget);
    await save(tester);
    expect((await rows(tester)).single.value,
        closeTo(UnitService.lbsToKg(165.3), 1e-8));
  });

  cardTest('historical diary day excludes future weights and saves to that day',
      (tester) async {
    final past = today.subtract(const Duration(days: 3));
    await seed(tester, 83.5, past.subtract(const Duration(days: 1)));
    await seed(tester, 82.0, today);
    await mount(tester, date: past);
    expect(find.text('83,5'), findsOneWidget);
    expect(find.text('vor 1 Tag'), findsOneWidget);
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    await save(tester);
    final all = await rows(tester);
    expect(
        all.where((row) => DateUtils.isSameDay(row.date, past)), hasLength(1));
    expect(find.text('heute'), findsNothing);
  });

  cardTest('out-of-range draft disables saving without rating color',
      (tester) async {
    await seed(tester, 28.4, today.subtract(const Duration(days: 1)));
    await mount(tester);
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    expect(find.text('Wert außerhalb des üblichen Bereichs'), findsOneWidget);
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'));
    expect(button.onPressed, isNull);
  });

  cardTest('save failure retains the draft and allows retry', (tester) async {
    await mount(tester, dataSource: _FailingSource(database));
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('nicht gespeichert'), findsOneWidget);
    expect(find.byType(WeightRuler), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Speichern'))
            .onPressed,
        isNotNull);
    expect(await rows(tester), isEmpty);
  });

  cardTest('ruler exposes one-decimal accessibility adjustments',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await mount(tester);
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byType(WeightRuler));
    tester.binding.performSemanticsAction(ui.SemanticsActionEvent(
      type: ui.SemanticsAction.increase,
      viewId: tester.view.viewId,
      nodeId: node.id,
    ));
    await tester.pumpAndSettle();
    expect(find.text('75,1'), findsOneWidget);
    semantics.dispose();
  });

  for (final language in ['de', 'en', 'fr', 'it', 'ja']) {
    for (final brightness in Brightness.values) {
      cardTest('$language $brightness narrow imperial layout has no overflow',
          (tester) async {
        await units.setUnitSystem(UnitSystem.imperial);
        await mount(tester,
            width: 320,
            textScale: 1.5,
            language: language,
            brightness: brightness);
        final l10n =
            AppLocalizations.of(tester.element(find.byType(WeightCard)))!;
        await tester.tap(find.text(l10n.diaryWeightLogLong));
        await tester.pumpAndSettle();
        expect(find.text(l10n.cancel), findsOneWidget);
        expect(find.text(l10n.save), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (language == 'de') {
          await capture(tester, 'narrow-${brightness.name}');
        }
      });
    }
  }
}
