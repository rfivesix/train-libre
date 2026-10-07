#!/usr/bin/env python3
"""Validate the public static-site artifacts before GitHub Pages deployment."""

from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree


REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
SITE_ORIGIN = "https://trainlibre.com"


class MetadataParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.canonical: str | None = None
        self.robots: str = ""
        self.links: list[str] = []
        self.csp: str | None = None
        self.content_type_options: str | None = None
        self.referrer: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag == "link" and attributes.get("rel") == "canonical":
            self.canonical = attributes.get("href")
        elif tag == "meta":
            name = (attributes.get("name") or "").lower()
            http_equiv = (attributes.get("http-equiv") or "").lower()
            content = attributes.get("content", "")
            if name == "robots":
                self.robots = content
            elif http_equiv == "content-security-policy":
                self.csp = content
            elif http_equiv == "x-content-type-options":
                self.content_type_options = content
            elif name == "referrer":
                self.referrer = content
        elif tag == "a" and attributes.get("href"):
            self.links.append(attributes["href"])


def public_path_to_file(path: str) -> Path:
    relative = path.lstrip("/")
    if not relative or path.endswith("/"):
        return DOCS_DIR / relative / "index.html"
    return DOCS_DIR / relative


def parse_html(path: Path) -> MetadataParser:
    parser = MetadataParser()
    parser.feed(path.read_text(encoding="utf-8"))
    return parser


def indexable_canonical_paths() -> set[str]:
    paths: set[str] = set()
    for page in DOCS_DIR.rglob("*.html"):
        if "node_modules" in page.parts or page.name == "404.html":
            continue
        metadata = parse_html(page)
        if "noindex" in metadata.robots.lower() or not metadata.canonical:
            continue
        canonical = urlparse(metadata.canonical)
        if f"{canonical.scheme}://{canonical.netloc}" != SITE_ORIGIN:
            continue
        paths.add(canonical.path or "/")
    return paths


def validate_sitemap() -> None:
    sitemap = DOCS_DIR / "sitemap.xml"
    root = ElementTree.parse(sitemap).getroot()
    namespace = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    locations = [node.text for node in root.findall("sm:url/sm:loc", namespace) if node.text]
    sitemap_paths = {urlparse(location).path or "/" for location in locations}
    expected_paths = indexable_canonical_paths()
    assert sitemap_paths == expected_paths, (
        "Sitemap must contain every and only indexable canonical page. "
        f"Missing: {sorted(expected_paths - sitemap_paths)}; "
        f"Unexpected: {sorted(sitemap_paths - expected_paths)}"
    )
    for path in sitemap_paths:
        assert public_path_to_file(path).is_file(), f"Sitemap route has no published file: {path}"


def validate_redirect(route: str, target: str) -> None:
    page = public_path_to_file(route)
    metadata = parse_html(page)
    assert "noindex" in metadata.robots.lower(), f"Redirect must not be indexed: {route}"
    assert target in page.read_text(encoding="utf-8"), f"Redirect target missing: {route} -> {target}"
    assert public_path_to_file(target).is_file(), f"Redirect destination has no published file: {target}"


def validate_noindex(route: str) -> None:
    metadata = parse_html(public_path_to_file(route))
    assert "noindex" in metadata.robots.lower(), f"Page must not be indexed: {route}"


def validate_404() -> None:
    page = DOCS_DIR / "404.html"
    assert page.is_file(), "Missing GitHub Pages 404.html"
    metadata = parse_html(page)
    assert "noindex" in metadata.robots.lower(), "404 page must not be indexed"
    for href in metadata.links:
        if urlparse(href).scheme or href.startswith("#"):
            continue
        target = (page.parent / href).resolve()
        if href.endswith("/"):
            target /= "index.html"
        assert target.is_file(), f"404 page links to missing local path: {href}"


def validate_security_headers() -> None:
    headers_file = DOCS_DIR / "_headers"
    assert headers_file.is_file(), "Missing docs/_headers file"
    headers_content = headers_file.read_text(encoding="utf-8")
    required_headers = [
        "Strict-Transport-Security:",
        "X-Content-Type-Options: nosniff",
        "X-Frame-Options: DENY",
        "Referrer-Policy: strict-origin-when-cross-origin",
        "Permissions-Policy:",
        "Content-Security-Policy:",
        "Cross-Origin-Opener-Policy: same-origin",
        "Cross-Origin-Resource-Policy: same-origin",
    ]
    for header in required_headers:
        assert header in headers_content, f"docs/_headers missing header directive: {header}"

    for path in indexable_canonical_paths():
        page = public_path_to_file(path)
        metadata = parse_html(page)
        assert metadata.csp, f"Page missing Content-Security-Policy meta tag: {path}"
        assert metadata.content_type_options == "nosniff", f"Page missing X-Content-Type-Options: {path}"
        assert metadata.referrer == "strict-origin-when-cross-origin", f"Page missing referrer policy: {path}"
        if "script-src" in metadata.csp:
            script_directive = metadata.csp.split("script-src")[1].split(";")[0]
            assert "unsafe-inline" not in script_directive, f"Page has unsafe-inline in script-src: {path}"


def main() -> None:
    validate_sitemap()
    validate_security_headers()
    validate_404()
    validate_noindex("/privacy-policy/")
    validate_redirect("/ai-nutrition/", "/docs/features/meal-capture-pipeline/")
    validate_redirect("/adaptive-nutrition/", "/docs/features/bayesian-tdee-estimator/")
    validate_redirect("/intelligent-workouts/", "/docs/features/intelligent-workouts/")
    validate_redirect("/recovery/", "/docs/features/muscle-recovery-model/")
    validate_redirect("/sleep-score/", "/docs/features/sleep-scoring-engine/")
    validate_redirect("/docs/features/", "/docs/features/overview/")
    validate_redirect("/docs/developer/", "/docs/developer/overview/")
    print("Validated sitemap, security headers, redirects, and GitHub Pages 404 page.")


if __name__ == "__main__":
    main()
