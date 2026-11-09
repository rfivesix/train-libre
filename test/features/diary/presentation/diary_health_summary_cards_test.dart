import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/diary/presentation/diary_view_model.dart';
import 'package:train_libre/features/diary/presentation/widgets/pulse_summary_card.dart';
import 'package:train_libre/features/diary/presentation/widgets/sleep_summary_card.dart';
import 'package:train_libre/features/pulse/domain/pulse_models.dart';
import 'package:train_libre/features/pulse/presentation/pulse_analysis_screen.dart';
import 'package:train_libre/features/sleep/data/sleep_day_repository.dart';
import 'package:train_libre/features/sleep/presentation/day/sleep_day_overview_page.dart';
import 'package:train_libre/features/sleep/presentation/sleep_navigation.dart';
import 'package:train_libre/features/sleep/presentation/widgets/sleep_period_scope_layout.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/util/design_constants.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

class _DiaryStub extends ChangeNotifier implements DiaryViewModel {
  bool loading = false;
  bool hasDiaryData = false;
  void updateLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  @override
  DateTime get selectedDate => DateTime(2026, 10, 3);
  @override
  bool get isSleepWidgetLoading => loading;
  @override
  bool get isPulseWidgetLoading => loading;
  @override
  bool get hasDataForSelectedDate => hasDiaryData;
  @override
  bool get isSelectedDateToday => false;
  @override
  SleepDayOverviewData? get sleepOverview => null;
  @override
  PulseAnalysisSummary? get pulseSummary => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Observer extends NavigatorObserver {
  Route<dynamic>? route;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    this.route = route;
  }
}

void main() {
  for (final sleep in [true, false]) {
    testWidgets(
        '${sleep ? 'sleep' : 'pulse'} does not flash while loading an empty day',
        (tester) async {
      final vm = _DiaryStub()..hasDiaryData = true;
      addTearDown(vm.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<DiaryViewModel>.value(
        value: vm,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body:
                  sleep ? const SleepSummaryCard() : const PulseSummaryCard()),
        ),
      ));
      expect(find.byType(SummaryCard), findsNothing);
      vm.updateLoading(true);
      await tester.pump();
      expect(find.byType(SummaryCard), findsNothing);
      vm.updateLoading(false);
      await tester.pump();
      expect(find.byType(SummaryCard), findsNothing);
    });
  }

  for (final sleep in [true, false]) {
    testWidgets(
        '${sleep ? 'sleep' : 'pulse'} card uses training spacing and a dated morph route',
        (tester) async {
      final vm = _DiaryStub();
      final observer = _Observer();
      addTearDown(vm.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<DiaryViewModel>.value(
        value: vm,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [observer],
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topCenter,
                  child: sleep
                      ? const SleepSummaryCard()
                      : const PulseSummaryCard())),
        ),
      ));
      await tester.pump();
      final card = tester.widget<SummaryCard>(find.byType(SummaryCard));
      expect(card.margin,
          const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS));
      final title = find.text(sleep ? 'Sleep' : 'Pulse');
      expect(title, findsOneWidget);
      final ink = find
          .descendant(
              of: find.byType(SummaryCard), matching: find.byType(InkWell))
          .first;
      final padding = tester.widget<Padding>(
          find.descendant(of: ink, matching: find.byType(Padding)).first);
      expect(
          padding.padding,
          const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingM));
      await tester.tap(title);
      final route = observer.route! as CardMorphRoute<void>;
      expect(route.sourceContext, isNotNull);
      expect(route.sourceBuilder, isNotNull);
      final destination = route.builder(tester.element(find.byType(Scaffold)));
      if (sleep) {
        expect(route.settings.name, SleepRouteNames.day);
        expect(route.settings.arguments, vm.selectedDate);
        expect(destination, isA<SleepDayOverviewPage>());
      } else {
        final pulse = destination as PulseAnalysisScreen;
        expect(pulse.initialDate, vm.selectedDate);
        expect(pulse.initialScope, SleepPeriodScope.day);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
