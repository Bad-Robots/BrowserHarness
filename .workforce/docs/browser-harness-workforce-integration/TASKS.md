# Browser Harness Workforce Integration Tasks

## Epic E1: Local CLI Foundation

### BHWI-E1-T1: Verify Installable CLI Contract

Type: implementation
Status: TODO
Depends on: none
Files: `pyproject.toml`, `src/browser_harness/run.py`, `install.md`

Define the supported local install path and confirm `browser-harness` remains the canonical CLI entrypoint.

Acceptance:

- `uv tool install -e .` or the selected install command is documented.
- `browser-harness --version` has deterministic output.
- Install troubleshooting covers missing browser, missing CDP, and PATH failures.

Validation:

```sh
browser-harness --version
browser-harness doctor
```

### BHWI-E1-T2: Create Shared Workforce Env And Workspace Setup

Type: implementation
Status: TODO
Depends on: BHWI-E1-T1
Files: `install.md`, `scripts/setup-workforce-browser-env.sh`

Create setup instructions or script for `~/.workforce/browser-harness.env` and `~/.workforce/browser-agent-workspace/`.

Acceptance:

- `BH_DOMAIN_SKILLS=0` is the default.
- Workspace directories are created idempotently.
- Existing env files are backed up or merged safely.

### BHWI-E1-T3: Implement `workforce-browser` Wrapper

Type: implementation
Status: TODO
Depends on: BHWI-E1-T2
Files: `scripts/workforce-browser`, `install.md`

Add a Workforce-stable wrapper that loads env, validates mode, and delegates to `browser-harness`.

Acceptance:

- Wrapper works from non-interactive shells.
- Wrapper prints actionable errors when env or CLI is missing.
- Wrapper does not mutate agent workspace except through explicit commands.

### BHWI-E1-T4: Add Wrapper Doctor Diagnostics

Type: implementation
Status: TODO
Depends on: BHWI-E1-T3
Files: `scripts/workforce-browser`, `scripts/setup-workforce-browser-env.sh`, `install.md`

Add `workforce-browser doctor` diagnostics for CLI presence, env, workspace, browser/CDP, and mode support.

Acceptance:

- Doctor exits nonzero for real blockers.
- Output is concise enough for agents to interpret.
- Diagnostics include log destination.

## Epic E2: Browser Modes

### BHWI-E2-T1: Verify Local GUI Mode

Type: verification
Status: TODO
Depends on: BHWI-E1-T4
Files: `install.md`, future verification script

Verify local GUI launch/connect/run/screenshot behavior.

Acceptance:

- Local browser can be launched or attached.
- CDP readiness is checked before commands run.
- Screenshot smoke test writes evidence.

### BHWI-E2-T2: Implement Headless Lifecycle Commands

Type: implementation
Status: TODO
Depends on: BHWI-E1-T4
Files: `scripts/workforce-browser`, `scripts/setup-workforce-browser-env.sh`, `install.md`

Add start, stop, and status behavior for managed headless browser sessions.

Acceptance:

- Start creates or reuses a deterministic CDP endpoint.
- Status distinguishes ready, starting, stopped, and failed.
- Stop cleans up only managed processes.

### BHWI-E2-T3: Verify Headless Mode

Type: verification
Status: TODO
Depends on: BHWI-E2-T2
Files: future verification script

Run a clean headless smoke test.

Acceptance:

- Start succeeds on a headless host with required packages.
- Navigation and screenshot work through CDP.
- Stop leaves no managed stale browser process.

### BHWI-E2-T4: Document Remote GUI, External CDP, Tobor/Twiki, And RustDesk

Type: documentation
Status: TODO
Depends on: BHWI-E1-T4
Files: `install.md`, `SKILL.md`

Document remote usage precisely.

Acceptance:

- Tobor/Twiki are supported only after host-local verification.
- RustDesk is described as human GUI access, not automation transport.
- External CDP mode is documented separately from local launch mode.

## Epic E3: Workforce Skill

### BHWI-E3-T1: Create `browser-automation` Workforce Skill

Type: implementation
Status: TODO
Depends on: BHWI-E1-T4
Files: `workforce-skills/browser-automation/SKILL.md`, repo `SKILL.md`

Create the Workforce skill content for Browser Harness usage.

Acceptance:

