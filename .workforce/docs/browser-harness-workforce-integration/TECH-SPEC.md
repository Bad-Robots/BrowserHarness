# Browser Harness Workforce Integration Technical Spec

## Architecture

Agents call `workforce-browser`. The wrapper loads `~/.workforce/browser-harness.env`, validates the selected mode, then delegates to `browser-harness`.

```text
Claude/Codex/Gemini/OpenCode/Hermes
  -> Workforce skill: browser-automation
  -> workforce-browser
  -> browser-harness
  -> browser via CDP
```

## Commands

Required stable command surface:

- `workforce-browser --version`
- `workforce-browser doctor`
- `workforce-browser launch`
- `workforce-browser connect`
- `workforce-browser run <script-or-command>`
- `workforce-browser screenshot`
- `workforce-browser headless start`
- `workforce-browser headless stop`
- `workforce-browser headless status`

The wrapper may delegate directly to equivalent `browser-harness` commands when they already exist.

## Environment Contract

Required file: `~/.workforce/browser-harness.env`

Required values:

```sh
BH_INSTALL_DIR="$HOME/workforce/browser-harness"
BH_WORKSPACE="$HOME/.workforce/browser-agent-workspace"
BH_DOMAIN_SKILLS=0
BH_MODE=local
BH_CDP_URL=
BH_TEST_RESULTS="$HOME/.workforce/test-results/browser-harness"
```

Supported `BH_MODE` values:

- `local`
- `remote-gui`
- `headless`
- `external-cdp`

## Workspace Contract

Agents may write only within:

- `~/.workforce/browser-agent-workspace/agent_helpers.py`
- `~/.workforce/browser-agent-workspace/domain-skills/`
- `~/.workforce/browser-agent-workspace/interaction-skills/`

Domain skill writes remain disabled by default until a promotion command and review workflow exist.

## Headless Contract

Headless mode requires:

- A display provider such as Xvfb.
- A browser launched with remote debugging enabled.
- A deterministic CDP URL.
- Readiness polling before any agent is told the browser is available.
- Cleanup on stop and stale process detection.

Headless verification must prove:

- Browser starts from a clean system state.
- CDP endpoint responds.
- A simple page navigation works.
- Screenshot capture works.
- Stop removes the managed browser process or marks externally managed processes clearly.

## Remote Host Contract

Tobor and Twiki are supported only after host-local verification. Each host must have:

- Browser Harness repo installed or updated.
- `browser-harness` and `workforce-browser` available on `PATH`.
- `~/.workforce/browser-harness.env` configured.
- Target browser or CDP endpoint reachable from that host.
- Smoke-test logs captured.

RustDesk can be used to inspect or repair a GUI session manually, but Browser Harness still uses CDP for automation.

## Agent Configuration Contract

Each supported agent receives a concise instruction block:

- Prefer `workforce-browser` for browser automation.
- Run `workforce-browser doctor` before first use in a session.
- Do not write outside the configured Browser Harness workspace.
- Use headless mode only when `workforce-browser headless status` reports ready.
- Store verification output under `~/.workforce/test-results/browser-harness/`.

Agent-specific targets:

- Claude: append to `~/.claude/CLAUDE.md`.
- Codex: install skill or symlink under `~/.codex/skills/browser-harness`.
- Gemini: add instructions under `~/.gemini/instructions.md`.
- OpenCode: append to `~/.config/opencode/instructions.md`.
- Hermes: configure only after CLIBridge prerequisites are present.

## Verification Contract

Verification must cover:

- Wrapper resolution on `PATH`.
- Env file loading.
- CLI doctor output.
- Local GUI or external CDP connection.
- Headless start/status/run/stop.
- Agent instruction discovery for all five agents.
- Host-local smoke results for Tobor and Twiki if included in rollout.
