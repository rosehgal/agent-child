# agent-child

**Fork your AI agent session into tmux split panes. Child agents die when the parent exits.**

You're deep in a Claude Code (or Gemini CLI, Codex, ...) session and want to hand a task to a second agent *with the same context* — without losing your main session, and without orphaned processes hanging around afterwards. `agent-child` gives you a `/child` command (and a standalone `child` CLI) that:

- **Forks the current session** into a new tmux pane — for Claude Code it uses `claude --resume <session> --fork-session`, so the child starts with your full conversation history.
- **Organizes the splits** — the main agent stays in the big pane, children stack beside it (`main-vertical` layout), or live in a dedicated tmux session if the parent isn't running inside tmux.
- **Ties child lifetime to the parent** — every child pane runs a watchdog on the main agent's PID. When the main agent exits, every child pane (and the tmux session created for them) is killed automatically. No orphans.
- **Works with any agent** — `--agent gemini`, `--agent codex`, or `--cmd "anything"`.

```
┌─────────────────────────────┬──────────────────┐
│                             │ child #1         │
│   main agent                │ (forked session) │
│   (claude)                  ├──────────────────┤
│                             │ child #2         │
│                             │ (gemini)         │
└─────────────────────────────┴──────────────────┘
        main exits  ──►  all children killed
```

## Install

Requires `tmux` (`brew install tmux` / `apt install tmux`).

**One-liner** (installs `child` to `~/.local/bin` and the `/child` command to `~/.claude/commands`):

```sh
curl -fsSL https://raw.githubusercontent.com/rosehgal/agent-child/main/install.sh | bash
```

**As a Claude Code plugin:**

```
/plugin marketplace add rosehgal/agent-child
/plugin install agent-child@agent-child
```

**From a clone:** `git clone https://github.com/rosehgal/agent-child && cd agent-child && ./install.sh`

## Use

**Important:** tmux can only split a window it owns — it cannot split a plain
terminal from the outside. To get child panes appearing *in the same window*
as your main agent, start the agent with `childmux` (installed alongside
`child`):

```sh
childmux                     # starts claude inside tmux, splittable
childmux claude --continue   # or any agent command
childmux gemini
```

If you start your agent without tmux, `/child` still works — children are
collected in a background tmux session you can attach to (the attach command
is printed) — but the window you're typing in won't visually split.

Inside Claude Code:

```
/child go fix the flaky tests while I keep working here
/child --agent gemini review this diff for security issues
```

Or from any shell / any agent's bash tool:

```sh
child "continue debugging the auth issue"        # fork current claude session
child --agent gemini "summarize recent commits"  # different agent, same pane management
child --cmd "npm run dev"                        # any long-running command
child --no-fork "fresh claude, no shared history"
child --list                                     # live children of this main agent
child --killall                                  # kill them all now
```

If the main agent **is running inside tmux**, children appear as splits in the same window and focus stays on the main pane. If it **isn't**, children are collected in a detached tmux session named `child-<main-pid>` — attach with `tmux attach -t child-<pid>` (printed on spawn), or pass `--open` on macOS to pop a Terminal window automatically.

## How it works

1. `child` walks up its process ancestry to find the main agent process (claude, gemini, codex, cursor-agent, aider, ...). That PID becomes the lifetime anchor. (Override with `--main-pid`.)
2. For Claude Code it resolves the current session ID (env var, `--session`, or the newest transcript in `~/.claude/projects/<project-slug>/`) and launches `claude --resume <id> --fork-session` — a true fork: same history, new session ID, fully independent from then on.
3. The child runs inside a tiny wrapper in the tmux pane:

   ```sh
   ( while kill -0 $MAIN_PID; do sleep 2; done
     tmux kill-pane -t "$TMUX_PANE" ) &
   exec <child agent command>
   ```

   The agent owns the pane's TTY in the foreground; the watchdog polls the main PID and kills the pane the moment the parent is gone. When the child exits on its own, the pane closes naturally. When the last pane in a dedicated `child-<pid>` session dies, tmux removes the session too.

## Options

| Flag | Meaning |
|---|---|
| `--agent <name>` | Agent CLI to run (default `claude`) |
| `--cmd "<command>"` | Arbitrary command instead of an agent |
| `--session <uuid>` | Claude session ID to fork (default: auto-detect) |
| `--no-fork` | Fresh Claude session instead of forking |
| `--main-pid <pid>` | Override the lifetime-anchor PID |
| `--open` | macOS: open Terminal attached to the child session |
| `--list` / `--killall` | Inspect / kill this parent's children |

## Limitations

- Session **forking** is Claude Code-specific (it's the only CLI with `--resume --fork-session`); other agents start fresh sessions in managed panes with the same lifecycle guarantees.
- The watchdog polls every 2 s, so children outlive the parent by at most ~2 s.
- PID reuse is theoretically possible on very long-lived systems; `--killall` is your escape hatch.

## License

MIT