- Frontmatter is valid.
- Skill routes agents to `workforce-browser`.
- Safety constraints are explicit.

### BHWI-E3-T2: Validate Skill Discovery

Type: verification
Status: TODO
Depends on: BHWI-E3-T1
Files: skill install path, verification logs

Verify Workforce agents can discover the skill.

Acceptance:

- Skill appears in the expected skill list.
- A fresh agent receives enough instruction to call `workforce-browser doctor`.

### BHWI-E3-T3: Gate Domain Skill Promotion

Type: implementation
Status: TODO
Depends on: BHWI-E3-T1
Files: future promotion command or docs

Keep domain skill mutation off by default and define a reviewed promotion path.

Acceptance:

- `BH_DOMAIN_SKILLS=0` remains default.
- Promotion requires explicit command or review.
- Agent-written files remain inside Browser Harness workspace.

## Epic E4: Agent Configurations

### BHWI-E4-T1: Configure Claude

Type: implementation
Status: TODO
Depends on: BHWI-E3-T1
Files: `~/.claude/CLAUDE.md`

Add Browser Harness instructions for Claude.

Acceptance:

- Claude instructions prefer `workforce-browser`.
- First-use doctor command is included.

### BHWI-E4-T2: Configure Codex

Type: implementation
Status: TODO
Depends on: BHWI-E3-T1
Files: `~/.codex/skills/browser-harness`

Install or symlink Codex skill access.

Acceptance:

- Codex can discover Browser Harness usage instructions.
- Skill does not conflict with repo-local `AGENTS.md`.

### BHWI-E4-T3: Configure Gemini

Type: implementation
Status: TODO
Depends on: BHWI-E3-T1
Files: `~/.gemini/instructions.md`

Add Gemini instructions.

Acceptance:

- Gemini uses `workforce-browser`.
- Instructions include mode and workspace constraints.

### BHWI-E4-T4: Configure OpenCode

Type: implementation
Status: TODO
Depends on: BHWI-E3-T1
Files: `~/.config/opencode/instructions.md`

Add OpenCode instructions with extra care for agentic default behavior.

Acceptance:

- Instructions avoid ambiguous prompts that may trigger unrelated work.
- Browser tasks route through `workforce-browser`.

### BHWI-E4-T5: Configure Hermes Agent

Type: implementation
Status: BLOCKED
Depends on: BHWI-E3-T1
Blocker: Hermes CLIBridge prerequisites must be verified first.
Files: `~/.hermes/config.yaml`

Add Hermes configuration only after CLIBridge is confirmed.

Acceptance:

- CLIBridge is present and documented.
- Hermes can call `workforce-browser doctor`.

## Epic E5: Verification

### BHWI-E5-T1: Add Verification Script

Type: implementation
Status: TODO
Depends on: BHWI-E4-T1, BHWI-E4-T2, BHWI-E4-T3, BHWI-E4-T4
Files: future `verify-setup.sh`

Create an idempotent verification script for wrapper, env, modes, and agent config presence.

Acceptance:

- Logs write under `~/.workforce/test-results/browser-harness/`.
- Script reports pass/fail per check.
- Script does not require a GUI for non-GUI checks.

### BHWI-E5-T2: Run Per-Agent Smoke Tests

Type: verification
Status: TODO
Depends on: BHWI-E5-T1
Files: verification logs

Run smoke tests for Claude, Codex, Gemini, OpenCode, and Hermes where supported.

Acceptance:

- Each supported agent can run `workforce-browser doctor`.
- Failures are captured with remediation notes.
- Hermes remains blocked if CLIBridge is absent.

## Epic E6: Rollout And Maintenance

### BHWI-E6-T1: Capture Rollout Evidence

Type: verification
Status: TODO
Depends on: BHWI-E5-T2
Files: verification logs, documentation

Collect logs and host matrix results.

Acceptance:

- Local host result is captured.
- Tobor/Twiki are marked verified or not installed.
- Headless status is explicit.

### BHWI-E6-T2: Add Maintenance And Rollback Docs

Type: documentation
Status: TODO
Depends on: BHWI-E6-T1
Files: `install.md`, `SKILL.md`

Document update, rollback, and disable procedures.

Acceptance:

- Update path covers repo pull and reinstall.
- Rollback path covers wrapper bypass/removal.
- Troubleshooting covers PATH, CDP, headless, permissions, and remote host failures.
