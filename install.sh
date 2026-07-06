#!/usr/bin/env bash
# Installs the `child` CLI and the /child Claude Code slash command.
#
#   curl -fsSL https://raw.githubusercontent.com/rosehgal/agent-child/main/install.sh | bash
#
# or from a clone:  ./install.sh
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/rosehgal/agent-child/main"
BIN_DIR="${CHILD_BIN_DIR:-$HOME/.local/bin}"
CMD_DIR="$HOME/.claude/commands"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")

mkdir -p "$BIN_DIR" "$CMD_DIR"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/child" ]; then
  cp "$SCRIPT_DIR/bin/child" "$BIN_DIR/child"
  cp "$SCRIPT_DIR/commands/child.md" "$CMD_DIR/child.md"
else
  curl -fsSL "$REPO_RAW/bin/child" -o "$BIN_DIR/child"
  curl -fsSL "$REPO_RAW/commands/child.md" -o "$CMD_DIR/child.md"
fi
chmod +x "$BIN_DIR/child"

echo "installed: $BIN_DIR/child"
echo "installed: $CMD_DIR/child.md  (/child command in Claude Code)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "WARNING: tmux is not installed. Install it with: brew install tmux (macOS) or apt install tmux (Linux)"
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "WARNING: $BIN_DIR is not on your PATH. Add it to your shell profile:"
     echo "  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
