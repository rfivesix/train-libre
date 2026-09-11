# Train Libre Website & Documentation

This directory is the deployable public website for [Train Libre](https://trainlibre.com/).
It contains the landing page, public feature explainers, legal pages, assets, and
the publishing configuration for GitHub Pages.

The documentation content itself is deliberately split by audience in the
repository's [`documentation/`](../documentation/README.md) directory:

- [`documentation/features/`](../documentation/features/overview.md) explains
  Train Libre's user-facing features, mathematical models, privacy boundaries,
  and their limitations.
- [`documentation/developer/`](../documentation/developer/overview.md) is for
  contributors and documents the app architecture, state and data flow,
  localization, and platform integrations.

The public website should expose both areas under one documentation experience.
The source folders above remain the canonical organisation of their content.

## Public feature pages

The currently published feature explainers are:

- [Adaptive Nutrition](adaptive-nutrition/)
- [AI Meal Recognition](ai-nutrition/)
- [Recovery Tracker](recovery/)
- [Sleep Health Score](sleep-score/)
- [Estimated 1RM](intelligent-workouts/)

Do not add links here to planned or removed pages. Add a public page only once
its corresponding files are present in `docs/`.

## Website and F-Droid publishing

The public website is hosted at `https://trainlibre.com/`. GitHub Pages serves
the root of `gh-pages`; `docs/CNAME` preserves the custom domain when the website
is deployed. The F-Droid repository is at `https://trainlibre.com/fdroid/repo`.

- `deploy-docs.yml` publishes changes to `docs/` on `main`, changes to that
  workflow itself, or a manual dispatch.
- `fdroid-repo.yml` runs once on release publication, or on manual dispatch.
  A manual dispatch resolves the latest release once and uses its tag for APKs,
  version information, store metadata, screenshots, and release notes. The
  workflow and F-Droid configuration still come from the selected workflow ref.
- F-Droid uses the App Store marketing screenshots from
  `ios/fastlane/screenshots` at that release tag, not the raw iOS screenshots.
  Only the `1320x2868` set is copied, in numbered order, for `en-US` and `de-DE`.
  Other resolutions and the duplicate `en-GB` set are excluded. English is
  required; if German is absent, only the English default is published. Old
  phone screenshots are removed from the generated metadata before copying.
- Both workflows share the `gh-pages-publish` concurrency group to prevent
  competing pushes. Keep the group identical and do not cancel active publishes.
  `queue: max` lets multiple pending publishes wait without replacing each other.
- Keep the existing F-Droid signing secrets and repository fingerprint unchanged.
  Regenerate indexes with `fdroid update`; never edit the published JSON by hand,
  because the signed entry contains the index hash and size.

For a repository/domain hotfix, first put the workflow changes on `main`, then
manually dispatch **Update F-Droid Repository** with `main` selected. Rerunning an
old release job uses its old workflow, not the corrected one. Confirm that both
the docs and F-Droid publishes finish successfully, then check the live repository
address, signed indexes, APK downloads, and adding/updating the repo in F-Droid.

Offline regression checks (requires Python, PyYAML, bash, and jq):

```sh
python3 .github/scripts/test_fdroid_workflows.py
```

These tests use fixtures and do not validate live TLS, real signatures, or Android
client behavior. The F-Droid workflow also runs them before generating the index.
