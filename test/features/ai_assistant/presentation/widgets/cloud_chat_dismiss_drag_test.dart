import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_chat_dismiss_drag.dart';

void main() {
  testWidgets('downward drag hands off at the top; history scrolls elsewhere',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var starts = 0;
    var distance = 0.0;
    var ends = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CloudChatDismissDrag(
      scrollController: scroll,
      onStart: (_) => starts++,
      onUpdate: (details) => distance += details.delta.dy,
      onEnd: (_) => ends++,
      onCancel: () {},
      child: ListView.builder(
        controller: scroll,
        itemCount: 40,
        itemBuilder: (_, i) => SizedBox(height: 80, child: Text('Item $i')),
      ),
    ))));
    scroll.jumpTo(700);
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(starts, 0);
    expect(scroll.offset, lessThan(700));
    scroll.jumpTo(0);
    await tester.drag(find.byType(ListView), const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(distance, greaterThan(100));
    expect(ends, 1);
  });

  testWidgets(
      'empty chat supports dismissal without a scroll controller client',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CloudChatDismissDrag(
      scrollController: scroll,
      onStart: (_) => starts++,
      onUpdate: (_) {},
      onEnd: (_) {},
      onCancel: () {},
      child: const SizedBox.expand(),
    ))));
    await tester.drag(find.byType(CloudChatDismissDrag), const Offset(0, 130));
    expect(starts, 1);
  });

  testWidgets('horizontal drags do not dismiss chat', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CloudChatDismissDrag(
      scrollController: scroll,
      onStart: (_) => starts++,
      onUpdate: (_) {},
      onEnd: (_) {},
      onCancel: () {},
      child: const SizedBox.expand(),
    ))));
    await tester.drag(find.byType(CloudChatDismissDrag), const Offset(150, 25));
    expect(starts, 0);
  });
}
