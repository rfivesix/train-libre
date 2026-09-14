#!/usr/bin/env python3
"""Generate the landing-page screenshots from the canonical iOS captures.

The app captures live in ``assets/screenshots``.  GitHub Pages, however,
publishes ``docs``.  Keeping the smaller WebP copies derived at build time
prevents those two locations from silently getting out of sync.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "screenshots" / "iOS"
DESTINATION = ROOT / "docs" / "assets" / "screenshots" / "iOS"
LOCALES = ("de-DE", "en-US")
THEMES = ("dark", "light")
SIZE = (828, 1800)


def main() -> None:
    for locale in LOCALES:
        for theme in THEMES:
            source_directory = SOURCE / locale / theme
            sources = sorted(source_directory.glob(f"iOS_{theme}_*.png"))
            if not sources:
                raise FileNotFoundError(
                    f"Missing canonical website screenshots: {source_directory}"
                )

            target_directory = DESTINATION / locale / theme
            target_directory.mkdir(parents=True, exist_ok=True)
            expected_targets = {source.with_suffix(".webp").name for source in sources}
            for stale in target_directory.glob("*.webp"):
                if stale.name not in expected_targets:
                    stale.unlink()

            for source in sources:
                target = target_directory / source.with_suffix(".webp").name
                with Image.open(source) as image:
                    image.convert("RGB").resize(SIZE, Image.Resampling.LANCZOS).save(
                        target,
                        "WEBP",
                        quality=90,
                        method=6,
                    )


if __name__ == "__main__":
    main()
