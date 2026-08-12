# "What's New" – User-Facing Release Notes

This folder is the **single source** for two things:

1. the in-app "What's New" sheet shown automatically after an update
2. the `## Release Notes` section in `metadata/app_store/<locale>.md`
   (the App Store "What's New" text)

The technical history stays in `CHANGELOG.md` — that one is for developers.
What goes here are short, user-readable texts.

## Where do I write?

One file per store locale:

| File | App language |
|---|---|
| `en-US.md` | `en` (fallback for every language without its own file) |
| `en-GB.md` | – (App Store only) |
| `de-DE.md` | `de` |
| `fr-FR.md` | `fr` |
| `it.md` | `it` |
| `ja.md` | `ja` |

## Format

```markdown
## 1.0.3 (2026-09-01)

{cloud} iCloud Backup: Your data now backs up automatically to iCloud.

{zap} Noticeably smoother: Faster navigation in Diary and Statistics.
```

- `## <version> (<YYYY-MM-DD>)` — the version must match `pubspec.yaml`
  **exactly** (without the `+buildnumber`). Newest version at the top.
- One paragraph = one entry. Separate paragraphs with a blank line.
- A leading `{icon}` is optional and picks the symbol shown in the app.
  Without it, `sparkles` is used. Allowed names live in
  `script/build_whats_new.py` (`ICON_MAP`) — among them `sparkles cloud zap
  layout_grid smartphone mic activity shield bug bell timer dumbbell heart star
  rocket lock chart_line utensils moon footprints camera watch circle_check`.
- Everything before the first `: ` is the **headline**, the rest is the
  description. Without a colon the whole paragraph is rendered as the headline.
- 3–5 entries per release. User-visible changes only, no refactorings.

## After writing

```bash
python3 script/build_whats_new.py --write --sync-store
```

- `--write` generates `lib/features/whats_new/domain/whats_new_content.g.dart`
  (never edit that file by hand).
- `--sync-store` writes the same texts, with the `{icon}` tokens stripped, into
  `metadata/app_store/<locale>.md`.

`script/deploy_release.sh` runs `python3 script/build_whats_new.py --check`
before it builds anything and asks for confirmation if the release notes for the
current version are missing or differ from the App Store metadata.
