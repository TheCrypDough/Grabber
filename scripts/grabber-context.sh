#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: grabber-context.sh <command> --file <path> [options]

Commands:
  summary   Generate a structured context summary markdown file
  code      Extract fenced code blocks into a markdown file

Options:
  --file <path>       Input conversation markdown file
  --out <path>        Output file path (optional)
  --max-items <n>     Summary list cap per section (default: 8)
  -h, --help          Show help

Examples:
  grabber-context.sh summary --file ~/convos/20260219-132000_chatgpt@chatgpt-com_auth.md
  grabber-context.sh code --file ~/convos/20260219-132000_chatgpt@chatgpt-com_auth.md
USAGE
}

extract_field() {
  local key="$1"
  local file="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm {
      if (index($0, key ":") == 1) {
        sub(/^[^:]*:[[:space:]]*/, "", $0)
        gsub(/^"|"$/, "", $0)
        gsub(/^'"'"'|'"'"'$/, "", $0)
        print
        exit
      }
    }
  ' "$file"
}

strip_frontmatter() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { in_fm=0; next }
    !in_fm { print }
  ' "$file"
}

role_highlights() {
  local file="$1"
  local target="$2"
  local max_items="$3"
  strip_frontmatter "$file" | awk -v target="$target" -v max_items="$max_items" '
    BEGIN { role=""; in_code=0; count=0 }

    /^```/ {
      in_code = !in_code
      next
    }

    /^##[[:space:]]+/ {
      h = tolower(substr($0, 4))
      role = ""
      if (h ~ /^(user|human|you)([[:space:]]|$)/) {
        role = "user"
      } else if (h ~ /^(assistant|model|ai|bot)([[:space:]]|$)/) {
        role = "assistant"
      }
      next
    }

    in_code { next }

    role == target {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^>/) {
        next
      }
      print line
      count++
      role = ""
      if (count >= max_items) {
        exit
      }
    }
  '
}

code_languages() {
  local file="$1"
  strip_frontmatter "$file" \
    | awk '/^```/ { lang = substr($0, 4); gsub(/[[:space:]]+$/, "", lang); if (lang != "") print lang }' \
    | sort -u \
    | tr '\n' ',' \
    | sed 's/,$//'
}

write_summary() {
  local input_file="$1"
  local output_file="$2"
  local max_items="$3"
  local source title date url message_count code_count langs now_iso

  source="$(extract_field "source" "$input_file" || true)"
  title="$(extract_field "title" "$input_file" || true)"
  date="$(extract_field "date" "$input_file" || true)"
  url="$(extract_field "url" "$input_file" || true)"

  if [ -z "$source" ]; then source="unknown"; fi
  if [ -z "$title" ]; then title="conversation"; fi
  if [ -z "$date" ]; then date="unknown"; fi
  if [ -z "$url" ]; then url="unknown"; fi

  message_count="$(strip_frontmatter "$input_file" | grep -Ec '^##[[:space:]]+' || true)"
  code_count="$(strip_frontmatter "$input_file" | grep -Ec '^```' || true)"
  code_count=$((code_count / 2))
  langs="$(code_languages "$input_file")"
  if [ -z "$langs" ]; then langs="none"; fi
  now_iso="$(date -u "+%Y-%m-%dT%H:%M:%SZ")"

  {
    echo "---"
    echo "grabber_summary: v1"
    echo "generated_at: $now_iso"
    echo "source_file: \"$input_file\""
    echo "---"
    echo
    echo "# Conversation Summary"
    echo
    echo "## Metadata"
    echo "- source: $source"
    echo "- title: $title"
    echo "- date: $date"
    echo "- url: $url"
    echo "- message headings: $message_count"
    echo "- code blocks: $code_count"
    echo "- code languages: $langs"
    echo
    echo "## User Requests"
    user_lines="$(role_highlights "$input_file" "user" "$max_items" || true)"
    if [ -z "$user_lines" ]; then
      echo "1. (none detected)"
    else
      i=1
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        echo "$i. $line"
        i=$((i + 1))
      done <<< "$user_lines"
    fi
    echo
    echo "## Assistant Responses"
    assistant_lines="$(role_highlights "$input_file" "assistant" "$max_items" || true)"
    if [ -z "$assistant_lines" ]; then
      echo "1. (none detected)"
    else
      i=1
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        echo "$i. $line"
        i=$((i + 1))
      done <<< "$assistant_lines"
    fi
  } > "$output_file"

  echo "Summary written: $output_file"
}

write_code_extract() {
  local input_file="$1"
  local output_file="$2"

  {
    echo "# Code Extract"
    echo
    echo "Source file: \`$input_file\`"
    echo
    strip_frontmatter "$input_file" | awk '
      BEGIN { in_code=0; idx=0; lang="" }
      /^```/ {
        if (!in_code) {
          idx++
          lang = substr($0, 4)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", lang)
          if (lang == "") {
            lang = "text"
          }
          print "## Block " idx " (" lang ")"
          print ""
          print "```" lang
          in_code=1
        } else {
          print "```"
          print ""
          in_code=0
        }
        next
      }
      in_code { print }
    '
  } > "$output_file"

  echo "Code extract written: $output_file"
}

command="${1:-}"
if [ -z "$command" ] || [ "$command" = "-h" ] || [ "$command" = "--help" ]; then
  usage
  exit 0
fi
shift || true

input_file=""
output_file=""
max_items="8"

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      input_file="${2:-}"
      shift 2
      ;;
    --out)
      output_file="${2:-}"
      shift 2
      ;;
    --max-items)
      max_items="${2:-}"
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

if [ -z "$input_file" ]; then
  echo "--file is required." >&2
  exit 1
fi
if [ ! -f "$input_file" ]; then
  echo "Input file not found: $input_file" >&2
  exit 1
fi
if ! printf "%s" "$max_items" | grep -Eq '^[0-9]+$'; then
  echo "--max-items must be an integer." >&2
  exit 1
fi

base="${input_file%.md}"

case "$command" in
  summary)
    if [ -z "$output_file" ]; then
      output_file="${base}.summary.md"
    fi
    write_summary "$input_file" "$output_file" "$max_items"
    ;;
  code)
    if [ -z "$output_file" ]; then
      output_file="${base}.code.md"
    fi
    write_code_extract "$input_file" "$output_file"
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 1
    ;;
esac
