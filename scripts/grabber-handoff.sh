#!/usr/bin/env bash
set -euo pipefail

CONTEXT_SCRIPT="${GRABBER_CONTEXT_SCRIPT:-$HOME/Github Repositories/Grabber/scripts/grabber-context.sh}"
FIND_SCRIPT="${GRABBER_FIND_SCRIPT:-$HOME/Github Repositories/Grabber/scripts/grabber-find.sh}"

usage() {
  cat <<'USAGE'
Usage: grabber-handoff.sh [options]

Create a single handoff package from a saved conversation bundle.

If --file is omitted, Grabber resolves the source bundle through find filters.

Options:
  --file <path>      Source bundle markdown file
  --out <path>       Output handoff markdown path
  --json             Print machine-readable JSON result
  --no-code          Skip code extract generation/inclusion
  --max-items <n>    Summary list cap per section (default: 8)

Find filters (used only when --file is omitted):
  --source <name>
  --host <name>
  --date <value>
  --context <text>
  --contains <text>
  --latest <n>       Search depth before choosing first result (default: 20)

  -h, --help         Show help

Examples:
  grabber-handoff.sh --file ~/convos/20260219-132000_chatgpt@chatgpt-com_auth.md
  grabber-handoff.sh --source claude-code --context deploy --latest 20
  grabber-handoff.sh --file ./bundle.md --json
USAGE
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf "%s" "$value"
}

strip_frontmatter_file() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { in_fm=0; next }
    !in_fm { print }
  ' "$file"
}

file=""
out_file=""
json_mode=false
include_code=true
max_items="8"

source_filter=""
host_filter=""
date_filter=""
context_filter=""
contains_filter=""
latest_limit="20"

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      file="${2:-}"
      shift 2
      ;;
    --out)
      out_file="${2:-}"
      shift 2
      ;;
    --json)
      json_mode=true
      shift
      ;;
    --no-code)
      include_code=false
      shift
      ;;
    --max-items)
      max_items="${2:-}"
      shift 2
      ;;
    --source)
      source_filter="${2:-}"
      shift 2
      ;;
    --host)
      host_filter="${2:-}"
      shift 2
      ;;
    --date)
      date_filter="${2:-}"
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

if [ ! -x "$CONTEXT_SCRIPT" ]; then
  echo "Context script not executable: $CONTEXT_SCRIPT" >&2
  exit 1
fi
if [ ! -x "$FIND_SCRIPT" ]; then
  echo "Find script not executable: $FIND_SCRIPT" >&2
  exit 1
fi
if ! printf "%s" "$max_items" | grep -Eq '^[0-9]+$'; then
  echo "--max-items must be an integer." >&2
  exit 1
fi
if ! printf "%s" "$latest_limit" | grep -Eq '^[0-9]+$'; then
  echo "--latest must be an integer." >&2
  exit 1
fi

if [ -z "$file" ]; then
  find_args=(--latest "$latest_limit" --paths)
  if [ -n "$source_filter" ]; then find_args=(--source "$source_filter" "${find_args[@]}"); fi
  if [ -n "$host_filter" ]; then find_args=(--host "$host_filter" "${find_args[@]}"); fi
  if [ -n "$date_filter" ]; then find_args=(--date "$date_filter" "${find_args[@]}"); fi
  if [ -n "$context_filter" ]; then find_args=(--context "$context_filter" "${find_args[@]}"); fi
  if [ -n "$contains_filter" ]; then find_args=(--contains "$contains_filter" "${find_args[@]}"); fi

  file="$("$FIND_SCRIPT" "${find_args[@]}" | head -n 1 || true)"
fi

if [ -z "$file" ]; then
  echo "Could not resolve a source bundle. Provide --file or find filters." >&2
  exit 1
fi
if [ ! -f "$file" ]; then
  echo "Source file not found: $file" >&2
  exit 1
fi

base="${file%.md}"
summary_file="${base}.summary.md"
code_file="${base}.code.md"
handoff_file="${out_file:-${base}.handoff.md}"
generated_at="$(date -u "+%Y-%m-%dT%H:%M:%SZ")"

"$CONTEXT_SCRIPT" summary --file "$file" --out "$summary_file" --max-items "$max_items" >/dev/null
if [ "$include_code" = true ]; then
  "$CONTEXT_SCRIPT" code --file "$file" --out "$code_file" >/dev/null
fi

{
  echo "---"
  echo "grabber_handoff: v1"
  echo "generated_at: $generated_at"
  echo "source_bundle: \"${file}\""
  echo "summary_file: \"${summary_file}\""
  if [ "$include_code" = true ]; then
    echo "code_file: \"${code_file}\""
  fi
  echo "---"
  echo
  echo "# Handoff Package"
  echo
  echo "## Source Bundle"
  echo "- file: \`${file}\`"
  echo "- generated_at: $generated_at"
  echo
  echo "## Summary"
  echo
  strip_frontmatter_file "$summary_file"
  if [ "$include_code" = true ]; then
    echo
    echo "## Code Extract"
    echo
    cat "$code_file"
  fi
} > "$handoff_file"

if [ "$json_mode" = true ]; then
  if [ "$include_code" = true ]; then
    code_json="\"$(json_escape "$code_file")\""
  else
    code_json="null"
  fi
  printf '{\n'
  printf '  "generated_at": "%s",\n' "$(json_escape "$generated_at")"
  printf '  "source_bundle": "%s",\n' "$(json_escape "$file")"
  printf '  "summary_file": "%s",\n' "$(json_escape "$summary_file")"
  printf '  "code_file": %s,\n' "$code_json"
  printf '  "handoff_file": "%s"\n' "$(json_escape "$handoff_file")"
  printf '}\n'
else
  echo "Handoff written: $handoff_file"
  echo "Source bundle: $file"
  echo "Summary file: $summary_file"
  if [ "$include_code" = true ]; then
    echo "Code file: $code_file"
  fi
fi
