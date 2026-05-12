# Browser Harness Workforce Integration Progress

## 2026-05-12

Status: decomposed

Completed:

- Converted the accepted Browser Harness Workforce integration plan into spec-to-ship artifacts.
- Created intake, plan, technical spec, implementation plan, FR coverage, task list, review log, workflow context, and state.
- Kept this pass planning-only; no installation, user home directory edits, or agent configuration changes were executed.

Next:

- Start implementation with BHWI-E1-T1.
- Carry the Gate 3 material notes into the first implementation pass, especially exact file paths, wrapper command contract, env schema, and headless lifecycle state.
- Keep Hermes blocked until CLIBridge prerequisites are verified.
- Keep routing registry edits blocked until the missing generator/source of truth is identified.

## 2026-05-12 Gate 3 Review

Status: approved with notes

Completed:

- Ran `$workforce-os:adversarial-review plan` against `TASKS.md`.
- Review returned `APPROVED_WITH_NOTES`.
- Blocking findings: 0.
- Material notes: 11.
- Tiebreaker was not invoked.

## 2026-05-12 Execution Loop

Status: in progress

Completed:

- `BHWI-E1-T1` verified the installable CLI contract.
- Added unit coverage for `browser-harness --version` and `browser-harness --doctor` dispatch.
- Updated `install.md` with the canonical CLI entrypoint, install validation commands, supported install modes, and troubleshooting.
- Ran targeted validation: `uv run --with pytest python -m pytest tests/unit/test_run.py -q` passed with 15 tests.
- Ran `uv run browser-harness --version`, which returned `0.1.0`.
- Ran `uv run browser-harness --doctor`; it executed correctly and returned nonzero because this host does not currently have an active Browser Harness daemon/browser connection.
- Ran adversarial review on the `BHWI-E1-T1` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E1-T2` created `scripts/setup-workforce-browser-env.sh`.
- Validated `BHWI-E1-T2` with `bash -n`, isolated temp-home idempotency checks, existing-env backup checks, and env key preservation checks.
- Ran adversarial review on the `BHWI-E1-T2` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E1-T3` created `scripts/workforce-browser`.
- Validated `BHWI-E1-T3` with syntax checks, fake `browser-harness` delegation checks, invalid mode checks, missing executable checks, external CDP config checks, and domain-skill value checks.
- Ran adversarial review on the revised `BHWI-E1-T3` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E1-T4` added wrapper doctor diagnostics for env, workspace, test results, state, log dir, and executable resolution.
- Validated `BHWI-E1-T4` with syntax checks and temp-home doctor success/failure/missing-env cases.
- Ran adversarial review on the `BHWI-E1-T4` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- Marked `BHWI-E2-T1` blocked on local GUI browser/daemon availability for this host.
- `BHWI-E2-T2` implemented managed headless lifecycle commands in `scripts/workforce-browser`.
- Validated `BHWI-E2-T2` with syntax checks, stopped status, cleanup, no-browser failure, and launch-timeout cleanup using isolated temp homes.
- Ran adversarial review on the `BHWI-E2-T2` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E2-T3` verified live headless mode with managed Chrome start/status/CDP probe/stop on a temp profile.
- Increased headless readiness polling to 20 seconds after the first Mac smoke run showed Chrome could become ready near the previous timeout.
- Ran adversarial review on the revised headless diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E2-T4` documented local GUI, external CDP, remote GUI, Tobor/Twiki host-local support, and RustDesk boundaries.
- Ran adversarial review on the `BHWI-E2-T4` docs diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E3-T1` created `workforce-skills/browser-automation/SKILL.md`.
- Validated the skill frontmatter and required content references with a Python structural check.
- Ran adversarial review on the final `BHWI-E3-T1` skill artifact; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E3-T2` exposed the skill at `~/.workforce/skills/browser-automation/SKILL.md`.
- Exposed `workforce-browser` at `~/.workforce/bin/workforce-browser`.
- Installed the local `browser-harness` CLI with `uv tool install -e .`.
- Captured discovery evidence in `artifacts/bhwi-e3-t2-discovery-evidence.md`.
- Ran adversarial review on the strengthened `BHWI-E3-T2` evidence; verdict was `APPROVED_WITH_NOTES` with 0 blockers and 0 material findings.
- `BHWI-E3-T3` changed the Workforce wrapper to fail closed when `BH_DOMAIN_SKILLS=1`.
- Updated Browser Harness and Workforce skill docs to state that domain-skill mutation remains disabled until a reviewed promotion command exists.
- Validated the domain-skill gate with syntax checks and temp-home wrapper checks for the accepted `0` path and rejected `1` path.
- Ran adversarial review on the `BHWI-E3-T3` diff; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E4-T1` configured Claude through `~/.claude/CLAUDE.md` and `~/.claude/skills/browser-automation`.
- `BHWI-E4-T2` configured Codex through `~/.codex/AGENTS.md` and `~/.codex/skills/browser-automation`.
- `BHWI-E4-T3` configured Gemini through `~/.gemini/GEMINI.md` and `~/.gemini/skills/browser-automation`.
- `BHWI-E4-T4` configured OpenCode through `~/.config/opencode/AGENTS.md` and `~/.config/opencode/skills/browser-automation`.
- `BHWI-E4-T5` configured Hermes through `~/.hermes/HERMES.md` and `~/.hermes/skills/workforce/browser-automation`.
- Captured E4 evidence in `artifacts/bhwi-e4-agent-config-evidence.md`.
- Ran adversarial review on E4 adapter evidence; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- Added `scripts/verify-workforce-browser-setup.sh`.
- Patched Workforce adapter source files under `/Users/mattheller/Projects/Workforce/workforce/` so Codex, Gemini, OpenCode, and Hermes config blocks survive `dev_env_sync.py`.
- Ran `python3 runtime/scripts/dev_env_sync.py --repo-root /Users/mattheller/Projects/Workforce`; sync completed with status `ok`.
- Ran `scripts/verify-workforce-browser-setup.sh`; it returned 0 with one expected warning for local GUI/profile optional doctor failures.
- Captured verifier output in `artifacts/bhwi-e5-t1-verify-setup-output.txt`.
- Ran adversarial review on the verification script; verdict was `APPROVED_WITH_NOTES` with 0 blockers.
- `BHWI-E5-T2` ran non-agentic per-agent smoke checks for Claude, Codex, Gemini, OpenCode, and Hermes.
- Captured smoke evidence in `artifacts/bhwi-e5-t2-agent-smoke-evidence.md`.
- Ran adversarial review on E5 smoke evidence; verdict was `APPROVED_WITH_NOTES` with 0 blockers and 0 material findings.
- `BHWI-E6-T1` captured rollout evidence in `ROLLOUT.md`.
- `BHWI-E6-T2` added maintenance, rollback, operating rules, and backlog notes to `ROLLOUT.md`.
- Ran adversarial review on the rollout docs; verdict was `APPROVED_WITH_NOTES` with 0 blockers.

In progress:

- Final verification and handoff summary.
