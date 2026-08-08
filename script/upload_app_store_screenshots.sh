#!/bin/bash
# ==============================================================================
# upload_app_store_screenshots.sh - Prepare and upload store screenshots to
#                                   App Store Connect using Fastlane.
# ==============================================================================
set -euo pipefail

# Logging helper functions
log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

usage() {
  cat <<EOF
Usage: $0 [options]

Automates the preparation and upload of marketing screenshots to App Store Connect.

Options:
  -s, --src DIR|ZIP    Source directory or ZIP file containing screenshots from
                       screenshot_editor or assets/screenshots/iOS.
                       (default: assets/screenshots/export_bundle if present,
                        otherwise assets/screenshots/iOS)
  -d, --dry-run        Stage and validate screenshots in fastlane directory,
                       but skip actual upload to App Store Connect.
  -h, --help           Show this help message.

Examples:
  $0                                           # Upload from export_bundle or assets
  $0 -s ~/Downloads/train-libre-apple-iphone.zip # Upload directly from downloaded ZIP
  $0 --dry-run                                 # Validate and stage without uploading
EOF
  exit 1
}

SRC_DIR=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--src)
      SRC_DIR="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown argument: $1"
      usage
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FASTLANE_SCREENSHOTS_DIR="$PROJECT_ROOT/ios/fastlane/screenshots"

# Determine default source if not passed
if [ -z "$SRC_DIR" ]; then
  if [ -d "$PROJECT_ROOT/assets/screenshots/export_bundle" ] && [ "$(ls -A "$PROJECT_ROOT/assets/screenshots/export_bundle")" ]; then
    SRC_DIR="assets/screenshots/export_bundle"
  else
    SRC_DIR="assets/screenshots/iOS"
  fi
fi

FULL_SRC_DIR="$SRC_DIR"
if [ ! -e "$FULL_SRC_DIR" ] && [ -e "$PROJECT_ROOT/$SRC_DIR" ]; then
  FULL_SRC_DIR="$PROJECT_ROOT/$SRC_DIR"
fi

log_info "Project root: $PROJECT_ROOT"
log_info "Source screenshots location: $FULL_SRC_DIR"

if [ ! -e "$FULL_SRC_DIR" ]; then
  log_error "Source path does not exist: $FULL_SRC_DIR"
  exit 1
fi

TEMP_UNZIP_DIR=""
cleanup() {
  if [ -n "$TEMP_UNZIP_DIR" ] && [ -d "$TEMP_UNZIP_DIR" ]; then
    rm -rf "$TEMP_UNZIP_DIR"
  fi
}
trap cleanup EXIT

# Handle ZIP files or ZIP files placed inside export_bundle directory
SEARCH_ROOT="$FULL_SRC_DIR"

if [[ "$FULL_SRC_DIR" == *.zip ]]; then
  log_info "Extracting ZIP file: $FULL_SRC_DIR"
  TEMP_UNZIP_DIR=$(mktemp -d /tmp/app_store_screenshots_XXXXXX)
  unzip -q "$FULL_SRC_DIR" -d "$TEMP_UNZIP_DIR"
  SEARCH_ROOT="$TEMP_UNZIP_DIR"
elif [ -d "$FULL_SRC_DIR" ]; then
  ZIP_IN_DIR=$(find "$FULL_SRC_DIR" -maxdepth 1 -name "*.zip" | head -n 1 || true)
  if [ -n "$ZIP_IN_DIR" ]; then
    log_info "Found ZIP file in export directory: $ZIP_IN_DIR"
    TEMP_UNZIP_DIR=$(mktemp -d /tmp/app_store_screenshots_XXXXXX)
    unzip -q "$ZIP_IN_DIR" -d "$TEMP_UNZIP_DIR"
    SEARCH_ROOT="$TEMP_UNZIP_DIR"
  fi
fi

# Ensure Fastlane screenshots root directory exists
mkdir -p "$FASTLANE_SCREENSHOTS_DIR"

# Helper to normalize locale codes
normalize_locale() {
  local code="$1"
  case "$code" in
    de|de-DE|de_DE) echo "de-DE" ;;
    en|en-US|en_US|en-GB) echo "en-US" ;;
    fr|fr-FR|fr_FR) echo "fr-FR" ;;
    es|es-ES|es_ES) echo "es-ES" ;;
    it|it-IT|it_IT) echo "it-IT" ;;
    ja|ja-JP|ja_JP) echo "ja" ;;
    *) echo "$code" ;;
  esac
}

