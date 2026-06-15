#!/bin/bash
# ==============================================================================
# sync_screenshots.sh - Automate Maestro output extraction, asset renaming,
#                       and atomic Fastlane overwrites.
# ==============================================================================
set -euo pipefail

# Initialize temporary workspace variable for cleanup
TEMP_WORKSPACE=""

# Safety cleanup handler
cleanup_temp() {
  if [ -n "${TEMP_WORKSPACE:-}" ] && [ -d "$TEMP_WORKSPACE" ]; then
    rm -rf "$TEMP_WORKSPACE"
  fi
}
trap cleanup_temp EXIT

# Logging helper functions
log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# Usage help
usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -s, --src DIR        Source directory where Maestro screenshots are saved.
                       (default: output/screenshots)
  -p, --platform PLAT  Target platform ('android' or 'ios'). (Required)
  -t, --theme THEME    Target theme ('light' or 'dark'). (Required)
  -l, --locale LOCALE  Target locale (e.g., 'en-US', 'de-DE'). (default: en-US)
  -f, --frame          Run framing script (assets/screenshots/generate_store_screenshots.py)
                       to overlay device frame, background, and titles, then copy
                       the framed output to Fastlane. (Android only)
  -h, --help           Show this help message.
EOF
  exit 1
}

# Variable defaults
SRC_DIR="maestro/Maestro/.maestro/screenshots"
PLATFORM=""
THEME=""
LOCALE="en-US"
RUN_FRAMING=false

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--src)
      SRC_DIR="$2"
      shift 2
      ;;
    -p|--platform)
      PLATFORM=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      shift 2
      ;;
    -t|--theme)
      THEME=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      shift 2
      ;;
    -l|--locale)
      LOCALE="$2"
      shift 2
      ;;
    -f|--frame)
      RUN_FRAMING=true
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

# Parameter validation
if [ -z "$PLATFORM" ]; then
  log_error "Platform (-p | --platform) is required."
  usage
fi
if [ "$PLATFORM" != "android" ] && [ "$PLATFORM" != "ios" ]; then
  log_error "Platform must be 'android' or 'ios'."
  exit 1
fi
if [ -z "$THEME" ]; then
  log_error "Theme (-t | --theme) is required."
  usage
fi
if [ "$THEME" != "light" ] && [ "$THEME" != "dark" ]; then
  log_error "Theme must be 'light' or 'dark'."
  exit 1
fi
if [ ! -d "$SRC_DIR" ]; then
  log_error "Source directory does not exist: $SRC_DIR"
  exit 1
fi

# Define screenshot keys in flow order
KEYS=(
  "diary"
  "nutrition"
  "data"
  "measurements"
  "recovery"
  "ai"
  "running_workout"
)

# Helper to get the correct asset filename key based on platform
get_asset_key() {
  local idx="$1"
  local key="${KEYS[$idx]}"
  if [ "$PLATFORM" = "android" ] && [ "$key" = "recovery" ]; then
    echo "recovery_tracker"
  else
    echo "$key"
  fi
}

# Array to hold matched source file paths
declare -a MATCHED_SOURCES=( "" "" "" "" "" "" "" )

# 1. Attempt Name-Based Matching (Preferred)
log_info "Searching for name-based screenshot matches in '$SRC_DIR'..."
PATTERNS=(
  "*01_diary*"
  "*02_nutrition*"
  "*03_data*"
  "*04_measurements*"
  "*05_recovery*"
  "*06_ai*"
  "*07_run*workout*"  # Handles double-n typo "runnning" or corrected "running"
)

NAME_MATCH_COUNT=0
for i in {0..6}; do
  pattern="${PATTERNS[$i]}"
  match=""
  # Find first matching png file (case-insensitive)
  match=$(find -L "$SRC_DIR" -maxdepth 1 -type f -iname "${pattern}.png" | head -n 1) || true
  if [ -n "$match" ]; then
    MATCHED_SOURCES[$i]="$match"
    NAME_MATCH_COUNT=$((NAME_MATCH_COUNT + 1))
  fi
done

# 2. Sequential Fallback Matching if Name-Based Matching is incomplete
if [ "$NAME_MATCH_COUNT" -eq 7 ]; then
  log_info "All 7 screenshots matched via filename patterns."
else
  log_warn "Only matched $NAME_MATCH_COUNT/7 screenshots via filename patterns. Falling back to alphabetical/creation sort..."
  
  # List files, sorting alphabetically as default sequential mapping
  # (which matches sequential naming output from test suites)
  IFS=$'\n' sorted_pngs=($(find -L "$SRC_DIR" -maxdepth 1 -type f -name "*.png" | sort))
  unset IFS
  
  if [ "${#sorted_pngs[@]}" -lt 7 ]; then
    log_error "Not enough PNG images in source directory '$SRC_DIR'. Found ${#sorted_pngs[@]}, need at least 7."
    exit 1
  fi
  
  log_info "Mapping first 7 sorted PNG files sequentially:"
  for i in {0..6}; do
    MATCHED_SOURCES[$i]="${sorted_pngs[$i]}"
  done
