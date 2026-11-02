import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/navigation/push_route_and_wait.dart';

void main() {
  testWidgets(
    'waits for a child route reverse transition before cascading parent pop',
    (tester) async {
      var homeTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Diary'),
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              body: Builder(
                                builder: (context) => TextButton(
                                  onPressed: () async {
                                    final result =
                                        await pushRouteAndWaitForCompletion<
                                            bool>(
                                      context,
                                      MaterialPageRoute<bool>(
                                        builder: (_) => Scaffold(
                                          body: Center(
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Save scan'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text('Open scan'),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Add'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => homeTaps++,
                    child: const Text('Diary action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save scan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The Add route must stay in place while the scan's reverse transition
      // owns the Navigator overlay; it is popped only after route.completed.
      expect(find.text('Open scan'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Diary'), findsOneWidget);
      await tester.tap(find.text('Diary action'));
      expect(homeTaps, 1);
    },
  );
}
