import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:train_libre/features/app/presentation/about_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/app_link_row.dart';

/// The credit CC BY-SA 4.0 obliges, on the screen where it is given.
///
/// The catalog moved out of this repository into OpenExerciseDB, under a
/// licence that names what a redistributor has to show: the source with a link
/// back, the licence with a link to it, and the upstream derivation. An About
/// screen that still credits only wger.de is not a stale label, it is the
/// wrong attribution for the data actually shipped.
Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Train Libre',
      packageName: 'de.rfivesix.trainlibre',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpAbout(WidgetTester tester, {Locale? locale}) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(const AboutScreen(), locale: locale ?? const Locale('en')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names OpenExerciseDB as the source of the exercise data',
      (tester) async {
    await pumpAbout(tester);

    expect(find.text('Exercise data from OpenExerciseDB'), findsOneWidget);
    expect(find.text('github.com/rfivesix/OpenExerciseDB'), findsOneWidget);
  });

  testWidgets('names the licence the data is under', (tester) async {
    await pumpAbout(tester);

    expect(find.text('Exercise data licence'), findsOneWidget);
    expect(find.text('CC BY-SA 4.0'), findsOneWidget);
  });

  testWidgets('keeps wger visible as the upstream it derives from',
      (tester) async {
    // Dropping wger would be the easy mistake. The data is derived from it,
    // and per-record upstream authors are still credited downstream, so the
    // credit is owed whether or not the app fetches from wger any more.
    await pumpAbout(tester);

    expect(find.text('Derived in part from wger'), findsOneWidget);
    expect(find.text('wger.de'), findsOneWidget);
  });

  testWidgets('no longer presents wger as the catalog itself', (tester) async {
    await pumpAbout(tester);

    expect(find.text('Exercise data from wger'), findsNothing);
    expect(find.text('wger.de (CC-BY-SA)'), findsNothing);
  });

  testWidgets('all three rows link somewhere', (tester) async {
    await pumpAbout(tester);

    for (final title in const [
      'Exercise data from OpenExerciseDB',
      'Exercise data licence',
      'Derived in part from wger',
    ]) {
      final row = tester.widget<AppLinkRow>(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(AppLinkRow),
        ),
      );
      expect(row.onTap, isNotNull, reason: '$title has no destination');
    }
  });

  testWidgets('the German build carries the same attribution', (tester) async {
    // The credit is a licence obligation, not an English-only nicety.
    await pumpAbout(tester, locale: const Locale('de'));

    expect(find.text('Übungsdaten von OpenExerciseDB'), findsOneWidget);
    expect(find.text('CC BY-SA 4.0'), findsOneWidget);
    expect(find.text('Teilweise abgeleitet von wger'), findsOneWidget);
  });
}
