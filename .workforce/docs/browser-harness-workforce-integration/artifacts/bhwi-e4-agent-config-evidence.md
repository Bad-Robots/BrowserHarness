# BHWI-E4 Agent Configuration Evidence

Timestamp: 2026-05-12T18:38:00Z
Working directory: `/Users/mattheller/Projects/BrowserHarness`

## Acceptance Criteria

- PASS if every configured agent instruction surface contains a `BROWSER-HARNESS-WORKFORCE` block.
- PASS if every configured agent block points to `workforce-browser doctor`.
- PASS if every configured agent has access to `browser-automation/SKILL.md` or a documented shared skill path.
- PASS if `workforce-browser --version` exits 0 from the shared Workforce PATH.
- PASS if domain-skill mutation guidance says to keep `BH_DOMAIN_SKILLS=0`.

## Shared Setup

```text
~/.workforce/bin/workforce-browser -> /Users/mattheller/Projects/BrowserHarness/scripts/workforce-browser
~/.workforce/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
browser-harness version: 0.1.0
```

## Claude

Instruction surface:

```text
~/.claude/CLAUDE.md
```

Skill surface:

```text
~/.claude/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Validated substrings:

```text
BROWSER-HARNESS-WORKFORCE
browser-automation
workforce-browser doctor
BH_DOMAIN_SKILLS=0
```

## Codex

Instruction surface:

```text
~/.codex/AGENTS.md
```

Skill surface:

```text
~/.codex/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Validated substrings:

```text
BROWSER-HARNESS-WORKFORCE
browser-automation
workforce-browser doctor
BH_DOMAIN_SKILLS=0
```

## Gemini

Instruction surface:

```text
~/.gemini/GEMINI.md
```

Skill surface:

```text
~/.gemini/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Validated substrings:

```text
BROWSER-HARNESS-WORKFORCE
browser-automation
workforce-browser doctor
BH_DOMAIN_SKILLS=0
```

Note: this host uses `~/.gemini/GEMINI.md`; `~/.gemini/instructions.md` was not present.

## OpenCode

Instruction surface:

```text
~/.config/opencode/AGENTS.md
```

Skill surface:

```text
~/.config/opencode/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Validated substrings:

```text
BROWSER-HARNESS-WORKFORCE
browser-automation
workforce-browser doctor
BH_DOMAIN_SKILLS=0
```

Note: `opencode run` was not used as a smoke test because OpenCode run mode is agentic and can execute inferred work from CWD.

## Hermes

Instruction surface:

```text
~/.hermes/HERMES.md
```

Skill surface:

```text
~/.hermes/skills/workforce/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Validated substrings:

```text
BROWSER-HARNESS-WORKFORCE
browser-automation
workforce-browser doctor
BH_DOMAIN_SKILLS=0
```

Note: Hermes CLIBridge package import was not required for this setup because this host already loads SKILL.md files under `~/.hermes/skills/workforce/`.
