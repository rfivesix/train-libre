#!/usr/bin/env python3
"""
sync_store_metadata.py - Convert between consolidated Markdown files in
                         metadata/app_store/<locale>.md and Fastlane's
                         ios/fastlane/metadata/<locale>/*.txt structure.
"""

import sys
import os
import re
from pathlib import Path

# Character limit constraints imposed by Apple App Store Connect
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "release_notes": 4000,
}

SECTION_MAP = {
    "Name": "name",
    "Title": "name",
    "Subtitle": "subtitle",
    "Keywords": "keywords",
    "Promotional Text": "promotional_text",
    "Description": "description",
    "Release Notes": "release_notes",
    "What's New": "release_notes",
    "Support URL": "support_url",
    "Marketing URL": "marketing_url",
    "Privacy Policy URL": "privacy_url",
    "Copyright": "copyright",
}

# Non-locale directories Fastlane's `deliver` also writes into the metadata
# folder. These hold app review contact info / demo credentials, not
# App Store text content, and must never be synced into Markdown.
NON_LOCALE_DIRS = {
    "review_information",
    "trade_representative_contact_information",
}

FIELD_TITLES = [
    ("Name", "name", "App Title (max 30 chars)"),
    ("Subtitle", "subtitle", "Subtitle (max 30 chars)"),
    ("Keywords", "keywords", "Keywords (max 100 chars, comma-separated)"),
    ("Promotional Text", "promotional_text", "Promotional Text (max 170 chars)"),
    ("Description", "description", "Full App Store Description"),
    ("Release Notes", "release_notes", "What's New / Release Notes in this version"),
    ("Support URL", "support_url", "Support Web Page URL"),
    ("Marketing URL", "marketing_url", "Marketing / Product Web Page URL"),
    ("Privacy Policy URL", "privacy_url", "Privacy Policy Web Page URL"),
    ("Copyright", "copyright", "Copyright holder (e.g. 2026 Richard Schotte)"),
]

def parse_markdown(md_path: Path) -> dict:
    """Parse a Markdown file with ## Section headers into a dictionary of field -> text."""
    content = md_path.read_text(encoding="utf-8")
    result = {}
    current_key = None
    current_lines = []

    for line in content.splitlines():
        if line.startswith("## "):
            if current_key:
                result[current_key] = "\n".join(current_lines).strip()
                current_lines = []
            
            header = line[3:].strip()
            # Strip the trailing parenthetical hint, e.g. "## Name (App Title (max 30 chars))".
            # Must be greedy and anchored: the hint itself contains nested parentheses.
            clean_header = re.sub(r"\s*\(.*\)$", "", header).strip()
            current_key = SECTION_MAP.get(clean_header, clean_header.lower().replace(" ", "_"))
        elif current_key is not None:
            current_lines.append(line)

    if current_key:
        result[current_key] = "\n".join(current_lines).strip()

    return result

def write_markdown(md_path: Path, locale: str, fields: dict):
    """Write structured fields dictionary into a clean Markdown document."""
    md_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"# App Store Metadata - {locale}", ""]

    for title, field_key, hint in FIELD_TITLES:
        val = fields.get(field_key, "").strip()
        lines.append(f"## {title} ({hint})")
        if val:
            lines.append(val)
        lines.append("")

    md_path.write_text("\n".join(lines), encoding="utf-8")

def check_limits(locale: str, fields: dict) -> bool:
    """Validate character limits for App Store Connect fields."""
    valid = True
    for field_key, limit in LIMITS.items():
        val = fields.get(field_key, "")
        if len(val) > limit:
            print(f"⚠️  [WARN] [{locale}] {field_key} exceeds limit: {len(val)}/{limit} chars!")
            print(f"   Value: \"{val[:50]}...\"")
            valid = False
        elif val:
            print(f"✓  [{locale}] {field_key}: {len(val)}/{limit} chars")
    return valid

def md_to_fastlane(md_dir: Path, fastlane_meta_dir: Path):
    """Convert Markdown files in md_dir to Fastlane text files in fastlane_meta_dir."""
    md_files = list(md_dir.glob("*.md"))
    if not md_files:
        print(f"No Markdown files found in {md_dir}")
        return

    print(f"Converting {len(md_files)} Markdown files to Fastlane metadata...")
    for md_file in md_files:
        locale = md_file.stem
        fields = parse_markdown(md_file)
        print(f"\n--- Processing {locale} ---")
        check_limits(locale, fields)

        loc_dir = fastlane_meta_dir / locale
        loc_dir.mkdir(parents=True, exist_ok=True)

        for field_key, val in fields.items():
            if val:
                txt_path = loc_dir / f"{field_key}.txt"
                txt_path.write_text(val + "\n", encoding="utf-8")
                print(f"  Wrote {txt_path.relative_to(fastlane_meta_dir.parent)}")

def fastlane_to_md(fastlane_meta_dir: Path, md_dir: Path):
    """Convert Fastlane text files in fastlane_meta_dir to Markdown files in md_dir."""
    if not fastlane_meta_dir.exists():
        print(f"Fastlane metadata directory not found: {fastlane_meta_dir}")
        return

    loc_dirs = [
        d for d in fastlane_meta_dir.iterdir()
        if d.is_dir() and d.name not in NON_LOCALE_DIRS
    ]
    if not loc_dirs:
        print(f"No locale directories found in {fastlane_meta_dir}")
        return

    print(f"Converting {len(loc_dirs)} Fastlane locale directories to Markdown...")
    for loc_dir in loc_dirs:
        locale = loc_dir.name
        fields = {}

        for txt_file in loc_dir.glob("*.txt"):
            field_key = txt_file.stem
            val = txt_file.read_text(encoding="utf-8").strip()
            fields[field_key] = val

        md_file = md_dir / f"{locale}.md"
        write_markdown(md_file, locale, fields)
        print(f"✓ Created/Updated: {md_file}")

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 sync_store_metadata.py <md_to_fastlane|fastlane_to_md> <md_dir> <fastlane_meta_dir>")
        sys.exit(1)

    mode = sys.argv[1]
    md_dir = Path(sys.argv[2])
    fastlane_meta_dir = Path(sys.argv[3])

    if mode == "md_to_fastlane":
        md_to_fastlane(md_dir, fastlane_meta_dir)
    elif mode == "fastlane_to_md":
        fastlane_to_md(fastlane_meta_dir, md_dir)
    else:
        print(f"Unknown mode: {mode}")
        sys.exit(1)

if __name__ == "__main__":
    main()
