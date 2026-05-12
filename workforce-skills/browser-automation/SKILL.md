---
name: browser-automation
description: Use the local Browser Harness CLI through Workforce. Invoke when a task needs browser automation, page inspection, web UI testing, scraping, screenshots, remote GUI/CDP access, or managed headless Chrome.
category: automation
allowed-tools: Bash, Read, Edit, Write
argument-hint: "[doctor | run | headless <start|status|stop> | -- <args>]"
---

# Browser Automation

Use `workforce-browser` as the stable Workforce entrypoint for Browser Harness. The repo source is `scripts/workforce-browser`, and agent installs expose it on `PATH` as `workforce-browser`. Do not call `browser-harness` directly unless you are debugging the wrapper itself. The setup script defaults to `BH_MODE=local`.

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

Run a small browser task in the default local mode:

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
