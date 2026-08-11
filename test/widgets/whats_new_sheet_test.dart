import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/whats_new/data/whats_new_service.dart';
import 'package:train_libre/features/whats_new/domain/whats_new_release.dart';
import 'package:train_libre/features/whats_new/presentation/whats_new_sheet.dart';
import 'package:train_libre/generated/app_localizations.dart';

WhatsNewRelease _release(String version, List<String> titles) =>
    WhatsNewRelease(
      version: version,
      releasedOn: '2026-08-11',
      entries: [
        for (final title in titles)
          WhatsNewEntry(
            icon: Icons.star,
            title: title,
            body: 'Body of $title',
          ),
      ],
    );

Widget _host(void Function(BuildContext) onReady) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => onReady(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final service = WhatsNewService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service.resetForTesting();
    service.alwaysShow = false;
    service.versionLoaderOverride = () async => '1.0.3';
  });

  tearDown(service.resetForTesting);

  testWidgets('renders every entry of every pending release', (tester) async {
    await tester.pumpWidget(_host((context) {
      showWhatsNewSheet(
        context,
        [
          _release('1.0.3', ['Widgets', 'Live Activity']),
          _release('1.0.2', ['Faster imports']),
        ],
        markSeen: false,
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Widgets'), findsOneWidget);
    expect(find.text('Live Activity'), findsOneWidget);
    expect(find.text('Faster imports'), findsOneWidget);
    expect(find.text('Body of Widgets'), findsOneWidget);

    // Multiple releases get a per-version header.
    expect(find.textContaining('1.0.3'), findsWidgets);
    expect(find.textContaining('1.0.2'), findsWidgets);
  });

  testWidgets('a single release shows its version in the subtitle line',
      (tester) async {
    await tester.pumpWidget(_host((context) {
      showWhatsNewSheet(
        context,
        [
          _release('1.0.3', ['Widgets'])
        ],
        markSeen: false,
      );
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1.0.3'), findsOneWidget);
  });

  testWidgets('the CTA closes the sheet and records the version',
      (tester) async {
    await tester.pumpWidget(_host((context) {
      showWhatsNewSheet(context, [
        _release('1.0.3', ['Widgets'])
      ]);
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.whatsNewCta));
    await tester.pumpAndSettle();

    expect(find.text('Widgets'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(WhatsNewService.lastSeenVersionKey), '1.0.3');
  });

  testWidgets('dismissing without the CTA still records the version',
      (tester) async {
    await tester.pumpWidget(_host((context) {
      showWhatsNewSheet(context, [
        _release('1.0.3', ['Widgets'])
      ]);
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the modal barrier.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(WhatsNewService.lastSeenVersionKey), '1.0.3');
  });

  testWidgets('an empty release list shows nothing at all', (tester) async {
    await tester.pumpWidget(_host((context) {
      showWhatsNewSheet(context, const []);
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
  });
}
