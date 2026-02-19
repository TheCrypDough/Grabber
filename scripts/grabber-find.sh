#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="${GRABBER_ARCHIVE_DIR:-${CTXPORT_ARCHIVE_DIR:-$HOME/convos}}"

usage() {
  cat <<'USAGE'
Usage: grabber-find.sh [options]

Find saved conversation files in the archive.

Options:
  --source <name>     Filter by source slug in filename
  --host <name>       Filter by host slug in filename
  --date <value>      Filter by date prefix (YYYYMMDD or YYYY-MM-DD)
  --context <text>    Case-insensitive context match in filename
  --contains <text>   Case-insensitive full-text match in file body
  --latest <n>        Limit number of results (default: all)
  --include-derived   Include .summary.md and .code.md files
  --paths             Print only file paths
  --tsv               Print tab-separated rows
  -h, --help          Show help

Examples:
  grabber-find.sh --source claude-code --latest 5
  grabber-find.sh --contains "oauth token refresh" --date 2026-02-19
USAGE
}

to_date_key() {
  local raw="${1:-}"
  raw="$(printf "%s" "$raw" | tr -cd '0-9')"
  if [ -z "$raw" ]; then
    printf ""
    return
  fi
  printf "%s" "$raw"
}

source_filter=""
host_filter=""
date_filter=""
context_filter=""
contains_filter=""
latest_limit=""
include_derived=false
mode="human"

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      source_filter="${2:-}"
      shift 2
      ;;
    --host)
      host_filter="${2:-}"
      shift 2
      ;;
    --date)
      date_filter="$(to_date_key "${2:-}")"
      shift 2
      ;;
    --context)
      context_filter="${2:-}"
      shift 2
      ;;
    --contains)
      contains_filter="${2:-}"
      shift 2
      ;;
    --latest)
      latest_limit="${2:-}"
      shift 2
      ;;
    --include-derived)
      include_derived=true
      shift
      ;;
    --paths)
      mode="paths"
      shift
      ;;
    --tsv)
      mode="tsv"
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

if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "Archive directory not found: $ARCHIVE_DIR" >&2
  exit 1
fi

if [ -n "$latest_limit" ] && ! printf "%s" "$latest_limit" | grep -Eq '^[0-9]+$'; then
  echo "--latest must be a positive integer." >&2
  exit 1
fi

if [ "$mode" = "tsv" ]; then
  printf "timestamp\tsource\thost\tcontext\tpath\n"
fi

count=0

while IFS= read -r file; do
  name="$(basename "$file")"

  if [ "$include_derived" != true ] && printf "%s" "$name" | grep -Eq '\.(summary|code)\.md$'; then
    continue
  fi

  base="${name%.md}"
  timestamp="${base%%_*}"
  rest="${base#*_}"
  source_host="${rest%%_*}"
  context="${rest#*_}"
  source="${source_host%@*}"
  host="${source_host#*@}"

  if [ "$source_host" = "$source" ]; then
    host="unknown"
  fi

  if [ -n "$source_filter" ] && [ "$source" != "$source_filter" ]; then
    continue
  fi
  if [ -n "$host_filter" ] && [ "$host" != "$host_filter" ]; then
    continue
  fi
  if [ -n "$date_filter" ] && [ "${timestamp#"$date_filter"}" = "$timestamp" ]; then
    continue
  fi
  if [ -n "$context_filter" ] && ! printf "%s\n" "$context" | grep -Eqi -- "$context_filter"; then
    continue
  fi
  if [ -n "$contains_filter" ] && ! rg -qi -- "$contains_filter" "$file"; then
    continue
  fi

  if [ "$mode" = "paths" ]; then
    printf "%s\n" "$file"
  elif [ "$mode" = "tsv" ]; then
    printf "%s\t%s\t%s\t%s\t%s\n" "$timestamp" "$source" "$host" "$context" "$file"
  else
    printf "%s | %s | %s | %s\n" "$timestamp" "$source" "$host" "$context"
    printf "  %s\n" "$file"
  fi

  count=$((count + 1))
  if [ -n "$latest_limit" ] && [ "$count" -ge "$latest_limit" ]; then
    break
  fi
done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.md' | sort -r)

if [ "$count" -eq 0 ]; then
  if [ "$mode" != "tsv" ]; then
    echo "No matching files."
  fi
  exit 1
fi
