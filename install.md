---
name: browser-install
description: Install browser-harness into the current agent and connect it to a browser with minimal prompting.
---

# `browser-harness` installation

Use this file only for browser-harness install, browser connection setup, and connection troubleshooting. For day-to-day browser work, read `SKILL.md`. Task-specific edits belong in `agent-workspace/agent_helpers.py` and `agent-workspace/domain-skills/`.

## Recommended `browser-harness` setup

### Installable CLI contract

`browser-harness` is the canonical executable. It is provided by `pyproject.toml`:

```toml
[project.scripts]
browser-harness = "browser_harness.run:main"
```

Supported install modes:

- **Editable repo install**: preferred for agents and Workforce-managed hosts.
- **Packaged install**: acceptable when a wheel or index package is intentionally used.

The install is valid only when all of these checks pass from a fresh shell in any directory:

```bash
command -v browser-harness
browser-harness --version
browser-harness --doctor
```

Expected behavior:

- `command -v browser-harness` prints the executable path that the current shell will run.
- `browser-harness --version` prints the installed package version, or `unknown` when package metadata is unavailable in a development checkout.
- `browser-harness --doctor` exits `0` only when the install, daemon, and browser connection are healthy. A nonzero exit is a setup failure to diagnose before giving the command to an agent.

If multiple installs exist, the valid one is the first `browser-harness` on `PATH`. Remove or reorder stale installs before continuing; do not rely on `uv run` or `python -m` as the agent-facing command.

### Editable install

Clone the repo once into a durable location, then install it as an editable tool so `browser-harness` works from any directory:

```bash
git clone https://github.com/browser-use/browser-harness
cd browser-harness
uv tool install -e .
command -v browser-harness
browser-harness --version
browser-harness --doctor
```

That keeps the command global while still pointing at the real repo checkout, so when the agent edits `agent-workspace/agent_helpers.py` the next `browser-harness` uses the new code immediately. Prefer a stable path like `~/Developer/browser-harness`, not `/tmp`.

For the Workforce fork, use the same contract with the fork URL and durable path chosen by the operator:

```bash
git clone https://github.com/Bad-Robots/BrowserHarness ~/workforce/browser-harness
cd ~/workforce/browser-harness
uv tool install -e .
command -v browser-harness
browser-harness --version
browser-harness --doctor
```

Troubleshooting the install contract:

- `command -v browser-harness` prints nothing: add the `uv tool` bin directory to `PATH`, then open a fresh shell and retry.
- `browser-harness --version` prints `unknown`: package metadata is not visible to the active executable. Reinstall with `uv tool install -e .` from the repo root and retry.
- `browser-harness --doctor` says Chrome is not running: start Chrome or Edge, then retry.
- `browser-harness --doctor` says the daemon is not alive: complete the browser connection setup below, then retry.
- `browser-harness --doctor` cannot reach GitHub for latest release: this does not by itself invalidate the install; continue if the local version and browser checks are otherwise healthy.

## Workforce shared environment setup

Workforce-managed agents use one shared browser environment file and workspace. The repo-local setup script is:

```bash
scripts/setup-workforce-browser-env.sh
```

Default paths:

- Env file: `~/.workforce/browser-harness.env`
- Browser Harness checkout: `~/workforce/browser-harness`
- Agent workspace: `~/.workforce/browser-agent-workspace`
- Domain skills: `~/.workforce/browser-agent-workspace/domain-skills`
- Interaction skills: `~/.workforce/browser-agent-workspace/interaction-skills`
- Test results: `~/.workforce/test-results/browser-harness`
- Runtime state: `~/.workforce/state/browser-harness`
- Diagnostic logs: `~/.workforce/logs/browser-harness`
- Wrapper bin directory: `~/.workforce/bin`

Run it from the repo root:

```bash
bash scripts/setup-workforce-browser-env.sh
```

The script is idempotent. It creates missing directories, creates the env file with mode `0600`, appends only missing known keys, preserves unknown keys, and writes a timestamped backup before modifying an existing env file.

Default env keys:

