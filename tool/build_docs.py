#!/usr/bin/env python3
"""
Train Libre Documentation Builder
---------------------------------
Compiles documentation from markdown in `documentation/` into styled static HTML
under `docs/docs/`, maintaining 100% fidelity with the Train Libre design system,
rendering math via KaTeX, and providing responsive sidebar navigation and TOC.
All CSS, font, image, and internal document links are computed as relative paths,
ensuring perfect rendering across local file preview, VS Code Live Server,
development servers, and GitHub Pages production.
"""

import html
import os
import re
import sys
from pathlib import Path

# Base paths
REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
SRC_DOC_DIR = REPO_ROOT / "documentation"
OUTPUT_DOCS_DIR = DOCS_DIR / "docs"

# Navigation structure
DOCS_STRUCTURE = [
    {
        "category": "Overview",
        "items": [
            {
                "id": "overview-root",
                "title": "Documentation Suite Overview",
                "slug": "",
                "src_file": SRC_DOC_DIR / "README.md",
                "out_dir": OUTPUT_DOCS_DIR,
                "url": "/docs/",
                "desc": "Overview of Train Libre architecture, heuristics, and developer guides."
            }
        ]
    },
    {
        "category": "Features & Heuristics",
        "items": [
            {
                "id": "features-overview",
                "title": "Capabilities & Privacy",
                "slug": "overview",
                "src_file": SRC_DOC_DIR / "features" / "overview.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "overview",
                "url": "/docs/features/overview/",
                "desc": "Smart processing boundaries, native secure storage, and opt-in telemetry."
            },
            {
                "id": "features-sleep",
                "title": "Sleep Health Score (SHS v3.5)",
                "slug": "sleep-scoring-engine",
                "src_file": SRC_DOC_DIR / "features" / "sleep_scoring_engine.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "sleep-scoring-engine",
                "url": "/docs/features/sleep-scoring-engine/",
                "desc": "Mathematical specification of the 5-domain continuous soft-cap multiplier sleep model."
            },
            {
                "id": "features-recovery",
                "title": "Muscle Recovery & Readiness",
                "slug": "muscle-recovery-model",
                "src_file": SRC_DOC_DIR / "features" / "muscle_recovery_model.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "muscle-recovery-model",
                "url": "/docs/features/muscle-recovery-model/",
                "desc": "Piecewise recovery kinetics, equivalent set weighting, and failure-induced fatigue."
            },
            {
                "id": "features-tdee",
                "title": "Bayesian TDEE Estimator",
                "slug": "bayesian-tdee-estimator",
                "src_file": SRC_DOC_DIR / "features" / "bayesian_tdee_estimator.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "bayesian-tdee-estimator",
                "url": "/docs/features/bayesian-tdee-estimator/",
                "desc": "Kalman filter and Bayesian recursive estimation for adaptive calorie targets."
            },
            {
                "id": "features-macro",
                "title": "Macronutrient Distribution",
                "slug": "macro-distribution",
                "src_file": SRC_DOC_DIR / "features" / "macro_distribution.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "macro-distribution",
                "url": "/docs/features/macro-distribution/",
                "desc": "Calorie target decomposition into protein, carbohydrate, and fat targets."
            },
            {
                "id": "features-progression",
                "title": "Workout Progression Engine",
                "slug": "workout-progression-engine",
                "src_file": SRC_DOC_DIR / "features" / "workout_progression_engine.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "workout-progression-engine",
                "url": "/docs/features/workout-progression-engine/",
                "desc": "First-working-set load recommendation, double progression, and e1RM back-offs."
            },
            {
                "id": "features-e1rm",
                "title": "Estimated 1-Rep Max (e1RM)",
                "slug": "intelligent-workouts",
                "src_file": SRC_DOC_DIR / "features" / "intelligent_workouts.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "intelligent-workouts",
                "url": "/docs/features/intelligent-workouts/",
                "desc": "Submaximal strength estimation heuristic, assisted & bodyweight load formulas."
            },
            {
                "id": "features-capture",
                "title": "Meal Capture Pipeline",
                "slug": "meal-capture-pipeline",
                "src_file": SRC_DOC_DIR / "features" / "meal_capture_pipeline.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "meal-capture-pipeline",
                "url": "/docs/features/meal-capture-pipeline/",
                "desc": "Unified camera, passive barcode detection, voice dictation, and privacy boundaries."
            },
            {
                "id": "features-byok",
                "title": "BYOK AI Meal Validation",
                "slug": "byok-ai-validation",
                "src_file": SRC_DOC_DIR / "features" / "byok_ai_validation.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "byok-ai-validation",
                "url": "/docs/features/byok-ai-validation/",
                "desc": "Local BYOK LLM integration, fuzzy matching, and 3-pass self-repair verification."
            },
            {
                "id": "features-depth",
                "title": "Depth Scale Hint (LiDAR)",
                "slug": "depth-scale-hint",
                "src_file": SRC_DOC_DIR / "features" / "depth_scale_hint.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "depth-scale-hint",
                "url": "/docs/features/depth-scale-hint/",
                "desc": "LiDAR metric scale facts and false-colour depth hints for portion guidance."
            },
            {
                "id": "features-health",
                "title": "Native Health Sync & Export",
                "slug": "health-sync-export",
                "src_file": SRC_DOC_DIR / "features" / "health_sync_export.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "health-sync-export",
                "url": "/docs/features/health-sync-export/",
                "desc": "Apple HealthKit and Health Connect bidirectional sync & SQLite idempotency."
            },
            {
                "id": "features-live-act",
                "title": "Live Activity & Workout Session",
                "slug": "live-activity-workout",
                "src_file": SRC_DOC_DIR / "features" / "live_activity_workout.md",
                "out_dir": OUTPUT_DOCS_DIR / "features" / "live-activity-workout",
                "url": "/docs/features/live-activity-workout/",
                "desc": "iOS Live Activity, Dynamic Island, and workout session state synchronization."
            }
        ]
    },
    {
        "category": "Developer & Architecture",
        "items": [
            {
                "id": "dev-overview",
                "title": "Developer Overview & Tests",
                "slug": "overview",
                "src_file": SRC_DOC_DIR / "developer" / "overview.md",
                "out_dir": OUTPUT_DOCS_DIR / "developer" / "overview",
                "url": "/docs/developer/overview/",
                "desc": "Architecture principles, testing tiers, and continuous integration strategy."
            },
            {
                "id": "dev-arch",
                "title": "System Architecture & Wiring",
                "slug": "architecture",
                "src_file": SRC_DOC_DIR / "developer" / "architecture.md",
                "out_dir": OUTPUT_DOCS_DIR / "developer" / "architecture",
                "url": "/docs/developer/architecture/",
                "desc": "Clean Architecture boundaries, Drift SQLite lifecycle, and DI provider graph."
            },
            {
                "id": "dev-flow",
                "title": "Data Flow & State Lifecycle",
                "slug": "data-flow-and-state",
                "src_file": SRC_DOC_DIR / "developer" / "data_flow_and_state.md",
                "out_dir": OUTPUT_DOCS_DIR / "developer" / "data-flow-and-state",
                "url": "/docs/developer/data-flow-and-state/",
                "desc": "Reactive reads, imperative writes, drift streams, and lock states."
            },
            {
                "id": "dev-l10n",
                "title": "Localization Architecture",
                "slug": "localization-architecture",
                "src_file": SRC_DOC_DIR / "developer" / "localization_architecture.md",
                "out_dir": OUTPUT_DOCS_DIR / "developer" / "localization-architecture",
                "url": "/docs/developer/localization-architecture/",
                "desc": "Multi-locale catalog translation pipeline, relational tables, and fallback chains."
            },
            {
                "id": "dev-widgets",
                "title": "Home Screen Widgets",
                "slug": "ios-home-screen-widgets",
                "src_file": SRC_DOC_DIR / "developer" / "ios_home_screen_widgets.md",
                "out_dir": OUTPUT_DOCS_DIR / "developer" / "ios-home-screen-widgets",
                "url": "/docs/developer/ios-home-screen-widgets/",
                "desc": "WidgetKit (iOS) and Glance/AppWidgetProvider (Android) background snapshots."
            }
        ]
    }
]

