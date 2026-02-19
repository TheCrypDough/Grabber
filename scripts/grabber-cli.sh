#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$REPO_DIR/apps/browser-extension/dist/chrome-mv3"
SAVE_SCRIPT="$REPO_DIR/scripts/grabber-save.sh"
AUTOSAVE_SCRIPT="$REPO_DIR/scripts/grabber-autosave.sh"
INGEST_SCRIPT="$REPO_DIR/scripts/grabber-ingest.sh"
FIND_SCRIPT="$REPO_DIR/scripts/grabber-find.sh"
CONTEXT_SCRIPT="$REPO_DIR/scripts/grabber-context.sh"
CAPTURE_SCRIPT="$REPO_DIR/scripts/grabber-capture.sh"

usage() {
  cat <<'USAGE'
Usage: grabber [command]

Commands:
  build      Build the Chrome extension bundle (default)
  dev        Run extension in watch/dev mode
  path       Print unpacked extension path for chrome://extensions
  update     Pull latest changes and rebuild
  clean      Remove extension build output
  save       Save current Grabber clipboard content to archive
  autosave   Manage autosave daemon (pass subcommand)
  ingest     Import CLI/IDE transcript into archive bundle
  find       Search archived conversation files
  summary    Generate a structured summary file from one conversation
  code       Extract code blocks from one conversation
  capture    Run a CLI tool, capture transcript, and auto-ingest
  help       Show this help
USAGE
}

ensure_deps() {
  if [ ! -d "$REPO_DIR/node_modules" ]; then
    echo "Installing dependencies..."
    (cd "$REPO_DIR" && pnpm install)
  fi
}

cmd="${1:-build}"

case "$cmd" in
  build)
    ensure_deps
    (cd "$REPO_DIR" && pnpm build:ext)
    echo "Built successfully. Load this folder in Chrome:"
    echo "$DIST_DIR"
    ;;
  dev)
    ensure_deps
    (cd "$REPO_DIR" && pnpm dev:ext)
    ;;
  path)
    echo "$DIST_DIR"
    ;;
  update)
    (cd "$REPO_DIR" && git pull --ff-only && pnpm install && pnpm build:ext)
    echo "Updated and rebuilt. Load this folder in Chrome:"
    echo "$DIST_DIR"
    ;;
  clean)
    rm -rf "$DIST_DIR"
    echo "Removed build output:"
    echo "$DIST_DIR"
    ;;
  save)
    exec "$SAVE_SCRIPT" "${@:2}"
    ;;
  autosave)
    exec "$AUTOSAVE_SCRIPT" "${@:2}"
    ;;
  ingest)
    exec "$INGEST_SCRIPT" "${@:2}"
    ;;
  find)
    exec "$FIND_SCRIPT" "${@:2}"
    ;;
  summary)
    exec "$CONTEXT_SCRIPT" summary "${@:2}"
    ;;
  code)
    exec "$CONTEXT_SCRIPT" code "${@:2}"
    ;;
  capture)
    exec "$CAPTURE_SCRIPT" "${@:2}"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
