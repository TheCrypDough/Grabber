#!/usr/bin/env bash
set -euo pipefail

SAVE_SCRIPT="${GRABBER_SAVE_SCRIPT:-$HOME/Github Repositories/Grabber/scripts/grabber-save.sh}"

usage() {
  cat <<'USAGE'
Usage: grabber-ingest.sh [options]

Import non-browser transcripts (CLI/IDE/etc) into Grabber bundle format and save.

Options:
  --source <name>     Source label, e.g. claude-code, codex-cli, cursor
  --title <text>      Conversation title/context for metadata + filename
  --url <value>       Optional source URL/path marker
  --date <value>      Optional date (any GNU date-compatible string)
  --context <text>    Optional filename context override
  --print-path        Print saved file path only (machine-friendly)
  --input <file>      Read transcript from file
  --stdin             Read transcript from stdin
  -h, --help          Show help

Examples:
  grabber-ingest.sh --source claude-code --title "auth refactor" --input ./session.md
  cat transcript.txt | grabber-ingest.sh --stdin --source codex-cli --title "lambda errors"
USAGE
}

yaml_quote() {
  local value="${1:-}"
  value="${value//$'\\'/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  printf '"%s"' "$value"
}

to_iso_date() {
  local raw="${1:-}"
  if [ -n "$raw" ] && date -u -d "$raw" "+%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
    date -u -d "$raw" "+%Y-%m-%dT%H:%M:%SZ"
    return
  fi
  date -u "+%Y-%m-%dT%H:%M:%SZ"
}

first_context_line() {
  local body="$1"
  printf "%s\n" "$body" | awk '
    /^## / { next }
    /^>/ { next }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    NF { print; exit }
  '
}

looks_like_bundle() {
  local body="$1"
  printf "%s\n" "$body" | head -n 40 | grep -Eq '^grabber:[[:space:]]*v2$'
}

count_nodes() {
  local body="$1"
  local count
  count=$(printf "%s\n" "$body" | grep -Ec '^##[[:space:]]+(User|Assistant|System|Tool|Developer)\b' || true)
  if [ "$count" -le 0 ]; then
    count=1
  fi
  printf "%s" "$count"
}

read_from_stdin=false
input_file=""
source_name=""
title_text=""
url_text=""
date_text=""
context_override=""
print_path_only=false

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
    --url)
      url_text="${2:-}"
      shift 2
      ;;
    --date)
      date_text="${2:-}"
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
    --input)
      input_file="${2:-}"
      shift 2
      ;;
    --stdin)
      read_from_stdin=true
      shift
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

if [ ! -x "$SAVE_SCRIPT" ]; then
  echo "Save script not executable: $SAVE_SCRIPT" >&2
  exit 1
fi

if [ -n "$input_file" ] && [ ! -f "$input_file" ]; then
  echo "Input file not found: $input_file" >&2
  exit 1
fi

if [ -n "$input_file" ] && [ "$read_from_stdin" = true ]; then
  echo "Use either --input or --stdin, not both." >&2
  exit 1
fi

if [ -n "$input_file" ]; then
  content="$(cat "$input_file")"
elif [ "$read_from_stdin" = true ] || [ ! -t 0 ]; then
  content="$(cat)"
else
  echo "No input provided. Use --input <file> or pipe stdin via --stdin." >&2
  exit 1
fi

if [ -z "${content//[$'\t\n\r ']/}" ]; then
  echo "Input transcript is empty." >&2
  exit 1
fi

save_args=(--from-stdin)
if [ "$print_path_only" = true ]; then
  save_args+=(--print-path)
fi

if looks_like_bundle "$content"; then
  if [ -n "$context_override" ]; then
    printf "%s\n" "$content" | "$SAVE_SCRIPT" "${save_args[@]}" "$context_override"
  else
    printf "%s\n" "$content" | "$SAVE_SCRIPT" "${save_args[@]}"
  fi
  exit 0
fi

if [ -z "$source_name" ]; then
  source_name="unknown"
fi

if [ -z "$title_text" ]; then
  title_text="$(first_context_line "$content")"
fi
if [ -z "$title_text" ]; then
  title_text="conversation"
fi

if [ -z "$context_override" ]; then
  context_override="$title_text"
fi

bundle_date="$(to_iso_date "$date_text")"
bundle_nodes="$(count_nodes "$content")"

bundle="$(
  cat <<EOF
---
grabber: v2
source: $(yaml_quote "$source_name")
url: $(yaml_quote "$url_text")
title: $(yaml_quote "$title_text")
date: $bundle_date
nodes: $bundle_nodes
format: full
---

## Transcript

$content
EOF
)"

printf "%s\n" "$bundle" | "$SAVE_SCRIPT" "${save_args[@]}" "$context_override"
