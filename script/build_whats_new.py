#!/usr/bin/env python3
"""
build_whats_new.py - Turn the user-facing release notes in metadata/whats_new/
                     into the in-app "What's New" catalog and (optionally) into
                     the App Store release notes.

Source of truth:  metadata/whats_new/<locale>.md
Generated Dart:   lib/features/whats_new/domain/whats_new_content.g.dart
Store sync target: metadata/app_store/<locale>.md, section "## Release Notes"

Modes
-----
  --check        Verify the current pubspec version has release notes in every
                 locale and that the App Store notes match. Exit code 1 on a
                 hard error, 2 when only the store copy is out of sync.
  --write        Regenerate the Dart catalog.
  --sync-store   Write the current version's notes (without {icon} tokens) into
                 metadata/app_store/<locale>.md.

Without any flag, --write is assumed.

Format of a locale file (see metadata/whats_new/README.md):

    ## 1.0.3 (2026-09-01)

    {cloud} iCloud Backup: Your data now backs up automatically.

Everything before the first ": " is the entry headline, the rest is the body.
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
NOTES_DIR = REPO_ROOT / "metadata" / "whats_new"
STORE_DIR = REPO_ROOT / "metadata" / "app_store"
PUBSPEC = REPO_ROOT / "pubspec.yaml"
DART_OUT = (
    REPO_ROOT
    / "lib"
    / "features"
    / "whats_new"
    / "domain"
    / "whats_new_content.g.dart"
)

# Store locale -> app language code. Locales without an app language (en-GB)
# are kept in sync with the store but never shipped inside the app.
LOCALE_TO_LANG = {
    "en-US": "en",
    "de-DE": "de",
    "fr-FR": "fr",
    "it": "it",
    "ja": "ja",
    "en-GB": None,
}

# Whitelist of icons usable via the {token} prefix. Every name must exist in
# flutter_lucide, otherwise the generated Dart will not compile.
ICON_MAP = {
    "sparkles": "LucideIcons.sparkles",
    "cloud": "LucideIcons.cloud",
    "zap": "LucideIcons.zap",
    "layout_grid": "LucideIcons.layout_grid",
    "smartphone": "LucideIcons.smartphone",
    "mic": "LucideIcons.mic",
    "activity": "LucideIcons.activity",
    "shield": "LucideIcons.shield",
    "bug": "LucideIcons.bug",
    "bell": "LucideIcons.bell",
    "timer": "LucideIcons.timer",
    "dumbbell": "LucideIcons.dumbbell",
    "heart": "LucideIcons.heart",
    "star": "LucideIcons.star",
    "rocket": "LucideIcons.rocket",
    "lock": "LucideIcons.lock",
    "chart_line": "LucideIcons.chart_line",
    "utensils": "LucideIcons.utensils",
    "moon": "LucideIcons.moon",
    "footprints": "LucideIcons.footprints",
    "camera": "LucideIcons.camera",
    "watch": "LucideIcons.watch",
    "circle_check": "LucideIcons.circle_check",
    "wand_sparkles": "LucideIcons.wand_sparkles",
}

DEFAULT_ICON = "sparkles"

VERSION_HEADER = re.compile(r"^##\s+([0-9][^\s(]*)\s*(?:\(([^)]*)\))?\s*$")
ICON_TOKEN = re.compile(r"^\{([a-z_]+)\}\s*")
HTML_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)


class Entry:
    def __init__(self, icon, title, body):
        self.icon = icon
        self.title = title
        self.body = body

    def as_store_text(self):
        """Plain rendering for App Store Connect - no icon tokens."""
        return f"{self.title}: {self.body}" if self.body else self.title


class Release:
    def __init__(self, version, released_on, entries):
        self.version = version
        self.released_on = released_on
        self.entries = entries


def parse_version(raw):
    """Split '1.0.10-beta.2' into a sortable tuple. Suffixes rank below the
    plain release, matching how CHANGELOG.md labels pre-releases."""
    core, _, suffix = raw.partition("-")
    parts = []
    for chunk in core.split("."):
        digits = re.match(r"\d+", chunk)
        parts.append(int(digits.group()) if digits else 0)
    while len(parts) < 3:
        parts.append(0)
    # No suffix sorts above any suffix: (1,0,2,1) > (1,0,2,0,'beta.1')
    return (parts[0], parts[1], parts[2], 0 if suffix else 1, suffix)


def current_version():
    line = next(
        (l for l in PUBSPEC.read_text(encoding="utf-8").splitlines()
         if l.startswith("version:")),
        None,
    )
    if line is None:
        raise SystemExit("version key not found in pubspec.yaml")
    return line.split(":", 1)[1].strip().split("+")[0]


def parse_notes(path):
    """Parse one locale file into a list of Release, newest first."""
    text = HTML_COMMENT.sub("", path.read_text(encoding="utf-8"))
    releases = []
    version = None
    released_on = ""
    buffer = []

    def flush():
        if version is None:
            return
        entries = []
        for para in buffer:
            para = para.strip()
            if not para:
                continue
            icon = DEFAULT_ICON
            match = ICON_TOKEN.match(para)
            if match:
                icon = match.group(1)
                para = para[match.end():]
                if icon not in ICON_MAP:
                    raise SystemExit(
                        f"{path.name}: unknown icon '{{{icon}}}' in version "
                        f"{version}. Allowed: {', '.join(sorted(ICON_MAP))}"
                    )
            title, sep, body = para.partition(": ")
            entries.append(
                Entry(icon, title.strip(), body.strip() if sep else "")
            )
        releases.append(Release(version, released_on, entries))

    paragraph = []
    for line in text.splitlines():
        header = VERSION_HEADER.match(line)
        if header:
            if paragraph:
                buffer.append(" ".join(paragraph))
                paragraph = []
            flush()
            version = header.group(1)
            released_on = (header.group(2) or "").strip()
            buffer = []
            continue
        if line.startswith("# "):
            continue
        if line.strip():
            paragraph.append(line.strip())
        elif paragraph:
            buffer.append(" ".join(paragraph))
            paragraph = []
    if paragraph:
        buffer.append(" ".join(paragraph))
    flush()

    releases.sort(key=lambda r: parse_version(r.version), reverse=True)
    return releases


def load_all():
    notes = {}
    for locale in LOCALE_TO_LANG:
        path = NOTES_DIR / f"{locale}.md"
        if not path.exists():
            raise SystemExit(f"Missing release notes file: {path}")
        notes[locale] = parse_notes(path)
    return notes


def dart_escape(value):
    return value.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


def generate_dart(notes, version):
    lines = [
        "// GENERATED FILE - DO NOT EDIT BY HAND.",
        "//",
        "// Source:    metadata/whats_new/<locale>.md",
        "// Generator: script/build_whats_new.py",
        "//",
        "// Add a new release by editing the Markdown files, then run:",
        "//   python3 script/build_whats_new.py --write --sync-store",
        "",
        "import 'package:flutter_lucide/flutter_lucide.dart';",
        "",
        "import 'whats_new_release.dart';",
        "",
        "/// User-facing release notes per app language code.",
        "///",
        "/// Languages without their own translation fall back to "
        "[kWhatsNewFallbackLanguage].",
        "const Map<String, List<WhatsNewRelease>> kWhatsNewContent = {",
    ]

    for locale, lang in LOCALE_TO_LANG.items():
        if lang is None:
            continue
        lines.append(f"  '{lang}': <WhatsNewRelease>[")
        for release in notes[locale]:
            lines.append("    WhatsNewRelease(")
            lines.append(f"      version: '{dart_escape(release.version)}',")
            lines.append(
                f"      releasedOn: '{dart_escape(release.released_on)}',"
            )
            lines.append("      entries: <WhatsNewEntry>[")
            for entry in release.entries:
                lines.append("        WhatsNewEntry(")
                lines.append(f"          icon: {ICON_MAP[entry.icon]},")
                lines.append(f"          title: '{dart_escape(entry.title)}',")
                lines.append(f"          body: '{dart_escape(entry.body)}',")
                lines.append("        ),")
            lines.append("      ],")
            lines.append("    ),")
        lines.append("  ],")

    lines.append("};")
    lines.append("")
    lines.append("/// Language used when the device language has no notes of its own.")
    lines.append("const String kWhatsNewFallbackLanguage = 'en';")
    lines.append("")
    lines.append(
        "/// The version this catalog was generated for, taken from pubspec.yaml."
    )
    lines.append(f"const String kWhatsNewGeneratedForVersion = '{version}';")
    lines.append("")
    return "\n".join(lines)


def dart_format(source):
    """Run `dart format` over generated source so --write and --check agree
    with what `dart format .` would produce. Falls back to the raw text when
    the Dart SDK is not on PATH."""
    dart = shutil.which("dart")
    if dart is None:
        return source
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "whats_new_content.g.dart"
        path.write_text(source, encoding="utf-8")
        # Format in place and read the file back: `--output show` writes the
        # formatted source *and* a "Formatted 1 file" summary line to stdout,
        # which would end up inside the generated Dart.
        result = subprocess.run(
            [dart, "format", str(path)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print("WARN  dart format failed, writing unformatted output")
            return source
        return path.read_text(encoding="utf-8")


def store_text_for(notes, locale, version):
    release = next(
        (r for r in notes[locale] if r.version == version), None
    )
    if release is None:
        return None
    return "\n\n".join(e.as_store_text() for e in release.entries)


def read_store_release_notes(locale):
    path = STORE_DIR / f"{locale}.md"
    if not path.exists():
        return None, path
    body = re.search(
        r"^##\s+Release Notes[^\n]*\n(.*?)(?=^##\s|\Z)",
        path.read_text(encoding="utf-8"),
        re.DOTALL | re.MULTILINE,
    )
    return (body.group(1).strip() if body else ""), path


def write_store_release_notes(locale, text):
    current, path = read_store_release_notes(locale)
    if current is None:
        return False
    original = path.read_text(encoding="utf-8")
    updated, count = re.subn(
        r"(^##\s+Release Notes[^\n]*\n)(.*?)(?=^##\s|\Z)",
        lambda m: f"{m.group(1)}{text}\n\n",
        original,
        count=1,
        flags=re.DOTALL | re.MULTILINE,
    )
    if count == 0:
        print(f"WARN  [{locale}] no '## Release Notes' section - skipped")
        return False
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def cmd_check(notes, version):
    errors = []
    warnings = []

    reference = None
    for locale in LOCALE_TO_LANG:
        release = next((r for r in notes[locale] if r.version == version), None)
        if release is None:
            errors.append(
                f"[{locale}] no '## {version}' section in "
                f"metadata/whats_new/{locale}.md"
            )
            continue
        if not release.entries:
            errors.append(f"[{locale}] version {version} has no entries")
            continue
        if reference is None:
            reference = (locale, len(release.entries))
        elif len(release.entries) != reference[1]:
            warnings.append(
                f"[{locale}] has {len(release.entries)} entries, "
                f"[{reference[0]}] has {reference[1]}"
            )
        for entry in release.entries:
            if not entry.body:
                warnings.append(
                    f"[{locale}] entry \"{entry.title[:40]}\" has no "
                    f"description (missing ': ' separator?)"
                )

    stale_store = []
    for locale in LOCALE_TO_LANG:
        expected = store_text_for(notes, locale, version)
        if expected is None:
            continue
        actual, path = read_store_release_notes(locale)
        if actual is None:
            warnings.append(f"[{locale}] {path} does not exist")
        elif actual.strip() != expected.strip():
            stale_store.append(locale)

    for message in warnings:
        print(f"WARN   {message}")
    for message in errors:
        print(f"ERROR  {message}")

    if stale_store:
        print(
            "ERROR  App Store release notes differ from metadata/whats_new for: "
            + ", ".join(stale_store)
        )
        print("       Fix with: python3 script/build_whats_new.py --sync-store")

    if DART_OUT.exists():
        expected_dart = dart_format(generate_dart(notes, version))
        if DART_OUT.read_text(encoding="utf-8") != expected_dart:
            print(
                "ERROR  whats_new_content.g.dart is out of date. "
                "Fix with: python3 script/build_whats_new.py --write"
            )
            errors.append("stale generated Dart")
    else:
        print(f"ERROR  {DART_OUT} is missing")
        errors.append("missing generated Dart")

    if errors:
        return 1
    if stale_store:
        return 2
    print(f"OK     Release notes for {version} are complete and in sync.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--sync-store", action="store_true")
    args = parser.parse_args()

    if not (args.check or args.write or args.sync_store):
        args.write = True

    version = current_version()
    notes = load_all()

    exit_code = 0

    if args.write:
        DART_OUT.parent.mkdir(parents=True, exist_ok=True)
        DART_OUT.write_text(
            dart_format(generate_dart(notes, version)), encoding="utf-8"
        )
        print(f"✓  Wrote {DART_OUT.relative_to(REPO_ROOT)}")

    if args.sync_store:
        for locale in LOCALE_TO_LANG:
            text = store_text_for(notes, locale, version)
            if text is None:
                print(f"WARN  [{locale}] no notes for {version} - store not updated")
                continue
            if write_store_release_notes(locale, text):
                print(f"✓  Updated metadata/app_store/{locale}.md")
            else:
                print(f"=  metadata/app_store/{locale}.md already up to date")

    if args.check:
        exit_code = cmd_check(notes, version)

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
