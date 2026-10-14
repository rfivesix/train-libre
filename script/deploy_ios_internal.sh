#!/bin/bash
set -euo pipefail

# Build and upload the current pubspec version to TestFlight internal testing.
# The build number is advanced only after Apple accepts the upload, leaving
# pubspec.yaml ready for the next run.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: iOS archive and App Store Connect upload require macOS."
  exit 1
fi

for command in flutter bundle python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Error: required command not found: $command"
    exit 1
  fi
done

VERSION_LINE="$(grep '^version:' pubspec.yaml || true)"
if [[ ! "$VERSION_LINE" =~ ^version:[[:space:]]*([^+[:space:]]+)\+([0-9]+)[[:space:]]*$ ]]; then
  echo "Error: expected pubspec version in the form x.y.z+build-number."
  exit 1
fi
VERSION_NUMBER="${BASH_REMATCH[1]}"
BUILD_NUMBER="${BASH_REMATCH[2]}"
IOS_BUILD_NAME="${VERSION_NUMBER%%-*}"

echo "Preparing iOS TestFlight build $IOS_BUILD_NAME ($BUILD_NUMBER)..."
flutter build ios --config-only \
  --build-name="$IOS_BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

# Flutter's IPA build runs the Xcode archive and export steps automatically.
flutter build ipa --release \
  --build-name="$IOS_BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

echo "Uploading archive to App Store Connect / TestFlight..."
UPLOAD_LOG="$(mktemp)"
if ! (cd ios && bundle exec fastlane upload_beta) 2>&1 | tee "$UPLOAD_LOG"; then
  if grep -Eqi 'bundle version must be higher than the previously uploaded version|already been used \(-19232\)' "$UPLOAD_LOG"; then
    # This build number is already present in App Store Connect. Advance the
    # source version now so the next run rebuilds with a fresh number.
    NEXT_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    python3 - "$VERSION_NUMBER" "$NEXT_BUILD_NUMBER" <<'PY_BUMP'
from pathlib import Path
import re
import sys

version, build_number = sys.argv[1:]
path = Path("pubspec.yaml")
content = path.read_text()
updated, count = re.subn(
    r"(?m)^version:\s*[^\s+]+\+\d+\s*$",
    f"version: {version}+{build_number}",
    content,
    count=1,
)
if count != 1:
    raise SystemExit("Error: could not safely update pubspec.yaml version.")
path.write_text(updated)
PY_BUMP
    echo "Apple already has build $BUILD_NUMBER. pubspec.yaml was advanced to $NEXT_BUILD_NUMBER; rerun the script to rebuild and upload." >&2
  fi
  rm -f "$UPLOAD_LOG"
  exit 1
fi
rm -f "$UPLOAD_LOG"

NEXT_BUILD_NUMBER=$((BUILD_NUMBER + 1))
python3 - "$VERSION_NUMBER" "$NEXT_BUILD_NUMBER" <<'PY'
from pathlib import Path
import re
import sys

version, build_number = sys.argv[1:]
path = Path("pubspec.yaml")
content = path.read_text()
updated, count = re.subn(
    r"(?m)^version:\s*[^\s+]+\+\d+\s*$",
    f"version: {version}+{build_number}",
    content,
    count=1,
)
if count != 1:
    raise SystemExit("Error: could not safely update pubspec.yaml version.")
path.write_text(updated)
PY

echo "Upload complete. pubspec.yaml is now ready with build number $NEXT_BUILD_NUMBER."