```sh
BH_INSTALL_DIR="$HOME/workforce/browser-harness"
BH_WORKSPACE="$HOME/.workforce/browser-agent-workspace"
BH_DOMAIN_SKILLS="0"
BH_MODE="local"
BH_CDP_URL=""
BH_TEST_RESULTS="$HOME/.workforce/test-results/browser-harness"
BH_STATE_DIR="$HOME/.workforce/state/browser-harness"
BH_LOG_DIR="$HOME/.workforce/logs/browser-harness"
BH_BIN_DIR="$HOME/.workforce/bin"
BH_HEADLESS_PORT="9222"
BH_HEADLESS_PROFILE_DIR="$HOME/.workforce/state/browser-harness/headless-profile"
BH_HEADLESS_STATE_FILE="$HOME/.workforce/state/browser-harness/headless-session.env"
BH_HEADLESS_LOG_FILE="$HOME/.workforce/logs/browser-harness/headless-browser.log"
```

`BH_DOMAIN_SKILLS` intentionally defaults to `0`. The Workforce wrapper refuses `BH_DOMAIN_SKILLS=1` until a reviewed promotion command and review path are implemented.

## Workforce wrapper command

The repo source for the Workforce wrapper is:

```bash
scripts/workforce-browser
```

Install tickets copy or symlink it to:

```bash
~/.workforce/bin/workforce-browser
```

The wrapper loads `${BH_ENV_FILE:-~/.workforce/browser-harness.env}`, validates `BH_MODE`, finds `browser-harness`, and delegates.

Supported wrapper commands:

```bash
workforce-browser --version
workforce-browser --doctor
workforce-browser doctor
workforce-browser run 'print(page_info())'
workforce-browser -- -c 'print(page_info())'
```

`workforce-browser doctor` and `workforce-browser --doctor` report wrapper env status, workspace directories, log destination, and executable resolution, then run `browser-harness --doctor`. `workforce-browser run '<python code>'` delegates to `browser-harness -c '<python code>'`. Arguments after `workforce-browser --` pass through unchanged to `browser-harness`.

Exit codes:

- `0`: command succeeded.
- `64`: usage error.
- `69`: `browser-harness` executable is unavailable.
- `70`: reserved command is not implemented yet.
- `78`: invalid wrapper configuration, such as unsupported `BH_MODE`.

Supported `BH_MODE` values are `local`, `remote-gui`, `headless`, and `external-cdp`. `external-cdp` requires `BH_CDP_URL`, `BU_CDP_URL`, or `BU_CDP_WS`. `BH_DOMAIN_SKILLS` must be `0`; the Workforce wrapper fails closed if it is set to `1`.

Headless lifecycle commands manage only browser processes recorded in `BH_HEADLESS_STATE_FILE`.

```bash
workforce-browser headless start
workforce-browser headless status
workforce-browser headless stop
workforce-browser headless cleanup
```

`start` launches Chrome or Chromium with `--headless=new`, a dedicated user-data-dir, and a loopback CDP endpoint. `status` reports stopped, stale, starting, or ready. `stop` terminates only the recorded managed PID and removes the state file. `cleanup` removes stale state only when the recorded PID is no longer alive.

When installed for agents, put `~/.workforce/bin` on `PATH` before agent sessions start:

```bash
export PATH="$HOME/.workforce/bin:$PATH"
```

## Make browser-harness global for the current agent

After the repo is installed, register this repo's `SKILL.md` with the agent you are using:

- **Codex**: add this file as a global skill at `$CODEX_HOME/skills/browser-harness/SKILL.md` (often `~/.codex/skills/browser-harness/SKILL.md`). A symlink to this repo's `SKILL.md` is fine.

  ```bash
  mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness" && ln -sf "$PWD/SKILL.md" "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness/SKILL.md"
  ```

- **Claude Code**: add an import to `~/.claude/CLAUDE.md` that points at this repo's `SKILL.md`, for example `@~/Developer/browser-harness/SKILL.md`.

This makes new Codex or Claude Code sessions in other folders load the runtime browser harness instructions automatically.

## Keeping the harness current

- On each run, `browser-harness` prints `[browser-harness] update available: X -> Y` (once per day) when a newer GitHub release exists.
- When you see that banner, run `browser-harness --update -y` yourself — don't ask the user. It pulls the new code (`git pull --ff-only` for editable clones, `uv tool upgrade browser-harness` for PyPI installs) and stops the running daemon so the next call picks up the new code. With `-y` it won't prompt.
- `--update` refuses to run on an editable clone with uncommitted changes. If that happens, tell the user and let them resolve the dirty worktree.

## Maintenance commands

- browser-harness --doctor — show version, install mode, daemon and Chrome state, and whether an update is pending.

## Architecture

```text
Chrome / Browser Use cloud -> CDP WS -> browser_harness.daemon -> IPC -> browser_harness.run
```

