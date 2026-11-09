import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';

void main() {
  testWidgets(
      'morph keeps an opaque color-changing surface and varies its corners',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    const cardColor = Color(0xFFFFFFFF);
    const pageColor = Color(0xFF808080);
    final route = CardMorphRoute<void>(
      sourceRect: const Rect.fromLTWH(40, 500, 200, 100),
      sourceBorderRadius: 12,
      sourceBuilder: (_) => const ColoredBox(color: cardColor),
      builder: (_) => const Scaffold(body: Text('detail')),
    );
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
          platform: TargetPlatform.iOS,
          cardColor: cardColor,
          scaffoldBackgroundColor: pageColor),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(viewPadding: const EdgeInsets.only(top: 62, bottom: 34)),
        child: child!,
      ),
      home: const Scaffold(body: Text('home')),
    ));
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    route.handleDragStart();
    route.handleDragUpdate(0.5);
    await tester.pump();
    RRect shape() {
      final clips = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
      final clip = clips.firstWhere((clip) => clip.clipper != null);
      return clip.clipper!.getClip(tester.getSize(find.byType(MaterialApp)));
    }

    final largerRadius = shape().tlRadius.x;
    expect(largerRadius, greaterThan(12));
    expect(largerRadius, lessThan(58.9));
    expect(largerRadius, greaterThan(44));
    final surface = tester
        .widget<ColoredBox>(find.byKey(const ValueKey('cardMorphSurface')));
    expect(surface.color.a, 1);
    expect(surface.color, pageColor);

    route.handleDragUpdate(0.4);
    await tester.pump();
    final smallerRadius = shape().tlRadius.x;
    expect(smallerRadius, greaterThan(12));
    expect(smallerRadius, lessThan(largerRadius));
    final transitioning = tester
        .widget<ColoredBox>(find.byKey(const ValueKey('cardMorphSurface')))
        .color;
    expect(transitioning.a, 1);
    expect(transitioning, isNot(pageColor));
    expect(transitioning, isNot(cardColor));
    // At the landing, the source copy owns the visible card; its transparent
    // margins must not be filled by the temporary surface.
    route.handleDragUpdate(0.099);
    await tester.pump();
    final landing = tester
        .widget<ColoredBox>(find.byKey(const ValueKey('cardMorphSurface')))
        .color;
    expect(landing.a, lessThan(0.05));
    route.handleDragEnd(shouldPop: false);
    await tester.pumpAndSettle();
  });
}