# 1. Search for screenshot_editor exported structure: any PNGs inside SEARCH_ROOT
EDITOR_PNGS=()
IFS=$'\n' read -r -d '' -a EDITOR_PNGS < <(find "$SEARCH_ROOT" -type f -name "*.png" | sort && printf '\0') || true

log_info "Scanning staged files in: $SEARCH_ROOT"

if [ ${#EDITOR_PNGS[@]} -gt 0 ]; then
  log_info "Found ${#EDITOR_PNGS[@]} screenshot images. Grouping by locale..."

  # Reset fastlane target screenshots dir for clean stage
  rm -rf "$FASTLANE_SCREENSHOTS_DIR"/*

  for file in "${EDITOR_PNGS[@]}"; do
    parent_dir=$(basename "$(dirname "$file")")
    target_locale=$(normalize_locale "$parent_dir")

    filename=$(basename "$file")
    res_dir=$(basename "$(dirname "$(dirname "$file")")")
    if [[ "$res_dir" =~ ^[0-9]+x[0-9]+$ ]]; then
      out_name="${res_dir}_${filename}"
    else
      out_name="${filename}"
    fi

    # Target locales: if English, stage for both en-GB (UK) and en-US (US)
    locales_to_stage=("$target_locale")
    if [ "$target_locale" = "en-US" ] || [ "$target_locale" = "en-GB" ]; then
      locales_to_stage=("en-GB" "en-US")
    fi

    for loc in "${locales_to_stage[@]}"; do
      target_dir="$FASTLANE_SCREENSHOTS_DIR/$loc"
      mkdir -p "$target_dir"
      cp "$file" "$target_dir/$out_name"
      log_info "  Staged ($loc): $out_name"
    done
  done

  log_success "Staged screenshots successfully into $FASTLANE_SCREENSHOTS_DIR"

else
  log_warn "No screenshot_editor bundle structure found. Falling back to direct assets scan..."

  sync_locale() {
    local src_locale_dir="$1"
    local target_locale="$2"

    if [ ! -d "$src_locale_dir" ]; then
      return
    fi

    local locales_to_stage=("$target_locale")
    if [ "$target_locale" = "en-US" ] || [ "$target_locale" = "en-GB" ]; then
      locales_to_stage=("en-GB" "en-US")
    fi

    for loc in "${locales_to_stage[@]}"; do
      local target_dir="$FASTLANE_SCREENSHOTS_DIR/$loc"
      rm -rf "$target_dir"
      mkdir -p "$target_dir"

      local count=1
      local png_files=()
      if [ -d "$src_locale_dir/dark" ]; then
        IFS=$'\n' read -r -d '' -a png_files < <(find "$src_locale_dir/dark" -maxdepth 1 -name "*.png" | sort && printf '\0') || true
      else
        IFS=$'\n' read -r -d '' -a png_files < <(find "$src_locale_dir" -maxdepth 1 -name "*.png" | sort && printf '\0') || true
      fi

      for file in "${png_files[@]}"; do
        if [ -f "$file" ]; then
          local filename=$(basename "$file")
          local dest="$target_dir/${count}_${filename}"
          cp "$file" "$dest"
          count=$((count + 1))
        fi
      done

      log_success "Staged $((count - 1)) screenshots for $loc"
    done
  }

  if [ -d "$SEARCH_ROOT/de-DE" ]; then sync_locale "$SEARCH_ROOT/de-DE" "de-DE"; fi
  if [ -d "$SEARCH_ROOT/de" ]; then sync_locale "$SEARCH_ROOT/de" "de-DE"; fi
  if [ -d "$SEARCH_ROOT/en-US" ]; then sync_locale "$SEARCH_ROOT/en-US" "en-US"; fi
  if [ -d "$SEARCH_ROOT/en-GB" ]; then sync_locale "$SEARCH_ROOT/en-GB" "en-GB"; fi
  if [ -d "$SEARCH_ROOT/en" ]; then sync_locale "$SEARCH_ROOT/en" "en-US"; fi
fi

if [ "$DRY_RUN" = "true" ]; then
  log_success "Dry-run complete. Screenshots prepared at: $FASTLANE_SCREENSHOTS_DIR"
  exit 0
fi

# Trigger Fastlane deliver / upload_screenshots
log_info "Triggering Fastlane upload to App Store Connect..."
cd "$PROJECT_ROOT/ios"

if command -v bundle >/dev/null 2>&1; then
  bundle exec fastlane upload_screenshots
else
  fastlane upload_screenshots
fi

log_success "App Store Connect screenshots upload completed successfully!"
