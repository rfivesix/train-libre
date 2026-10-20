import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/widgets/common/time_range_filter.dart';

void main() {
  testWidgets('TimeRangeFilter scales height cleanly under Dynamic Type XXL without clipping',
      (tester) async {
    tester.view.physicalSize = const Size(375, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 200),
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(
            body: TimeRangeFilter(
              ranges: const ['Tag', 'Woche', 'Monat', 'Jahr'],
              selectedIndex: 0,
              onSelected: (_) {},
              showDateNavigation: true,
              displayDate: '14. Okt.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TimeRangeFilter), findsOneWidget);
  });
}
