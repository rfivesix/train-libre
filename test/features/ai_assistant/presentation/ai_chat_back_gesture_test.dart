import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/ai_global_cloud_presentation.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets(
      'predictive back follows, cancels, and dismisses chat without popping its route',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final cloudKey = GlobalKey<DraggableAiCloudState>();
    bool expanded = false;
    final backNotifications = <bool>[];
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      onNavigationNotification: (notification) {
        backNotifications.add(notification.canHandlePop);
        return true;
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: DraggableAiCloud(
        key: cloudKey,
        navigatorKey: navigatorKey,
        semanticLabel: 'AI cloud',
        semanticHint: 'Open',
        liveliness: 0.3,
        onExpandedChanged: (value) => expanded = value,
      )),
    ));
    AiGlobalCloudPresentation.requestOpenChat();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(expanded, isTrue);
    final field = find.byType(TextField);
    final fullWidth = tester.getRect(field).width;
    Future<void> send(String method, [double? progress]) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(MethodCall(
          method,
          progress == null
              ? null
              : {
                  'touchOffset': <double>[10, 200],
                  'progress': progress,
                  'swipeEdge': 0,
                },
        )),
        (_) {},
      );
      await tester.pump();
    }

    expect(backNotifications.last, isTrue);
    await send('startBackGesture', 0);
    await send('updateBackGestureProgress', 0.6);
    final draggedWidth = tester.getRect(field).width;
    expect(draggedWidth, lessThan(fullWidth));
    await send('cancelBackGesture');
    await tester.pump(const Duration(milliseconds: 600));
    expect(expanded, isTrue);
    expect(tester.getRect(field).width, greaterThan(draggedWidth));
    await send('startBackGesture', 0);
    await send('updateBackGestureProgress', 0.4);
    await send('commitBackGesture');
    await tester.pump(const Duration(milliseconds: 600));
    expect(expanded, isFalse);
    expect(backNotifications.last, isFalse);
    expect(navigatorKey.currentState!.canPop(), isFalse);

    AiGlobalCloudPresentation.requestOpenChat();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(await navigatorKey.currentState!.maybePop(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(expanded, isFalse);
    expect(navigatorKey.currentState!.canPop(), isFalse);
  });
}
