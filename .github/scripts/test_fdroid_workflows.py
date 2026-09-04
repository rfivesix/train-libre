"""Offline regression checks: python3 .github/scripts/test_fdroid_workflows.py.

Requires PyYAML, bash, and jq. Does not publish, download APKs, or use secrets.
"""

import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
import zipfile

import yaml


ROOT = Path(__file__).resolve().parents[2]
URL = "https://trainlibre.com/fdroid/repo"
FINGERPRINT = "759124FF05FDCFA070EB2475D86D79614AE4F58779E391C8AE44C4EDC7A2CFB8"


def workflow(name):
    # BaseLoader preserves GitHub's `on` key (YAML 1.1 treats it as a boolean).
    return yaml.load(
        (ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader
    )


FDROID = workflow("fdroid-repo.yml")
DOCS = workflow("deploy-docs.yml")
STEPS = FDROID["jobs"]["update-fdroid-repo"]["steps"]


def step(name):
    return next(item for item in STEPS if item["name"] == name)


def run_script(script, directory, **environment):
    return subprocess.run(
        ["bash", "-e", "-o", "pipefail", "-c", script],
        cwd=directory,
        env={**os.environ, **environment},
        capture_output=True,
        text=True,
    )


class FdroidWorkflowTests(unittest.TestCase):
    def test_single_release_trigger_and_shared_publish_lock(self):
        self.assertEqual(FDROID["on"]["release"]["types"], ["published"])
        self.assertIn("workflow_dispatch", FDROID["on"])
        self.assertEqual(FDROID["concurrency"], DOCS["concurrency"])
        self.assertEqual(FDROID["concurrency"]["cancel-in-progress"], "false")
        self.assertEqual(FDROID["concurrency"]["group"], "gh-pages-publish")
        self.assertEqual(FDROID["concurrency"]["queue"], "max")
        self.assertIn(
            ".github/workflows/deploy-docs.yml", DOCS["on"]["push"]["paths"]
        )

    def test_domain_and_fingerprint_are_consistent(self):
        self.assertEqual((ROOT / "docs/CNAME").read_text().strip(), "trainlibre.com")
        for filename in ["README.md", "docs/index.html", "docs/script.js"]:
            with self.subTest(filename=filename):
                content = (ROOT / filename).read_text()
                self.assertIn(f"{URL}?fingerprint={FINGERPRINT}", content)
                self.assertNotIn("rfivesix.github.io/train-libre/fdroid", content)
        self.assertIn(f'REPO_URL="{URL}"', step("Configure F-Droid settings")["run"])

    def test_embedded_shell_and_python_syntax(self):
        for definition in [FDROID, DOCS]:
            for job in definition["jobs"].values():
                for item in job["steps"]:
                    if "run" not in item:
                        continue
                    with self.subTest(step=item["name"]):
                        result = subprocess.run(
                            ["bash", "-n"], input=item["run"], text=True,
                            capture_output=True,
                        )
                        self.assertEqual(result.returncode, 0, result.stderr)
                        tokens = shlex.split(item["run"])
                        for index, token in enumerate(tokens[:-2]):
                            if token == "python3" and tokens[index + 1] == "-c":
                                compile(tokens[index + 2], item["name"], "exec")

    def test_manual_and_event_release_resolution(self):
        mock = '''
        gh() {
          printf '%s\\n' "$@" > "$RUNNER_TEMP/gh-args"
          printf '%s' '{"tagName":"v1.2.1","body":"Release notes"}'
        }
        '''
        for tag in ["", "v1.2.1"]:
            with self.subTest(tag=tag), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / "outputs"
                result = run_script(
                    mock + step("Resolve release")["run"], directory,
                    RUNNER_TEMP=directory, GITHUB_OUTPUT=str(output), RELEASE_TAG=tag,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(output.read_text(), "tag=v1.2.1\n")
                args = (Path(directory) / "gh-args").read_text().splitlines()
                self.assertEqual(args, ["release", "view"] + ([tag] if tag else [])
                                 + ["--json", "tagName,body"])
        self.assertEqual(
            step("Checkout release metadata")["with"]["ref"],
            "refs/tags/${{ steps.release.outputs.tag }}",
        )
        download = step("Download Release APKs")
        self.assertEqual(download["env"]["TAG_NAME"], "${{ steps.release.outputs.tag }}")
        self.assertIn('gh release download "$TAG_NAME"', download["run"])

    def test_metadata_comes_from_release_not_workflow_branch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / "release-source"
            changelogs = release / "fastlane/metadata/android/en-US/changelogs"
            changelogs.mkdir(parents=True)
            (root / "fdroid/metadata").mkdir(parents=True)
            (root / "pubspec.yaml").write_text("version: 9.9.9+999\n")
            (release / "pubspec.yaml").write_text("version: 1.2.1+121\n")
            (root / "fdroid-release.json").write_text(json.dumps({
                "tagName": "v1.2.1", "body": "Release notes\nwith 'quotes' and $text"
            }))
            result = run_script(
                step("Dynamic Changelog Injection & Fastlane Metadata Bridge")["run"],
                directory, RUNNER_TEMP=directory,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            for path in [
                "fdroid/fastlane/metadata/android/en-US/changelogs",
                "fdroid/metadata/com.rfivesix.trainlibre/metadata/android/en-US/changelogs",
            ]:
                self.assertEqual(
                    (root / path / "121.txt").read_text(),
                    "Release notes\nwith 'quotes' and $text",
                )
                self.assertFalse((root / path / "999.txt").exists())

    def test_app_store_screenshot_selection(self):
        for case in ["bilingual", "english-only", "missing-english", "gap", "duplicate"]:
            with self.subTest(case=case), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / "release-source/ios/fastlane/screenshots"
                destinations = [
                    root / "fdroid/fastlane/metadata/android",
                    root / "fdroid/metadata/com.rfivesix.trainlibre/metadata/android",
                ]
                for locale in ["de-DE", "en-US", "en-GB"]:
                    folder = source / locale
                    folder.mkdir(parents=True)
                    for number in range(1, 8):
                        if not (case == "missing-english" and locale == "en-US") and not (
                            case == "english-only" and locale == "de-DE"
                        ) and not (case == "gap" and number == 3):
                            (folder / f"1320x2868_{number:02d}-device-bottom.png").write_bytes(
                                f"marketing-{locale}-{number}".encode()
                            )
                        (folder / f"1125x2436_{number:02d}-device-bottom.png").write_bytes(b"other-resolution")
                    for destination in destinations:
                        old = destination / locale / "images/phoneScreenshots"
                        old.mkdir(parents=True)
                        (old / "old.png").write_bytes(b"raw-screenshot")
                        (old / "old.jpg").write_bytes(b"raw-screenshot-jpeg")
                        (old.parent / "icon.png").write_bytes(b"keep-icon")
                if case == "duplicate":
                    (source / "en-US/1320x2868_01-device-top.png").write_bytes(b"duplicate")
                result = run_script(step("Copy App Store marketing screenshots")["run"], directory)
                if case in ["missing-english", "gap", "duplicate"]:
                    self.assertNotEqual(result.returncode, 0)
                    continue
                self.assertEqual(result.returncode, 0, result.stderr)
                for destination in destinations:
                    for locale in ["en-US", "de-DE", "en-GB"]:
                        folder = destination / locale / "images/phoneScreenshots"
                        expected_count = 7 if locale == "en-US" or (
                            locale == "de-DE" and case == "bilingual"
                        ) else 0
                        self.assertEqual(len(list(folder.iterdir())), expected_count)
                        for number in range(1, expected_count + 1):
                            self.assertEqual(
                                (folder / f"{number:02d}.png").read_bytes(),
                                f"marketing-{locale}-{number}".encode(),
                            )
                        self.assertEqual((folder.parent / "icon.png").read_bytes(), b"keep-icon")
                self.assertTrue((source / "en-US/1320x2868_01-device-bottom.png").exists())

    def test_generated_repository_validation(self):
        # These fixture ZIPs test structure/hash validation, not cryptographic signatures.
        for case in ["valid", "old-domain", "wrong-hash", "wrong-size", "missing-app", "missing-v1"]:
            with self.subTest(case=case), tempfile.TemporaryDirectory() as directory:
                repo = Path(directory) / "fdroid/repo"
                repo.mkdir(parents=True)
                index = json.dumps({
                    "repo": {"address": URL if case != "old-domain" else "https://rfivesix.github.io/train-libre/fdroid/repo"},
                    "packages": {} if case == "missing-app" else {"com.rfivesix.trainlibre": {}},
                }).encode()
                (repo / "index-v2.json").write_bytes(index)
                entry = {"index": {
                    "name": "/index-v2.json",
                    "sha256": "bad" if case == "wrong-hash" else hashlib.sha256(index).hexdigest(),
                    "size": 0 if case == "wrong-size" else len(index),
                }}
                with zipfile.ZipFile(repo / "entry.jar", "w") as archive:
                    archive.writestr("entry.json", json.dumps(entry))
                if case != "missing-v1":
                    (repo / "index-v1.jar").touch()
                result = run_script(step("Validate generated repository")["run"], directory)
                self.assertEqual(result.returncode == 0, case == "valid", result.stderr)


if __name__ == "__main__":
    unittest.main()
