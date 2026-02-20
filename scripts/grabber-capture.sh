#!/usr/bin/env bash
set -euo pipefail

INGEST_SCRIPT="${GRABBER_INGEST_SCRIPT:-$HOME/Github Repositories/Grabber/scripts/grabber-ingest.sh}"
RAW_LOG_DIR="${GRABBER_RAW_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/grabber/raw}"

usage() {
  cat <<'USAGE'
Usage: grabber-capture.sh --source <name> [options] -- <command> [args...]

Run an interactive CLI tool, capture transcript, and auto-ingest into Grabber.

Options:
  --source <name>     Required source label (claude-code, codex-cli, opencode)
  --title <text>      Optional title/context label
  --context <text>    Optional filename context override
  --print-path        Print saved file path only from ingest output
  --keep-log          Keep raw transcript log file (default behavior)
  --delete-log        Delete raw transcript after ingest
  -h, --help          Show help

Examples:
  grabber-capture.sh --source claude-code --title "lambda hotfix" -- claude
  grabber-capture.sh --source codex-cli --title "db migration" -- codex
USAGE
}

source_name=""
title_text=""
context_override=""
print_path_only=false
delete_log=false

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      source_name="${2:-}"
      shift 2
      ;;
    --title)
      title_text="${2:-}"
      shift 2
      ;;
    --context)
      context_override="${2:-}"
      shift 2
      ;;
    --print-path)
      print_path_only=true
      shift
      ;;
    --keep-log)
      delete_log=false
      shift
      ;;
    --delete-log)
      delete_log=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$source_name" ]; then
  echo "--source is required." >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Missing command. Use '-- <command> [args...]'." >&2
  exit 1
fi

if [ ! -x "$INGEST_SCRIPT" ]; then
  echo "Ingest script not executable: $INGEST_SCRIPT" >&2
  exit 1
fi

mkdir -p "$RAW_LOG_DIR"

started_at="$(date -u "+%Y-%m-%dT%H:%M:%SZ")"
ts="$(date -u "+%Y%m%d-%H%M%S")"
safe_source="$(printf "%s" "$source_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
if [ -z "$safe_source" ]; then
  safe_source="unknown"
fi
raw_log="$RAW_LOG_DIR/${ts}_${safe_source}.log"

cmd_string="$(printf "%q " "$@")"
cmd_string="${cmd_string% }"

echo "Capturing CLI session..."
echo "Source: $source_name"
echo "Raw log: $raw_log"

exit_code=0
if command -v script >/dev/null 2>&1; then
  # script preserves interactive terminal sessions better than pipe-based capture.
  if ! script -q -f "$raw_log" -c "$cmd_string"; then
    exit_code=$?
  fi
else
  if ! bash -lc "$cmd_string" | tee "$raw_log"; then
    exit_code=$?
  fi
fi

if [ -z "$title_text" ]; then
  title_text="$(basename "$1") session $ts"
fi

ingest_args=(
  --source "$source_name"
  --title "$title_text"
  --date "$started_at"
  --input "$raw_log"
)
if [ -n "$context_override" ]; then
  ingest_args+=(--context "$context_override")
fi
if [ "$print_path_only" = true ]; then
  ingest_args+=(--print-path)
fi

"$INGEST_SCRIPT" "${ingest_args[@]}"

if [ "$delete_log" = true ]; then
  rm -f "$raw_log"
  echo "Deleted raw log: $raw_log"
fi

exit "$exit_code"
