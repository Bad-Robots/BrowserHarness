# Browser Harness Workforce CLI Integration Plan

**Document Type:** Integration Plan
**Created:** 2026-05-10
**Revised:** 2026-05-11
**Status:** Draft - Awaiting Adversarial Review

---

## 1. Goal

Make Browser Harness available everywhere Matt uses coding agents:

- local macOS development
- Workforce-managed sessions
- Claude Code
- Codex
- Gemini CLI
- OpenCode
- Hermes Agent
- remote/headless machines including Tobor and Twiki, when reachable
- RustDesk-controlled desktops, when browser work needs a visible GUI session

The stable execution primitive is the local CLI. Workforce skills and agent instructions are discovery/routing layers on top of that CLI.

---

## 2. Naming Decision

Keep the real executable name:

```bash
browser-harness
```

Add a Workforce wrapper command:

```bash
workforce-browser
```

Add a Workforce skill name:

```text
browser-automation
```

Rationale:

- `browser-harness` already exists as the package/CLI name.
- `workforce-browser` gives Workforce one stable command that can source shared env before delegating to the real CLI.
- `browser-automation` is better for routing natural-language intent.
- `browser-harness.env` keeps the env file tied to the underlying executable and existing `BU_*` / `BH_*` variables, while the skill name remains intent-oriented.

---

## 3. Deployment Model

Each machine that may run browser automation needs its own local installation.

The harness controls a browser on the machine where the CLI runs, unless `BU_CDP_URL` or `BU_CDP_WS` points it at another browser endpoint.

### Supported modes

| Mode | Use case | Browser source | Required config |
|---|---|---|---|
| Local GUI | normal Mac or desktop dev | visible Chrome/Chromium with remote debugging | Chrome remote debugging enabled or dedicated Chrome on a CDP port |
| Remote GUI | Tobor/Twiki with desktop session, or RustDesk attached desktop | browser on remote machine | install CLI on that machine and run via SSH/shell there |
| Headless self-hosted | Tobor/Twiki/server/CI without display | Chrome/Chromium under Xvfb or native headless | `BU_CDP_URL=http://127.0.0.1:9222` |
| Cloud fallback | no local browser or disposable remote browser needed | Browser Use Cloud | `BROWSER_USE_API_KEY` and `BU_AUTOSPAWN=1` |
| External CDP | browser launched by another service | remote CDP HTTP or WebSocket endpoint | `BU_CDP_URL` or `BU_CDP_WS` |

### RustDesk behavior

RustDesk is not a transport for Browser Harness. It is only a way for a human or agent operator to access a desktop session.

If RustDesk is connected to a desktop where Chrome is running:

1. Install Browser Harness on that machine.
2. Use `workforce-browser` from a terminal on that same machine.
3. Either enable Chrome remote debugging in the visible browser or launch a dedicated automation Chrome.

If the machine is headless and only reachable through RustDesk intermittently, use the headless self-hosted mode instead of relying on an interactive RustDesk session.

---

## 4. Canonical File Layout Per Machine

Install root:

```bash
~/workforce/browser-harness
```

Workforce wrapper:

```bash
~/.workforce/bin/workforce-browser
```

Shared env:

```bash
~/.workforce/browser-harness.env
```

Shared browser workspace:

```bash
~/.workforce/browser-agent-workspace
```

Workforce skill:

```bash
~/.workforce/skills/browser-automation/SKILL.md
```

Test output:

```bash
~/.workforce/test-results/browser-harness
```

---

## 5. Phase 1 - Install CLI On Each Target Machine

### 5.1 Target machine inventory

Before installing, classify each target:

| Machine | Role | Expected mode | Notes |
|---|---|---|---|
| local Mac | primary dev | local GUI | default first target |
| Tobor | remote/dev/automation | remote GUI or headless self-hosted | verify SSH/shell and browser availability |
| Twiki | remote/dev/automation | remote GUI or headless self-hosted | verify SSH/shell and browser availability |
| RustDesk-attached host | GUI fallback | remote GUI | not a CLI transport; only desktop access |

