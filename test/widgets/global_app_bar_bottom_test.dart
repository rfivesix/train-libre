import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/global_app_bar.dart';

void main() {
  testWidgets('app bar bottom receives taps and horizontal drags',
      (tester) async {
    var taps = 0;
    var drags = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(
          title: 'Statistics',
          bottom: GestureDetector(
            onTap: () => taps++,
            onHorizontalDragUpdate: (_) => drags++,
            child: const SizedBox.expand(child: Text('Date filters')),
          ),
        ),
        body: const SizedBox.expand(),
      ),
    ));

    expect(find.text('Date filters'), findsOneWidget);
    await tester.tap(find.text('Date filters'));
    expect(taps, 1);
    await tester.drag(find.text('Date filters'), const Offset(-80, 0));
    expect(drags, greaterThan(0));
  });
}
