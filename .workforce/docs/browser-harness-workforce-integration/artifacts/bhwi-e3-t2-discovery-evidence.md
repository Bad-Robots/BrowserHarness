# BHWI-E3-T2 Skill Discovery Evidence

Timestamp: 2026-05-12T18:21:29Z
Working directory: `/Users/mattheller/Projects/BrowserHarness`

## Acceptance Criteria

- PASS if `~/.workforce/skills/browser-automation/SKILL.md` exists and resolves to this repo's `workforce-skills/browser-automation/SKILL.md`.
- PASS if the installed skill frontmatter includes `name: browser-automation`.
- PASS if the installed skill content instructs a fresh agent to run `workforce-browser doctor`.
- PASS if `workforce-browser` resolves from the shared Workforce bin path.
- PASS if `browser-harness` is installed and `workforce-browser --version` exits 0.
- PASS_WITH_ENV_NOTE if `workforce-browser doctor` validates the wrapper/env/workspace/bin layers but exits nonzero only because local GUI daemon/browser connectivity is unavailable on this host.

Known nonblocking doctor notes for this ticket:

- `latest release (could not reach github)` is informational and offline-tolerant.
- `daemon alive` and `active browser connections` are covered by `BHWI-E2-T1`, already blocked on local GUI daemon/browser availability.
- `profile-use installed` and `BROWSER_USE_API_KEY set` are optional cloud/profile-sync checks.

## Commands And Results

Install/expose the skill:

```sh
mkdir -p ~/.workforce/skills/browser-automation
ln -sfn /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md ~/.workforce/skills/browser-automation/SKILL.md
```

Result:

```text
/Users/mattheller/.workforce/skills/browser-automation/SKILL.md -> /Users/mattheller/Projects/BrowserHarness/workforce-skills/browser-automation/SKILL.md
```

Install/expose the wrapper and env:

```sh
bash scripts/setup-workforce-browser-env.sh
ln -sfn /Users/mattheller/Projects/BrowserHarness/scripts/workforce-browser ~/.workforce/bin/workforce-browser
uv tool install -e .
```

Discovery assertion:

```sh
find "$HOME/.workforce/skills" -maxdepth 2 -name SKILL.md -print | sort
```

Result:

```text
/Users/mattheller/.workforce/skills/browser-automation/SKILL.md
```

Skill content assertion:

```sh
python3 - <<'PY'
from pathlib import Path
p = Path.home() / ".workforce/skills/browser-automation/SKILL.md"
s = p.read_text()
assert p.is_symlink()
assert "name: browser-automation" in s
assert "workforce-browser doctor" in s
assert "scripts/workforce-browser" in s
print("skill discovery assertions passed")
PY
```

Result:

```text
skill discovery assertions passed
```

Wrapper assertion:

```sh
PATH="$HOME/.workforce/bin:$PATH" command -v workforce-browser
PATH="$HOME/.workforce/bin:$PATH" workforce-browser --capabilities
PATH="$HOME/.workforce/bin:$PATH" workforce-browser --version
```

Result:

```text
/Users/mattheller/.workforce/bin/workforce-browser
commands:
  --version
  --doctor
  doctor
  run
  headless start
  headless status
  headless stop
  headless cleanup
  --
0.1.0
```

Non-mutating headless assertion:

```sh
PATH="$HOME/.workforce/bin:$PATH" workforce-browser headless status
```

Result:

```text
headless stopped: no managed state at /Users/mattheller/.workforce/state/browser-harness/headless-session.env
exit=1
```

`exit=1` is accepted for this assertion because no managed headless session was started.

Doctor assertion:

```sh
PATH="$HOME/.workforce/bin:$PATH" workforce-browser doctor
```

Result summary:

```text
[ok] env file
[ok] mode
[ok] workspace
[ok] domain skills
[ok] interaction skills
[ok] test results
[ok] state dir
[ok] log dir
[ok] browser-harness
[ok] chrome running
[FAIL] daemon alive
[FAIL] active browser connections
[FAIL] profile-use installed
[FAIL] BROWSER_USE_API_KEY set
exit=1
```

Status: `PASS_WITH_ENV_NOTE`.