# Map markdown relative filenames to target item descriptors
TARGET_MAP = {}
for cat in DOCS_STRUCTURE:
    for itm in cat["items"]:
        # Map relative source path
        rel_src = str(itm["src_file"].relative_to(SRC_DOC_DIR))
        TARGET_MAP[rel_src] = itm
        TARGET_MAP[f"../{rel_src}"] = itm
        TARGET_MAP[itm["src_file"].name] = itm


def slugify(text: str) -> str:
    """Generate a clean URL/anchor slug from a heading text."""
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    text = re.sub(r'[*_`$~]', '', text)
    text = re.sub(r'\\[\(\)\[\]]', '', text)
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'-+', '-', text)
    return text.strip('-') or 'section'


class MarkdownParser:
    """Robust Markdown to HTML parser with KaTeX, table, and TOC support."""

    def __init__(self, current_out_dir: Path):
        self.current_out_dir = current_out_dir
        self.toc = []
        self.title = ""
        self.first_h1_found = False
        self.raw_text = {}

    def parse(self, text: str) -> str:
        placeholders = {}
        self.raw_text = {}
        counter = 0

        # 1. Protect fenced code blocks ``` ... ```
        def code_repl(match):
            nonlocal counter
            lang = (match.group(1) or "").strip().lower()
            code_content = match.group(2)
            escaped_code = html.escape(code_content.strip("\n"))

            if lang == "mermaid":
                key = f"@@TL_MERMAID_{counter}@@"
                counter += 1
                html_block = (
                    f'<div class="mermaid-container">'
                    f'<pre class="mermaid" data-mermaid="{escaped_code}">{escaped_code}</pre>'
                    f'</div>'
                )
                placeholders[key] = html_block
                return f"\n\n{key}\n\n"

            key = f"@@TL_CODE_{counter}@@"
            counter += 1
            code_class = f' class="language-{lang}"' if lang else ""
            html_block = (
                f'<div class="code-block-wrapper">'
                f'<div class="code-block-header"><span class="code-lang">{html.escape(lang or "text")}</span>'
                f'<button class="copy-btn" onclick="navigator.clipboard.writeText(this.closest(\'.code-block-wrapper\').querySelector(\'code\').innerText); this.textContent=\'Copied!\'; setTimeout(()=>this.textContent=\'Copy\', 1500);">Copy</button>'
                f'</div>'
                f'<pre><code{code_class}>{escaped_code}</code></pre></div>'
            )
            placeholders[key] = html_block
            return f"\n\n{key}\n\n"

        text = re.sub(r'```([a-zA-Z0-9_-]*)\n(.*?)```', code_repl, text, flags=re.DOTALL)

        # 2. Protect display math blocks $$ ... $$
        def math_block_repl(match):
            nonlocal counter
            key = f"@@TL_MATHB_{counter}@@"
            counter += 1
            math_content = match.group(1).strip()
            html_block = f'<div class="math-block">$${math_content}$$</div>'
            placeholders[key] = html_block
            return f"\n\n{key}\n\n"

        text = re.sub(r'\$\$(.*?)\$\$', math_block_repl, text, flags=re.DOTALL)

        # 3. Protect inline math $ ... $
        def math_inline_repl(match):
            nonlocal counter
            key = f"@@TL_MATHI_{counter}@@"
            counter += 1
            math_content = match.group(1).strip()
            placeholders[key] = f'<span class="math-inline">${math_content}$</span>'
            self.raw_text[key] = math_content
            return key

        text = re.sub(r'(?<!\$)\$(?!\$)(.*?)(?<!\$)\$(?!\$)', math_inline_repl, text)

        # 4. Protect inline code ` ... `
        def code_inline_repl(match):
            nonlocal counter
            key = f"@@TL_CODEI_{counter}@@"
            counter += 1
            code_raw = match.group(1)
            code_str = html.escape(code_raw)
            placeholders[key] = f'<code>{code_str}</code>'
            self.raw_text[key] = code_raw
            return key

        text = re.sub(r'`([^`]+)`', code_inline_repl, text)

        # Split into blocks by blank lines
        raw_blocks = text.split("\n\n")
        parsed_blocks = []

        i = 0
        while i < len(raw_blocks):
            block = raw_blocks[i].strip()
            if not block:
                i += 1
                continue

            if block in placeholders:
                parsed_blocks.append(placeholders[block])
                i += 1
                continue

            # Heading detection - single line only!
            if block.startswith("#"):
                lines = block.split("\n")
                first_line = lines[0].strip()
                h_match = re.match(r'^(#{1,6})\s+(.*)$', first_line)
                if h_match:
                    level = len(h_match.group(1))
                    h_text = h_match.group(2).strip()
                    h_html = self._parse_heading(level, h_text)
                    parsed_blocks.append(h_html)
                    rest = "\n".join(lines[1:]).strip()
                    if rest:
                        raw_blocks.insert(i + 1, rest)
                    i += 1
                    continue

            lines = [l.strip() for l in block.split("\n") if l.strip()]
            if len(lines) >= 2 and "|" in lines[0] and re.match(r'^[\|\s:-]+$', lines[1]):
                table_html = self._parse_table(lines)
                parsed_blocks.append(table_html)
                i += 1
                continue

            if block.startswith(">"):
                quote_html = self._parse_blockquote(block)
                parsed_blocks.append(quote_html)
                i += 1
                continue

            if re.match(r'^(?:---|\*\*\*|___)$', block):
                parsed_blocks.append('<hr class="divider">')
                i += 1
                continue

            if re.match(r'^(\*|-|\d+\.)\s+', lines[0]):
                list_html = self._parse_list(block)
                parsed_blocks.append(list_html)
                i += 1
                continue

            p_html = self._parse_paragraph(block)
            parsed_blocks.append(p_html)
            i += 1

        result = "\n".join(parsed_blocks)

        for k, v in placeholders.items():
            result = result.replace(k, v)

        return result

    def _parse_heading(self, level: int, text: str) -> str:
        clean_text = re.sub(r'\s+', ' ', text).strip()
        
        # Clean text for TOC & slug by resolving raw tokens
        plain_title = clean_text
        for k, v in self.raw_text.items():
            plain_title = plain_title.replace(k, v)
        clean_title = re.sub(r'[*_`$~]', '', plain_title)

        if level == 1 and not self.first_h1_found:
            self.first_h1_found = True
            self.title = clean_title
            return f'<h1 class="doc-title">{self._parse_inline(clean_text)}</h1>'

        slug = slugify(clean_title)

        extra_anchor = ""
        is_evidence = any(w in clean_title.lower() for w in ["evidence", "scientific references", "references & sources"])
        if is_evidence:
            extra_anchor = '<a id="evidence" class="anchor-target"></a>'

        if level in (2, 3):
            self.toc.append((level, slug, clean_title))

        rendered_text = self._parse_inline(clean_text)
        # Anchor is placed AFTER text so it never prefixes heading if CSS is missing
        return f'<h{level} id="{slug}" class="doc-h{level}">{extra_anchor}{rendered_text}<a href="#{slug}" class="header-anchor" aria-label="Link to section">#</a></h{level}>'

    def _parse_blockquote(self, block: str) -> str:
        cleaned_lines = []
        for line in block.split("\n"):
            line = line.strip()
            if line.startswith(">"):
                line = line[1:].strip()
            cleaned_lines.append(line)

        content = " ".join(cleaned_lines)

        alert_match = re.match(r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*)$', content, flags=re.IGNORECASE)
        if alert_match:
            alert_type = alert_match.group(1).lower()
            inner_text = alert_match.group(2)
            title = alert_match.group(1).capitalize()
            return (
                f'<div class="callout callout-{alert_type}">'
                f'<div class="callout-title"><span class="callout-badge">{title}</span></div>'
                f'<div class="callout-body">{self._parse_inline(inner_text)}</div>'
                f'</div>'
            )

        if "disclaimer" in content.lower():
            return (
                f'<div class="callout callout-warning">'
                f'<div class="callout-title"><span class="callout-badge">Disclaimer</span></div>'
                f'<div class="callout-body">{self._parse_inline(content)}</div>'
                f'</div>'
            )

        return f'<blockquote><p>{self._parse_inline(content)}</p></blockquote>'

    def _parse_table(self, lines: list) -> str:
        header_line = lines[0].strip("|").split("|")
        headers = [h.strip() for h in header_line]
        
        align_line = lines[1].strip("|").split("|")
        alignments = []
        for a in align_line:
            a = a.strip()
            if a.startswith(":") and a.endswith(":"):
                alignments.append(' style="text-align:center"')
            elif a.endswith(":"):
                alignments.append(' style="text-align:right"')
            elif a.startswith(":"):
                alignments.append(' style="text-align:left"')
            else:
                alignments.append('')

        rows = []
        for l in lines[2:]:
            cols = [c.strip() for c in l.strip("|").split("|")]
            rows.append(cols)

        out = ['<div class="table-responsive"><table class="doc-table"><thead><tr>']
        for idx, h in enumerate(headers):
            style = alignments[idx] if idx < len(alignments) else ''
            out.append(f'<th{style}>{self._parse_inline(h)}</th>')
        out.append('</tr></thead><tbody>')

        for row in rows:
            out.append('<tr>')
            for idx, c in enumerate(row):
                style = alignments[idx] if idx < len(alignments) else ''
                out.append(f'<td{style}>{self._parse_inline(c)}</td>')
            out.append('</tr>')

        out.append('</tbody></table></div>')
        return "".join(out)

    def _parse_list(self, block: str) -> str:
        lines = block.split("\n")
        is_ordered = bool(re.match(r'^\d+\.', lines[0].strip()))
        tag = "ol" if is_ordered else "ul"
        
        items = []
        for line in lines:
            line_str = line.strip()
            if not line_str:
                continue
            item_content = re.sub(r'^(\*|-|\d+\.)\s+', '', line_str)
            items.append(f'<li>{self._parse_inline(item_content)}</li>')

        return f'<{tag} class="doc-list">\n' + "\n".join(items) + f'\n</{tag}>'

    def _parse_paragraph(self, block: str) -> str:
        text = " ".join(line.strip() for line in block.split("\n") if line.strip())
        return f'<p>{self._parse_inline(text)}</p>'

    def _parse_inline(self, text: str) -> str:
        # Step 1: Strikethrough
        text = re.sub(r'~~(.*?)~~', r'<del>\1</del>', text)

        # Step 2: Bold
        text = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', text)
        text = re.sub(r'(?<!\w)__(.*?)(?<!\s)__(?!\w)', r'<strong>\1</strong>', text)

        # Step 3: Italic
        text = re.sub(r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)', r'<em>\1</em>', text)
        text = re.sub(r'(?<!\w)_(?!\s)(.*?)(?<!\s)_(?!\w)', r'<em>\1</em>', text)

        # Step 4: Links
        def link_repl(match):
            link_text = match.group(1)
            target = match.group(2).strip()

            clean_target = target.split("#")[0]
            anchor = ("#" + target.split("#")[1]) if "#" in target else ""

            # Check if link points to repository files (lib, script, TELEMETRY)
            clean_norm = clean_target.lstrip("./").lstrip("../")
            if clean_norm.startswith("lib/") or clean_norm.startswith("script/") or clean_norm.endswith(".js") or clean_norm.endswith(".dart") or clean_norm.endswith(".py") or "telemetry" in clean_norm.lower():
                gh_url = f"https://github.com/rfivesix/train-libre/blob/main/{clean_norm}"
                return f'<a href="{gh_url}" target="_blank" rel="noopener noreferrer">{link_text} <span class="ext-icon">↗</span></a>'

            if clean_target in TARGET_MAP:
                target_out = TARGET_MAP[clean_target]["out_dir"] / "index.html"
                rel_url = os.path.relpath(target_out, self.current_out_dir)
                return f'<a href="{rel_url}{anchor}">{link_text}</a>'
            elif clean_target.endswith(".md"):
                # Fallback relative resolution
                base_name = clean_target.replace("../", "").replace(".md", "").replace("_", "-")
                return f'<a href="{base_name}/{anchor}">{link_text}</a>'
            elif target.startswith("http://") or target.startswith("https://"):
                return f'<a href="{target}" target="_blank" rel="noopener noreferrer">{link_text} <span class="ext-icon">↗</span></a>'
            else:
                return f'<a href="{target}">{link_text}</a>'

        # Markdown link destinations may contain a balanced parenthesis, as is
        # common in DOI URLs such as `S0140-6736(11)60812-X`. A plain
        # `[^)]` matcher would truncate those links at the first parenthesis.
        text = re.sub(
            r'\[([^\]]+)\]\(((?:[^()]|\([^()]*\))*)\)',
            link_repl,
            text,
        )

        return text


