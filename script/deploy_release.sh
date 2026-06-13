#!/bin/bash
set -e

# ==============================================================================
# Train Libre Automated Release Script (Android, iOS & GitHub)
# ==============================================================================

# Temporary file to store extracted changelog release notes
CHANGELOG_TEMP_FILE=$(mktemp /tmp/changelog-XXXXXX.md)
cleanup() {
  rm -f "$CHANGELOG_TEMP_FILE"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# STEP 1: Version & Pre-Release Detection
# ------------------------------------------------------------------------------
echo "Detecting version from pubspec.yaml..."
VERSION_LINE=$(grep "^version:" pubspec.yaml)
if [ -z "$VERSION_LINE" ]; then
  echo "Error: version key not found in pubspec.yaml"
  exit 1
fi
FULL_VERSION=${VERSION_LINE#version: }
FULL_VERSION=$(echo "$FULL_VERSION" | xargs)
VERSION_NUMBER=${FULL_VERSION%+*}

echo "Active version: $VERSION_NUMBER"

if [[ "$VERSION_NUMBER" =~ [a-zA-Z] ]]; then
  IS_PRERELEASE=true
  echo "Pre-release version detected."
else
  IS_PRERELEASE=false
  echo "Production/stable version detected."
fi

# ------------------------------------------------------------------------------
# STEP 2: Branch Verification & PR Automation
# ------------------------------------------------------------------------------
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Branch is not main. Ensuring all work is committed..."
  if [ -n "$(git status --porcelain)" ]; then
    echo "Found uncommitted changes. Staging and committing..."
    git add .
    git commit -m "chore: pre-release changes commit"
  else
    echo "Clean working directory."
  fi

  echo "Pushing $CURRENT_BRANCH to origin..."
  git push origin "$CURRENT_BRANCH"

  echo "Opening Pull Request into main..."
  gh pr create --base main --title "Merge release $VERSION_NUMBER into main" --body "Automated release synchronization split." || echo "Pull request creation skipped (may already exist)."
fi

# ------------------------------------------------------------------------------
# STEP 3: Clean, Increment pubspec.yaml & Generate All Release Artifacts
# ------------------------------------------------------------------------------
echo "Running core build preparation pipeline..."
flutter clean

OLD_BUILD_NUMBER=${FULL_VERSION#*+}
NEW_BUILD_NUMBER=$((OLD_BUILD_NUMBER + 1))

echo "Incrementing build number in pubspec.yaml: $OLD_BUILD_NUMBER -> $NEW_BUILD_NUMBER"

sed -i '' "s/version: .*/version: $VERSION_NUMBER+$NEW_BUILD_NUMBER/g" pubspec.yaml

flutter pub get
flutter gen-l10n

echo "Building Android Production Release Artifacts (Build: $NEW_BUILD_NUMBER)..."
flutter build appbundle --release
flutter build apk --release --split-per-abi
flutter build apk --release

echo "Building iOS Production Release Artifact (IPA) (Build: $NEW_BUILD_NUMBER)..."
flutter build ipa --release

# ------------------------------------------------------------------------------
# STEP 4: Changelog Extraction
# ------------------------------------------------------------------------------
echo "Extracting release notes from CHANGELOG.md..."
awk -v ver="$VERSION_NUMBER" '
  BEGIN { found=0; target1="## [" ver "]"; target2="## " ver }
  (index($0, target1) == 1 || index($0, target2) == 1) { found=1; next }
  found && index($0, "## ") == 1 { found=0; exit }
  found { print }
' CHANGELOG.md > "$CHANGELOG_TEMP_FILE"

if [ ! -s "$CHANGELOG_TEMP_FILE" ]; then
  echo "Warning: No section found for version $VERSION_NUMBER in CHANGELOG.md"
  echo "Release v$VERSION_NUMBER. Please see CHANGELOG.md for detailed changes." > "$CHANGELOG_TEMP_FILE"
fi

# ------------------------------------------------------------------------------
# STEP 5: Git Tagging & Local Commit
# ------------------------------------------------------------------------------
echo "Staging release files..."
git add .

if [ -n "$(git status --porcelain)" ]; then
  echo "Committing release version changes..."
  git commit -m "chore: release v$VERSION_NUMBER"
else
  echo "No changes to commit for release."
fi

if git rev-parse "v$VERSION_NUMBER" >/dev/null 2>&1; then
  echo "Tag v$VERSION_NUMBER already exists. Overwriting tag..."
  git tag -d "v$VERSION_NUMBER" || true
  git push origin :refs/tags/"v$VERSION_NUMBER" || true
fi

git tag -a "v$VERSION_NUMBER" -m "Release v$VERSION_NUMBER"
git push origin "$CURRENT_BRANCH"
git push origin --tags

# ------------------------------------------------------------------------------
# STEP 6: GitHub Release & Asset Upload
# ------------------------------------------------------------------------------
GH_FLAGS=()
if [ "$IS_PRERELEASE" = "true" ]; then
  GH_FLAGS+=("--prerelease")
fi

echo "Generating GitHub Release Container..."
if gh release view "v$VERSION_NUMBER" >/dev/null 2>&1; then
  gh release delete "v$VERSION_NUMBER" --yes
fi

gh release create "v$VERSION_NUMBER" \
  --title "Release v$VERSION_NUMBER" \
  --notes-file "$CHANGELOG_TEMP_FILE" \
  "${GH_FLAGS[@]}"

echo "Uploading Android Binaries to GitHub Release..."
gh release upload "v$VERSION_NUMBER" build/app/outputs/bundle/release/app-release.aab
gh release upload "v$VERSION_NUMBER" build/app/outputs/flutter-apk/app-release.apk
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  gh release upload "v$VERSION_NUMBER" "$apk"
done

# ------------------------------------------------------------------------------
# STEP 7: Trigger Xcode Upload Pipeline via Fastlane
# ------------------------------------------------------------------------------
echo "Triggering Fastlane for iOS Deployment..."
cd ios
bundle exec fastlane upload_beta
cd ..

# ------------------------------------------------------------------------------
# STEP 8: Clean Up Local Build Settings Changes
# ------------------------------------------------------------------------------
echo "Restoring dynamic build number variables in iOS project files..."
git restore ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist

echo "=============================================================================="
echo "SUCCESS: Version v$VERSION_NUMBER deployed to GitHub (with Android Assets) & TestFlight!"
echo "=============================================================================="
