import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/app/presentation/widgets/glass_bottom_menu.dart';

void main() {
  testWidgets('full-height sheet respects safe area and keyboard', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.viewPadding = FakeViewPadding(top: 44, bottom: 20);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(body: TextButton(
        onPressed: () => showGlassBottomMenu<void>(
          context: context,
          title: 'Sheet',
          expandToFullHeight: true,
          contentBuilder: (_, __) => const SizedBox.expand(key: Key('content')),
        ),
        child: const Text('Open'),
      ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Sheet')).dy, greaterThanOrEqualTo(60));
    final originalHeight = tester.getSize(find.byKey(const Key('content'))).height;
    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final reducedHeight = tester.getSize(find.byKey(const Key('content'))).height;
    expect(originalHeight - reducedHeight, closeTo(300, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long action menus use available height and scroll', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showGlassBottomMenu<void>(
          context: context,
          title: 'Actions',
          actions: List.generate(20, (i) => GlassMenuAction(
            icon: Icons.add, label: 'Item $i', onTap: () {},
          )),
        ),
        child: const Text('Open'),
      ),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(of: find.byType(GlassBottomMenuSheet), matching: find.byType(SingleChildScrollView));
    expect(tester.getSize(scrollable).height, greaterThan(420));
    await tester.drag(scrollable, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded sheet stays inside its host constraints', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(height: 300, child: GlassBottomMenuSheet(
        expandToFullHeight: true,
        contentBuilder: _content,
      )),
    ))));
    expect(tester.getSize(find.byType(GlassBottomMenuSheet)).height, 300);
    expect(tester.takeException(), isNull);
  });
}

Widget _content(BuildContext context, VoidCallback close) => const SizedBox.expand();
