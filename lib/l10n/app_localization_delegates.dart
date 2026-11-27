import 'package:cupertino_ui/cupertino_ui.dart' as cupertino_ui;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import '../generated/app_localizations.dart';

/// Provides localizations to both migrated widgets and legacy dependencies.
/// The generated delegates still supply Flutter's original Material and
/// Cupertino types, which are distinct from the migrated package types.
const List<LocalizationsDelegate<dynamic>> appLocalizationDelegates = [
  material_ui.GlobalMaterialLocalizations.delegate,
  cupertino_ui.GlobalCupertinoLocalizations.delegate,
  ...AppLocalizations.localizationsDelegates,
];