Acceptance criteria for each target:

```bash
hostname
uname -a
command -v uv
command -v git
command -v browser-harness || true
```

If `uv` is missing, the target is not ready for installation. Use the target's normal package manager and then rerun the inventory check:

```bash
# macOS
brew install uv

# Linux fallback when no package manager recipe exists
curl -LsSf https://astral.sh/uv/install.sh | sh
```

No-go rule: do not continue with Browser Harness installation on a target until `command -v uv` passes for the same user account that will run Claude, Codex, Gemini, OpenCode, or Hermes.

### 5.2 Install commands

Use the Bad Robots repo as canonical:

```bash
mkdir -p ~/workforce
git clone https://github.com/Bad-Robots/BrowserHarness ~/workforce/browser-harness
cd ~/workforce/browser-harness
uv tool install -e .
browser-harness --version
browser-harness --doctor
```

If the repo already exists:

```bash
cd ~/workforce/browser-harness
git remote -v
git status --short
git pull --ff-only
uv tool install -e .
```

Do not install from `browser-use/browser-harness` for this project unless explicitly switching upstreams.

---

## 6. Phase 2 - Workforce Wrapper And Env Loading

### 6.1 Shared env file

Create:

```bash
~/.workforce/browser-harness.env
```

Contents:

```bash
export BU_NAME=workforce
export BH_AGENT_WORKSPACE="$HOME/.workforce/browser-agent-workspace"
# Domain skills stay disabled until browser-harness-promote-domain-skill is installed and verified.
export BH_DOMAIN_SKILLS=0

# Optional: connect to a specific local or remote Chrome DevTools endpoint.
# export BU_CDP_URL=http://127.0.0.1:9222
# export BU_CDP_WS=ws://127.0.0.1:9222/devtools/browser/<id>

# Optional: cloud fallback when no local browser is available.
# export BROWSER_USE_API_KEY=...
# export BU_AUTOSPAWN=1
```

### 6.2 Wrapper command

Create:

```bash
~/.workforce/bin/workforce-browser
```

Exact setup:

```bash
mkdir -p "$HOME/.workforce/bin"
cat > "$HOME/.workforce/bin/workforce-browser" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ -f "$HOME/.workforce/browser-harness.env" ]; then
  source "$HOME/.workforce/browser-harness.env"
fi
BH_BIN="$(command -v browser-harness || true)"
if [ -z "$BH_BIN" ] && [ -x "$HOME/.local/bin/browser-harness" ]; then
  BH_BIN="$HOME/.local/bin/browser-harness"
fi
if [ -z "$BH_BIN" ]; then
  echo "browser-harness not found; ensure uv tool bin dir is on PATH or reinstall with uv tool install -e ." >&2
  exit 127
fi
exec "$BH_BIN" "$@"
EOF
chmod 755 "$HOME/.workforce/bin/workforce-browser"
```

Persist `~/.workforce/bin` on PATH for login and non-login shells used by coding agents:

```bash
for profile in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$profile"
  grep -q 'HOME/.workforce/bin' "$profile" || \
    printf '\nexport PATH="$HOME/.workforce/bin:$PATH"\n' >> "$profile"
done
```

Agent-specific acceptance criteria:

```bash
command -v workforce-browser
command -v browser-harness || test -x "$HOME/.local/bin/browser-harness"
env PATH="$HOME/.workforce/bin:$PATH" command -v workforce-browser
```

Each supported agent acceptance prompt must also prove the agent can find `workforce-browser` from its own shell environment. If an agent cannot inherit shell profile PATH reliably, its instructions must call the absolute path:

```bash
$HOME/.workforce/bin/workforce-browser
```

Acceptance criteria:

