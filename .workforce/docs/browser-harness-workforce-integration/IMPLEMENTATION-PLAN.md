# Browser Harness Workforce Integration Implementation Plan

## Phase 1: Foundation

Create the shared env file, workspace directories, wrapper source location, and local install contract. Keep all changes reversible and host-local.

Exit criteria:

- `browser-harness --version` works from the target shell.
- `workforce-browser --version` delegates correctly.
- `workforce-browser doctor` reports missing dependencies instead of failing ambiguously.

## Phase 2: Browser Mode Support

Implement and verify local, remote GUI, headless, and external CDP behavior. Headless mode must include lifecycle commands and readiness polling before any agent integration relies on it.

Exit criteria:

- Each mode has a documented setup path.
- Headless smoke test passes from clean start through stop.
- Remote GUI guidance distinguishes CDP automation from RustDesk human access.

## Phase 3: Workforce Skill

Create the `browser-automation` skill and install it where Workforce agents can discover it. The skill should be concise, command-oriented, and conservative about write permissions.

Exit criteria:

- Skill frontmatter is valid.
- Skill tells agents to use `workforce-browser`.
- Skill includes mode selection, safety constraints, and troubleshooting.

## Phase 4: Supported Agent Configuration

Configure Claude, Codex, Gemini, OpenCode, and Hermes to discover the same tool contract. Delay Hermes until CLIBridge is verified.

Exit criteria:

- Each agent has a documented config file update.
- Each agent can run `workforce-browser doctor`.
- OpenCode instructions avoid unbounded agentic work from ambiguous prompts.

## Phase 5: Verification And Rollout

Add a verification script and collect evidence per host and per agent.

Exit criteria:

- Logs exist under `~/.workforce/test-results/browser-harness/`.
- Failures include actionable diagnostics.
- Tobor and Twiki are marked supported only after host-local proof.

## Phase 6: Maintenance

Document update, rollback, and troubleshooting procedures. Keep CLI updates independent from Workforce skill updates where possible.

Exit criteria:

- Operators can update the repo and rerun verification.
- Operators can disable browser automation by removing or bypassing `workforce-browser`.
- Domain skill promotion remains gated until implemented and reviewed.
