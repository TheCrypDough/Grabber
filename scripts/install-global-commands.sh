#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="${GRABBER_BIN_DIR:-$HOME/.local/bin}"

mkdir -p "$BIN_DIR"

install_wrapper() {
  local name="$1"
  local target="$2"
  cat > "$BIN_DIR/$name" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$target" "\$@"
EOF
  chmod +x "$BIN_DIR/$name"
}

install_wrapper "grabber" "$REPO_DIR/scripts/grabber-cli.sh"
install_wrapper "grabber-save" "$REPO_DIR/scripts/grabber-save.sh"
install_wrapper "grabber-autosave" "$REPO_DIR/scripts/grabber-autosave.sh"

echo "Installed commands to: $BIN_DIR"
echo "Commands:"
echo "  grabber, grabber-save, grabber-autosave"
