import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/ai_global_cloud_visibility.dart';
import 'package:train_libre/features/ai_assistant/presentation/ai_global_cloud_presentation.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import 'package:train_libre/features/diary/presentation/ai_meal_review_reveal_route.dart';
import 'package:train_libre/widgets/common/platform_adaptive_pickers.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('visibility leases overlap and release idempotently', () {
    expect(AiGlobalCloudVisibility.isVisible, isTrue);

    final scannerLease = AiGlobalCloudVisibility.suppress();
    final reviewLease = AiGlobalCloudVisibility.suppress();
    expect(AiGlobalCloudVisibility.suppressionCount.value, 2);
    expect(AiGlobalCloudVisibility.isVisible, isFalse);

    scannerLease.dispose();
    scannerLease.dispose();
    expect(AiGlobalCloudVisibility.suppressionCount.value, 1);
    expect(AiGlobalCloudVisibility.isVisible, isFalse);

    reviewLease.dispose();
    expect(AiGlobalCloudVisibility.isVisible, isTrue);
  });

  testWidgets('visibility changes from widget lifecycle notify after build',
      (tester) async {
    final baseline = AiGlobalCloudVisibility.suppressionCount.value;
    await tester.pumpWidget(
      const MaterialApp(home: _AcquireVisibilityLeaseOnMount()),
    );
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(AiGlobalCloudVisibility.suppressionCount.value, baseline + 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(AiGlobalCloudVisibility.suppressionCount.value, baseline);
  });

  testWidgets('reveal route releases transferred startup visibility lease',
      (tester) async {
    final startupLease = AiGlobalCloudVisibility.suppress();
    var entryCompleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement<void, void>(
                AiMealReviewRevealRoute<void>(
                  duration: const Duration(milliseconds: 100),
                  onEnterComplete: () {
                    entryCompleted = true;
                    startupLease.dispose();
                  },
                  builder: (_) => const Scaffold(body: Text('Ready')),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(AiGlobalCloudVisibility.isVisible, isFalse);
    await tester.pump(const Duration(milliseconds: 120));
    expect(entryCompleted, isTrue);
    expect(AiGlobalCloudVisibility.isVisible, isTrue);
  });

  testWidgets('adaptive date picker releases cloud suppression when dismissed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await showAdaptiveDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 10, 25),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                },
                child: const Text('Open date picker'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(AiGlobalCloudVisibility.isVisible, isTrue);
    await tester.tap(find.text('Open date picker'));
    await tester.pumpAndSettle();
    expect(AiGlobalCloudVisibility.isVisible, isFalse);

    await tester.tapAt(const Offset(8, 120));
    await tester.pumpAndSettle();
    expect(AiGlobalCloudVisibility.isVisible, isTrue);
  });

  testWidgets('cloud slides off and returns on its docked side without reset',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final visibility = ValueNotifier(true);
    addTearDown(visibility.dispose);
    const cloudKey = ValueKey('global-ai-cloud');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visibility,
            builder: (context, isVisible, _) => SizedBox.expand(
              child: DraggableAiCloud(
                key: cloudKey,
                semanticLabel: 'AI cloud',
                semanticHint: 'Open assistant',
                liveliness: 0.3,
                isGloballyVisible: isVisible,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 420));
    final cloudState =
        tester.state<DraggableAiCloudState>(find.byKey(cloudKey));

    // Move the cloud to the opposite edge, then confirm hiding follows the
    // current docking side instead of a fixed default direction.
    var orbBox = tester.renderObject<RenderBox>(
      find.byType(AiNeuralCloudOrbWidget).first,
    );
    var orbPosition = orbBox.localToGlobal(Offset.zero);
    expect(orbPosition.dx, -96.0);
    await tester.timedDragFrom(
      Offset(15, orbPosition.dy + 80),
      const Offset(300, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pump(const Duration(milliseconds: 500));
    orbBox = tester.renderObject<RenderBox>(
      find.byType(AiNeuralCloudOrbWidget).first,
    );
    orbPosition = orbBox.localToGlobal(Offset.zero);
    expect(orbPosition.dx, greaterThan(100));
    final dockedPosition = orbPosition.dx;

    visibility.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    orbPosition = tester
        .renderObject<RenderBox>(find.byType(AiNeuralCloudOrbWidget).first)
        .localToGlobal(Offset.zero);
    expect(orbPosition.dx, greaterThan(400));
    expect(find.bySemanticsLabel('AI cloud').hitTestable(), findsNothing);

    visibility.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    orbPosition = tester
        .renderObject<RenderBox>(find.byType(AiNeuralCloudOrbWidget).first)
        .localToGlobal(Offset.zero);
    expect(orbPosition.dx, closeTo(dockedPosition, 1));
    expect(tester.state<DraggableAiCloudState>(find.byKey(cloudKey)),
        same(cloudState));

    // The assistant's expanded state remains open across another temporary
    // hide and reveal.
    await tester.tapAt(Offset(orbPosition.dx + 80, orbPosition.dy + 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(TextField).hitTestable(), findsOneWidget);

    visibility.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TextField).hitTestable(), findsNothing);

    visibility.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.state<DraggableAiCloudState>(find.byKey(cloudKey)),
        same(cloudState));
  });

  testWidgets('quick chat only captures taps on the visible cloud',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      AiGlobalCloudPresentation.isAddMenuOpen.value = false;
      AiGlobalCloudPresentation.quickChatActionCenter.value = null;
      AiGlobalCloudPresentation.onQuickChatTap = null;
    });

    var backgroundTaps = 0;
    var cloudTaps = 0;
    AiGlobalCloudPresentation.onQuickChatTap = () => cloudTaps++;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => backgroundTaps++,
            ),
          ),
          const DraggableAiCloud(
              semanticLabel: 'AI cloud', semanticHint: '', liveliness: 0.3),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 500));

    AiGlobalCloudPresentation.quickChatActionCenter.value =
        const Offset(320, 400);
    AiGlobalCloudPresentation.isAddMenuOpen.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tapAt(const Offset(380, 460));
    expect(backgroundTaps, 1);
    expect(cloudTaps, 0);
    await tester.tapAt(const Offset(320, 400));
    expect(cloudTaps, 1);
  });
}

class _AcquireVisibilityLeaseOnMount extends StatefulWidget {
  const _AcquireVisibilityLeaseOnMount();

  @override
  State<_AcquireVisibilityLeaseOnMount> createState() =>
      _AcquireVisibilityLeaseOnMountState();
}

class _AcquireVisibilityLeaseOnMountState
    extends State<_AcquireVisibilityLeaseOnMount> {
  late final AiGlobalCloudVisibilityLease _lease;

  @override
  void initState() {
    super.initState();
    _lease = AiGlobalCloudVisibility.suppress();
  }

  @override
  void dispose() {
    _lease.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
