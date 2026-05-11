# Browser Harness CLI Integration Plan

**Document Type:** Integration Plan  
**Created:** 2026-05-10  
**Status:** Draft — Awaiting Adversarial Review  

---

## Executive Summary

Integrate browser-harness as a shared CLI tool across all supported coding agents (Claude Code, Codex, Gemini CLI, OpenCode, Hermes Agent) with Workforce skill routing. Single installation, shared daemon, agent-specific configuration layers.

**Proposed CLI Name:** Keep `browser-harness` (already on PATH)  
**Workforce Skill Name:** `browser-automation`  
**Env Config:** `~/.workforce/browser-harness.env`  
**Shared Workspace:** `~/.workforce/browser-agent-workspace/`

---

## Phase 1: Infrastructure Setup

### 1.1 Install Location

```bash
# Clone to stable Workforce-managed location
git clone https://github.com/browser-use/browser-harness ~/workforce/browser-harness
cd ~/workforce/browser-harness

# Install as editable tool (global CLI)
uv tool install -e .

# Verify
browser-harness --version
```

**Rationale:** Editable install means updates via `git pull` are immediately live. Centralized under `~/workforce/` for consistent discovery.

### 1.2 Environment Configuration

Create `~/.workforce/browser-harness.env`:

```bash
# Default daemon name
BU_NAME=workforce

# Enable domain skills (opt-in per-site playbooks)
BH_DOMAIN_SKILLS=1

# Agent workspace location (where agents write helpers)
BH_AGENT_WORKSPACE=~/.workforce/browser-agent-workspace

# Cloud browser API key (optional, for headless fallback)
# BROWSER_USE_API_KEY=your-key-here

# Auto-spawn cloud browser if local unavailable (optional)
# BU_AUTOSPAWN=1
```

**Rationale:** Centralized env file means all agents share the same daemon, profiles, and workspace.

### 1.3 Create Shared Agent Workspace

```bash
mkdir -p ~/.workforce/browser-agent-workspace/domain-skills
mkdir -p ~/.workforce/browser-agent-workspace/interaction-skills

# Copy existing skills from repo
cp -r ~/workforce/browser-harness/interaction-skills/* ~/.workforce/browser-agent-workspace/interaction-skills/
```

**Rationale:** Agents write task-specific helpers to `agent_helpers.py` and read domain skills from `domain-skills/`. Shared location means learnings persist across sessions and agents.

---

## Phase 2: Workforce Skill System Integration

### 2.1 Create Workforce Skill

**File:** `~/.workforce/skills/browser-automation/SKILL.md`

```markdown
---
name: browser-automation
description: Direct browser control via browser-harness CLI. Use for testing, scraping, automation, and QA validation.
---

# Browser Automation

Invoke the `browser-harness` CLI (on PATH) for all browser operations.

## When to Use

- QA validation of completed coding tasks
- End-to-end testing
- Web scraping
- Browser automation tasks
- Visual verification

## Invocation Pattern

```bash
browser-harness -c '
# Python code here. Helpers pre-imported.
new_tab("https://example.com")
wait_for_load()
capture_screenshot("/tmp/test.png")
print(page_info())
'
```

## Available Helpers

Pre-imported in `-c` scripts:
- Navigation: `new_tab(url)`, `goto_url(url)`, `switch_tab(target)`, `list_tabs()`
- Input: `click_at_xy(x, y)`, `type_text(text)`, `fill_input(selector, text)`, `press_key(key)`
- Wait: `wait(seconds)`, `wait_for_load(timeout)`, `wait_for_element(selector, timeout)`, `wait_for_network_idle(timeout)`
- Visual: `capture_screenshot(path, full=False, max_dim=1800)`
- DOM: `js(expression, target_id=None)`, `page_info()`
- Network: `http_get(url, headers, timeout)`, `drain_events()`
- Raw CDP: `cdp(method, session_id, **params)`
- Upload: `upload_file(selector, path)`
- Tabs: `ensure_real_tab()`, `iframe_target(url_substr)`
- Admin: `restart_daemon()`, `start_remote_daemon(name, **kwargs)`

## QA Validation Pattern

```bash
browser-harness -c '
import sys

