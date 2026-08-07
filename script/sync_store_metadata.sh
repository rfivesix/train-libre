#!/bin/bash
# ==============================================================================
# sync_store_metadata.sh - Synchronize App Store Connect metadata between VS Code
#                          Markdown documents (metadata/app_store/*.md) and Apple.
# ==============================================================================
set -euo pipefail

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

usage() {
  cat <<EOF
Usage: $0 <push|pull> [options]

Synchronize App Store Connect metadata between Markdown files and Apple.

Commands:
  push, upload       Validate Markdown files in metadata/app_store/*.md,
                     convert to Fastlane format, and upload to App Store Connect.
  pull, download     Download live/draft metadata from App Store Connect,
                     and update Markdown files in metadata/app_store/*.md.

Options:
  -h, --help         Show this help message.

Examples:
  $0 push            # Push your Markdown edits in VS Code to App Store Connect
  $0 pull            # Pull current App Store Connect metadata into Markdown files
EOF
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

ACTION="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MD_DIR="$PROJECT_ROOT/metadata/app_store"
FASTLANE_META_DIR="$PROJECT_ROOT/ios/fastlane/metadata"

case "$ACTION" in
  push|upload)
    log_info "Converting Markdown metadata in '$MD_DIR' to Fastlane format..."
    python3 "$SCRIPT_DIR/sync_store_metadata.py" md_to_fastlane "$MD_DIR" "$FASTLANE_META_DIR"
    
    log_info "Uploading metadata to App Store Connect..."
    cd "$PROJECT_ROOT/ios"
    if command -v bundle >/dev/null 2>&1; then
      bundle exec fastlane upload_metadata
    else
      fastlane upload_metadata
    fi
    log_success "App Store Connect metadata upload completed successfully!"
    ;;

  pull|download)
    log_info "Cleaning local metadata cache and downloading live metadata from App Store Connect..."
    rm -rf "$FASTLANE_META_DIR"/*
    cd "$PROJECT_ROOT/ios"
    if command -v bundle >/dev/null 2>&1; then
      bundle exec fastlane download_metadata
    else
      fastlane download_metadata
    fi

    log_info "Updating Markdown metadata in '$MD_DIR'..."
    python3 "$SCRIPT_DIR/sync_store_metadata.py" fastlane_to_md "$MD_DIR" "$FASTLANE_META_DIR"
    log_success "Markdown metadata successfully synchronized from App Store Connect!"
    ;;

  -h|--help)
    usage
    ;;

  *)
    log_error "Unknown command: $ACTION"
    usage
    ;;
esac