def build_page_html(
    title: str,
    description: str,
    content_html: str,
    toc: list,
    current_item: dict,
    prev_item: dict = None,
    next_item: dict = None
) -> str:
    """Wrap content in full responsive Train Libre documentation HTML template with RELATIVE asset paths."""

    current_out_dir = current_item["out_dir"]

    # Calculate exact relative paths to key directories
    rel_to_docs = os.path.relpath(DOCS_DIR, current_out_dir)
    rel_to_suite = os.path.relpath(OUTPUT_DOCS_DIR, current_out_dir)

    style_href = f"{rel_to_docs}/style.css"
    docs_css_href = f"{rel_to_suite}/docs.css"
    katex_css_href = f"{rel_to_docs}/katex.min.css"
    favicon_href = f"{rel_to_docs}/favicon.png?v=2"
    apple_icon_href = f"{rel_to_docs}/assets/apple-touch-icon.png"

    home_href = f"{rel_to_docs}/index.html"
    docs_root_href = f"{rel_to_suite}/index.html"

    # Generate sidebar HTML with exact relative links
    sidebar_sections = []
    for cat in DOCS_STRUCTURE:
        cat_name = cat["category"]
        links = []
        for itm in cat["items"]:
            is_active = (itm["id"] == current_item["id"])
            active_cls = ' class="sidebar-link active" aria-current="page"' if is_active else ' class="sidebar-link"'
            rel_link = os.path.relpath(itm["out_dir"] / "index.html", current_out_dir)
            links.append(f'<li><a href="{rel_link}"{active_cls}>{html.escape(itm["title"])}</a></li>')
        
        sidebar_sections.append(
            f'<div class="sidebar-group">'
            f'<div class="sidebar-group-title">{html.escape(cat_name)}</div>'
            f'<ul class="sidebar-nav-list">\n' + "\n".join(links) + f'\n</ul></div>'
        )

    sidebar_html = "\n".join(sidebar_sections)

    # Generate TOC HTML
    toc_links = []
    for level, slug, h_title in toc:
        indent_cls = f"toc-item-l{level}"
        toc_links.append(f'<li class="toc-item {indent_cls}"><a href="#{slug}">{html.escape(h_title)}</a></li>')

    toc_html = ""
    if toc_links:
        toc_html = (
            f'<aside class="docs-toc" aria-label="Table of contents">'
            f'<div class="toc-sticky-box">'
            f'<div class="toc-heading">On this page</div>'
            f'<ul class="toc-list">\n' + "\n".join(toc_links) + f'\n</ul>'
            f'</div></aside>'
        )

    # Breadcrumb
    breadcrumb_parts = [
        f'<a href="{home_href}">Home</a>',
        f'<a href="{docs_root_href}">Docs</a>'
    ]
    if "/features/" in current_item["url"]:
        breadcrumb_parts.append('<span>Features &amp; Heuristics</span>')
    elif "/developer/" in current_item["url"]:
        breadcrumb_parts.append('<span>Developer</span>')
    breadcrumb_html = ' <span class="bc-sep">/</span> '.join(breadcrumb_parts)

    # Prev / Next pagination
    pager_html = []
    if prev_item or next_item:
        pager_html.append('<nav class="docs-pager" aria-label="Documentation navigation">')
        if prev_item:
            prev_rel = os.path.relpath(prev_item["out_dir"] / "index.html", current_out_dir)
            pager_html.append(
                f'<a href="{prev_rel}" class="pager-card pager-prev">'
                f'<span class="pager-label">← Previous</span>'
                f'<span class="pager-title">{html.escape(prev_item["title"])}</span>'
                f'</a>'
            )
        else:
            pager_html.append('<div></div>')

        if next_item:
            next_rel = os.path.relpath(next_item["out_dir"] / "index.html", current_out_dir)
            pager_html.append(
                f'<a href="{next_rel}" class="pager-card pager-next">'
                f'<span class="pager-label">Next →</span>'
                f'<span class="pager-title">{html.escape(next_item["title"])}</span>'
                f'</a>'
            )
        pager_html.append('</nav>')

    pager_markup = "\n".join(pager_html)

    return f"""<!doctype html>
<html lang="en" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{html.escape(description)}">
  <title>{html.escape(title)} | Train Libre Documentation</title>
  <link rel="canonical" href="https://trainlibre.com{current_item['url']}">

  <link rel="icon" type="image/png" sizes="32x32" href="{favicon_href}">
  <link rel="apple-touch-icon" sizes="180x180" href="{apple_icon_href}">

  <!-- Open Graph -->
  <meta property="og:site_name" content="Train Libre Documentation">
  <meta property="og:title" content="{html.escape(title)} | Train Libre">
  <meta property="og:description" content="{html.escape(description)}">
  <meta property="og:url" content="https://trainlibre.com{current_item['url']}">
  <meta property="og:type" content="article">
  <meta property="og:image" content="https://trainlibre.com/assets/og-image.png">

  <!-- KaTeX CSS (CDN primary with local fallback) -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.css">
  <link rel="stylesheet" href="{katex_css_href}">

  <!-- Train Libre Design System & Dedicated Docs Styles -->
  <link rel="stylesheet" href="{style_href}">
  <link rel="stylesheet" href="{docs_css_href}">

  <!-- KaTeX Auto-render Script -->
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.js" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/contrib/auto-render.min.js" defer onload="renderMathInElement(document.body, {{
    delimiters: [
      {{left: '$$', right: '$$', display: true}},
      {{left: '$', right: '$', display: false}}
    ],
    throwOnError: false
  }});"></script>

  <!-- Mermaid.js for Architecture Diagrams -->
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <script>
    document.addEventListener("DOMContentLoaded", () => {{
      if (typeof mermaid !== "undefined") {{
        const isDark = document.documentElement.getAttribute("data-theme") !== "light";
        mermaid.initialize({{
          startOnLoad: true,
          theme: isDark ? "dark" : "default",
          themeVariables: isDark ? {{
            darkMode: true,
            background: "#151815",
            primaryColor: "#1b1f1b",
            primaryTextColor: "#f4f6f4",
            primaryBorderColor: "rgba(221, 255, 0, 0.4)",
            lineColor: "#ddff00",
            secondaryColor: "#151815",
            tertiaryColor: "#0e100e"
          }} : {{}}
        }});
      }}
    }});
  </script>

  <!-- Prevent Theme Flash -->
  <script>
    (function () {{
      const theme = localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: light)').matches ? "light" : "dark");
      document.documentElement.setAttribute("data-theme", theme);
    }})();
  </script>
</head>
<body class="docs-body">
  <div class="page">
    <!-- Header -->
    <header class="docs-header">
      <nav class="docs-nav" aria-label="Documentation navigation">
        <a class="brand" href="{home_href}" aria-label="Train Libre Home">
          <span class="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 270.933 270.933" role="img">
              <path fill="#ddff00"
                d="M47.621 39.688c-4.385 0-7.939 3.554-7.939 7.939v116.172c0 37.238 30.188 67.472 67.426 67.459l13.482-.006c.15.003.3.005.451.005h89.722c11.367 0 20.518-9.154 20.518-20.525s-9.151-20.525-20.518-20.525h-42.739a7.937 7.937 0 0 1-7.937-7.937v-25.174a7.937 7.937 0 0 1 7.937-7.937l41.159-.001c12.244 0 22.101-9.154 22.1-20.525-.001-11.371-9.859-20.525-22.103-20.525l-41.156.001a7.937 7.937 0 0 1-7.937-7.937V47.627c0-4.385-3.555-7.939-7.939-7.939z" />
            </svg>
          </span>
          <span class="brand-name">Train Libre</span>
          <span class="docs-badge">Docs</span>
        </a>

        <div class="nav-links">
          <a href="{home_href}" class="nav-link">Website</a>
          <a class="nav-priority" href="https://github.com/rfivesix/train-libre" target="_blank" rel="noreferrer">GitHub</a>
        </div>

        <div class="nav-controls">
          <button id="theme-toggle" class="control-btn" aria-label="Toggle Theme">
            <svg class="sun-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="5"></circle>
              <line x1="12" y1="1" x2="12" y2="3"></line>
              <line x1="12" y1="21" x2="12" y2="23"></line>
              <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
              <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
              <line x1="1" y1="12" x2="3" y2="12"></line>
              <line x1="21" y1="12" x2="23" y2="12"></line>
              <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
              <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
            </svg>
            <svg class="moon-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
            </svg>
          </button>
          
          <button id="sidebar-toggle" class="control-btn mobile-menu-btn" aria-label="Open sidebar menu" aria-expanded="false">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
        </div>
      </nav>
    </header>

    <!-- Docs Main Layout -->
    <div class="docs-container">
      <!-- Left Sidebar -->
      <aside id="docs-sidebar" class="docs-sidebar" aria-label="Documentation sidebar">
        <div class="sidebar-header-search">
          <input type="text" id="sidebar-filter" placeholder="Filter topics..." aria-label="Filter topics in documentation">
        </div>
        <div class="sidebar-scroll-area">
          {sidebar_html}
        </div>
      </aside>

      <!-- Center Article Content -->
      <main class="docs-main" id="main-content">
        <div class="docs-breadcrumb" aria-label="Breadcrumb">
          {breadcrumb_html}
        </div>

        <article class="docs-article">
          {content_html}
        </article>

        {pager_markup}
      </main>

      <!-- Right Table of Contents -->
      {toc_html}
    </div>

    <!-- Footer (100% harmonized with main website footer) -->
    <footer class="site-footer">
      <div>
        <a class="brand" href="{home_href}" aria-label="Train Libre home">
          <span class="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 270.933 270.933" role="img">
              <path fill="#ddff00"
                d="M47.621 39.688c-4.385 0-7.939 3.554-7.939 7.939v116.172c0 37.238 30.188 67.472 67.426 67.459l13.482-.006c.15.003.3.005.451.005h89.722c11.367 0 20.518-9.154 20.518-20.525s-9.151-20.525-20.518-20.525h-42.739a7.937 7.937 0 0 1-7.937-7.937v-25.174a7.937 7.937 0 0 1 7.937-7.937l41.159-.001c12.244 0 22.101-9.154 22.1-20.525-.001-11.371-9.859-20.525-22.103-20.525l-41.156.001a7.937 7.937 0 0 1-7.937-7.937V47.627c0-4.385-3.555-7.939-7.939-7.939z" />
            </svg>
          </span>
          <span>Train Libre</span>
        </a>
        <p class="fine-print">Fitness, nutrition, recovery, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions (such as eating or sleep disorders).</p>
      </div>
      <div class="footer-links">
        <a href="{docs_root_href}">Documentation</a>
        <a href="{rel_to_docs}/privacy.html">Privacy Policy</a>
        <a href="{rel_to_docs}/terms.html">Terms of Service</a>
        <a href="{rel_to_docs}/impressum.html">Imprint</a>
        <a href="{rel_to_docs}/support.html">Support</a>
        <a href="https://github.com/rfivesix/train-libre" data-link="github" target="_blank" rel="noreferrer">GitHub</a>
      </div>
    </footer>
  </div>

  <!-- Documentation Interactions Script -->
  <script>
    // Theme toggle interaction
    const themeBtn = document.getElementById("theme-toggle");
    if (themeBtn) {{
      themeBtn.addEventListener("click", () => {{
        const current = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
        document.documentElement.setAttribute("data-theme", current);
        localStorage.setItem("theme", current);
        if (typeof mermaid !== "undefined") {{
          const mNodes = document.querySelectorAll(".mermaid");
          if (mNodes.length > 0) {{
            mNodes.forEach(node => {{
              if (node.hasAttribute("data-mermaid")) {{
                node.removeAttribute("data-processed");
                node.innerHTML = node.getAttribute("data-mermaid");
              }}
            }});
            mermaid.initialize({{
              startOnLoad: false,
              theme: current === "light" ? "default" : "dark"
            }});
            mermaid.run();
          }}
        }}
      }});
    }}

    // Mobile sidebar toggle
    const sidebarToggle = document.getElementById("sidebar-toggle");
    const sidebar = document.getElementById("docs-sidebar");
    if (sidebarToggle && sidebar) {{
      sidebarToggle.addEventListener("click", () => {{
        const expanded = sidebar.classList.toggle("open");
        sidebarToggle.setAttribute("aria-expanded", expanded);
      }});

      document.addEventListener("click", (e) => {{
        if (sidebar.classList.contains("open") && !sidebar.contains(e.target) && !sidebarToggle.contains(e.target)) {{
          sidebar.classList.remove("open");
          sidebarToggle.setAttribute("aria-expanded", "false");
        }}
      }});
    }}

    // Sidebar filter/search
    const filterInput = document.getElementById("sidebar-filter");
    if (filterInput) {{
      filterInput.addEventListener("input", (e) => {{
        const val = e.target.value.toLowerCase().trim();
        document.querySelectorAll(".sidebar-nav-list li").forEach(li => {{
          const text = li.textContent.toLowerCase();
          li.style.display = text.includes(val) ? "" : "none";
        }});
        document.querySelectorAll(".sidebar-group").forEach(group => {{
          const hasVisible = Array.from(group.querySelectorAll("li")).some(li => li.style.display !== "none");
          group.style.display = hasVisible ? "" : "none";
        }});
      }});
    }}

    // Scroll-spy for Table of Contents
    const tocItems = document.querySelectorAll(".toc-list a");
    if (tocItems.length > 0) {{
      const headingElements = Array.from(tocItems).map(a => {{
        const id = a.getAttribute("href").substring(1);
        return document.getElementById(id);
      }}).filter(Boolean);

      const observer = new IntersectionObserver((entries) => {{
        entries.forEach(entry => {{
          if (entry.isIntersecting) {{
            const id = entry.target.getAttribute("id");
            tocItems.forEach(a => {{
              if (a.getAttribute("href") === "#" + id) {{
                a.classList.add("active");
              }} else {{
                a.classList.remove("active");
              }}
            }});
          }}
        }});
      }}, {{ rootMargin: "0px 0px -70% 0px", threshold: 0.1 }});

      headingElements.forEach(h => observer.observe(h));
    }}
  </script>
</body>
</html>
"""