def test_login():
    new_tab("https://app.com/login")
    wait_for_load()
    fill_input("#email", "test@test.com")
    fill_input("#password", "pass123")
    press_key("Enter")
    wait_for_load()
    
    info = page_info()
    passed = "dashboard" in info["url"].lower()
    capture_screenshot(f"/tmp/login-{"pass" if passed else "fail"}.png")
    return passed

results = test_login()
sys.exit(0 if results else 1)
'
```

## Domain Skills

When `BH_DOMAIN_SKILLS=1`, site-specific playbooks auto-load from `~/.workforce/browser-agent-workspace/domain-skills/<site>/`.

Check existing skills before inventing approaches:
```bash
ls ~/.workforce/browser-agent-workspace/domain-skills/
```

## Troubleshooting

```bash
# Check daemon and browser status
browser-harness --doctor

# Restart daemon (picks up code changes)
browser-harness --reload

# Update harness
browser-harness --update -y
```

## Connection Setup

First-time only:
1. Open Chrome
2. Navigate to `chrome://inspect/#remote-debugging`
3. Tick "Allow remote debugging for this browser instance"
4. Click Allow on popup if it appears

Alternative (headless/isolated):
```bash
chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-workforce
export BU_CDP_URL=http://127.0.0.1:9222
```

## Remote/Cloud Browsers

```bash
browser-harness -c '
start_remote_daemon("qa", proxyCountryCode="us")
new_tab("https://example.com")
'
```

Requires `BROWSER_USE_API_KEY` set in `~/.workforce/browser-harness.env`.
```

### 2.2 Register Skill in Workforce Routing

**File:** `~/.workforce/config/routing.yaml` (or equivalent)

Add entry:
```yaml
skills:
  browser-automation:
    path: ~/.workforce/skills/browser-automation/SKILL.md
    triggers:
      - "browser"
      - "web automation"
      - "selenium"
      - "playwright"
      - "end-to-end test"
      - "e2e test"
      - "scrape"
      - "QA validation"
      - "test the"
      - "open chrome"
      - "navigate to"
    routes_to: engineering
    priority: high
```

### 2.3 Create Department Integration

**File:** `~/.workforce/skills/engineering/browser-workflow.md`

```markdown
## Browser Testing Workflow

When a task requires browser validation:

1. **Check if browser-harness is available:**
   ```bash
   browser-harness --version
   ```

2. **Run the browser-automation skill** for complex flows

3. **Write test scripts** that:
   - Capture screenshots before/after actions
   - Assert on page_info() or js() results
   - Exit with code 0/1 for pass/fail
   - Write results to `~/.workforce/test-results/`

4. **For repeated tests**, create a domain skill under `~/.workforce/browser-agent-workspace/domain-skills/<app>/`
```

---

## Phase 3: CLI Agent Configuration

### 3.1 Claude Code

**File:** `~/.claude/CLAUDE.md` (append)

```markdown
---

## Browser Automation

For any browser task (testing, scraping, automation), use the `browser-harness` CLI:

```bash
browser-harness -c '
new_tab("https://example.com")
wait_for_load()
print(page_info())
'
```

**Setup:** Already installed at `~/workforce/browser-harness`. Env config at `~/.workforce/browser-harness.env`.

**Helpers pre-imported:** `new_tab`, `goto_url`, `click_at_xy`, `type_text`, `fill_input`, `press_key`, `wait_for_load`, `wait_for_element`, `capture_screenshot`, `js`, `page_info`, `cdp`, `upload_file`, `switch_tab`, `list_tabs`, `ensure_real_tab`, `drain_events`, `wait_for_network_idle`, `http_get`.

**First-time browser connection:**
1. Open Chrome
2. Go to `chrome://inspect/#remote-debugging`
3. Tick "Allow remote debugging"
4. Click Allow on popup

**QA pattern:** Screenshot → act → screenshot → assert on `page_info()` or `js()` result.

**Domain skills:** Check `~/.workforce/browser-agent-workspace/domain-skills/` for site-specific playbooks before inventing approaches.

