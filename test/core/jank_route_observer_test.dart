import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/core/performance/jank_recorder.dart';
import 'package:train_libre/core/performance/jank_route_observer.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home'));
}

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('detail'));
}

void main() {
  late JankRecorder recorder;
  late JankRouteObserver observer;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    recorder = JankRecorder.createForTest();
    observer = JankRouteObserver(recorder: recorder);
    navigatorKey = GlobalKey<NavigatorState>();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [observer],
      home: const HomeShellScreen(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('derives the screen name from the mounted widget',
      (tester) async {
    await pumpApp(tester);

    // The app pushes unnamed MaterialPageRoutes; the label has to come from the
    // widget tree, or none of the ~100 navigation call sites would be usable.
    expect(recorder.currentScreen, 'HomeShellScreen');

    unawaitedPush(navigatorKey, const MealDetailScreen());
    await tester.pumpAndSettle();

    expect(recorder.currentScreen, 'MealDetailScreen');
  });

  testWidgets('restores the previous screen after a pop', (tester) async {
    await pumpApp(tester);

    unawaitedPush(navigatorKey, const MealDetailScreen());
    await tester.pumpAndSettle();
    expect(recorder.currentScreen, 'MealDetailScreen');

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(recorder.currentScreen, 'HomeShellScreen');
  });

  testWidgets('an explicit route name wins over the derived one',
      (tester) async {
    await pumpApp(tester);

    navigatorKey.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'CheckoutFlow'),
      builder: (_) => const MealDetailScreen(),
    ));
    await tester.pumpAndSettle();

    expect(recorder.currentScreen, 'CheckoutFlow');
  });

  testWidgets('a screen can name its own route', (tester) async {
    await pumpApp(tester);

    // A tab shell names its own route from inside it, the way MainScreen does.
    final route = ModalRoute.of(tester.element(find.byType(HomeShellScreen)));
    observer.setLabelForRoute(route, 'DiaryTab');
    await tester.pump();

    expect(recorder.currentScreen, 'DiaryTab');
  });
}

void unawaitedPush(GlobalKey<NavigatorState> key, Widget page) {
  key.currentState!.push(MaterialPageRoute<void>(builder: (_) => page));
}
