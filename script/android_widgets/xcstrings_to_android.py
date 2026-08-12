#!/usr/bin/env python3
"""Convert the widget extension's .xcstrings catalogue into Android strings.xml.

The translations already exist on the iOS side; this only changes the container.
Only the *named* keys travel (`widget.*`, `quickAction.*`) — the catalogue also
holds bare format strings like `%@ / %@ kcal`, which are compositions the widget
code performs itself and have no place as Android resources.
"""

import json
import os
import re
import sys
from xml.sax.saxutils import escape

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
SOURCE = "ios/TrainLibreLiveActivity/Localizable.xcstrings"
LOCALES = {"en": "values", "de": "values-de", "fr": "values-fr", "it": "values-it", "ja": "values-ja"}

# A key is either a plain identifier, or an identifier followed by the single
# placeholder Xcode folds into the key itself.
NAMED = re.compile(r"^([a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+)(?:\s+(%@|%lld))?$")


def resource_name(key: str) -> str:
    """`widget.lastWorkout.empty.title` -> `widget_last_workout_empty_title`."""
    parts = []
    for segment in key.split("."):
        snake = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", segment)
        parts.append(snake.lower())
    return "_".join(parts)


LITERAL_PERCENT = "\x00"
PLACEHOLDER_PERCENT = "\x01"


def to_android_format(value: str) -> str:
    """iOS placeholders -> Android's, with literal percents kept literal.

    Order matters. `%lld%%` is a placeholder followed by an *escaped* percent, so
    both kinds are moved out of the way as sentinels before anything is doubled —
    otherwise the escape that was already there gets doubled a second time and
    "50% of goal" ships as "50%% of goal".
    """
    value = value.replace("%%", LITERAL_PERCENT)

    index = [0]

    def repl(match):
        kind = match.group("kind")
        position = match.group("pos")
        if position:
            number = int(position)
        else:
            index[0] += 1
            number = index[0]
        return PLACEHOLDER_PERCENT + f"{number}$" + ("s" if kind == "@" else "d")

    value = re.sub(r"%(?:(?P<pos>\d+)\$)?(?P<kind>@|lld)", repl, value)
    # Anything still bare is a percent the catalogue never escaped; Android's
    # formatter would read it as a broken conversion.
    value = value.replace("%", LITERAL_PERCENT)
    return value.replace(LITERAL_PERCENT, "%%").replace(PLACEHOLDER_PERCENT, "%")


def android_escape(value: str) -> str:
    value = escape(value)
    value = value.replace("'", "\\'").replace('"', '\\"')
    value = value.replace("\n", "\\n")
    if value.startswith("@") or value.startswith("?"):
        value = "\\" + value
    return value


def main():
    with open(os.path.join(ROOT, SOURCE), encoding="utf-8") as handle:
        catalogue = json.load(handle)

    source_language = catalogue.get("sourceLanguage", "en")
    collected = {locale: {} for locale in LOCALES}
    skipped = []

    for key, entry in sorted(catalogue["strings"].items()):
        match = NAMED.match(key)
        if not match:
            skipped.append(key)
            continue
        localizations = entry.get("localizations", {})
        if not localizations:
            # Xcode auto-extracted the key but nobody ever filled it in, so on
            # iOS it renders as the raw key. Emitting that here would only carry
            # the same defect across; the Android side has no field for it.
            skipped.append(key)
            continue
        name = resource_name(match.group(1))
        for locale in LOCALES:
            value = localizations.get(locale, {}).get("stringUnit", {}).get("value")
            if value is None:
                continue
            collected[locale][name] = to_android_format(value)

    # Every locale falls back to the default file, so a name present there but
    # missing in a translation still resolves at runtime.
    base = collected[source_language]
    missing = {
        locale: sorted(set(base) - set(values))
        for locale, values in collected.items()
        if locale != source_language
    }

    for locale, directory in LOCALES.items():
        values = collected[locale]
        if not values:
            continue
        target_dir = os.path.join(ROOT, "android/app/src/main/res", directory)
        os.makedirs(target_dir, exist_ok=True)
        target = os.path.join(target_dir, "widget_strings.xml")
        lines = [
            '<?xml version="1.0" encoding="utf-8"?>',
            "<!--",
            "  Generated from ios/TrainLibreLiveActivity/Localizable.xcstrings.",
            "  Both platforms show the same widgets, so they share one set of",
            "  translations; edit the catalogue, not this file.",
            "-->",
            "<resources>",
        ]
        for name in sorted(values):
            lines.append(f"    <string name=\"{name}\">{android_escape(values[name])}</string>")
        lines.append("</resources>")
        with open(target, "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
        print(f"{directory}/widget_strings.xml: {len(values)} strings")

    print(f"\nSkipped {len(skipped)} format-string keys (composed in code):")
    for key in sorted(skipped):
        print(f"  {key!r}")
    for locale, names in missing.items():
        if names:
            print(f"\n{locale} is missing {len(names)}: {', '.join(names)}")


if __name__ == "__main__":
    sys.exit(main())
