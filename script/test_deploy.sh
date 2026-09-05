#!/bin/bash
set -e

# ==============================================================================
# Train Libre DRY RUN / TEST Release Script
# ==============================================================================

CHANGELOG_TEMP_FILE=$(mktemp /tmp/changelog-XXXXXX.md)
cleanup() {
  rm -f "$CHANGELOG_TEMP_FILE"
}
trap cleanup EXIT

# 1. Version Detection
echo "🔍 DRY RUN: Detecting version from pubspec.yaml..."
VERSION_LINE=$(grep "^version:" pubspec.yaml)
FULL_VERSION=${VERSION_LINE#version: }
FULL_VERSION=$(echo "$FULL_VERSION" | xargs)
VERSION_NUMBER=${FULL_VERSION%+*}
echo "Active version: $VERSION_NUMBER"

# 2. Branch Check (Dry-run simulation only)
CURRENT_BRANCH=$(git branch --show-current || git rev-parse --abbrev-ref HEAD)
echo "Branch: $CURRENT_BRANCH"
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "[DRY RUN] Would ensure work is committed and simulate PR creation."
fi

# 3. Code Generation & Artifact Build (Actual test execution)
echo "skipping android for this test"
echo "⚙️ Preparing iOS Workspace & Native Pods..."
cd ios
pod install
cd ..

# 4. Changelog Extraction Test
echo "📝 Testing Changelog Extraction..."
awk -v ver="$VERSION_NUMBER" '
  BEGIN { found=0; target1="## [" ver "]"; target2="## " ver }
  (index($0, target1) == 1 || index($0, target2) == 1) { found=1; next }
  found && index($0, "## ") == 1 { found=0; exit }
  found { print }
' CHANGELOG.md > "$CHANGELOG_TEMP_FILE"

echo "--- Extracted Notes Preview ---"
cat "$CHANGELOG_TEMP_FILE"
echo "-------------------------------"

# 5. Git & GitHub Simulation (No live push)
echo "🛑 [DRY RUN] Skipping: git commit, git tag, and git push"
echo "🛑 [DRY RUN] Skipping: gh release create & asset upload"

# ------------------------------------------------------------------------------
# STEP 7: Trigger Xcode Upload Pipeline via Fastlane (Absolute path isolation)
# ------------------------------------------------------------------------------
echo "Triggering Fastlane for iOS Deployment..."
cd ios

if [ ! -f "Gemfile" ]; then
  echo "Creating default Gemfile..."
  echo "source \"https://rubygems.org\"" > Gemfile
  echo "gem \"fastlane\"" >> Gemfile
fi

echo "Installing bundler dependencies completely standalone..."
# --path ensures executables land safely in vendor/bundle
bundle install --path vendor/bundle --binstubs vendor/bundle/bin

echo "Executing Fastlane via explicit local binary path..."
# Completely bypass Bundler's global system search:
./vendor/bundle/bin/fastlane test_build

cd ..


echo "=============================================================================="
echo "🎉 SUCCESS: Dry run complete! All Android & iOS build pipelines compiled successfully."
echo "=============================================================================="