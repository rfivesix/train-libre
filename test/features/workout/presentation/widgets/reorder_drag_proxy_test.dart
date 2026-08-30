import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/reorder_drag_proxy.dart';
import 'package:train_libre/theme/app_colors.dart';

/// Mirrors the workout cards: transparent by design, so a row only ever shows
/// the background it sits on. In the drag overlay there is no such background —
/// the proxy has to bring its own.
class _TransparentCard extends StatelessWidget {
  const _TransparentCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72.0,
      alignment: Alignment.centerLeft,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(label),
    );
  }
}

ThemeData _theme(Brightness brightness, {Color? cardSurface}) {
  final ThemeData base = ThemeData(
    useMaterial3: false,
    brightness: brightness,
    scaffoldBackgroundColor:
        brightness == Brightness.dark ? Colors.black : Colors.white,
  );
  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      if (cardSurface != null) AppSurfaces(summaryCard: cardSurface),
    ],
  );
}

/// The [Material] the proxy puts directly around the dragged row.
Material _proxyMaterialAround(WidgetTester tester, Finder content) {
  return tester.widget<Material>(
    find.ancestor(of: content, matching: find.byType(Material)).first,
  );
}

void main() {
  group('buildReorderDragProxy', () {
    testWidgets('hands the row widget through instead of rebuilding it',
        (tester) async {
      const Widget row = _TransparentCard(label: 'Bankdrücken');

      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(Brightness.light, cardSurface: Colors.white),
          home: Scaffold(
            body: Builder(
              builder: (context) => buildReorderDragProxy(
                context,
                row,
                kAlwaysCompleteAnimation,
              ),
            ),
          ),
        ),
      );

      // Identity, not just "something that looks similar": the exact widget
      // instance passed in has to end up on screen.
      expect(find.byWidget(row), findsOneWidget);
      expect(find.text('Bankdrücken'), findsOneWidget);
    });

    testWidgets('gives the proxy an opaque surface in light and dark theme',
        (tester) async {
      const List<(Brightness, Color)> cases = <(Brightness, Color)>[
        (Brightness.light, Colors.white),
        (Brightness.dark, Color(0xFF1C1C1E)),
      ];

      for (final (Brightness brightness, Color card) in cases) {
        await tester.pumpWidget(
          MaterialApp(
            theme: _theme(brightness, cardSurface: card),
            home: Scaffold(
              body: Builder(
                builder: (context) => buildReorderDragProxy(
                  context,
                  const _TransparentCard(label: 'Kniebeuge'),
                  kAlwaysCompleteAnimation,
                ),
              ),
            ),
          ),
        );

        // MaterialApp cross-fades between themes, so let the switch land
        // before reading the colour.
        await tester.pumpAndSettle();

        final Material material =
            _proxyMaterialAround(tester, find.text('Kniebeuge'));
        expect(material.color, isNotNull);
        expect(material.color!.a, 1.0,
            reason: 'a see-through proxy is invisible in the drag overlay');
        expect(material.color, card);
        expect(material.elevation, greaterThan(0.0));
      }
    });

    testWidgets('surface stays opaque without the AppSurfaces extension',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(Brightness.dark),
          home: Scaffold(
            body: Builder(
              builder: (context) => buildReorderDragProxy(
                context,
                const _TransparentCard(label: 'Klimmzug'),
                kAlwaysCompleteAnimation,
              ),
            ),
          ),
        ),
      );

      final Material material =
          _proxyMaterialAround(tester, find.text('Klimmzug'));
      expect(material.color!.a, 1.0);
    });

    testWidgets('stays flat while the lift animation has not started yet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(Brightness.light, cardSurface: Colors.white),
          home: Scaffold(
            body: Builder(
              builder: (context) => buildReorderDragProxy(
                context,
                const _TransparentCard(label: 'Rudern'),
                kAlwaysDismissedAnimation,
              ),
            ),
          ),
        ),
      );

      final Material material =
          _proxyMaterialAround(tester, find.text('Rudern'));
      expect(material.elevation, 0.0);
      expect(material.color!.a, 1.0);
    });

    test('a translucent card colour is composited onto the background', () {
      final ThemeData theme = _theme(
        Brightness.light,
        cardSurface: const Color(0x80000000),
      );

      final Color surface = reorderDragProxySurfaceColor(theme);

      expect(surface.a, 1.0);
      expect(surface, isNot(const Color(0x80000000)));
    });
  });

  group('drag overlay', () {
    /// A list wired up like the live workout screen: no default drag handles,
    /// transparent rows, and [buildReorderDragProxy] as the proxy decorator.
    Widget listUnderTest() {
      return MaterialApp(
        theme: _theme(Brightness.light, cardSurface: Colors.white),
        home: Scaffold(
          body: Builder(
            builder: (context) => ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: 4,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) =>
                      buildReorderDragProxy(context, child, animation),
              onReorderItem: (_, __) {},
              itemBuilder: (context, index) => ReorderableDragStartListener(
                key: ValueKey<int>(index),
                index: index,
                child: _TransparentCard(label: 'Übung $index'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'the lifted proxy carries the row itself, opaque and centred on the '
        'finger', (tester) async {
      await tester.pumpWidget(listUnderTest());

      /// The row that gets dragged, wherever it currently lives — in the list
      /// before the drag, in the overlay during it.
      final Finder draggedCard = find.ancestor(
        of: find.text('Übung 1'),
        matching: find.byType(_TransparentCard),
      );

      final Offset centreBefore = tester.getCenter(draggedCard);
      final Size sizeBefore = tester.getSize(draggedCard);

      final TestGesture gesture = await tester.startGesture(centreBefore);
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(0.0, 100.0));
      await tester.pumpAndSettle();

      // The row left the list (which now renders a placeholder) and exists
      // exactly once: in the drag overlay.
      expect(draggedCard, findsOneWidget);
      expect(find.byType(_TransparentCard), findsNWidgets(4));

      // Same content, same metrics as the row it was dragged out of — a proxy
      // rebuilt from scratch cannot guarantee that.
      expect(
        tester.getSize(draggedCard),
        sizeBefore,
        reason: 'different metrics make the proxy drift away from the finger',
      );

      // The lift scales around the centre, so the centre follows the finger.
      final Offset centreDuring = tester.getCenter(draggedCard);
      expect(centreDuring.dy,
          moreOrLessEquals(centreBefore.dy + 100.0, epsilon: 1.0));
      expect(centreDuring.dx, moreOrLessEquals(centreBefore.dx, epsilon: 1.0));

      // And it is painted on something solid.
      final Material material = _proxyMaterialAround(tester, draggedCard);
      expect(material.color!.a, 1.0);
      expect(material.color, Colors.white);
      expect(material.elevation, greaterThan(0.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
