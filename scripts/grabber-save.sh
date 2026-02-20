#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="${GRABBER_ARCHIVE_DIR:-$HOME/convos}"

usage() {
  cat <<'USAGE'
Usage: grabber-save.sh [--from-stdin] [--print-path] [context override]

Save Grabber markdown into /home/thecrypdough/convos (or $GRABBER_ARCHIVE_DIR).

Filename format:
  YYYYMMDD-HHMMSS_source@host_context.md

Examples:
  grabber-save.sh
  grabber-save.sh "lambda agent routing"
  grabber-save.sh --from-stdin < convo.md
  grabber-save.sh --from-stdin --print-path < convo.md
USAGE
}

slugify() {
  local value="${1:-}"
  local max_len="${2:-80}"

  local slug
  slug=$(printf "%s" "$value" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g' \
    | cut -c1-"$max_len")

  if [ -z "$slug" ]; then
    slug="unknown"
  fi

  printf "%s" "$slug"
}

read_clipboard() {
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Get-Clipboard -Raw" | tr -d '\r'
    return
  fi

  if command -v wl-paste >/dev/null 2>&1; then
    wl-paste -n
    return
  fi

  if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o
    return
  fi

  if command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --output
    return
  fi

  if command -v pbpaste >/dev/null 2>&1; then
    pbpaste
    return
  fi

  echo "No supported clipboard command found." >&2
  exit 1
}

extract_field() {
  local key="$1"
  local fm="$2"

  printf "%s\n" "$fm" \
    | awk -v key="$key" '
      index($0, key ":") == 1 {
        sub(/^[^:]*:[[:space:]]*/, "", $0)
        gsub(/^"|"$/, "", $0)
        gsub(/^'"'"'|'"'"'$/, "", $0)
        print
        exit
      }
    '
}

parse_url_host() {
  local url="${1:-}"
  if [ -z "$url" ]; then
    printf "unknown"
    return
  fi

  local host
  host=$(printf "%s" "$url" | sed -E 's#^[a-zA-Z]+://([^/:?#]+).*$#\1#')
  if [ -z "$host" ] || [ "$host" = "$url" ]; then
    printf "unknown"
    return
  fi

  printf "%s" "$host"
}

format_date_stamp() {
  local raw="${1:-}"

  if [ -n "$raw" ] && date -u -d "$raw" "+%Y%m%d-%H%M%S" >/dev/null 2>&1; then
    date -u -d "$raw" "+%Y%m%d-%H%M%S"
    return
  fi

  date -u "+%Y%m%d-%H%M%S"
}

first_context_line() {
  local body="$1"
  printf "%s\n" "$body" | awk '
    /^## / { next }
    /^>/ { next }
    NF { print; exit }
  '
}

from_stdin=false
print_path_only=false

while [ $# -gt 0 ]; do
  case "$1" in
    --from-stdin)
      from_stdin=true
      shift
      ;;
    --print-path)
      print_path_only=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

context_override="${*:-}"

mkdir -p "$ARCHIVE_DIR"

if [ "$from_stdin" = true ]; then
  content=$(cat)
else
  content=$(read_clipboard)
fi

if [ -z "${content//[$'\t\n\r ']/}" ]; then
  echo "Clipboard/stdin is empty. Copy a Grabber conversation first." >&2
  exit 1
fi

frontmatter=""
body="$content"

if [ "$(printf "%s\n" "$content" | sed -n '1p')" = "---" ]; then
  frontmatter=$(printf "%s\n" "$content" | awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm { print }
  ')

  body=$(printf "%s\n" "$content" | awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { in_fm=0; body=1; next }
    body { print }
  ')
fi

program_raw="$(extract_field "source" "$frontmatter" || true)"
date_raw="$(extract_field "date" "$frontmatter" || true)"
title_raw="$(extract_field "title" "$frontmatter" || true)"
url_raw="$(extract_field "url" "$frontmatter" || true)"

if [ -z "$program_raw" ]; then
  program_raw="unknown"
fi

if [ -n "$context_override" ]; then
  context_raw="$context_override"
elif [ -n "$title_raw" ]; then
  context_raw="$title_raw"
else
  context_raw="$(first_context_line "$body")"
fi

if [ -z "$context_raw" ]; then
  context_raw="conversation"
fi

timestamp="$(format_date_stamp "$date_raw")"
program_slug="$(slugify "$program_raw" 24)"
host_slug="$(slugify "$(parse_url_host "$url_raw")" 28)"
context_slug="$(slugify "$context_raw" 64)"

base="${timestamp}_${program_slug}@${host_slug}_${context_slug}"
path="$ARCHIVE_DIR/${base}.md"

if [ -e "$path" ]; then
  i=2
  while [ -e "$ARCHIVE_DIR/${base}_$(printf '%02d' "$i").md" ]; do
    i=$((i + 1))
  done
  path="$ARCHIVE_DIR/${base}_$(printf '%02d' "$i").md"
fi

printf "%s\n" "$content" > "$path"

if [ "$print_path_only" = true ]; then
  printf "%s\n" "$path"
  exit 0
fi

echo "Saved: $path"
echo "Program: $program_raw"
echo "Host: $(parse_url_host "$url_raw")"
echo "Date: ${date_raw:-$timestamp}"
echo "Context: $context_raw"
