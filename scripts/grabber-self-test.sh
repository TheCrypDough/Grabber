#!/usr/bin/env bash
set -euo pipefail

WITH_EXTENSION_BUILD=false
PROFILE="quick"
RUN_PLUGIN_TESTS=false
CLEANUP=false

usage() {
  cat <<'USAGE'
Usage: grabber-self-test.sh [options]

Options:
  --with-extension-build   Build extension and verify manifest exists
  --profile <quick|full>   quick=core smoke, full=additional source matrix
  --run-plugin-tests       Run core-plugins URL matching tests
  --cleanup                Remove temporary artifacts after run
  -h, --help               Show help

What this script validates:
  - command availability
  - ingest (file + stdin)
  - find
  - summary/code generation
  - capture flow
  - autosave start/status/stop
  - optional extension build
  - optional URL matching tests
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --with-extension-build)
      WITH_EXTENSION_BUILD=true
      shift
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --run-plugin-tests)
      RUN_PLUGIN_TESTS=true
      shift
      ;;
    --cleanup)
      CLEANUP=true
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

if [ "$PROFILE" != "quick" ] && [ "$PROFILE" != "full" ]; then
  echo "--profile must be quick or full." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_ROOT="$(mktemp -d /tmp/grabber-selftest-XXXX)"
ARCHIVE_DIR="$TMP_ROOT/archive"
STATE_HOME="$TMP_ROOT/state"
FIXTURE_DIR="$TMP_ROOT/fixtures"
REPORT_FILE="$TMP_ROOT/self-test-report.md"

mkdir -p "$ARCHIVE_DIR" "$STATE_HOME" "$FIXTURE_DIR"

export GRABBER_ARCHIVE_DIR="$ARCHIVE_DIR"
export CTXPORT_ARCHIVE_DIR="$ARCHIVE_DIR"
export XDG_STATE_HOME="$STATE_HOME"

run() {
  echo "+ $*"
  "$@"
}

assert_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "Missing expected file: $path" >&2
    exit 1
  fi
}

echo "== Grabber self-test =="
echo "Repo: $REPO_DIR"
echo "Profile: $PROFILE"
echo "Temp root: $TMP_ROOT"
echo "Archive dir: $ARCHIVE_DIR"
echo "State home: $STATE_HOME"

run "$REPO_DIR/scripts/install-global-commands.sh"
run grabber help >/dev/null
run grabber find --help >/dev/null
run grabber ingest --help >/dev/null
run grabber capture --help >/dev/null
run grabber summary --help >/dev/null
run grabber code --help >/dev/null

cat > "$FIXTURE_DIR/cli-session.md" <<'EOF'
## User
Need deploy-safe rollback.

## Assistant
Use blue/green plus health checks.

```bash
kubectl rollout undo deployment/api
```
EOF

cat > "$FIXTURE_DIR/ide-session.txt" <<'EOF'
User: plan migration path
Assistant: split schema and data phases.
EOF

run grabber ingest --source claude-code --title "selftest deploy rollback" --date "2026-02-19 18:00:00 UTC" --input "$FIXTURE_DIR/cli-session.md"
run bash -lc "cat '$FIXTURE_DIR/ide-session.txt' | grabber ingest --stdin --source cursor --title 'selftest ide ingest'"
run grabber capture --source openclaw --title "selftest capture" -- bash -lc 'echo openclaw capture ok'

CLAUDE_FILE="$(grabber find --source claude-code --latest 1 --paths)"
if [ -z "$CLAUDE_FILE" ] || [ ! -f "$CLAUDE_FILE" ]; then
  echo "Failed to locate claude-code bundle." >&2
  exit 1
fi

run grabber summary --file "$CLAUDE_FILE"
run grabber code --file "$CLAUDE_FILE"

assert_file "${CLAUDE_FILE%.md}.summary.md"
assert_file "${CLAUDE_FILE%.md}.code.md"

run grabber autosave start
run grabber autosave status >/dev/null
run grabber autosave stop

if [ "$PROFILE" = "full" ]; then
  SOURCES=(
    chatgpt claude gemini deepseek grok github
    aistudio perplexity kimi genspark poe mistral-chat copilot qwen
    meta-ai pi-ai you-chat duck-ai groq-chat character-ai huggingchat
    notebooklm openrouter-chat phind blackbox codex-cloud local-agent-chat
    claude-code codex-cli opencode cursor antigravity vscode-chat
    agent-zero openclaw
  )

  for source in "${SOURCES[@]}"; do
    run grabber ingest --source "$source" --title "selftest $source" --input "$FIXTURE_DIR/ide-session.txt"
    run grabber find --source "$source" --latest 1 --paths >/dev/null
  done
fi

if [ "$RUN_PLUGIN_TESTS" = true ]; then
  run bash -lc "cd '$REPO_DIR' && pnpm --filter @ctxport/core-plugins test"
fi

if [ "$WITH_EXTENSION_BUILD" = true ]; then
  run grabber build >/dev/null
  EXT_PATH="$(grabber path)"
  assert_file "$EXT_PATH/manifest.json"
fi

{
  echo "# Grabber Self-Test Report"
  echo
  echo "- profile: $PROFILE"
  echo "- extension_build: $WITH_EXTENSION_BUILD"
  echo "- plugin_tests: $RUN_PLUGIN_TESTS"
  echo "- repo: $REPO_DIR"
  echo "- temp_root: $TMP_ROOT"
  echo "- archive_dir: $ARCHIVE_DIR"
  echo "- state_home: $STATE_HOME"
  echo
  echo "## Pass Criteria"
  echo
  echo "1. Commands available: \`grabber help/find/ingest/capture/summary/code\`"
  echo "2. Ingest works from file and stdin"
  echo "3. Capture creates a saved bundle"
  echo "4. Summary and code artifacts are generated"
  echo "5. Autosave start/status/stop works"
  if [ "$PROFILE" = "full" ]; then
    echo "6. Additional source matrix ingests and is retrievable via \`grabber find\`"
  fi
  if [ "$RUN_PLUGIN_TESTS" = true ]; then
    echo "7. Core plugin URL matching tests pass"
  fi
  if [ "$WITH_EXTENSION_BUILD" = true ]; then
    echo "8. Extension build output contains \`manifest.json\`"
  fi
  echo
  echo "## Archive Files"
  find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.md' | sort
} > "$REPORT_FILE"

echo
echo "Self-test PASS"
echo "Report: $REPORT_FILE"
echo "Artifacts kept at: $TMP_ROOT"
echo "Archive files:"
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.md' | sort

if [ "$CLEANUP" = true ]; then
  rm -rf "$TMP_ROOT"
  echo "Cleanup complete: $TMP_ROOT removed"
fi