**Troubleshooting:** `browser-harness --doctor`
```

### 3.2 Codex (OpenAI)

**File:** `~/.codex/config.toml` (or `~/.codex/instructions.md`)

```toml
[instructions]
browser_automation = """
For browser tasks, use the browser-harness CLI:

  browser-harness -c 'new_tab("https://example.com"); print(page_info())'

Installed at ~/workforce/browser-harness with env at ~/.workforce/browser-harness.env.

Pre-imported helpers: new_tab, goto_url, click_at_xy, type_text, fill_input, press_key, 
wait_for_load, wait_for_element, capture_screenshot, js, page_info, cdp, upload_file, 
switch_tab, ensure_real_tab, drain_events, wait_for_network_idle, http_get.

Browser setup: chrome://inspect/#remote-debugging → tick checkbox → Allow popup.

For complex flows, write multi-line scripts with screenshots for verification.
"""
```

Or as symlinked skill (already done in your setup):
```bash
ln -s ~/workforce/browser-harness/SKILL.md ~/.codex/skills/browser-harness
```

### 3.3 Gemini CLI

**File:** `~/.gemini/instructions.md` (create)

```markdown
# Browser Automation

Use `browser-harness` CLI for all browser operations:

```bash
browser-harness -c '
new_tab("https://example.com")
wait_for_load()
capture_screenshot("/tmp/test.png")
print(page_info())
'
```

**Location:** `~/workforce/browser-harness` (editable install)
**Config:** `~/.workforce/browser-harness.env`

**Key helpers:**
- `new_tab(url)` - open new tab
- `click_at_xy(x, y)` - click at coordinates (works through iframes/shadow DOM)
- `fill_input(selector, text)` - fill form field
- `wait_for_element(selector, timeout)` - wait for SPA rendering
- `capture_screenshot(path)` - visual verification
- `js(expression)` - run JavaScript, return result
- `page_info()` - get URL, title, viewport dimensions

**Browser connection:**
```bash
# One-time setup
# Open Chrome → chrome://inspect/#remote-debugging → tick checkbox → Allow popup
```

**QA example:**
```bash
browser-harness -c '
import sys
new_tab("https://app.com")
wait_for_load()
passed = "expected" in js("document.body.textContent")
sys.exit(0 if passed else 1)
'
```
```

### 3.4 OpenCode

**File:** `~/.config/opencode/instructions.md` (append to existing)

```markdown
---

## Browser Harness

Installed globally at `~/workforce/browser-harness`. Use for browser automation:

```bash
browser-harness -c 'new_tab("https://example.com"); print(page_info())'
```

Env: `~/.workforce/browser-harness.env`
Workspace: `~/.workforce/browser-agent-workspace/`

Connection: `chrome://inspect/#remote-debugging` → tick checkbox → Allow.
```

### 3.5 Hermes Agent

**File:** `~/.hermes/config.yaml` (or equivalent instructions file)

```yaml
instructions:
  browser: |
    Use browser-harness CLI for web automation:
    
      browser-harness -c 'new_tab("https://example.com"); capture_screenshot("/tmp/test.png")'
    
    Installed: ~/workforce/browser-harness
    Config: ~/.workforce/browser-harness.env
    
    Helpers: new_tab, click_at_xy, fill_input, wait_for_element, capture_screenshot, js, page_info, cdp
    
    QA pattern: screenshot → action → screenshot → assert
```

---

## Phase 4: Verification & Testing

### 4.1 Setup Verification Script

Create `~/workforce/browser-harness/verify-setup.sh`:

```bash
#!/bin/bash
set -e

echo "=== Browser Harness Setup Verification ==="
echo

# Check CLI
echo -n "CLI installed: "
if command -v browser-harness &> /dev/null; then
    browser-harness --version
else
    echo "FAILED - run: uv tool install -e ~/workforce/browser-harness"
    exit 1
fi

# Check env
echo -n "Env file: "
if [ -f ~/.workforce/browser-harness.env ]; then
    echo "OK"
else
    echo "MISSING - create ~/.workforce/browser-harness.env"
fi

# Check workspace
echo -n "Agent workspace: "
if [ -d ~/.workforce/browser-agent-workspace ]; then
    echo "OK"
else
    echo "MISSING - mkdir ~/.workforce/browser-agent-workspace"
fi

# Check daemon
echo -n "Daemon status: "
browser-harness --doctor | grep "daemon"

# Check browser connection
echo -n "Browser connection: "
browser-harness -c 'print(page_info())' &> /dev/null && echo "OK" || echo "FAILED - see chrome://inspect/#remote-debugging"

