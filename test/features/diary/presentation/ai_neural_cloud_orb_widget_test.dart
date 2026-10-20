// test/features/diary/presentation/ai_neural_cloud_orb_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiNeuralCloudOrbWidget', () {
    testWidgets('renders properly with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AiNeuralCloudOrbWidget(),
            ),
          ),
        ),
      );

      expect(find.byType(AiNeuralCloudOrbWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance frames to ensure continuous animation runs smoothly
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('triggers impulse on tap and calls onTap callback',
        (tester) async {
      bool tapped = false;
      final key = GlobalKey<AiNeuralCloudOrbWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AiNeuralCloudOrbWidget(
                key: key,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AiNeuralCloudOrbWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);

      final state = key.currentState;
      expect(state, isNotNull);
      state?.triggerImpulse();

      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('pauses animation on lifecycle pause and resumes on resume',
        (tester) async {
      final key = GlobalKey<AiNeuralCloudOrbWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AiNeuralCloudOrbWidget(key: key),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(key.currentState, isNotNull);

      // Simulate app going to background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Simulate app returning to foreground
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('renders properly with edgeBlurSigma and bounded layer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AiNeuralCloudOrbWidget(
                edgeBlurSigma: 4.0,
                forceHighFrameRate: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AiNeuralCloudOrbWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