```bash
command -v workforce-browser
workforce-browser --version
workforce-browser --doctor
```

This wrapper is mandatory because the harness reads env vars from the process environment. Creating `~/.workforce/browser-harness.env` alone is not enough.

---

## 7. Phase 3 - Browser Modes

### 7.1 Local GUI mode

Use when a desktop session is available.

Option A: use existing browser remote debugging setup:

1. Open Chrome.
2. Visit `chrome://inspect/#remote-debugging`.
3. Enable remote debugging if prompted.
4. Run:

```bash
workforce-browser --doctor
workforce-browser -c 'print(page_info())'
```

Option B: launch dedicated automation Chrome:

```bash
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.workforce/chrome-browser-harness" \
  --no-first-run \
  --no-default-browser-check

export BU_CDP_URL=http://127.0.0.1:9222
workforce-browser -c 'print(page_info())'
```

On macOS, replace `google-chrome` with the local Chrome executable path if needed.

### 7.2 Headless self-hosted mode

Use on Tobor, Twiki, Linux servers, and CI systems without a GUI.

Prerequisites:

```bash
CHROME_BIN="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
test -n "$CHROME_BIN"
command -v Xvfb
```

Launch:

```bash
mkdir -p "$HOME/.workforce/browser-harness-runtime"
mkdir -p "$HOME/.workforce/chrome-browser-harness"
CHROME_BIN="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
test -n "$CHROME_BIN"

if curl -fsS http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  echo "CDP port 9222 is already serving a browser; use existing endpoint or run browser-harness-headless-stop first." >&2
  exit 1
fi

Xvfb :99 -screen 0 1920x1080x24 &
echo "$!" > "$HOME/.workforce/browser-harness-runtime/xvfb.pid"
export DISPLAY=:99

"$CHROME_BIN" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.workforce/chrome-browser-harness" \
  --no-first-run \
  --no-default-browser-check \
  --disable-dev-shm-usage \
  --disable-gpu &
echo "$!" > "$HOME/.workforce/browser-harness-runtime/chrome.pid"

for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:9222/json/version >/dev/null; then
    break
  fi
  sleep 1
done

export BU_CDP_URL=http://127.0.0.1:9222
workforce-browser --doctor
workforce-browser -c 'print(page_info())'
```

The readiness loop is required. Starting Chrome and immediately running Browser Harness is flaky on headless systems.

Lifecycle rule: the background `Xvfb` and Chrome processes must be owned by an explicit script or service, not left as unmanaged shells.

Create these operational scripts on headless targets:

```bash
~/.workforce/bin/browser-harness-headless-start
~/.workforce/bin/browser-harness-headless-stop
~/.workforce/bin/browser-harness-headless-status
```

The start script owns the launch sequence above, writes PID files under `~/.workforce/browser-harness-runtime/`, and refuses to continue if port 9222 is occupied by a process it did not start unless the operator passes a force flag. The stop script kills only PIDs recorded in that runtime directory after confirming their command lines are Chrome or Xvfb. The status script checks PID liveness and `http://127.0.0.1:9222/json/version`.

The start script must resolve the browser binary in this order: `google-chrome`, `chromium`, `chromium-browser`. It must store the resolved path in `CHROME_BIN` and use that variable in launch and command-line validation.

Crash/reboot cleanup rule: stale PID files do not authorize killing arbitrary processes. If a PID file points to a non-running process, remove the PID file. If a PID file points to a running process whose command line is not the resolved Chrome binary or Xvfb, refuse to act and print a manual cleanup warning.

Acceptance criteria on Tobor/Twiki/headless targets:

```bash
browser-harness-headless-start
browser-harness-headless-status
BU_CDP_URL=http://127.0.0.1:9222 workforce-browser -c 'print(page_info())'
browser-harness-headless-stop
```

### 7.3 Cloud fallback mode

Use only when local/headless browser setup is unavailable or not worth maintaining.

