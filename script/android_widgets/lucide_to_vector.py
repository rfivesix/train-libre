#!/usr/bin/env python3
"""Turn the Lucide icons the app already uses into Android VectorDrawables.

The app draws its quick actions with `flutter_lucide` glyphs, so the widget has
to draw the same shapes or the two stop looking like one product. The package
ships only a font, but embeds each icon's original SVG as base64 in its Dart doc
comments — that is the source used here, rather than paths transcribed by hand.

Lucide is a stroked icon set (2px, round caps and joins), and VectorDrawable
supports stroking directly, so no outline conversion is involved.
"""

import base64
import os
import re
import sys

PACKAGE = os.path.expanduser(
    "~/.pub-cache/hosted/pub.dev/flutter_lucide-1.11.0/lib/src/flutter_lucide.dart"
)

# Quick action key -> Lucide icon name. The first six mirror
# `_getSpeedDialActions` in lib/features/app/presentation/main_screen.dart;
# scan_barcode is widget-only and matches iOS's "barcode.viewfinder".
ICONS = {
    "add_liquid": "glass_water",
    "add_food": "utensils",
    "add_measurement": "ruler",
    "start_workout": "dumbbell",
    "log_supplement": "pill",
    "ai_meal_capture": "sparkles",
    "scan_barcode": "scan_barcode",
    # Chrome, not actions: the glyphs the iOS widgets take from SF Symbols.
    "locked": "lock",
    "arrow_up": "arrow_up",
    "arrow_down": "arrow_down",
}

EMBEDDED = re.compile(r"/// !\[([a-z0-9_]+)\]\(data:image/svg\+xml;base64,([A-Za-z0-9+/=]+)\)")
PATH_D = re.compile(r'<path\s+d="([^"]+)"')
CIRCLE = re.compile(r'<circle\s+cx="([-\d.]+)"\s+cy="([-\d.]+)"\s+r="([-\d.]+)"')

# The package renders its doc-comment previews at 48x48 by substituting the
# svg's width/height attributes — which also rewrites any <rect>'s own width and
# height, so those are unrecoverable from that source. The affected icons carry
# their real geometry here, taken from lucide-static v1.31.0.
RECT_OVERRIDES = {
    # x, y, w, h, r
    "lock": (3.0, 11.0, 18.0, 11.0, 2.0),
}

TEMPLATE = """<?xml version="1.0" encoding="utf-8"?>
<!--
  {name} from Lucide, the icon set the app itself draws with
  (see _getSpeedDialActions in lib/features/app/presentation/main_screen.dart).
  Generated from the SVG embedded in flutter_lucide; drawn in white and tinted
  at the call site.
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
{paths}
</vector>
"""

PATH_ELEMENT = """    <path
        android:pathData="{data}"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="2"
        android:strokeLineCap="round"
        android:strokeLineJoin="round" />"""


def circle_to_path(cx: float, cy: float, r: float) -> str:
    """VectorDrawable has no circle element, so it becomes two half-arcs."""
    return f"M{cx - r},{cy} a{r},{r} 0 1,0 {2 * r},0 a{r},{r} 0 1,0 {-2 * r},0"


def rect_to_path(x: float, y: float, w: float, h: float, r: float) -> str:
    """Nor a rect; a rounded one is four lines joined by quarter arcs."""
    return (
        f"M{x + r},{y} H{x + w - r} A{r},{r} 0 0 1 {x + w},{y + r} "
        f"V{y + h - r} A{r},{r} 0 0 1 {x + w - r},{y + h} "
        f"H{x + r} A{r},{r} 0 0 1 {x},{y + h - r} "
        f"V{y + r} A{r},{r} 0 0 1 {x + r},{y} Z"
    )


def main():
    out_dir = os.path.join(sys.argv[1], "android/app/src/main/res/drawable")
    os.makedirs(out_dir, exist_ok=True)

    with open(PACKAGE, encoding="utf-8") as handle:
        source = handle.read()
    svgs = {m.group(1): base64.b64decode(m.group(2)).decode() for m in EMBEDDED.finditer(source)}

    for action, icon in ICONS.items():
        svg = svgs.get(icon)
        if svg is None:
            print(f"!! {icon} not found in the package", file=sys.stderr)
            continue
        if "<rect" in svg and icon not in RECT_OVERRIDES:
            # See RECT_OVERRIDES: a rect's dimensions cannot be trusted in this
            # source. Bail loudly rather than emit a silently wrong shape.
            print(f"!! {icon} has a <rect> and no override; add its real geometry", file=sys.stderr)
            continue

        data = PATH_D.findall(svg)
        data += [circle_to_path(float(a), float(b), float(c)) for a, b, c in CIRCLE.findall(svg)]
        if icon in RECT_OVERRIDES:
            data.append(rect_to_path(*RECT_OVERRIDES[icon]))
        if not data:
            print(f"!! {icon} produced no paths", file=sys.stderr)
            continue

        paths = "\n".join(PATH_ELEMENT.format(data=d) for d in data)
        target = os.path.join(out_dir, f"ic_widget_{action}.xml")
        with open(target, "w", encoding="utf-8") as handle:
            handle.write(TEMPLATE.format(name=icon, paths=paths))
        print(f"ic_widget_{action}.xml  <- lucide/{icon}  ({len(data)} paths)")


if __name__ == "__main__":
    sys.exit(main())
