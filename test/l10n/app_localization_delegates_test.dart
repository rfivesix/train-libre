import 'package:cupertino_ui/cupertino_ui.dart' as cupertino_ui;
// Both Material implementations are still used by app dependencies.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/app/presentation/widgets/speed_dial_menu_overlay.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';

void main() {
  testWidgets('German localizations are available to both Material libraries', (
    tester,
  ) async {
    late BuildContext contentContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              contentContext = context;
              return SpeedDialMenuOverlay(
                animation: const AlwaysStoppedAnimation<double>(0),
                actions: const [],
                onClose: () {},
                onActionTap: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      MaterialLocalizations.of(contentContext).closeButtonTooltip,
      'Schließen',
    );
    expect(
      legacy.MaterialLocalizations.of(contentContext).closeButtonTooltip,
      'Schließen',
    );
    expect(cupertino_ui.CupertinoLocalizations.of(contentContext), isNotNull);
    expect(tester.takeException(), isNull);
  });
}