Env:

```bash
export BROWSER_USE_API_KEY=...
export BU_AUTOSPAWN=1
```

Then:

```bash
workforce-browser -c '
new_tab("https://example.com")
wait_for_load()
print(page_info())
'
```

Cost-control rule: `BROWSER_USE_API_KEY` alone must not imply cloud use. `BU_AUTOSPAWN=1` is required.

### 7.4 Remote CDP mode

Use when a browser is launched elsewhere but exposes CDP.

```bash
export BU_CDP_URL=http://remote-host:9222
# or
export BU_CDP_WS=ws://remote-host:9222/devtools/browser/<id>
workforce-browser --doctor
workforce-browser -c 'print(page_info())'
```

Security rule: do not expose CDP ports broadly. Prefer SSH tunnels:

```bash
ssh -L 9222:127.0.0.1:9222 user@remote-host
export BU_CDP_URL=http://127.0.0.1:9222
```

---

## 8. Phase 4 - Shared Browser Workspace

Create:

```bash
mkdir -p ~/.workforce/browser-agent-workspace/domain-skills
mkdir -p ~/.workforce/browser-agent-workspace/domain-skills/.staging
mkdir -p ~/.workforce/browser-agent-workspace/interaction-skills
mkdir -p ~/.workforce/test-results/browser-harness

cp ~/workforce/browser-harness/agent-workspace/agent_helpers.py \
  ~/.workforce/browser-agent-workspace/agent_helpers.py

cp -R ~/workforce/browser-harness/interaction-skills/. \
  ~/.workforce/browser-agent-workspace/interaction-skills/

chmod 755 ~/.workforce/browser-agent-workspace
chmod 755 ~/.workforce/browser-agent-workspace/domain-skills
chmod 755 ~/.workforce/browser-agent-workspace/domain-skills/.staging
chmod 644 ~/.workforce/browser-agent-workspace/agent_helpers.py
```

Rules:

- Agents may read `domain-skills`.
- Agents may write temporary helpers to `agent_helpers.py`.
- New or changed domain skills must first be written under `.staging/<agent-id>/<site>/`.
- A human or maintainer promotes staged skills with `~/.workforce/bin/browser-harness-promote-domain-skill`.
- `BH_DOMAIN_SKILLS` remains `0` until the promotion command is installed and verified.

Promotion command contract:

```bash
browser-harness-promote-domain-skill [--approve] <agent-id> <site>
```

The command must:

1. read only from `~/.workforce/browser-agent-workspace/domain-skills/.staging/<agent-id>/<site>/`
2. reject paths containing `..`, absolute paths, symlinks, or non-regular files
3. require Markdown files to pass a basic frontmatter/body sanity check
4. show a diff against the live `domain-skills/<site>/`
5. copy into `domain-skills/<site>/` only when `--approve` is present
6. write an audit line to `~/.workforce/test-results/browser-harness/domain-skill-promotions.jsonl`

Noninteractive behavior: without `--approve`, the command must perform validation, print the diff, exit nonzero with a "review required" message, and make no changes. Agents must not pass `--approve`; only a human/maintainer may do so.

Promotion acceptance criteria:

```bash
command -v browser-harness-promote-domain-skill
browser-harness-promote-domain-skill test-agent example.com || test $? -ne 0
test -f ~/.workforce/test-results/browser-harness/domain-skill-promotions.jsonl
```

Only after the promotion command passes acceptance may the env file be changed to:

```bash
export BH_DOMAIN_SKILLS=1
```

Ownership rule: all workspace files are owned by the same user account that runs the coding agents. Do not use `sudo` for workspace setup unless followed by a group-aware ownership repair:

```bash
chown -R "$USER:$(id -gn)" ~/.workforce/browser-agent-workspace
```

Workspace sync rule: repo updates do not automatically overwrite the shared workspace. After every `git pull` or `browser-harness --update`, run a workspace sync check that diffs the repo templates against shared workspace files:

