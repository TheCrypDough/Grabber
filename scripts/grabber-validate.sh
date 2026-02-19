#!/usr/bin/env bash
set -euo pipefail

MODE="full"
WITH_BUILD_ALL=false
AUTO_FIX_LINT=false

usage() {
  cat <<'USAGE'
Usage: grabber-validate.sh [options]

Options:
  --quick            Run core validation only
  --full             Run full validation (default)
  --with-build-all   Also run pnpm build
  --auto-fix-lint    Run pnpm lint:fix before validation
  -h, --help         Show help

Outputs:
  reports/runs/<timestamp>/
    - *.log per check
    - results.tsv
    - SUMMARY.md
    - summary.json
  reports/latest -> latest run directory symlink
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --quick)
      MODE="quick"
      shift
      ;;
    --full)
      MODE="full"
      shift
      ;;
    --with-build-all)
      WITH_BUILD_ALL=true
      shift
      ;;
    --auto-fix-lint)
      AUTO_FIX_LINT=true
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
REPORT_ROOT="$REPO_DIR/reports"
RUNS_DIR="$REPORT_ROOT/runs"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%SZ)"
RUN_DIR="$RUNS_DIR/$TIMESTAMP"

mkdir -p "$RUN_DIR"

RESULTS_FILE="$RUN_DIR/results.tsv"
SUMMARY_MD="$RUN_DIR/SUMMARY.md"
SUMMARY_JSON="$RUN_DIR/summary.json"

echo -e "check\tstatus\tlog" > "$RESULTS_FILE"

run_check() {
  local name="$1"
  local cmd="$2"
  local log_file="$RUN_DIR/${name}.log"

  echo "== $name =="
  echo "+ $cmd"

  if bash -lc "cd '$REPO_DIR' && $cmd" >"$log_file" 2>&1; then
    echo -e "${name}\tPASS\t${log_file}" >> "$RESULTS_FILE"
    echo "PASS: $name"
  else
    echo -e "${name}\tFAIL\t${log_file}" >> "$RESULTS_FILE"
    echo "FAIL: $name (see $log_file)"
  fi
}

if [ "$AUTO_FIX_LINT" = true ]; then
  run_check "lint_fix" "pnpm lint:fix"
fi

run_check "global_command_install" "./scripts/install-global-commands.sh"
run_check "grabber_help" "grabber help"
run_check "bash_syntax_scripts" "bash -n scripts/*.sh"
run_check "self_test_quick" "./scripts/grabber-self-test.sh"

if [ "$MODE" = "full" ]; then
  run_check "self_test_full" "./scripts/grabber-self-test.sh --profile full --run-plugin-tests"
  run_check "lint" "pnpm lint"
  run_check "test" "pnpm test"
  run_check "extension_build" "pnpm build:extension"
  run_check "core_plugins_test" "pnpm test:core-plugins"
fi

if [ "$WITH_BUILD_ALL" = true ]; then
  run_check "build_all" "pnpm build"
fi

TOTAL_COUNT=$(awk 'NR>1 {count++} END {print count+0}' "$RESULTS_FILE")
PASS_COUNT=$(awk 'NR>1 && $2=="PASS" {count++} END {print count+0}' "$RESULTS_FILE")
FAIL_COUNT=$((TOTAL_COUNT - PASS_COUNT))

{
  echo "# Grabber Validation Report"
  echo
  echo "- timestamp_utc: $TIMESTAMP"
  echo "- mode: $MODE"
  echo "- with_build_all: $WITH_BUILD_ALL"
  echo "- auto_fix_lint: $AUTO_FIX_LINT"
  echo "- total_checks: $TOTAL_COUNT"
  echo "- passed: $PASS_COUNT"
  echo "- failed: $FAIL_COUNT"
  echo
  echo "## Results"
  echo
  echo "| Check | Status | Log |"
  echo "|---|---|---|"
  awk -F '\t' 'NR>1 {printf "| %s | %s | `%s` |\n", $1, $2, $3}' "$RESULTS_FILE"
  echo
  echo "## Next Steps"
  echo
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "All checks passed."
  else
    echo "Review failed check logs and re-run:"
    echo "\`./scripts/grabber-validate.sh --full\`"
  fi
} > "$SUMMARY_MD"

{
  echo "{"
  echo "  \"timestamp_utc\": \"${TIMESTAMP}\","
  echo "  \"mode\": \"${MODE}\","
  echo "  \"with_build_all\": ${WITH_BUILD_ALL},"
  echo "  \"auto_fix_lint\": ${AUTO_FIX_LINT},"
  echo "  \"total_checks\": ${TOTAL_COUNT},"
  echo "  \"passed\": ${PASS_COUNT},"
  echo "  \"failed\": ${FAIL_COUNT}"
  echo "}"
} > "$SUMMARY_JSON"

ln -sfn "$RUN_DIR" "$REPORT_ROOT/latest"

echo
echo "Validation run complete."
echo "Summary: $SUMMARY_MD"
echo "JSON: $SUMMARY_JSON"
echo "Latest link: $REPORT_ROOT/latest"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi
