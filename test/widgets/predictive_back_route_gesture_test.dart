import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';

void main() {
  testWidgets(
      'Android back channel drives and cancels a card morph, then commits',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final route = CardMorphRoute<void>(
      sourceRect: const Rect.fromLTWH(20, 500, 100, 80),
      builder: (_) => const Scaffold(body: Text('detail')),
    );
    await tester.pumpWidget(MaterialApp(
        navigatorKey: key, home: const Scaffold(body: Text('home'))));
    key.currentState!.push(route);
    await tester.pumpAndSettle();

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
                  })),
        (_) {},
      );
      await tester.pump();
    }

    await send('startBackGesture', 0);
    await send('updateBackGestureProgress', 0.5);
    expect(route.animation!.value, closeTo(0.5, 0.001));
    await send('cancelBackGesture');
    await tester.pumpAndSettle();
    expect(route.animation!.value, 1);
    expect(route.isCurrent, isTrue);
    await send('startBackGesture', 0);
    await send('updateBackGestureProgress', 0.4);
    await send('commitBackGesture');
    expect(route.animation!.value, lessThan(0.7));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('detail'), findsNothing);
  });
}
