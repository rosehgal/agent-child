---
description: Fork this session into a tmux split pane running a child agent
argument-hint: "[--agent claude|gemini|codex] [prompt for the child agent]"
allowed-tools: Bash(child:*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/child:*)
---

Fork the current session into a background child agent running in a tmux split pane, using the `child` CLI.

Steps:

1. Resolve the binary: use `child` if it is on PATH, otherwise `${CLAUDE_PLUGIN_ROOT}/bin/child`.
2. Determine the current session ID if you can — it is the UUID that appears in your scratchpad/transcript directory path. If you cannot determine it, omit `--session`; the script auto-detects the newest session for this project, which is the current one.
3. Run it, passing the user's arguments through:

   ```
   child --session <session-uuid> -- $ARGUMENTS
   ```

   If the user passed `--agent`, `--cmd`, `--no-fork`, `--list`, or `--killall`, forward them before the `--`.
4. Relay the script's output to the user verbatim — especially the pane ID and, if printed, the `tmux attach -t child-<pid>` command they need to see the child agent. If the current session is not running inside tmux, tell the user the window they are looking at cannot be split (tmux can only split its own windows), that they can attach from any terminal or pass `--open` (macOS), and that starting the agent with `childmux` next time makes /child split the current window in place.

Notes:
- The child is a **fork** of this session (same conversation history) by default; it runs independently from here on.
- All child panes are automatically killed when this main agent process exits.
- Do not wait for or monitor the child agent; it is interactive and belongs to the user.
