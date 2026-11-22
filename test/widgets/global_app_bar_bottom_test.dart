import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/global_app_bar.dart';

void main() {
  testWidgets('app bar bottom receives taps and horizontal drags', (
    tester,
  ) async {
    var taps = 0;
    var drags = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlobalAppBar(
            title: 'Statistics',
            bottom: GestureDetector(
              onTap: () => taps++,
              onHorizontalDragUpdate: (_) => drags++,
              child: const SizedBox.expand(child: Text('Date filters')),
            ),
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('Date filters'), findsOneWidget);
    await tester.tap(find.text('Date filters'));
    expect(taps, 1);
    await tester.drag(find.text('Date filters'), const Offset(-80, 0));
    expect(drags, greaterThan(0));
  });

  testWidgets(
    'GlobalAppBar renders top-to-bottom ProgressiveBlur fade without bottom glass rim',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            extendBodyBehindAppBar: true,
            appBar: GlobalAppBar(title: 'Statistiken'),
            body: SizedBox.expand(),
          ),
        ),
      );

      final blurFinder = find.descendant(
        of: find.byType(GlobalAppBar),
        matching: find.byType(ProgressiveBlur),
      );
      expect(blurFinder, findsOneWidget);
      final progressiveBlur = tester.widget<ProgressiveBlur>(blurFinder);
      expect(progressiveBlur.direction, ProgressiveBlurDirection.topToBottom);
      expect(progressiveBlur.maxSigma, greaterThan(0));

      final glassFinder = find.descendant(
        of: find.byType(GlobalAppBar),
        matching: find.byType(GlassContainer),
      );
      expect(glassFinder, findsNothing);

      final appBarRect = tester.getRect(find.byType(GlobalAppBar));
      final blurRect = tester.getRect(blurFinder);
      expect(blurRect.top, closeTo(appBarRect.top, 0.001));
      expect(blurRect.left, closeTo(appBarRect.left, 0.001));
      expect(blurRect.right, closeTo(appBarRect.right, 0.001));
      expect(blurRect.bottom, closeTo(appBarRect.bottom + 8.0, 0.001));
    },
  );
}