- Protocol is one JSON line each way.
- Requests are {method, params, session_id} for CDP or {meta: ...} for daemon control.
- Responses are {result} / {error} / {events} / {session_id}.
- IPC: Unix socket at `/tmp/bu-<NAME>.sock` on POSIX, TCP loopback + port file on Windows.
- BU_NAME namespaces the daemon's IPC, pid, and log files.
- BU_CDP_WS overrides local Chrome discovery for remote browsers.
- BU_CDP_URL overrides local Chrome discovery with a specific DevTools HTTP endpoint (used for Way 2).
- BU_BROWSER_ID + BROWSER_USE_API_KEY lets the daemon stop a Browser Use cloud browser on shutdown.

# Browser connection setup and troubleshooting

## Browser connection reference

This section is the source of truth for how browser-harness connects to a browser. It is the canonical reference for every agent and user of this repo. Every statement here is intended to be verifiable against either an official Chrome source or this repo's own code, and is held to that standard deliberately. If anything below is incorrect, incomplete, or misleading, open an issue on the browser-harness repository immediately with clear evidence and explanation so it can be corrected. Do not silently work around an error in this document; the cost of one user being misled is much higher than the cost of one issue.

Browser-harness can connect to any Chrome or Chromium-based browser on your computer, or to a Browser Use cloud browser.

## Workforce remote mode reference

Workforce uses the same CDP transport in every mode. The difference between modes is where the browser process lives and how the operator reaches the GUI when human inspection is needed.

### Local GUI

Use `BH_MODE=local` when the agent and browser run on the same machine and Chrome remote debugging is enabled by Way 1 or Way 2 below. This is the default mode.

### External CDP

Use `BH_MODE=external-cdp` when another process owns the browser lifecycle and gives Workforce a DevTools endpoint.

Required env:

```sh
BH_MODE="external-cdp"
BH_CDP_URL="http://127.0.0.1:9222"
# or BU_CDP_URL / BU_CDP_WS for compatibility with browser-harness internals
```

The wrapper validates that at least one CDP endpoint variable exists. The external process remains responsible for start, stop, profile cleanup, and port selection.

### Remote GUI

Use `BH_MODE=remote-gui` when the browser runs on another host that has a visible desktop session. Browser Harness still uses CDP; remote desktop tools are only for human observation or repair.

Remote GUI support requires host-local setup on the remote machine:

```bash
git clone https://github.com/Bad-Robots/BrowserHarness ~/workforce/browser-harness
cd ~/workforce/browser-harness
uv tool install -e .
bash scripts/setup-workforce-browser-env.sh
ln -sf "$PWD/scripts/workforce-browser" "$HOME/.workforce/bin/workforce-browser"
export PATH="$HOME/.workforce/bin:$PATH"
workforce-browser doctor
```

Do not mark a remote host supported until `workforce-browser doctor` and a browser smoke test pass on that host.

### Tobor and Twiki

Tobor and Twiki are supported targets only when each host has completed the same host-local verification:

- Browser Harness checkout exists at the chosen durable path.
- `browser-harness` resolves on `PATH`.
- `workforce-browser` resolves on `PATH`.
- `~/.workforce/browser-harness.env` exists and has the correct mode for that host.
- The target browser or external CDP endpoint is reachable from that host.
- Verification logs are saved under `~/.workforce/test-results/browser-harness/`.

Do not assume support just because the repo exists elsewhere. Each host has its own browser, PATH, shell startup, permissions, and CDP reachability.

### RustDesk

RustDesk is human GUI access only. It is useful for seeing the desktop, clicking a browser permission prompt, or repairing a remote session. It is not the automation transport and does not replace CDP.

When RustDesk is involved, the automation path is still:

```text
agent -> workforce-browser -> browser-harness -> CDP -> browser
```

If CDP is unavailable, RustDesk can help a human fix the browser session, but agents should not automate through RustDesk itself.

**Cloud browsers** are managed by the Browser Use cloud API. Start one in Python with `start_remote_daemon("work", ...)`. Authentication is via the `BROWSER_USE_API_KEY` environment variable; the harness handles the WebSocket URL itself. To carry your local Chrome cookies into a cloud browser, install `profile-use` once (`curl -fsSL https://browser-use.com/profile.sh | sh`), then call `uuid = sync_local_profile("MyChromeProfile")` followed by `start_remote_daemon("work", profileId=uuid)`. Cookies are the only thing synced — not localStorage, not extensions, not history.

**Local browsers** require remote debugging to be enabled. There are two ways, and they suit different use cases.

