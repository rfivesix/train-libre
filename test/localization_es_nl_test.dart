import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  test('Spanish and Dutch locales load for regional device locales', () async {
    expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('nl')));
    expect(
      AppLocalizations.delegate.isSupported(const Locale('es', 'MX')),
      isTrue,
    );
    expect(
      AppLocalizations.delegate.isSupported(const Locale('nl', 'BE')),
      isTrue,
    );

    final spanish = await AppLocalizations.delegate.load(
      const Locale('es', 'MX'),
    );
    final dutch = await AppLocalizations.delegate.load(
      const Locale('nl', 'BE'),
    );

    expect(spanish.settingsBaseFoodLanguageSpanish, 'Español');
    expect(dutch.settingsBaseFoodLanguageDutch, 'Nederlands');
  });
}