```bash
diff -u ~/workforce/browser-harness/agent-workspace/agent_helpers.py ~/.workforce/browser-agent-workspace/agent_helpers.py || true
diff -ru ~/workforce/browser-harness/interaction-skills ~/.workforce/browser-agent-workspace/interaction-skills || true
```

Agents must not overwrite user-edited shared helpers automatically. Any template sync requires a visible diff and explicit approval.

---

## 9. Phase 5 - Workforce Skill

Create:

```bash
~/.workforce/skills/browser-automation/SKILL.md
```

Content contract:

```markdown
---
name: browser-automation
description: Use local Browser Harness through the Workforce browser wrapper for browser QA, UI validation, scraping, visual verification, and web automation.
---

# Browser Automation

Use this command:

```bash
workforce-browser -c '
new_tab("https://example.com")
wait_for_load()
print(page_info())
'
```

Run diagnostics before debugging browser failures:

```bash
workforce-browser --doctor
```

Write evidence to:

```text
~/.workforce/test-results/browser-harness/
```

For repeated site-specific work, check:

```text
~/.workforce/browser-agent-workspace/domain-skills/
```

For new domain skills, write to:

```text
~/.workforce/browser-agent-workspace/domain-skills/.staging/
```

Do not use raw Selenium or Playwright unless the user explicitly asks for them.
```

---

## 10. Phase 6 - Workforce Routing

For this Workforce installation, routing source of truth is the Workforce repo, not `~/.workforce/config/routing.yaml`.

Authoritative routing docs discovered in the local Workforce repo:

- `workforce/CLAUDE.md` Section 2 says machine-readable routing lives in `routing/registry.d/`.
- `routing/registry.json` and `routing/rules.json` are generated artifacts and must not be hand-edited.
- Agent keyword routes live in `routing/registry.d/agents/*.json`.
- Skill routing is primarily driven by skill frontmatter description plus mirrored skill surfaces.

### 10.1 Skill source

Create the source skill in the Workforce source tree:

```bash
/Users/mattheller/Projects/Workforce/workforce/skills/browser-automation/SKILL.md
```

Then generate/sync the target skill surfaces using the Workforce skill mirror pipeline for Codex/Gemini/Hermes/OpenCode. If the mirror pipeline is unavailable, create explicit per-agent instruction entries in Phase 7 and mark skill mirror sync as blocked.

Known constraint: the executable skill mirror command has not been identified in this Browser Harness planning session. Therefore, this rollout does not depend on mirrored skill generation. Phase 7 explicit per-agent instructions are the required path for Claude, Codex, Gemini, OpenCode, and Hermes. Skill mirror discovery is a separate follow-up item.

### 10.2 Routing metadata

Because Browser Harness is a tool/skill rather than a department agent, do not create a fake agent in `routing/registry.d/agents/` unless the Office Manager decides a dedicated browser automation agent is needed.

The skill frontmatter description must contain the routing phrases:

```yaml
---
name: browser-automation
description: Use local Browser Harness through the Workforce browser wrapper for browser QA, UI validation, test in browser, e2e browser test, scraping, visual verification, and web automation.
---
```

### 10.3 Optional agent keyword routing - blocked unless generator is restored

Do not implement this subsection during the Browser Harness rollout unless the current routing artifact generator is identified or restored.

If a later Workforce routing task needs browser QA prompts to dispatch to an existing engineering agent, update the existing engineering automation route rather than creating a new phantom route. Candidate file:

```bash
/Users/mattheller/Projects/Workforce/workforce/routing/registry.d/agents/python-automation.json
```

Add aliases only if the current routing owner approves and the artifact generator exists:

```json
{
  "department": "engineering",
  "aliases": [
    "python automation",
    "browser qa",
    "browser validation",
    "e2e browser test",
    "web automation"
  ]
}
```

