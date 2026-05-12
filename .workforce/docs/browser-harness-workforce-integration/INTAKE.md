# Browser Harness Workforce Integration Intake

Date: 2026-05-12
Slug: browser-harness-workforce-integration
Prefix: BHWI
Mode: plan-only
Source plan: workforce-integration/browser-harness-cli-plan.md

## User Intent

Make Browser Harness available in every coding environment used for development through a local CLI and Workforce skill integration. Supported coding agents are Claude, Codex, Gemini, OpenCode, and Hermes Agent.

## Working Recommendation

Use both layers:

- Keep the existing repo as an installable local CLI named `browser-harness`.
- Add a Workforce wrapper named `workforce-browser` for stable cross-agent invocation.
- Add a Workforce skill named `browser-automation` so agents know when and how to use the CLI.

This keeps the browser tool usable outside Workforce while making Workforce the operational control plane for routing, configuration, verification, and agent instructions.

## Required Environments

- Local GUI systems with an attached browser.
- Remote GUI systems, including Tobor and Twiki when installed and verified on those hosts.
- Headless Linux/self-hosted systems through Xvfb or an equivalent managed browser display stack.
- RustDesk-assisted systems for human GUI access only; RustDesk is not the automation transport.
- External CDP endpoints where the browser is managed outside the local CLI.

## Out Of Scope For This Planning Run

- Installing Browser Harness on any host.
- Editing user home directory agent configuration.
- Changing Workforce routing registries.
- Running browser smoke tests.
- Implementing scripts.

## Accepted Review Status

The source plan passed adversarial review as `APPROVED_WITH_NOTES`. The user accepted the remaining material findings and moved the workflow to spec-to-ship decomposition.
