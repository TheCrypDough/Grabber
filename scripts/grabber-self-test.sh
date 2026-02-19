#!/usr/bin/env bash
set -euo pipefail

WITH_EXTENSION_BUILD=false

usage() {
  cat <<'USAGE'
Usage: grabber-self-test.sh [--with-extension-build] [--help]

Runs a local smoke/regression test for Grabber:
- command availability
- ingest (file + stdin)
- find
- summary/code generation
- capture flow
- autosave start/status/stop
- optional extension build
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --with-extension-build)
      WITH_EXTENSION_BUILD=true
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_ROOT="$(mktemp -d /tmp/grabber-selftest-XXXX)"
ARCHIVE_DIR="$TMP_ROOT/archive"
STATE_HOME="$TMP_ROOT/state"
FIXTURE_DIR="$TMP_ROOT/fixtures"

mkdir -p "$ARCHIVE_DIR" "$STATE_HOME" "$FIXTURE_DIR"

export GRABBER_ARCHIVE_DIR="$ARCHIVE_DIR"
export CTXPORT_ARCHIVE_DIR="$ARCHIVE_DIR"
export XDG_STATE_HOME="$STATE_HOME"

run() {
  echo "+ $*"
  "$@"
}

echo "== Grabber self-test =="
echo "Repo: $REPO_DIR"
echo "Temp root: $TMP_ROOT"
echo "Archive dir: $ARCHIVE_DIR"
echo "State home: $STATE_HOME"

run "$REPO_DIR/scripts/install-global-commands.sh"
run grabber help >/dev/null
run grabber find --help >/dev/null
run grabber ingest --help >/dev/null
run grabber capture --help >/dev/null

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

if [ ! -f "${CLAUDE_FILE%.md}.summary.md" ]; then
  echo "Missing summary artifact: ${CLAUDE_FILE%.md}.summary.md" >&2
  exit 1
fi
if [ ! -f "${CLAUDE_FILE%.md}.code.md" ]; then
  echo "Missing code artifact: ${CLAUDE_FILE%.md}.code.md" >&2
  exit 1
fi

run grabber autosave start
run grabber autosave status >/dev/null
run grabber autosave stop

if [ "$WITH_EXTENSION_BUILD" = true ]; then
  run grabber build >/dev/null
  EXT_PATH="$(grabber path)"
  if [ ! -f "$EXT_PATH/manifest.json" ]; then
    echo "Extension build output missing manifest: $EXT_PATH/manifest.json" >&2
    exit 1
  fi
fi

echo
echo "Self-test PASS"
echo "Artifacts kept at: $TMP_ROOT"
echo "Archive files:"
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.md' | sort
