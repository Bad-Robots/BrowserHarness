# Browser Harness Workforce Integration Plan

## Goal

Deliver a durable implementation path that makes Browser Harness callable by all supported CLI coding agents through a consistent Workforce-facing command and skill.

## Product Shape

- Canonical CLI: `browser-harness`
- Workforce wrapper: `workforce-browser`
- Workforce skill: `browser-automation`
- Shared env file: `~/.workforce/browser-harness.env`
- Shared workspace: `~/.workforce/browser-agent-workspace/`
- Verification logs: `~/.workforce/test-results/browser-harness/`

## Strategy

1. Install Browser Harness as a normal local CLI on each target host.
2. Put `workforce-browser` on `PATH` for agents and humans.
3. Source shared Workforce browser settings from one env file.
4. Give each supported agent explicit instructions for when to call the wrapper.
5. Keep `BH_DOMAIN_SKILLS=0` until promotion/export behavior is implemented and verified.
6. Treat headless browser execution as a managed lifecycle with start, stop, status, and readiness checks.
7. Verify every target mode independently before enabling default routing.

## Delivery Phases

1. Foundation and local CLI install contract.
2. Workforce wrapper and shared env.
3. Browser mode support: local GUI, remote GUI, headless, external CDP.
4. Workforce skill and routing-safe registration.
5. Agent-specific configuration for Claude, Codex, Gemini, OpenCode, and Hermes.
6. Verification scripts and evidence capture.
7. Documentation, maintenance, and rollout handoff.

## Key Constraints

- Do not write directly into agent workspaces except documented Browser Harness workspace paths.
- Do not enable domain-skill mutation by default.
- Do not assume Tobor or Twiki already have the CLI installed.
- Do not treat RustDesk as a CDP or automation mechanism.
- Do not edit Workforce routing registries until the missing generator/source of truth is identified.
- Do not enable Hermes integration until CLIBridge prerequisites are verified.