# Check agent configs
echo
echo "=== Agent Configurations ==="
for agent in claude codex gemini opencode hermes; do
    case $agent in
        claude)
            [ -f ~/.claude/CLAUDE.md ] && grep -q "browser-harness" ~/.claude/CLAUDE.md && echo "Claude Code: OK" || echo "Claude Code: MISSING"
            ;;
        codex)
            [ -L ~/.codex/skills/browser-harness ] && echo "Codex: OK" || echo "Codex: MISSING"
            ;;
        gemini)
            [ -f ~/.gemini/instructions.md ] && grep -q "browser-harness" ~/.gemini/instructions.md && echo "Gemini: OK" || echo "Gemini: MISSING"
            ;;
        opencode)
            [ -f ~/.config/opencode/instructions.md ] && grep -q "browser-harness" ~/.config/opencode/instructions.md && echo "OpenCode: OK" || echo "OpenCode: MISSING"
            ;;
        hermes)
            [ -f ~/.hermes/config.yaml ] && grep -q "browser-harness" ~/.hermes/config.yaml && echo "Hermes: OK" || echo "Hermes: MISSING"
            ;;
    esac
done

echo
echo "=== Verification Complete ==="
```

### 4.2 Test Suite for Each Agent

Create `~/workforce/browser-harness/tests/agent-smoke-tests.md`:

```markdown
# Agent Smoke Tests

Run these in each agent to verify browser-harness integration:

## Claude Code
```
Use the browser-harness CLI to open https://github.com/browser-use/browser-harness and capture a screenshot to /tmp/claude-test.png
```

## Codex
```
Use the browser-harness skill to navigate to https://example.com and print page_info()
```

## Gemini
```
Use browser-harness to test if https://httpbin.org/status/200 returns successfully
```

## OpenCode
```
Use browser-harness CLI to open a new tab and verify the URL
```

## Hermes
```
Use browser-harness to navigate and screenshot a test page
```

## Expected Output
All agents should:
1. Know to invoke `browser-harness -c '...'`
2. Have access to pre-imported helpers
3. Successfully connect to the browser
4. Complete the task without explaining setup
```

---

## Phase 5: Maintenance & Updates

### 5.1 Update Flow

```bash
# Check for updates
browser-harness --doctor

# Update (agents should pass -y)
browser-harness --update -y

# Verify
browser-harness --version
```

### 5.2 Domain Skill Contribution

When agents learn site-specific patterns:

1. Agent writes skill to `~/.workforce/browser-agent-workspace/domain-skills/<site>/<task>.md`
2. User reviews and commits to `~/workforce/browser-harness/agent-workspace/domain-skills/<site>/`
3. PR to upstream repo

### 5.3 Daemon Lifecycle

```bash
# Check status
browser-harness --doctor

# Restart (after code changes)
browser-harness --reload

# Manual restart
# Kill daemon process, next call auto-starts fresh
```

---

## Phase 6: Documentation

### 6.1 Quick Reference Card

Create `~/workforce/browser-harness/QUICKREF.md`:

```markdown
# Browser Harness Quick Reference

## Invoke
```bash
browser-harness -c 'new_tab("https://url.com"); print(page_info())'
```

## Common Tasks
| Task | Command |
|------|---------|
| Navigate | `new_tab(url)` |
| Click | `click_at_xy(x, y)` |
| Fill input | `fill_input(selector, text)` |
| Wait | `wait_for_element(selector, timeout=10)` |
| Screenshot | `capture_screenshot("/tmp/name.png")` |
| Assert | `assert js("condition")` |
| Raw CDP | `cdp("Page.navigate", url="...")` |

## Troubleshooting
```bash
browser-harness --doctor
browser-harness --reload
```

## Browser Setup
1. Chrome → `chrome://inspect/#remote-debugging`
2. Tick checkbox
3. Allow popup

## Files
- CLI: `~/workforce/browser-harness/`
- Env: `~/.workforce/browser-harness.env`
- Workspace: `~/.workforce/browser-agent-workspace/`
- Skills: `~/.workforce/skills/browser-automation/SKILL.md`
```

### 6.2 Onboarding Doc

Create `~/workforce/browser-harness/ONBOARDING.md`:

```markdown
# Browser Harness Onboarding

## For New Agents

1. Read `SKILL.md` for usage patterns
2. Check `QUICKREF.md` for syntax
3. Run `browser-harness --doctor` to verify setup
4. Test with: `browser-harness -c 'print(page_info())'`

