import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/app/presentation/legal_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legal screen accordions expand with animation on tap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const LegalScreen()));
    await tester.pumpAndSettle();

    // Section 1. Verantwortlicher header
    final header = find.text('1. Verantwortlicher');
    expect(header, findsOneWidget);

    final sizeTransitionFinder = find.byType(SizeTransition).first;

    // SizeTransition height should be 0 before tap (collapsed)
    expect(tester.getSize(sizeTransitionFinder).height, equals(0.0));

    // Tap header to expand
    await tester.tap(header);
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 140)); // Mid animation

    // Height should be partially expanded
    expect(tester.getSize(sizeTransitionFinder).height, greaterThan(0.0));

    await tester.pumpAndSettle(); // End animation

    // Height should now be fully expanded
    expect(tester.getSize(sizeTransitionFinder).height, greaterThan(100.0));

    // RotationTransition should be rotated
    final rotation = tester.widget<RotationTransition>(find.byType(RotationTransition).first);
    expect(rotation.turns.value, equals(0.5));

    // SizeTransition should be vertical
    final sizeTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(sizeTransition.axis, equals(Axis.vertical));
    expect(sizeTransition.alignment, equals(Alignment.topCenter));
    expect(sizeTransition.sizeFactor.value, equals(1.0));

    // Tap header again to collapse
    await tester.tap(header);
    await tester.pumpAndSettle();

    // Height should be 0 after collapse
    expect(tester.getSize(sizeTransitionFinder).height, equals(0.0));
  });
}
