#!/usr/bin/env bash
set -euo pipefail

MODE="full"
AUTO_FIX=false
WITH_BUILD_ALL=false

usage() {
  cat <<'USAGE'
Usage: grabber-doctor.sh [options]

Run validation, summarize failures, and optionally attempt safe auto-fix.

Options:
  --quick            Run quick validation profile
  --full             Run full validation profile (default)
  --with-build-all   Include full workspace build in validation
  --auto-fix         Run pnpm lint:fix, then re-validate if first pass fails
  -h, --help         Show help

Examples:
  grabber-doctor.sh --quick
  grabber-doctor.sh --full --auto-fix
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
    --auto-fix)
      AUTO_FIX=true
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
VALIDATE_SCRIPT="$REPO_DIR/scripts/grabber-validate.sh"
LATEST_DIR="$REPO_DIR/reports/latest"

if [ ! -x "$VALIDATE_SCRIPT" ]; then
  echo "Validate script not executable: $VALIDATE_SCRIPT" >&2
  exit 1
fi

validate_args=()
if [ "$MODE" = "quick" ]; then
  validate_args+=(--quick)
else
  validate_args+=(--full)
fi
if [ "$WITH_BUILD_ALL" = true ]; then
  validate_args+=(--with-build-all)
fi

run_validate() {
  "$VALIDATE_SCRIPT" "${validate_args[@]}"
}

print_failure_report() {
  if [ ! -d "$LATEST_DIR" ]; then
    echo "No validation report directory found at: $LATEST_DIR"
    return
  fi

  local results_file="$LATEST_DIR/results.tsv"
  if [ ! -f "$results_file" ]; then
    echo "No results.tsv found at: $results_file"
    return
  fi

  echo
  echo "Doctor failure summary:"
  awk -F '\t' 'NR>1 && $2=="FAIL" {printf "- %s (%s)\n", $1, $3}' "$results_file"

  echo
  echo "First error lines per failed check:"
  while IFS=$'\t' read -r check status log_file; do
    if [ "$status" != "FAIL" ]; then
      continue
    fi
    echo
    echo "[$check] $log_file"
    if [ -f "$log_file" ]; then
      rg -n -m 5 -e "error|fail|exception|cannot|not found" "$log_file" || sed -n '1,15p' "$log_file"
    else
      echo "Log file missing."
    fi
  done < <(tail -n +2 "$results_file")
}

echo "== Grabber doctor =="
echo "Repo: $REPO_DIR"
echo "Mode: $MODE"
echo "Auto-fix: $AUTO_FIX"
echo "With build all: $WITH_BUILD_ALL"
echo
echo "Running validation..."

if run_validate; then
  echo
  echo "Doctor PASS: validation succeeded."
  echo "Report: $LATEST_DIR/SUMMARY.md"
  exit 0
fi

print_failure_report

if [ "$AUTO_FIX" != true ]; then
  echo
  echo "Doctor FAIL: validation failed."
  echo "Tip: run with --auto-fix for a safe lint-fix + revalidate attempt."
  exit 1
fi

echo
echo "Attempting auto-fix: pnpm lint:fix"
if ! bash -lc "cd '$REPO_DIR' && pnpm lint:fix"; then
  echo "Auto-fix step failed."
  exit 1
fi

echo "Re-running validation..."
if run_validate; then
  echo
  echo "Doctor PASS after auto-fix."
  echo "Report: $LATEST_DIR/SUMMARY.md"
  exit 0
fi

print_failure_report
echo
echo "Doctor FAIL after auto-fix."
echo "Report: $LATEST_DIR/SUMMARY.md"
exit 1
