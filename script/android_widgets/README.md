# Android widget generators

Two one-shot generators behind the Android home screen widgets. Both take assets
that already exist elsewhere in the project and restate them in the form Android
resources need — so neither output should be edited by hand.

Run both from the repository root:

```bash
python3 script/android_widgets/xcstrings_to_android.py .
```

```bash
python3 script/android_widgets/lucide_to_vector.py .
```

## `xcstrings_to_android.py`

Converts `ios/TrainLibreLiveActivity/Localizable.xcstrings` into
`android/app/src/main/res/values*/widget_strings.xml`. Both platforms show the
same widgets, so they share one set of translations; the catalogue is the source.

Only the *named* keys travel. The catalogue also holds bare format strings like
`%@ / %@ kcal`, which are compositions the widget code performs itself, and keys
Xcode auto-extracted but nobody filled in — emitting the latter would carry an
iOS defect across rather than fix it. The script lists what it skipped.

Android-only strings live in `widget_strings_android.xml` and are hand-maintained;
this script does not touch them.

## `lucide_to_vector.py`

Generates `android/app/src/main/res/drawable/ic_widget_*.xml` from the Lucide
icons the app itself draws with (`flutter_lucide`, see `_getSpeedDialActions` in
`lib/features/app/presentation/main_screen.dart`).

The package ships only a font, but embeds each icon's original SVG as base64 in
its Dart doc comments — that is the source, rather than paths transcribed by
hand. One caveat the script guards against: the package renders those previews at
48×48 by substituting the SVG's `width`/`height`, which also rewrites any
`<rect>`'s own dimensions. Affected icons carry their real geometry in
`RECT_OVERRIDES`, taken from `lucide-static`; anything else with a `<rect>` makes
the script refuse rather than emit a wrong shape.
