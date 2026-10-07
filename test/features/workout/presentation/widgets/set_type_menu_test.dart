import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/set_type_menu.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  Widget buildTestableWidget({
    required String currentSetType,
    required ValueChanged<String> onSetTypeChanged,
    bool enabled = true,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Center(
          child: SetTypeMenu(
            currentSetType: currentSetType,
            enabled: enabled,
            onSetTypeChanged: onSetTypeChanged,
            child: const Text('1'),
          ),
        ),
      ),
    );
  }

  testWidgets('SetTypeMenu renders trigger child', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        currentSetType: 'normal',
        onSetTypeChanged: (_) {},
      ),
    );

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Tapping SetTypeMenu opens dropdown with set types and info item', (tester) async {
    String? selected;
    await tester.pumpWidget(
      buildTestableWidget(
        currentSetType: 'normal',
        onSetTypeChanged: (type) => selected = type,
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Warmup'), findsOneWidget);
    expect(find.text('Failure'), findsOneWidget);
    expect(find.text('Dropset'), findsOneWidget);
    expect(find.text('Info & Explanations'), findsOneWidget);

    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();

    expect(selected, 'warmup');
  });

  testWidgets('Tapping Info & Explanations opens explanation-rich bottom sheet', (tester) async {
    String? selected;
    await tester.pumpWidget(
      buildTestableWidget(
        currentSetType: 'normal',
        onSetTypeChanged: (type) => selected = type,
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info & Explanations'));
    await tester.pumpAndSettle();

    // The explanation rich sheet has the title "Change set type"
    expect(find.text('Change set type'), findsOneWidget);
    // And explanation subtitles
    expect(
      find.text('A regular working set. After warming up, the first is usually your heavy focus set; it counts towards progression.'),
      findsOneWidget,
    );

    // Tapping Dropset in the bottom sheet calls onSetTypeChanged
    await tester.tap(find.text('Dropset'));
    await tester.pumpAndSettle();

    expect(selected, 'dropset');
  });

  testWidgets('Disabled SetTypeMenu does not open dropdown on tap', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        currentSetType: 'normal',
        enabled: false,
        onSetTypeChanged: (_) {},
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Normal'), findsNothing);
    expect(find.text('Info & Explanations'), findsNothing);
  });
}
