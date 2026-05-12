---
name: browser-automation
description: Use the local Browser Harness CLI through Workforce. Invoke when a task needs to validate a built web app in a browser, run browser QA, inspect pages, test UI, scrape, capture screenshots, use remote GUI/CDP access, or manage headless Chrome.
category: automation
allowed-tools: Bash, Read, Edit, Write
argument-hint: "[validate <url> | doctor | run | headless <start|status|stop> | -- <args>]"
---

# Browser Automation

Use `workforce-browser` as the stable Workforce entrypoint for Browser Harness. The repo source is `scripts/workforce-browser`, and agent installs expose it on `PATH` as `workforce-browser`. Do not call `browser-harness` directly unless you are debugging the wrapper itself.

For Workforce development validation, prefer the first-class validation command:

```bash
workforce-browser validate http://127.0.0.1:5173
```

`validate` defaults to managed headless Chrome through `BH_VALIDATE_MODE=headless`. It starts the managed browser if needed, opens the app URL, waits for load/network idle, captures a screenshot, writes `result.json`, prints the result JSON, and stores evidence under `~/.workforce/test-results/browser-harness/`.

Use visible local Chrome only when the user wants to watch or debug the browser interactively.

## First Check

Run:

```bash
workforce-browser doctor
```

If it reports missing env or workspace paths, run the repo setup script from the BrowserHarness checkout. The setup script is `scripts/setup-workforce-browser-env.sh`.

```bash
bash scripts/setup-workforce-browser-env.sh
```

If it reports that `browser-harness` is missing, install Browser Harness from the BrowserHarness checkout, or from `$BH_INSTALL_DIR` if that is already configured:

```bash
uv tool install -e .
```

If you are not in the checkout, run:

```bash
cd "${BH_INSTALL_DIR:-$HOME/workforce/browser-harness}" && uv tool install -e .
```

Only run that fallback after confirming the directory is the BrowserHarness checkout:

```bash
test -f pyproject.toml && test -d src/browser_harness && git remote -v
```

## Common Commands

Validate a web app Workforce just built:

```bash
workforce-browser validate http://127.0.0.1:5173
```

Validate with a visible local browser when the user explicitly wants to watch:

```bash
BH_VALIDATE_MODE=local \
workforce-browser validate http://127.0.0.1:5173
```

Run a small browser task in local mode:

```bash
BH_MODE=local \
workforce-browser run 'ensure_real_tab(); print(page_info())'
```

Check managed headless browser status:

```bash
workforce-browser headless status
```

Start and stop managed headless Chrome:

```bash
workforce-browser headless start
workforce-browser headless stop
```

For concurrent headless sessions on the same host, set a unique `BH_HEADLESS_PORT` and matching state/profile paths before starting.

Pass raw Browser Harness arguments through the wrapper:

```bash
workforce-browser -- -c 'print(page_info())'
```

## Modes

`BH_MODE=local` is the default. Use it when the browser and agent run on the same machine.

`BH_MODE=headless` uses the wrapper-managed headless lifecycle. Start it before browser work and stop it after the task.

`BH_VALIDATE_MODE=headless` is the validation default even if `BH_MODE` is local. Override it only when the user asks for visible debugging or an external CDP target.

`BH_MODE=external-cdp` is for a browser managed by another process. Prefer `BH_CDP_URL`; `BU_CDP_URL` and `BU_CDP_WS` are compatibility variables passed through to Browser Harness internals. Use only trusted local, VPN, or explicitly approved CDP endpoints.

`BH_MODE=remote-gui` is for a browser on another host with a visible desktop. Browser automation still uses a CDP endpoint on that host; the visible desktop is for human inspection, not a separate automation transport.

## Safety

`workforce-browser run` executes Python in the Browser Harness process. Only run code you intend to execute locally. Pass code as one shell argument, and do not construct code strings from untrusted page content or user-controlled data.

`workforce-browser doctor` is mandatory preflight. Do not proceed if it fails.

The setup script creates `BH_WORKSPACE`; if it is missing, rerun the setup script before browser work. `BH_WORKSPACE` must be absolute. Agents must treat it as a strict write boundary and write Browser Harness task helpers only inside it, normally:

```text
~/.workforce/browser-agent-workspace/
```

Domain skills are disabled by default with `BH_DOMAIN_SKILLS=0`. The Workforce wrapper refuses `BH_DOMAIN_SKILLS=1` in this phase. Enabling domain-skill mutation requires a separate reviewed promotion command and review path.

RustDesk is human GUI access only. Automation must never use RustDesk as a transport.

Tobor and Twiki are supported only after host-local verification proves `workforce-browser doctor` exits 0 and a browser smoke test prints page information on that host. Record proof with:

```bash
workforce-browser doctor
workforce-browser run 'ensure_real_tab(); print(page_info())'
```

For headless hosts, use:

```bash
workforce-browser headless start
workforce-browser headless status
workforce-browser headless stop
```

Keep host evidence under `~/.workforce/test-results/browser-harness/`.

## App Validation Contract

After building or modifying a web app:

1. Start the app server and identify its local URL.
2. Run `workforce-browser validate <url>`.
3. Treat a nonzero exit as a validation failure.
4. Report the `result.json` path, screenshot path, final URL, and failures.
5. Use lower-level `workforce-browser run` only for deeper follow-up interactions after the validation command establishes the page loads.