fi

# Pre-flight integrity validation
log_info "Validating matched files..."
for i in {0..6}; do
  src="${MATCHED_SOURCES[$i]}"
  if [ -z "$src" ] || [ ! -f "$src" ]; then
    log_error "Missing or invalid source file for step $((i+1)) (key: ${KEYS[$i]})."
    exit 1
  fi
  # Verify files are valid PNGs
  if command -v file >/dev/null 2>&1; then
    if ! file "$src" | grep -q -i "PNG image data"; then
      log_error "File is not a valid PNG image: $src"
      exit 1
    fi
  fi
  log_info "  Step $((i+1)) [${KEYS[$i]}]: $(basename "$src")"
done

# Define Asset output directory
if [ "$PLATFORM" = "android" ]; then
  ASSET_DIR="assets/screenshots/android/$THEME"
else
  # iOS has localized asset directories
  ASSET_DIR="assets/screenshots/iOS/$LOCALE/$THEME"
fi

log_info "Ensuring asset target directory exists: $ASSET_DIR"
mkdir -p "$ASSET_DIR"

# Copy to Assets with atomic writes
log_info "Copying raw screenshots to assets folder..."
for i in {0..6}; do
  src="${MATCHED_SOURCES[$i]}"
  key=$(get_asset_key "$i")
  dest=""
  if [ "$PLATFORM" = "android" ]; then
    dest="$ASSET_DIR/android_${THEME}_${key}.png"
  else
    dest="$ASSET_DIR/iOS_${THEME}_${key}.png"
  fi
  
  cp "$src" "${dest}.tmp"
  mv "${dest}.tmp" "$dest"
  log_info "  Updated asset: $dest"
done
log_success "Asset folder synchronization complete."

# Fastlane processing (Android only)
if [ "$PLATFORM" = "android" ]; then
  FASTLANE_DIR="fastlane/metadata/android/$LOCALE/images/phoneScreenshots"
  log_info "Ensuring Fastlane directory exists: $FASTLANE_DIR"
  mkdir -p "$FASTLANE_DIR"
  
  if [ "$RUN_FRAMING" = "true" ]; then
    log_info "Framing option (-f/--frame) enabled. Preparing framing workspace..."
    TEMP_WORKSPACE=$(mktemp -d /tmp/screenshot_frame_XXXXXX)
    
    mkdir -p "$TEMP_WORKSPACE/android"
    mkdir -p "$TEMP_WORKSPACE/ios"
    
    # Copy assets with names expected by generate_store_screenshots.py
    for i in {0..6}; do
      src="${MATCHED_SOURCES[$i]}"
      key=$(get_asset_key "$i")
      cp "$src" "$TEMP_WORKSPACE/android/android_${key}.png"
    done
    
    # Run the Python framing script
    log_info "Executing python framing script..."
    if ! python3 assets/screenshots/generate_store_screenshots.py --root "$TEMP_WORKSPACE"; then
      log_error "Failed to run generate_store_screenshots.py framing script."
      exit 1
    fi
    
    # Copy framed output to Fastlane directory
    log_info "Copying framed screenshots to Fastlane..."
    for i in {0..6}; do
      key=$(get_asset_key "$i")
      framed_src="$TEMP_WORKSPACE/store_output/android/android_${key}.png"
      step_num=$(printf "%02d" $((i+1)))
      dest="$FASTLANE_DIR/${step_num}.png"
      
      if [ ! -f "$framed_src" ]; then
        log_error "Framed output file not found: $framed_src"
        exit 1
      fi
      
      cp "$framed_src" "${dest}.tmp"
      mv "${dest}.tmp" "$dest"
      log_info "  Updated Fastlane (framed): $dest"
    done
  else
    # Copy raw screenshots directly to Fastlane
    log_info "Copying raw screenshots to Fastlane..."
    for i in {0..6}; do
      src="${MATCHED_SOURCES[$i]}"
      step_num=$(printf "%02d" $((i+1)))
      dest="$FASTLANE_DIR/${step_num}.png"
      
      cp "$src" "${dest}.tmp"
      mv "${dest}.tmp" "$dest"
      log_info "  Updated Fastlane (raw): $dest"
    done
  fi
  
  # Atomic overwrite cleanup: remove any unexpected or stale files in phoneScreenshots directory
  log_info "Cleaning up stale files in Fastlane directory..."
  for file in "$FASTLANE_DIR"/*; do
    if [ -f "$file" ]; then
      bn=$(basename "$file")
      if [[ ! "$bn" =~ ^0[1-7]\.png$ ]]; then
        log_warn "  Removing stale file: $bn"
        rm -f "$file"
      fi
    fi
  done
  log_success "Fastlane directory synchronization complete."
fi

log_success "Screenshot post-processing and translation bridge execution succeeded!"