After any `routing/registry.d/` change, regenerate artifacts from the Workforce repo root using the current Workforce publish/generation command.

Known constraint in this checkout: the older docs reference `runtime/scripts/generate_routing_artifacts.py`, but that file is not present. Therefore, do not edit `routing/registry.d/` for this integration until the current routing artifact generation path is identified or restored.

No-go rule for optional agent keyword routing:

- if the routing artifact generator cannot be located, skip `routing/registry.d/` changes
- rely on the `browser-automation` skill frontmatter and explicit per-agent instructions instead
- record the routing generator gap as follow-up work

```bash
cd /Users/mattheller/Projects/Workforce/workforce
# Replace with the current routing artifact generation command once identified.
```

Validation after the generator is restored:

```bash
cd /Users/mattheller/Projects/Workforce/workforce
python3 -m json.tool routing/registry.json >/dev/null
python3 -m json.tool routing/rules.json >/dev/null
rg -n "browser qa|browser validation|e2e browser test|web automation" routing/registry.d routing/registry.json routing/rules.json CLAUDE.md
```

Required routing intent for any route or skill mirror:

```yaml
skills:
  browser-automation:
    path: ~/.workforce/skills/browser-automation/SKILL.md
    routes_to: engineering
    priority: high
    triggers:
      - browser qa
      - browser validation
      - visual verification
      - e2e browser test
      - test in browser
      - web automation
      - scrape website
      - open chrome
```

Avoid over-broad triggers such as `test the` or `navigate to`.

Acceptance criteria:

- `browser-automation` exists in the source skill tree.
- Codex/Gemini/OpenCode/Hermes have explicit Phase 7 instructions.
- No `routing/registry.d/` files are edited during this rollout unless the routing generator exists and is run.
- The acceptance prompts in Phase 7 cause each agent to choose `workforce-browser`.

---

## 11. Phase 7 - Supported Agent Configuration

All agents should point to `workforce-browser`, not directly to `browser-harness`, so the shared env is always loaded.

### 11.1 Claude Code

Append to:

```bash
~/.claude/CLAUDE.md
```

Add:

```markdown
## Browser Automation

For browser QA, scraping, UI validation, or visual verification, use:

```bash
workforce-browser -c 'print(page_info())'
```

Run `workforce-browser --doctor` for diagnostics. Write screenshots/logs to `~/.workforce/test-results/browser-harness/`.
```

Acceptance prompt:

```text
Use the local browser harness to open https://example.com and print page_info().
```

### 11.2 Codex

Preferred setup:

```bash
mkdir -p ~/.codex/skills/browser-harness
ln -s ~/.workforce/skills/browser-automation/SKILL.md \
  ~/.codex/skills/browser-harness/SKILL.md
```

If symlinks are not supported, create a real `~/.codex/skills/browser-harness/SKILL.md` with the same command contract.

Acceptance prompt:

```text
Use the browser-harness skill to open https://example.com and report the page title.
```

### 11.3 Gemini CLI

Append to:

```bash
~/.gemini/instructions.md
```

Add:

```markdown
# Browser Automation

Use the Workforce browser wrapper for browser work:

```bash
workforce-browser -c 'new_tab("https://example.com"); print(page_info())'
```
```

Acceptance prompt:

```text
Open https://example.com using the local browser harness and verify the page loaded.
```

### 11.4 OpenCode

Append to:

```bash
~/.config/opencode/instructions.md
```

Add:

```markdown
## Browser Automation

Use `workforce-browser` for browser automation:

```bash
workforce-browser -c 'new_tab("https://example.com"); print(page_info())'
```
```

Acceptance prompt:

```text
Use the local browser CLI to navigate to example.com and capture a screenshot.
```

### 11.5 Hermes Agent

Hermes-specific facts from the local Workforce repo:

- Hermes reads runtime guidance from `workforce/HERMES.md`.
- Hermes skills load from `~/.hermes/skills/` using `manifest.yaml` plus `.tmpl` files.
- Workforce CLIBridge packages live in `/Users/mattheller/Projects/Workforce/workforce/skills-clibridge/`.
- `~/.hermes/config.yaml` is for MCP server configuration, not the browser-automation instruction body.

Prerequisites:

```bash
command -v hermes
test -d /Users/mattheller/Projects/Workforce/workforce/skills-clibridge
find /Users/mattheller/Projects/Workforce/workforce/skills-clibridge -maxdepth 2 -name manifest.yaml | head -1
```

If any prerequisite fails, defer Hermes configuration and record Hermes as not in scope for the current rollout.

Create a Hermes CLIBridge skill package:

```bash
/Users/mattheller/Projects/Workforce/workforce/skills-clibridge/browser-automation/manifest.yaml
/Users/mattheller/Projects/Workforce/workforce/skills-clibridge/browser-automation/browser_automation.tmpl
```

`manifest.yaml` contract:

```yaml
name: browser-automation
version: "1.0.0"
description: "Use local Browser Harness through workforce-browser for browser QA, UI validation, scraping, visual verification, and web automation."
provider: claude
model: sonnet
system_prompt: |
  Use the local Workforce browser wrapper for browser tasks:

    workforce-browser -c 'new_tab("https://example.com"); print(page_info())'

  Run workforce-browser --doctor for diagnostics.
endpoints:
  - path: /browser/automation
    method: POST
    template: browser_automation.tmpl
    response_format: raw
    timeout_seconds: 300
```

Install into Hermes:

```bash
hermes skills install /Users/mattheller/Projects/Workforce/workforce/skills-clibridge/browser-automation
```

Acceptance prompt:

```text
Use the local browser harness to open example.com and return page_info.
```

Acceptance criteria:

```bash
test -f ~/.hermes/skills/browser-automation/manifest.yaml
hermes skills list | rg "browser-automation"
```

---

## 12. Phase 8 - Verification

Create:

```bash
~/workforce/browser-harness/scripts/verify-workforce-integration.sh
```

Required checks:

```bash
#!/usr/bin/env bash
set -euo pipefail

command -v browser-harness
command -v workforce-browser
command -v browser-harness || test -x "$HOME/.local/bin/browser-harness"

test -f "$HOME/.workforce/browser-harness.env"
test -d "$HOME/.workforce/browser-agent-workspace"
test -f "$HOME/.workforce/browser-agent-workspace/agent_helpers.py"
test -d "$HOME/.workforce/browser-agent-workspace/domain-skills"
test -f "$HOME/.workforce/skills/browser-automation/SKILL.md"

workforce-browser --version
workforce-browser --doctor
workforce-browser -c 'import json; print(json.dumps(page_info()))'
workforce-browser -c 'import os; assert os.environ.get("BH_AGENT_WORKSPACE") == os.path.expanduser("~/.workforce/browser-agent-workspace"); assert os.environ.get("BH_DOMAIN_SKILLS") in {"0", "1"}; print("env-ok")'
workforce-browser -c 'import os, shutil, sys; enabled=os.environ.get("BH_DOMAIN_SKILLS") == "1"; has_promoter=shutil.which("browser-harness-promote-domain-skill") is not None; sys.exit(0 if (not enabled or has_promoter) else 1)'
```

Agent config checks must validate the selected canonical path for each agent. They must not accept mutually inconsistent alternatives without proving the agent actually loads them.

The script itself must be executable and must write a timestamped log:

```bash
chmod 755 ~/workforce/browser-harness/scripts/verify-workforce-integration.sh
mkdir -p ~/.workforce/test-results/browser-harness
~/workforce/browser-harness/scripts/verify-workforce-integration.sh \
  2>&1 | tee ~/.workforce/test-results/browser-harness/verify-workforce-integration-$(date +%Y%m%d-%H%M%S).log
```

