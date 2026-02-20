#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/lib/grabber-sources.sh"

if [ ! -f "$LIB_FILE" ]; then
  echo "Missing sources registry: $LIB_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$LIB_FILE"

category_filter=""
json_output=false
ids_only=false
categories_only=false

usage() {
  cat <<'USAGE'
Usage: grabber-sources.sh [options]

List canonical source labels for browser, CLI, IDE, and agent workflows.

Options:
  --ids                 Print only source IDs
  --categories          Print available categories
  --category <name>     Filter by one category
  --json                Print JSON output
  -h, --help            Show help

Examples:
  grabber-sources.sh
  grabber-sources.sh --ids
  grabber-sources.sh --category cli
  grabber-sources.sh --json
USAGE
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --ids)
      ids_only=true
      shift
      ;;
    --categories)
      categories_only=true
      shift
      ;;
    --category)
      category_filter="${2:-}"
      shift 2
      ;;
    --json)
      json_output=true
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

if [ "$ids_only" = true ] && [ "$categories_only" = true ]; then
  echo "--ids and --categories cannot be used together." >&2
  exit 1
fi

if [ -n "$category_filter" ]; then
  if ! grabber_source_categories | grep -Fxq "$category_filter"; then
    echo "Unknown category: $category_filter" >&2
    echo "Available categories:"
    grabber_source_categories
    exit 1
  fi
fi

if [ "$categories_only" = true ]; then
  if [ "$json_output" = true ]; then
    first=true
    printf '['
    while IFS= read -r cat; do
      [ -n "$cat" ] || continue
      if [ "$first" = false ]; then
        printf ','
      fi
      first=false
      printf '"%s"' "$(json_escape "$cat")"
    done < <(grabber_source_categories)
    printf ']\n'
    exit 0
  fi
  grabber_source_categories
  exit 0
fi

rows="$(grabber_source_rows)"
if [ -n "$category_filter" ]; then
  rows="$(printf "%s\n" "$rows" | awk -F'|' -v c="$category_filter" '$2 == c')"
fi

if [ -z "$rows" ]; then
  echo "No sources found." >&2
  exit 1
fi

if [ "$ids_only" = true ]; then
  printf "%s\n" "$rows" | awk -F'|' '{ print $1 }'
  exit 0
fi

if [ "$json_output" = true ]; then
  first=true
  printf '['
  while IFS='|' read -r id category description; do
    [ -n "$id" ] || continue
    if [ "$first" = false ]; then
      printf ','
    fi
    first=false
    printf '{"id":"%s","category":"%s","description":"%s"}' \
      "$(json_escape "$id")" \
      "$(json_escape "$category")" \
      "$(json_escape "$description")"
  done <<< "$rows"
  printf ']\n'
  exit 0
fi

printf "%-18s %-10s %s\n" "SOURCE" "CATEGORY" "DESCRIPTION"
printf "%-18s %-10s %s\n" "------" "--------" "-----------"
while IFS='|' read -r id category description; do
  [ -n "$id" ] || continue
  printf "%-18s %-10s %s\n" "$id" "$category" "$description"
done <<< "$rows"
