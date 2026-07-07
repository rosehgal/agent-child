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
  cp "$SCRIPT_DIR/bin/childmux" "$BIN_DIR/childmux"
  cp "$SCRIPT_DIR/commands/child.md" "$CMD_DIR/child.md"
else
  curl -fsSL "$REPO_RAW/bin/child" -o "$BIN_DIR/child"
  curl -fsSL "$REPO_RAW/bin/childmux" -o "$BIN_DIR/childmux"
  curl -fsSL "$REPO_RAW/commands/child.md" -o "$CMD_DIR/child.md"
fi
chmod +x "$BIN_DIR/child" "$BIN_DIR/childmux"

echo "installed: $BIN_DIR/child"
echo "installed: $BIN_DIR/childmux  (launch your agent inside tmux for in-window splits)"
echo "installed: $CMD_DIR/child.md  (/child command in Claude Code)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "WARNING: tmux is not installed. Install it with: brew install tmux (macOS) or apt install tmux (Linux)"
fi

# --- tmux quality-of-life: mouse support (click panes to focus, drag borders) ---
TMUX_CONF="$HOME/.tmux.conf"
if ! grep -qs 'set -g mouse on' "$TMUX_CONF" 2>/dev/null; then
  printf '\nset -g mouse on\n' >> "$TMUX_CONF"
  echo "configured: mouse support in $TMUX_CONF"
fi
tmux set-option -g mouse on 2>/dev/null || true  # apply to a running server too

# --- Shift+Enter passthrough (needed by Claude Code inside tmux) ---
# tmux swallows modified keys like Shift+Enter unless extended-keys are enabled.
if ! grep -qs 'extended-keys' "$TMUX_CONF" 2>/dev/null; then
  printf 'set -s extended-keys always\nset -as terminal-features "xterm*:extkeys"\n' >> "$TMUX_CONF"
  echo "configured: Shift+Enter (extended-keys) passthrough in $TMUX_CONF"
  echo "  (a running tmux server picks this up fully only after restart: tmux kill-server)"
fi
tmux set-option -s extended-keys always 2>/dev/null || true

# --- auto-tmux: make plain `claude` always start inside tmux ---
# Claude Code has no native setting for this (--tmux requires --worktree),
# so we install a shell alias that routes through childmux. Skip with
# CHILD_NO_ALIAS=1.
if [ "${CHILD_NO_ALIAS:-0}" != "1" ]; then
  ALIAS_LINE="alias claude='childmux claude'  # agent-child: start claude inside tmux"
  case "$(basename "${SHELL:-}")" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) RC="$HOME/.bashrc" ;;
    *)    RC="" ;;
  esac
  if [ -n "$RC" ]; then
    if ! grep -qs "agent-child: start claude inside tmux" "$RC" 2>/dev/null; then
      printf '\n%s\n' "$ALIAS_LINE" >> "$RC"
      echo "configured: 'claude' alias in $RC — new claude sessions start inside tmux"
      echo "  (open a new terminal or 'source $RC' to activate; set CHILD_NO_ALIAS=1 to skip)"
    fi
  else
    echo "NOTE: couldn't detect your shell rc file; to auto-start claude in tmux add:"
    echo "  $ALIAS_LINE"
  fi
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "WARNING: $BIN_DIR is not on your PATH. Add it to your shell profile:"
     echo "  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