Per-agent acceptance tests are separate from file checks. Run the acceptance prompt in each agent and capture:

- prompt used
- command the agent ran
- exit code
- screenshot or `page_info` output
- log path under `~/.workforce/test-results/browser-harness/`

---

## 13. Phase 9 - Remote Host Verification

For each remote host, including Tobor and Twiki when in scope:

```bash
ssh <host> 'hostname && command -v workforce-browser && workforce-browser --version'
ssh <host> 'workforce-browser --doctor'
```

For headless mode:

```bash
ssh <host> 'curl -fsS http://127.0.0.1:9222/json/version'
ssh <host> 'BU_CDP_URL=http://127.0.0.1:9222 workforce-browser -c "print(page_info())"'
```

For RustDesk-controlled GUI mode:

1. Connect with RustDesk.
2. Open a terminal on the remote desktop.
3. Run:

```bash
workforce-browser --doctor
workforce-browser -c 'print(page_info())'
```

Do not mark RustDesk as verified unless the command runs on the RustDesk-attached machine, not only on the local controller.

---

## 14. Rollout Order

1. Local Mac CLI install.
2. `workforce-browser` wrapper and env loading.
3. Shared workspace.
4. Local browser GUI verification.
5. Headless lifecycle scripts installed and verified on one machine when headless is in scope.
6. Headless launch verification using the lifecycle scripts.
7. Workforce skill.
8. Workforce routing through skill frontmatter and explicit per-agent instructions.
9. Claude pilot configuration.
10. Codex configuration.
11. Gemini configuration.
12. OpenCode configuration.
13. Hermes prerequisite check and configuration if prerequisites pass.
14. Domain skill promotion command, or keep `BH_DOMAIN_SKILLS=0`.
15. Tobor verification.
16. Twiki verification.
17. RustDesk-attached GUI verification, only if needed.

Each step must have an artifact under `~/.workforce/test-results/browser-harness/`.

---

## 15. Risks And Mitigations

| Risk | Mitigation |
|---|---|
| Env file created but not loaded | require all agents to call `workforce-browser`; wrapper sources env |
| Wrong upstream repo | clone `Bad-Robots/BrowserHarness`; verify `git remote -v` |
| Headless startup race | require `/json/version` readiness loop before using CDP |
| Headless process leakage after crash or reboot | lifecycle scripts own PID files, validate command lines, and remove stale PID files |
| CDP exposed on network | use SSH tunnel or localhost only |
| RustDesk mistaken for browser transport | document RustDesk as GUI access only |
| Agent config path wrong | verify with per-agent acceptance prompt, not only grep |
| Domain skill poisoning or clobbering | use `.staging` and manual promotion |
| Cloud browser cost surprise | require both `BROWSER_USE_API_KEY` and `BU_AUTOSPAWN=1` |
| Remote host drift | verify install/env/browser mode per host |

---

## 16. Go / No-Go Criteria

Go only when all are true:

- `workforce-browser --doctor` runs locally.
- `workforce-browser -c 'print(page_info())'` works in at least one browser mode.
- Workforce skill exists and routes browser-intent tasks.
- Claude, Codex, Gemini, OpenCode, and Hermes each pass one acceptance prompt.
- Headless mode has been verified or explicitly marked out of scope.
- Tobor/Twiki/RustDesk targets are either verified or explicitly marked not in scope for this rollout.
- Domain skills are disabled with `BH_DOMAIN_SKILLS=0`, or the promotion command is installed, verified, audited, and `BH_DOMAIN_SKILLS=1` is explicitly enabled afterward.

No-go if:

- env loading depends on agents remembering to source a file manually
- `routing/registry.d/` changes are planned while the routing artifact generator is unknown
- browser verification is only a file grep
- CDP is exposed insecurely
- the plan cannot distinguish local, remote GUI, headless, and cloud modes
