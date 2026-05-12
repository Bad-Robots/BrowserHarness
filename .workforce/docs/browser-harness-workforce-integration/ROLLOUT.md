# Browser Harness Workforce Rollout

Date: 2026-05-12
Host: `/Users/mattheller`
Repo: `/Users/mattheller/Projects/BrowserHarness`

## Installed Surfaces

- Shared wrapper: `~/.workforce/bin/workforce-browser`
- Wrapper source: `/Users/mattheller/Projects/BrowserHarness/scripts/workforce-browser`
- Shared env: `~/.workforce/browser-harness.env`
- Shared workspace: `~/.workforce/browser-agent-workspace/`
- Shared skill: `~/.workforce/skills/browser-automation/SKILL.md`
- Installed CLI: `browser-harness 0.1.0`

Agent skill surfaces:

- Claude: `~/.claude/skills/browser-automation/SKILL.md`
- Codex: `~/.codex/skills/browser-automation/SKILL.md`
- Gemini: `~/.gemini/skills/browser-automation/SKILL.md`
- OpenCode: `~/.config/opencode/skills/browser-automation/SKILL.md`
- Hermes: `~/.hermes/skills/workforce/browser-automation/SKILL.md`

Agent instruction surfaces:

- Claude: `~/.claude/CLAUDE.md`
- Codex: `~/.codex/AGENTS.md`
- Gemini: `~/.gemini/GEMINI.md`
- OpenCode: `~/.config/opencode/AGENTS.md`
- Hermes: `~/.hermes/HERMES.md`

The durable source adapter files for Codex, Gemini, OpenCode, Hermes, and Claude are under `/Users/mattheller/Projects/Workforce/workforce/`.

## Verification

Primary verification command:

```bash
scripts/verify-workforce-browser-setup.sh
```

Current result:

```text
summary: failures=0 warnings=1
```

The verifier also checks that the shared env keeps `BH_DOMAIN_SKILLS=0` and that `BH_DOMAIN_SKILLS=1` fails closed in the wrapper.

The warning is expected on this host until a local Browser Harness daemon/browser connection is active. Accepted warning lines:

- `daemon alive`
- `active browser connections`
- `profile-use installed`
- `BROWSER_USE_API_KEY set`

Evidence files:

- `artifacts/bhwi-e3-t2-discovery-evidence.md`
- `artifacts/bhwi-e4-agent-config-evidence.md`
- `artifacts/bhwi-e5-t1-verify-setup-output.txt`
- `artifacts/bhwi-e5-t2-agent-smoke-evidence.md`

## Operating Rules

- Agents should use `workforce-browser`, not `browser-harness`, unless debugging the wrapper.
- `workforce-browser doctor` is mandatory preflight.
- `BH_DOMAIN_SKILLS=0` is the only allowed Workforce mode. `BH_DOMAIN_SKILLS=1` fails closed.
- Headless sessions must be stopped with `workforce-browser headless stop`.
- Tobor and Twiki require host-local verification before scheduling browser work.
- RustDesk is only for human GUI inspection or repair; automation must use CDP.

## Rollback

Remove Browser Harness from shared Workforce paths:

```bash
rm -f ~/.workforce/bin/workforce-browser
rm -rf ~/.workforce/skills/browser-automation
```

Remove agent skill links:

```bash
rm -rf ~/.claude/skills/browser-automation
rm -rf ~/.codex/skills/browser-automation
rm -rf ~/.gemini/skills/browser-automation
rm -rf ~/.config/opencode/skills/browser-automation
rm -rf ~/.hermes/skills/workforce/browser-automation
```

Remove Browser Harness blocks from these source adapter files, then resync:

```text
/Users/mattheller/Projects/Workforce/workforce/CLAUDE.md
/Users/mattheller/Projects/Workforce/workforce/AGENTS.md
/Users/mattheller/Projects/Workforce/workforce/GEMINI.md
/Users/mattheller/Projects/Workforce/workforce/OPENCODE.md
/Users/mattheller/Projects/Workforce/workforce/HERMES.md
```

Block markers:

```text
<!-- BROWSER-HARNESS-WORKFORCE:START -->
<!-- BROWSER-HARNESS-WORKFORCE:END -->
```

```bash
python3 /Users/mattheller/Projects/Workforce/runtime/scripts/dev_env_sync.py --repo-root /Users/mattheller/Projects/Workforce
```

Uninstall the CLI if needed:

```bash
uv tool uninstall browser-harness
```

Do not delete `~/.workforce/browser-agent-workspace/` unless the operator has confirmed that helper files and domain-skill experiments are disposable.

Remove `~/.workforce/browser-harness.env` only for a full Browser Harness reset. Leaving it in place is safe when rolling back just agent discovery.

## Maintenance Backlog

- Add structured output for `workforce-browser doctor`.
- Add structured output for `workforce-browser --capabilities`.
- Split verification into `STRUCTURAL_OK` and `OPERATIONAL_OK`.
- Add host attestation for Tobor/Twiki.
- Add external CDP allowlisting for non-local endpoints.
- Harden headless lifecycle PID identity and lock cleanup for shared hosts.
