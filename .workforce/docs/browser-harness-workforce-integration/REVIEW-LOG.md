# Browser Harness Workforce Integration Review Log

## Accepted Inputs

- Source plan: `workforce-integration/browser-harness-cli-plan.md`
- Latest adversarial review status: `APPROVED_WITH_NOTES`
- Reviewer set:
  - Architecture: `kimi-k2.6`
  - Implementation: `codex-cli-default`
  - Tiebreaker: `deepseek-v4-pro`
- User decision: accepted remaining material findings and moved to spec-to-ship.

## Material Findings Carried Forward

- Headless support requires explicit lifecycle scripts and readiness checks.
- Tobor and Twiki support is conditional on host-local install and verification.
- RustDesk is human GUI access only, not the automation transport.
- Domain skills remain disabled by default until promotion behavior is implemented and verified.
- Workforce routing registry edits remain blocked until the generator/source of truth is identified.
- Hermes remains blocked until CLIBridge prerequisites are verified.

## Gate 3 Spec-To-Ship Plan Review

Date: 2026-05-12
Artifact: `.workforce/docs/browser-harness-workforce-integration/TASKS.md`
Task ID: `final-gate3-spec-to-ship-plan-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 11
- Nit: 0

Models:

- Architecture: `gemma4:31b` fallback after `kimi-k2.6` returned HTTP 503
- Implementation contract: `codex-cli-default`
- Tiebreaker: not invoked

Carryforward material notes:

- Replace placeholder `future ...` file scopes with exact source and install paths before assigning tickets to coding agents.
- Define the `workforce-browser` command grammar, env variables, pass-through behavior, and exit-code contract.
- Specify managed headless lifecycle state: pidfile, lockfile, CDP URL, stale-state recovery, and managed-only cleanup.
- Specify env file schema, backup, merge, idempotency, and parsing rules.
- Add backup and merge markers for user agent configuration files.
- Define wrapper install path and binary resolution strategy.
- Add cleanup/watchdog behavior for crashed headless sessions.
- Make the domain-skill promotion mechanism explicit.
- Consider consolidating repetitive agent config tickets into a matrix-based task when execution starts.

## BHWI-E1-T1 Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e1-t1.diff`
Task ID: `BHWI-E1-T1-code-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 8
- Nit: 1

Notes:

- Several material notes were based on diff-only context and asked for existing `run.py`/`admin.py` behavior already present in the repo.
- Useful carryforward notes remain: make install-path verification stronger in later wrapper/setup work, and keep doctor checks aligned with automation expectations.

## BHWI-E1-T2 Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e1-t2.diff`
Task ID: `BHWI-E1-T2-code-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 12
- Nit: 1

Notes:

- Several material notes were based on diff-only context and did not see existing repo files.
- Useful carryforward notes remain: `workforce-browser` must source the shared env file, and future doctor behavior should separate install/config/browser readiness where possible.

## BHWI-E1-T3 Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e1-t3-r2.diff`
Task ID: `BHWI-E1-T3-code-review-r2-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 11
- Nit: 1

Notes:

- Useful carryforward notes remain: strengthen non-interactive PATH guidance, keep domain-skill promotion hard-gated in `BHWI-E3-T3`, and consider future capability reporting for wrapper commands.

## BHWI-E1-T4 Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e1-t4.diff`
Task ID: `BHWI-E1-T4-code-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 11
- Nit: 1

Notes:

- Useful carryforward notes remain: add capability discovery later if wrapper command surface expands, and harden domain-skill approval in `BHWI-E3-T3`.

## BHWI-E2-T2 Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e2-t2.diff`
Task ID: `BHWI-E2-T2-code-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 11
- Nit: 1

Notes:

- Useful carryforward notes remain: add stronger PID identity checks later if headless mode is used on shared hosts, and keep domain-skill approval hard-gated in `BHWI-E3-T3`.

## BHWI-E2-T2/T3 Revised Code Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e2-t2-t3-r2.diff`
Task ID: `BHWI-E2-T2-T3-code-review-r2-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 12
- Nit: 1

Notes:

- Useful carryforward notes remain: document code-execution trust boundaries clearly in downstream skills and keep PID identity hardening on the maintenance backlog for shared hosts.

## BHWI-E2-T4 Docs Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e2-t4.diff`
Task ID: `BHWI-E2-T4-doc-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 6
- Nit: 2

Notes:

- Useful carryforward notes remain: persist PATH setup during installation/config tickets and keep headless state schema visible in operator docs.

## BHWI-E3-T1 Skill Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e3-t1-r4.diff`
Task ID: `BHWI-E3-T1-skill-review-r4-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 11
- Nit: 2

Notes:

- Useful carryforward notes remain: strengthen host attestation and external CDP allowlisting in later verification/config tickets, and keep domain-skill promotion hard-gated in `BHWI-E3-T3`.

## BHWI-E3-T2 Discovery Evidence Review

Date: 2026-05-12
Artifact: `.workforce/docs/browser-harness-workforce-integration/artifacts/bhwi-e3-t2-discovery-evidence.md`
Task ID: `BHWI-E3-T2-discovery-review-r2-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 0
- Nit: 13

Notes:

- Discovery evidence passed after adding explicit acceptance criteria. Remaining notes are assertion-strength and portability improvements for later verification automation.

## BHWI-E3-T3 Domain Gate Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e3-t3-domain-gate.diff`
Task ID: `BHWI-E3-T3-domain-gate-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 5
- Nit: 4

Notes:

- The domain-skill fail-closed gate passed. Material notes mostly concern pre-existing headless lifecycle hardening and remote setup docs; carry them into E5 verification and maintenance backlog.

## BHWI-E4 Agent Config Review

Date: 2026-05-12
Artifact: `.workforce/docs/browser-harness-workforce-integration/artifacts/bhwi-e4-agent-config-evidence.md`
Task ID: `BHWI-E4-agent-config-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 8
- Nit: 7

Notes:

- All five agent config surfaces passed. Material notes are evidence-strength and runtime-enumeration concerns; carry them into `BHWI-E5-T1` verification script.

## BHWI-E5-T1 Verification Script Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e5-t1-verify-script.diff`
Task ID: `BHWI-E5-T1-verify-script-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 10
- Nit: 1

Notes:

- The verifier passed locally and review found no blockers. Carry material hardening notes into maintenance: path canonicalization, stricter structured doctor/capability parsing, and clearer structural-vs-operational readiness tiers.

## BHWI-E5-T2 Agent Smoke Review

Date: 2026-05-12
Artifact: `.workforce/docs/browser-harness-workforce-integration/artifacts/bhwi-e5-t2-agent-smoke-evidence.md`
Task ID: `BHWI-E5-T2-agent-smoke-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 0
- Nit: 10

Notes:

- Non-agentic per-agent smoke passed. Remaining notes are evidence detail improvements and optional negative-smoke coverage.

## BHWI-E6 Rollout Review

Date: 2026-05-12
Artifact: `/private/tmp/bhwi-e6-rollout.diff`
Task ID: `BHWI-E6-rollout-review-20260512`
Verdict: `APPROVED_WITH_NOTES`

Counts:

- Blocking: 0
- Material: 3
- Nit: 2

Notes:

- Rollout and rollback docs passed. Easy notes were incorporated: wrapper source path, env/domain verification, source adapter file list, and rollback block markers.
