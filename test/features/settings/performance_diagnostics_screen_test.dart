import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/performance/jank_recorder.dart';
import 'package:train_libre/features/settings/presentation/performance_diagnostics_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';

FrameTiming _frame({required int buildMs, required int rasterMs}) {
  final int buildFinish = buildMs * 1000;
  final int rasterFinish = buildFinish + rasterMs * 1000;
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildFinish,
    rasterStart: buildFinish,
    rasterFinish: rasterFinish,
    rasterFinishWallTime: rasterFinish,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  late JankRecorder recorder;
  final List<MethodCall> clipboardCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    clipboardCalls.clear();
    recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardCalls.add(call);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('lists the screens that dropped frames', (tester) async {
    recorder.setScreen('AiMealCaptureScreen');
    recorder.handleTimings([
      _frame(buildMs: 2, rasterMs: 2),
      _frame(buildMs: 6, rasterMs: 60),
    ]);

    await tester.pumpWidget(
      _wrap(PerformanceDiagnosticsScreen(
        recorder: recorder,
        deviceLabelLoader: () async => 'iPhone (iPhone14,4)',
      )),
    );
    await tester.pump();

    expect(find.text('AiMealCaptureScreen'), findsOneWidget);
    expect(find.textContaining('cause raster'), findsOneWidget);
    expect(find.textContaining('60 Hz'), findsOneWidget);
  });

  testWidgets('copies the log as plain text', (tester) async {
    recorder.setScreen('DiaryTab');
    recorder.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);

    await tester.pumpWidget(
      _wrap(PerformanceDiagnosticsScreen(
        recorder: recorder,
        deviceLabelLoader: () async => 'iPhone (iPhone14,4)',
      )),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('performance_diagnostics_copy_button')),
    );
    await tester.pump();

    expect(clipboardCalls, hasLength(1));
    final copied = (clipboardCalls.single.arguments as Map)['text'] as String;
    expect(copied, contains('performance log'));
    expect(copied, contains('device: iPhone (iPhone14,4)'));
    expect(copied, contains('screen[DiaryTab]:'));
    expect(copied, contains('frame_budget_ms: 16.7'));
  });

  testWidgets('reset asks for confirmation before clearing', (tester) async {
    recorder.setScreen('DiaryTab');
    recorder.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);

    await tester.pumpWidget(
      _wrap(PerformanceDiagnosticsScreen(
        recorder: recorder,
        deviceLabelLoader: () async => 'iPhone (iPhone14,4)',
      )),
    );
    await tester.pump();
    expect(find.text('DiaryTab'), findsOneWidget);

    // The screen grew past one viewport, so the tile is not built until the
    // list is scrolled to it — ensureVisible alone needs an element that
    // already exists.
    final resetTile =
        find.byKey(const Key('performance_diagnostics_reset_tile'));
    await tester.scrollUntilVisible(
      resetTile,
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('performance_diagnostics_scroll_view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    await tester.tap(resetTile);
    await tester.pumpAndSettle();

    // Wiping the measurements is not undoable, so it goes through the same
    // confirmation sheet the other destructive settings use.
    expect(find.text('DiaryTab'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('performance_diagnostics_reset_confirm')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DiaryTab'), findsNothing);
    expect(find.text('Noch keine Frames erfasst.'), findsOneWidget);
  });
}
