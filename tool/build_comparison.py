#!/usr/bin/env python3
"""Render the shared app-comparison data into the homepage and docs."""

from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DATA_FILE = ROOT / "documentation" / "features" / "app_comparison.json"
HOME_FILE = ROOT / "docs" / "index.html"

STATUS = {
    "yes": ("✓", "comparison_status_yes", "status-yes"),
    "partial": ("◐", "comparison_status_partial", "status-partial"),
    "nd": ("?", "comparison_status_unknown", "status-unknown"),
    "na": ("—", "comparison_status_na", "status-na"),
    "no": ("×", "comparison_status_no", "status-no"),
}


def read_data() -> dict:
    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    if len(data["apps"]) != 20:
        raise ValueError(f"Expected Train Libre and 19 comparison apps, got {len(data['apps'])}")
    ids = [app["id"] for app in data["apps"]]
    if len(set(ids)) != len(ids) or ids[0] != "train-libre":
        raise ValueError("App IDs must be unique and Train Libre must be first")
    return data


def platform_status(app: dict, platform: str) -> str:
    availability = app["platforms"][platform]
    if availability == "na":
        return "na"
    if availability == "nd":
        return "nd"
    status = app["features"].get("_unused", "nd")
    return status


def feature_status(app: dict, feature_id: str, platform: str) -> str:
    availability = app["platforms"][platform]
    if availability in {"na", "nd"}:
        return availability
    status = app["features"].get(feature_id, "nd")
    if availability == "partial" and status == "yes":
        return "partial"
    return status


def render_badge(status: str, platform: str) -> str:
    symbol, label_key, css_class = STATUS[status]
    platform_label = "iOS" if platform == "ios" else "Android"
    title = {
        "yes": "Documented",
        "partial": "Partial or platform-limited",
        "nd": "Not documented",
        "na": "Not applicable or unavailable",
        "no": "Not included",
    }[status]
    return (
        f'<span class="comparison-platform-status {css_class}" '
        f'title="{platform_label}: {title}" data-i18n-aria-label="{label_key}" aria-label="{title}">'
        f'<span class="comparison-platform-name" data-i18n="comparison_platform_{platform}">{platform_label}</span> '
        f'<span aria-hidden="true">{symbol}</span>'
        f'<span class="sr-only" data-i18n="{label_key}">{title}</span>'
        f'</span>'
    )


