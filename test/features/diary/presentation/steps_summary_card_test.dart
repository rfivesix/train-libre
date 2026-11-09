import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/diary/presentation/diary_view_model.dart';
import 'package:train_libre/features/diary/presentation/widgets/steps_summary_card.dart';
import 'package:train_libre/features/steps/domain/steps_models.dart';
import 'package:train_libre/features/steps/presentation/steps_module_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

class _DiaryStub extends ChangeNotifier implements DiaryViewModel {
  _DiaryStub(this.steps, {this.loading = false});
  final int? steps;
  final bool loading;
  @override
  DateTime get selectedDate => DateTime(2026, 10, 3);
  @override
  bool get isStepsWidgetLoading => loading;
  @override
  int? get stepsForSelectedDay => steps;
  @override
  int get targetSteps => 10000;
  @override
  bool get hasDataForSelectedDate => true;
  @override
  bool get isSelectedDateToday => false;
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
  for (final steps in <int?>[null, 0, 12881]) {
    testWidgets('steps card displays $steps and opens the selected day',
        (tester) async {
      final vm = _DiaryStub(steps);
      final observer = _Observer();
      addTearDown(vm.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<DiaryViewModel>.value(
        value: vm,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [observer],
          home: const Scaffold(body: StepsSummaryCard()),
        ),
      ));
      expect(find.byType(SummaryCard), findsOneWidget);
      expect(
          find.text(steps == null
              ? 'No step data yet'
              : '${steps == 0 ? '0' : '12,881'} / 10,000'),
          findsOneWidget);
      await tester.tap(find.text('Steps'));
      final route = observer.route! as CardMorphRoute<void>;
      final destination = route.builder(tester.element(find.byType(Scaffold)))
          as StepsModuleScreen;
      expect(destination.initialDate, vm.selectedDate);
      expect(destination.initialScope, StepsScope.day);
      expect(route.sourceBuilder, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('steps card reports loading without hiding prior counts',
      (tester) async {
    final vm = _DiaryStub(null, loading: true);
    addTearDown(vm.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<DiaryViewModel>.value(
      value: vm,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: StepsSummaryCard()),
      ),
    ));
    expect(find.text('Syncing steps...'), findsOneWidget);

    final existing = _DiaryStub(2450, loading: true);
    addTearDown(existing.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<DiaryViewModel>.value(
      value: existing,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: StepsSummaryCard()),
      ),
    ));
    expect(find.text('2,450 / 10,000'), findsOneWidget);
  });
}
