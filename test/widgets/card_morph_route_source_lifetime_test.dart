// The flight has to survive the screen underneath rebuilding itself away.
//
// A `sourceBuilder` closes over the screen it came from. Screens that hold
// their content in a FutureBuilder and reload on the push future put a spinner
// in place of that whole subtree — and the push future completes when the pop
// starts, not when the collapse lands. So for most of the collapse the source's
// elements are deactivated, and a builder called again at that point would
// throw "Looking up a deactivated widget's ancestor is unsafe" on every frame.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/card_morph_route.dart';

/// A screen shaped like the nutrition hub: content behind a FutureBuilder,
/// reloaded the moment the pushed route pops.
class _ReloadingScreen extends StatefulWidget {
  const _ReloadingScreen();

  @override
  State<_ReloadingScreen> createState() => _ReloadingScreenState();
}

class _ReloadingScreenState extends State<_ReloadingScreen> {
  late Future<String> _data = Future.value('meal');

  /// Never completes, so the FutureBuilder stays in `waiting` and the card's
  /// subtree stays deactivated for the rest of the collapse.
  void _reload() {
    if (!mounted) return;
    setState(() {
      _data = Completer<String>().future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Builder(
              builder: (cardCtx) {
                // Deliberately closes over the card's own context, the way the
                // hub screens' card builders do.
                Widget copy() => SizedBox(
                      width: 100,
                      height: 60,
                      child: ColoredBox(
                        color: Theme.of(cardCtx).colorScheme.surface,
                        child: const Text('card'),
                      ),
                    );

                return GestureDetector(
                  onTap: () {
                    Navigator.of(cardCtx)
                        .push(
                          CardMorphRoute<void>(
                            sourceContext: cardCtx,
                            sourceBuilder: (_) => copy(),
                            builder: (_) => const Scaffold(
                              body: Center(child: Text('detail')),
                            ),
                          ),
                        )
                        .then((_) => _reload());
                  },
                  child: copy(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void main() {
  testWidgets('keeps flying the source copy after the screen below reloads',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ReloadingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('card'), findsOneWidget);

    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    // Pop, then step through the collapse. The reload fires on the first of
    // these frames and takes the card's elements with it.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        tester.takeException(),
        isNull,
        reason: 'frame $i of the collapse threw',
      );
    }

    // No pumpAndSettle from here: the screen's spinner never stops.
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('detail'), findsNothing);
  });
}