def build_redirect_stub(rel_target: str, canonical_url: str, title: str) -> str:
    """Creates a lightweight, hash-preserving redirect HTML page with relative target."""
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Redirecting to {html.escape(title)} — Train Libre Documentation</title>
  <meta http-equiv="refresh" content="0; url={rel_target}">
  <link rel="canonical" href="{canonical_url}">
  <script>
    (function () {{
      var hash = window.location.hash || '';
      window.location.replace('{rel_target}' + hash);
    }})();
  </script>
</head>
<body style="background:#070807;color:#f4f6f4;font-family:-apple-system,BlinkMacSystemFont,sans-serif;padding:60px 20px;text-align:center;">
  <p style="font-size:1.1rem;">Redirecting to <a href="{rel_target}" style="color:#ddff00;text-decoration:underline;">{html.escape(title)} Documentation</a>...</p>
</body>
</html>
"""


def main():
    print("🚀 Starting Train Libre Documentation Build...")

    all_items = []
    for cat in DOCS_STRUCTURE:
        for itm in cat["items"]:
            all_items.append(itm)

    for idx, item in enumerate(all_items):
        src_file = item["src_file"]
        out_dir = item["out_dir"]
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / "index.html"

        if not src_file.exists():
            print(f"⚠️  Warning: Source file not found: {src_file}")
            continue

        raw_md = src_file.read_text(encoding="utf-8")
        parser = MarkdownParser(current_out_dir=out_dir)
        content_html = parser.parse(raw_md)

        prev_item = all_items[idx - 1] if idx > 0 else None
        next_item = all_items[idx + 1] if idx < len(all_items) - 1 else None

        page_html = build_page_html(
            title=parser.title or item["title"],
            description=item["desc"],
            content_html=content_html,
            toc=parser.toc,
            current_item=item,
            prev_item=prev_item,
            next_item=next_item
        )

        out_file.write_text(page_html, encoding="utf-8")
        print(f"✅ Generated: {item['url']} -> {out_file.relative_to(REPO_ROOT)}")

    redirects = [
        ("sleep-score", OUTPUT_DOCS_DIR / "features" / "sleep-scoring-engine", "/docs/features/sleep-scoring-engine/", "Sleep Health Score"),
        ("recovery", OUTPUT_DOCS_DIR / "features" / "muscle-recovery-model", "/docs/features/muscle-recovery-model/", "Muscle Recovery"),
        ("intelligent-workouts", OUTPUT_DOCS_DIR / "features" / "intelligent-workouts", "/docs/features/intelligent-workouts/", "Intelligent Workouts"),
        ("adaptive-nutrition", OUTPUT_DOCS_DIR / "features" / "bayesian-tdee-estimator", "/docs/features/bayesian-tdee-estimator/", "Adaptive Nutrition"),
        ("ai-nutrition", OUTPUT_DOCS_DIR / "features" / "meal-capture-pipeline", "/docs/features/meal-capture-pipeline/", "AI Nutrition"),
    ]

    for legacy_folder, target_dir, target_canonical, title in redirects:
        folder_path = DOCS_DIR / legacy_folder
        folder_path.mkdir(parents=True, exist_ok=True)
        stub_file = folder_path / "index.html"
        rel_target = os.path.relpath(target_dir, folder_path) + "/"
        canonical_url = f"https://trainlibre.com{target_canonical}"
        stub_html = build_redirect_stub(rel_target, canonical_url, title)
        stub_file.write_text(stub_html, encoding="utf-8")
        print(f"🔄 Created redirect: /{legacy_folder}/ -> {rel_target}")

    print("✨ Train Libre Documentation Build Completed Successfully!")


if __name__ == "__main__":
    main()