def render_matrix(data: dict, *, include_sources: bool = False, standalone: bool = False) -> str:
    apps = data["apps"]
    features = data["features"]
    classes = "comparison-table doc-table" if standalone else "comparison-table"
    region_label = "Comparison table, scroll horizontally to compare all apps" if standalone else "App comparison table, scroll horizontally to compare all apps"
    region_key = "comparison_table_region_docs" if standalone else "comparison_table_region_home"
    parts = [
        f'<div class="table-responsive comparison-table-scroll" role="region" tabindex="0" '
        f'data-i18n-aria-label="{region_key}" aria-label="{region_label}">',
        f'<table class="{classes}">',
        '<thead><tr><th class="comparison-feature-column" scope="col" data-i18n="comparison_feature_column">Feature</th>',
    ]
    for app in apps:
        name = html.escape(app["name"])
        url = html.escape(app["url"], quote=True)
        parts.append(
            '<th scope="col" class="comparison-app-column">'
            f'<a href="{url}" target="_blank" rel="noreferrer">{name}</a>'
            '<span class="comparison-app-platforms">'
            f'{render_badge(app["platforms"]["ios"], "ios")}'
            f'{render_badge(app["platforms"]["android"], "android")}'
            '</span></th>'
        )
    parts.append('</tr></thead><tbody>')

    active_category = None
    for feature in features:
        if feature["category"] != active_category:
            active_category = feature["category"]
            parts.append(
                f'<tr class="comparison-category-row"><th colspan="{len(apps) + 1}" '
                f'data-i18n="{feature["category"]}">{feature["category_label"]}</th></tr>'
            )
        parts.append(
            f'<tr><th scope="row" class="comparison-feature-column" '
            f'data-i18n="{feature["label"]}">{feature["label_text"]}</th>'
        )
        for app in apps:
            if feature.get("type") == "price":
                price_key = app["price"]
                parts.append(
                    f'<td class="comparison-value-cell comparison-price-cell" '
                    f'data-i18n="{price_key}">{price_key.removeprefix("comparison_price_").replace("_", " ").title()}</td>'
                )
                continue
            parts.append('<td class="comparison-value-cell"><span class="comparison-value-pair">')
            parts.append(render_badge(feature_status(app, feature["id"], "ios"), "ios"))
            parts.append(render_badge(feature_status(app, feature["id"], "android"), "android"))
            parts.append('</span></td>')
        parts.append('</tr>')
    parts.append('</tbody></table></div>')

    parts.append(
        '<div class="comparison-legend" aria-label="Comparison legend" data-i18n-aria-label="comparison_legend">'
        '<span><b class="status-yes" aria-hidden="true">✓</b> '
        '<span data-i18n="comparison_status_yes">Documented</span></span>'
        '<span><b class="status-partial" aria-hidden="true">◐</b> '
        '<span data-i18n="comparison_status_partial">Partial or platform-limited</span></span>'
        '<span><b class="status-unknown" aria-hidden="true">?</b> '
        '<span data-i18n="comparison_status_unknown">Not documented</span></span>'
        '<span><b class="status-na" aria-hidden="true">—</b> '
        '<span data-i18n="comparison_status_na">Not applicable or unavailable</span></span>'
        '<span><b class="status-no" aria-hidden="true">×</b> '
        '<span data-i18n="comparison_status_no">Not included (confirmed)</span></span>'
        '</div>'
    )
    parts.append(
        f'<p class="comparison-review-note" data-i18n="comparison_review_note">'
        'Public product pages and official app listings reviewed 21 October 2026. A missing public claim is not evidence that an app lacks a feature.'
        '</p>'
    )
    if include_sources:
        parts.append('<h2 id="comparison-sources">Evidence sources</h2><ul class="comparison-source-list">')
        for app in apps:
            parts.append(
                f'<li><a href="{html.escape(app["url"], quote=True)}" target="_blank" rel="noreferrer">'
                f'{html.escape(app["name"])} official product information</a></li>'
            )
            for source in app.get("evidence", []):
                parts.append(
                    f'<li><a href="{html.escape(source["url"], quote=True)}" target="_blank" rel="noreferrer">'
                    f'{html.escape(app["name"])}: {html.escape(source["label"])}</a></li>'
                )
        parts.append('</ul>')
    return "\n".join(parts)


def render_home_section(data: dict) -> str:
    table = render_matrix(data)
    return f'''<section class="comparison-section" id="comparison" aria-labelledby="comparison-title">
  <div class="comparison-header reveal">
    <span class="section-kicker" data-i18n="comparison_kicker">Compare fitness apps</span>
    <h2 class="section-heading" id="comparison-title" data-i18n="comparison_heading">See how the features compare.</h2>
    <p class="section-copy" data-i18n="comparison_intro">Compare Train Libre with 19 training and nutrition apps. The table links to public sources and separates iOS from Android.</p>
    <p class="comparison-scroll-hint" data-i18n="comparison_scroll_hint">Swipe or scroll horizontally to compare the apps.</p>
  </div>
  {table}
  <p class="comparison-doc-link"><a href="./docs/features/app-comparison/" data-i18n="comparison_docs_link">Methodology and sources in the documentation</a></p>
</section>'''


def main() -> None:
    data = read_data()
    content = HOME_FILE.read_text(encoding="utf-8")
    start = "<!-- APP_COMPARISON_START -->"
    end = "<!-- APP_COMPARISON_END -->"
    if content.count(start) != 1 or content.count(end) != 1:
        raise ValueError("Homepage must contain exactly one comparison placeholder pair")
    before, rest = content.split(start, 1)
    _, after = rest.split(end, 1)
    content = before + start + "\n" + render_home_section(data) + "\n    " + end + after
    HOME_FILE.write_text(content, encoding="utf-8")
    print(f"Rendered comparison data for {len(data['apps'])} apps and {len(data['features'])} features.")


if __name__ == "__main__":
    main()
