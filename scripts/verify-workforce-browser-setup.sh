#!/usr/bin/env bash
set -euo pipefail

failures=0
warnings=0

pass() {
  printf '[PASS] %s\n' "$*"
}

warn() {
  warnings=$((warnings + 1))
  printf '[WARN] %s\n' "$*"
}

fail() {
  failures=$((failures + 1))
  printf '[FAIL] %s\n' "$*" >&2
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

require_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    pass "directory exists: $path"
  else
    fail "missing directory: $path"
  fi
}

require_contains() {
  local path="$1"
  local needle="$2"
  if grep -Fq "$needle" "$path"; then
    pass "$path contains: $needle"
  else
    fail "$path missing: $needle"
  fi
}

require_symlink_target() {
  local path="$1"
  local expected="$2"
  if [[ ! -L "$path" ]]; then
    fail "not a symlink: $path"
    return
  fi
  local target
  target="$(readlink "$path")"
  if [[ "$target" == "$expected" ]]; then
    pass "$path -> $target"
  else
    fail "$path points to $target, expected $expected"
  fi
}

require_resolved_target() {
  local path="$1"
  local expected="$2"
  if [[ ! -e "$path" ]]; then
    fail "missing path: $path"
    return
  fi
  local resolved
  resolved="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
  if [[ "$resolved" == "$expected" ]]; then
    pass "$path resolves to $resolved"
  else
    fail "$path resolves to $resolved, expected $expected"
  fi
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_dir="$repo_root/workforce-skills/browser-automation"
skill_file="$skill_dir/SKILL.md"
wrapper_file="$repo_root/scripts/workforce-browser"
export PATH="$HOME/.workforce/bin:$PATH"

printf 'Browser Harness Workforce setup verification\n'
printf 'repo_root=%s\n' "$repo_root"

require_file "$skill_file"
require_file "$wrapper_file"
require_contains "$skill_file" "name: browser-automation"
require_contains "$skill_file" "workforce-browser doctor"
require_contains "$skill_file" "workforce-browser validate"
require_contains "$skill_file" "BH_DOMAIN_SKILLS=0"

require_dir "$HOME/.workforce"
require_file "$HOME/.workforce/browser-harness.env"
require_symlink_target "$HOME/.workforce/bin/workforce-browser" "$wrapper_file"
require_symlink_target "$HOME/.workforce/skills/browser-automation/SKILL.md" "$skill_file"

agent_pairs=(
  "$HOME/.claude/CLAUDE.md|$HOME/.claude/skills/browser-automation/SKILL.md|$skill_file"
  "$HOME/.codex/AGENTS.md|$HOME/.codex/skills/browser-automation/SKILL.md|$skill_file"
  "$HOME/.gemini/GEMINI.md|$HOME/.gemini/skills/browser-automation/SKILL.md|$skill_file"
  "$HOME/.config/opencode/AGENTS.md|$HOME/.config/opencode/skills/browser-automation/SKILL.md|$skill_file"
  "$HOME/.hermes/HERMES.md|$HOME/.hermes/skills/workforce/browser-automation/SKILL.md|$skill_file"
)

for entry in "${agent_pairs[@]}"; do
  IFS='|' read -r doc skill_link expected_target <<<"$entry"
  require_file "$doc"
  require_resolved_target "$skill_link" "$expected_target"
  require_file "$skill_link"
  require_contains "$doc" "BROWSER-HARNESS-WORKFORCE"
  require_contains "$doc" "workforce-browser doctor"
  require_contains "$doc" "Keep \`BH_DOMAIN_SKILLS=0\`"
  require_contains "$doc" "fails closed if domain-skill mutation is enabled"
done

if command -v workforce-browser >/dev/null 2>&1; then
  pass "workforce-browser resolves to $(command -v workforce-browser)"
else
  fail "workforce-browser not found on PATH"
fi

if command -v browser-harness >/dev/null 2>&1; then
  pass "browser-harness resolves to $(command -v browser-harness)"
else
  fail "browser-harness not found on PATH"
fi

if version="$(workforce-browser --version 2>&1)"; then
  pass "workforce-browser --version: $version"
else
  fail "workforce-browser --version failed: $version"
fi

capabilities="$(workforce-browser --capabilities)"
for capability in "validate" "run" "headless start" "headless status" "headless stop" "headless cleanup"; do
  if grep -Fq "$capability" <<<"$capabilities"; then
    pass "capability present: $capability"
  else
    fail "capability missing: $capability"
  fi
done

tmp_home="$(mktemp -d "${TMPDIR:-/tmp}/bhwi-domain-gate.XXXXXX")"
trap 'rm -rf "$tmp_home"' EXIT
HOME="$tmp_home" "$repo_root/scripts/setup-workforce-browser-env.sh" >/dev/null
printf 'BH_DOMAIN_SKILLS="1"\n' >> "$tmp_home/.workforce/browser-harness.env"
set +e
domain_gate_output="$(HOME="$tmp_home" PATH="$repo_root/scripts:$PATH" "$wrapper_file" --capabilities 2>&1)"
domain_gate_status="$?"
set -e
if [[ "$domain_gate_status" -eq 78 ]] && grep -Fq "BH_DOMAIN_SKILLS=1 is disabled" <<<"$domain_gate_output"; then
  pass "BH_DOMAIN_SKILLS=1 fails closed"
else
  fail "BH_DOMAIN_SKILLS=1 did not fail closed; status=$domain_gate_status output=$domain_gate_output"
fi

set +e
doctor_output="$(workforce-browser doctor 2>&1)"
doctor_status="$?"
set -e
printf '%s\n' "$doctor_output"
if [[ "$doctor_status" -eq 0 ]]; then
  pass "workforce-browser doctor passed"
else
  allowed_failures=(
    "daemon alive"
    "active browser connections"
    "profile-use installed"
    "BROWSER_USE_API_KEY set"
  )
  unexpected=0
  while IFS= read -r line; do
    [[ "$line" == *"[FAIL]"* ]] || continue
    known=0
    for allowed in "${allowed_failures[@]}"; do
      if [[ "$line" == *"$allowed"* ]]; then
        known=1
        break
      fi
    done
    if [[ "$known" -eq 0 ]]; then
      unexpected=1
      fail "unexpected doctor failure: $line"
    fi
  done <<<"$doctor_output"
  if [[ "$unexpected" -eq 0 ]]; then
    warn "workforce-browser doctor exited $doctor_status with only known local GUI/profile optional failures"
  fi
fi

printf 'summary: failures=%s warnings=%s\n' "$failures" "$warnings"
if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
