# BHWI-E5-T2 Per-Agent Smoke Evidence

Timestamp: 2026-05-12T18:50:00Z
Working directory: `/Users/mattheller/Projects/BrowserHarness`

## CLI Presence

```text
claude   /Users/mattheller/.local/bin/claude              2.1.139 (Claude Code)
codex    /Users/mattheller/.workforce/bin/codex           codex-cli 0.130.0
gemini   /Users/mattheller/.npm-global/bin/gemini         0.41.2
opencode /Users/mattheller/.workforce/bin/opencode        1.14.48
hermes   /Users/mattheller/.local/bin/hermes              Hermes Agent v0.12.0
```

No agentic model-run smoke was executed. This avoids OpenCode/Codex-style agentic `run` modes inferring work from the current repository. The non-agentic smoke checks verify binary presence, adapter instruction surfaces, skill surfaces, and shared Browser Harness CLI health.

## Shared Verification

Command:

```sh
scripts/verify-workforce-browser-setup.sh
```

Result:

```text
summary: failures=0 warnings=1
```

The one warning is expected on this host:

```text
workforce-browser doctor exited 1 with only known local GUI/profile optional failures
```

The verifier confirmed:

- `workforce-browser` resolves from `~/.workforce/bin`.
- `browser-harness` resolves from `~/.local/bin`.
- `workforce-browser --version` returns `0.1.0`.
- `browser-automation` skill surfaces resolve for Claude, Codex, Gemini, OpenCode, and Hermes.
- All five agent instruction surfaces contain the Browser Harness block.
- `BH_DOMAIN_SKILLS=1` fails closed.
