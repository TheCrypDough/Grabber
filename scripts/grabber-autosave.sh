#!/usr/bin/env bash
set -euo pipefail

SAVE_SCRIPT="${GRABBER_SAVE_SCRIPT:-${CTXPORT_SAVE_SCRIPT:-$HOME/Github Repositories/Grabber/scripts/grabber-save.sh}}"
POLL_SECONDS="${GRABBER_AUTOSAVE_POLL_SECONDS:-${CTXPORT_AUTOSAVE_POLL_SECONDS:-2}}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_ROOT/grabber"
PID_FILE="$STATE_DIR/autosave.pid"
LOG_FILE="$STATE_DIR/autosave.log"

mkdir -p "$STATE_DIR"

usage() {
  cat <<'USAGE'
Usage: grabber-autosave.sh <command>

Commands:
  start    Run autosave in background
  stop     Stop background autosave
  restart  Restart background autosave
  status   Show autosave status
  run      Run loop in foreground
  once     Save current clipboard once (if it is Grabber content)
  help     Show this help

Environment:
  GRABBER_ARCHIVE_DIR             Destination folder (default: ~/convos)
  GRABBER_AUTOSAVE_POLL_SECONDS   Poll interval in seconds (default: 2)
USAGE
}

is_pid_running() {
  local pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

get_pid() {
  if [ -f "$PID_FILE" ]; then
    cat "$PID_FILE"
  fi
}

read_clipboard_safe() {
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Get-Clipboard -Raw" 2>/dev/null | tr -d '\r'
    return 0
  fi

  if command -v wl-paste >/dev/null 2>&1; then
    wl-paste -n 2>/dev/null || true
    return 0
  fi

  if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o 2>/dev/null || true
    return 0
  fi

  if command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --output 2>/dev/null || true
    return 0
  fi

  if command -v pbpaste >/dev/null 2>&1; then
    pbpaste 2>/dev/null || true
    return 0
  fi

  return 1
}

hash_text() {
  local text="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf "%s" "$text" | sha256sum | awk '{print $1}'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf "%s" "$text" | shasum -a 256 | awk '{print $1}'
    return
  fi

  # Fallback: weak hash by length and first bytes.
  printf "%s_%s" "${#text}" "$(printf "%s" "$text" | head -c 32)"
}

is_grabber_content() {
  local text="$1"
  printf "%s\n" "$text" | head -n 40 | grep -Eq '^(ctxport|grabber):[[:space:]]*v2$'
}

save_if_grabber() {
  local text="$1"
  if ! is_grabber_content "$text"; then
    return 1
  fi

  if [ ! -x "$SAVE_SCRIPT" ]; then
    echo "Save script not executable: $SAVE_SCRIPT" >&2
    return 1
  fi

  printf "%s\n" "$text" | "$SAVE_SCRIPT" --from-stdin
  return 0
}

run_loop() {
  echo "Grabber autosave loop started (poll=${POLL_SECONDS}s)"
  local last_hash=""

  while true; do
    local content
    content="$(read_clipboard_safe || true)"

    if [ -n "${content//[$'\t\n\r ']/}" ] && is_grabber_content "$content"; then
      local current_hash
      current_hash="$(hash_text "$content")"
      if [ "$current_hash" != "$last_hash" ]; then
        if save_if_grabber "$content"; then
          last_hash="$current_hash"
        fi
      fi
    fi

    sleep "$POLL_SECONDS"
  done
}

start_background() {
  local existing_pid
  existing_pid="$(get_pid || true)"
  if is_pid_running "${existing_pid:-}"; then
    echo "Grabber autosave already running (pid=$existing_pid)"
    return 0
  fi

  nohup "$0" run >>"$LOG_FILE" 2>&1 &
  local pid=$!
  echo "$pid" > "$PID_FILE"
  echo "Grabber autosave started (pid=$pid)"
  echo "Log: $LOG_FILE"
}

stop_background() {
  local pid
  pid="$(get_pid || true)"
  if ! is_pid_running "${pid:-}"; then
    rm -f "$PID_FILE"
    echo "Grabber autosave is not running"
    return 0
  fi

  kill "$pid" >/dev/null 2>&1 || true
  rm -f "$PID_FILE"
  echo "Grabber autosave stopped (pid=$pid)"
}

status_background() {
  local pid
  pid="$(get_pid || true)"
  if is_pid_running "${pid:-}"; then
    echo "Grabber autosave is running (pid=$pid)"
    echo "Log: $LOG_FILE"
    return 0
  fi

  echo "Grabber autosave is not running"
  return 1
}

command="${1:-help}"

case "$command" in
  start)
    start_background
    ;;
  stop)
    stop_background
    ;;
  restart)
    stop_background
    start_background
    ;;
  status)
    status_background
    ;;
  run)
    run_loop
    ;;
  once)
    content="$(read_clipboard_safe || true)"
    if [ -z "${content//[$'\t\n\r ']/}" ]; then
      echo "Clipboard is empty"
      exit 1
    fi
    if ! save_if_grabber "$content"; then
      echo "Clipboard does not look like Grabber content (grabber/ctxport: v2 not found)"
      exit 1
    fi
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 1
    ;;
esac