*Way 1: chrome://inspect/#remote-debugging checkbox — uses your real profile.* In your running Chrome, navigate to `chrome://inspect/#remote-debugging` and tick the "Allow remote debugging for this browser instance" checkbox. This setting is per-profile and sticky: tick it once and it persists across every future Chrome launch of that profile. Then run any `browser-harness` command. On Chrome 144 and later, the first attach by the harness triggers an in-browser "Allow remote debugging?" popup that you must click Allow on. The popup may reappear on later attaches under conditions that are not fully characterized.[^1] This path inherits your everyday Chrome's logins, extensions, history, and bookmarks, which makes it the right choice for an agent helping you with tasks in your real browser.

*Way 2: command-line flag — uses an isolated profile, no popups ever.* Launch Chrome with `--remote-debugging-port=9222 --user-data-dir=<path>`. Two precisions:

- The path must be a directory that is **not** Chrome's platform default (`%LOCALAPPDATA%\Google\Chrome\User Data` on Windows, `~/Library/Application Support/Google/Chrome` on macOS, `~/.config/google-chrome` on Linux). On Chrome 136 and later, the port flag is silently no-opped when the user-data-dir is the platform default, even if you pass it explicitly. An empty or new path gives a fresh clean profile that Chrome will persist there across future runs.
- This path does **not** let you reuse your everyday Chrome profile. Copying the default profile's files into a custom directory makes Chrome accept the flag, but cookies are encrypted under a key bound to the original directory and will not survive the copy — so you carry over bookmarks and extensions but lose every logged-in session. If you want your real logins, use Way 1.

Tell the harness which port you launched on by setting `BU_CDP_URL=http://127.0.0.1:9222` before running `browser-harness`.

For most tasks where the agent acts on your behalf in your normal browser, use Way 1. For automation that runs without you watching, or any case where popup interruptions are unacceptable, use Way 2 or a cloud browser.

[^1]: The conditions that cause Chrome to re-show the "Allow remote debugging?" popup on a subsequent attach (time elapsed since previous Allow, daemon restart, browser restart, new CDP session, version-dependent options like "Allow for N hours") are not fully characterized. Way 2 sidesteps this entirely.

## First time setup

Try yourself before asking the user to do anything. Retry transient errors briefly. Only ask the user when a step genuinely needs them — ticking a checkbox, clicking Allow.

If the user hasn't said which connection method to use, default to Way 1 if Chrome is already running, Way 2 if not. Cloud is only used when the user opts in.

1. Try the harness:

   ```bash
   browser-harness -c 'print(page_info())'
   ```

   If it prints page info, you're done.

2. Otherwise run `browser-harness --doctor`. The two lines that matter for connection are `chrome running` and `daemon alive`.

3. Match the output to a case:

   - **chrome FAIL** → no Chrome process detected.
     - **Way 1**: ask the user to open their target Chrome themselves.
     - **Way 2**: launch Chrome yourself with `--remote-debugging-port=9222 --user-data-dir=<non-default path>`, then set `BU_CDP_URL=http://127.0.0.1:9222` for the harness (see the Browser connection reference).

   - **chrome ok, daemon FAIL** → Way 1 setup is incomplete. Tell the user to:
     - navigate to `chrome://inspect/#remote-debugging` in their Chrome and tick "Allow remote debugging for this browser instance" if not yet ticked (one-time per profile)
     - click Allow on the in-browser popup if it appears (every attach on Chrome 144+)

     On macOS, you can open the inspect page in their running Chrome yourself instead of asking them to navigate:

     ```bash
     osascript -e 'tell application "Google Chrome" to activate' \
               -e 'tell application "Google Chrome" to open location "chrome://inspect/#remote-debugging"'
     ```

   - **chrome ok, daemon ok, but step 1 still failed** → stale daemon. Restart it:

     ```bash
     browser-harness -c 'restart_daemon()'
     ```

     If that hangs, escalate: kill all Chrome and daemon processes, then reopen Chrome and retry. On macOS/Linux, also remove `/tmp/bu-default.sock` and `/tmp/bu-default.pid` if they linger.

4. After any fix, retry step 1.

If Way 1 fails repeatedly or the user's task is unattended, move to Way 2 or a cloud browser per the Browser connection reference (these have no popups).

If you are testing browser connection for the first time, run this demo: open `https://github.com/browser-use/browser-harness` in a new tab and activate it (`switch_tab`) so the user sees the harness has attached. Then ask what they want to do next.