## For New Sites

1. Check `~/.workforce/browser-agent-workspace/domain-skills/` for existing playbooks
2. If none exist, navigate and screenshot first
3. Document selectors, APIs, and quirks in new domain skill
4. Commit to repo for reuse

## QA Integration

1. Write test scripts that exit 0/1
2. Capture screenshots on failure
3. Log results to `~/.workforce/test-results/`
4. Run in CI with `BU_CDP_URL` for headless Chrome
```

---

## File Tree Summary

```
~/workforce/
├── browser-harness/                    # Main repo (editable install)
│   ├── SKILL.md                        # Source skill file
│   ├── src/browser_harness/            # Core code
│   ├── agent-workspace/                # Template workspace
│   ├── verify-setup.sh                 # Verification script
│   ├── tests/                          # Test suite
│   └── QUICKREF.md                     # Quick reference
│
~/.workforce/
├── browser-harness.env                 # Shared environment
├── browser-agent-workspace/            # Shared agent workspace
│   ├── agent_helpers.py                # Agents write helpers here
│   ├── domain-skills/                  # Site-specific playbooks
│   └── interaction-skills/             # UI mechanics
├── skills/
│   └── browser-automation/
│       └── SKILL.md                    # Workforce skill
├── config/
│   └── routing.yaml                    # Skill routing
└── test-results/                       # QA output

~/.claude/
└── CLAUDE.md                           # Browser section added

~/.codex/
├── skills/
│   └── browser-harness -> ~/workforce/browser-harness/SKILL.md
└── config.toml                         # Browser instructions

~/.gemini/
└── instructions.md                     # Browser section

~/.config/opencode/
└── instructions.md                     # Browser section

~/.hermes/
└── config.yaml                         # Browser section
```

---

## Decision Points

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| CLI name | Keep `browser-harness` | Already on PATH, rebranding adds confusion |
| Skill name | `browser-automation` | Clearer than `browser-harness` for routing |
| Workspace location | `~/.workforce/browser-agent-workspace/` | Shared across agents, persistent |
| Env file | `~/.workforce/browser-harness.env` | Centralized config, sourced by daemon |
| Domain skills | Enabled by default (`BH_DOMAIN_SKILLS=1`) | Agents learn from each other |
| Cloud fallback | Opt-in via `BROWSER_USE_API_KEY` | Cost control, local-first |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Daemon conflicts (multiple BUs) | Single `BU_NAME=workforce` for all agents |
| Stale browser sessions | `ensure_real_tab()` helper, `--reload` command |
| Agent writes non-reusable helpers | Enforce `agent_helpers.py` pattern, review before commit |
| Headless detection | Xvfb wrapper, cloud browser fallback |
| Skill not triggering | Add broad trigger patterns to routing.yaml |
| Updates break workflows | Test suite in `tests/`, run before `--update` |

---

## Next Steps (When Resuming)

1. **Run adversarial review** on this plan
   - Reviewers: kimi-k2.6 (Ollama), deepseek-v4-pro (OpenCode), codex (CLI)
   - Role assignments: TBD
   - Focus area: TBD

2. **Address BLOCKING findings** from review

3. **Execute Phase 1** — Infrastructure setup
   - Clone and install
   - Create env file
   - Create shared workspace

4. **Execute Phase 2** — Workforce skill registration

5. **Execute Phase 3** — Agent-specific configs

6. **Execute Phase 4** — Verification

7. **Document lessons learned** in domain skills

---

## Appendix: Headless Ubuntu Deployment Notes

For CI/CD or server deployment:

### Option 1: Browser Use Cloud
```bash
export BROWSER_USE_API_KEY="your-key"
export BU_AUTOSPAWN=1
browser-harness -c 'start_remote_daemon("work"); new_tab("https://...")'
```

### Option 2: Self-Hosted Headless
```bash
apt install -y google-chrome-stable xvfb
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-qa &
export BU_CDP_URL=http://127.0.0.1:9222
```

### Option 3: GitHub Actions
```yaml
- name: Setup Chrome
  run: |
    # Install Chrome + Xvfb
- name: Launch browser
  run: |
    # Start Xvfb + Chrome with remote debugging
- name: Run tests
  env:
    BU_CDP_URL: http://127.0.0.1:9222
  run: |
    browser-harness -c '...'
```
