#!/usr/bin/env bash
set -euo pipefail

umask 077

wf_home="${WORKFORCE_HOME:-$HOME/.workforce}"
env_file="${BH_ENV_FILE:-$wf_home/browser-harness.env}"
install_dir="${BH_INSTALL_DIR:-$HOME/workforce/browser-harness}"
workspace="${BH_WORKSPACE:-$wf_home/browser-agent-workspace}"
test_results="${BH_TEST_RESULTS:-$wf_home/test-results/browser-harness}"
state_dir="${BH_STATE_DIR:-$wf_home/state/browser-harness}"
bin_dir="${BH_BIN_DIR:-$wf_home/bin}"
log_dir="${BH_LOG_DIR:-$wf_home/logs/browser-harness}"
headless_profile_dir="${BH_HEADLESS_PROFILE_DIR:-$state_dir/headless-profile}"
headless_state_file="${BH_HEADLESS_STATE_FILE:-$state_dir/headless-session.env}"
headless_log_file="${BH_HEADLESS_LOG_FILE:-$log_dir/headless-browser.log}"

mkdir -p "$wf_home" "$bin_dir" "$workspace/domain-skills" "$workspace/interaction-skills" "$test_results" "$state_dir" "$log_dir" "$headless_profile_dir"

created_env=0
if [[ ! -e "$env_file" ]]; then
  mkdir -p "$(dirname "$env_file")"
  : > "$env_file"
  created_env=1
fi
chmod 600 "$env_file"

needs_update=0
for key in BH_INSTALL_DIR BH_WORKSPACE BH_DOMAIN_SKILLS BH_MODE BH_CDP_URL BH_TEST_RESULTS BH_STATE_DIR BH_BIN_DIR BH_LOG_DIR BH_HEADLESS_PORT BH_HEADLESS_PROFILE_DIR BH_HEADLESS_STATE_FILE BH_HEADLESS_LOG_FILE; do
  if ! grep -Eq "^${key}=" "$env_file"; then
    needs_update=1
    break
  fi
done

backup_path=""
if [[ "$created_env" -eq 0 && "$needs_update" -eq 1 ]]; then
  backup_path="${env_file}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p "$env_file" "$backup_path"
fi

append_if_missing() {
  local key="$1"
  local value="$2"
  if ! grep -Eq "^${key}=" "$env_file"; then
    printf '%s="%s"\n' "$key" "$value" >> "$env_file"
  fi
}

append_if_missing BH_INSTALL_DIR "$install_dir"
append_if_missing BH_WORKSPACE "$workspace"
append_if_missing BH_DOMAIN_SKILLS "0"
append_if_missing BH_MODE "local"
append_if_missing BH_CDP_URL ""
append_if_missing BH_TEST_RESULTS "$test_results"
append_if_missing BH_STATE_DIR "$state_dir"
append_if_missing BH_BIN_DIR "$bin_dir"
append_if_missing BH_LOG_DIR "$log_dir"
append_if_missing BH_HEADLESS_PORT "9222"
append_if_missing BH_HEADLESS_PROFILE_DIR "$headless_profile_dir"
append_if_missing BH_HEADLESS_STATE_FILE "$headless_state_file"
append_if_missing BH_HEADLESS_LOG_FILE "$headless_log_file"

printf 'env_file=%s\n' "$env_file"
printf 'workspace=%s\n' "$workspace"
printf 'test_results=%s\n' "$test_results"
printf 'state_dir=%s\n' "$state_dir"
printf 'log_dir=%s\n' "$log_dir"
printf 'headless_state_file=%s\n' "$headless_state_file"
if [[ -n "$backup_path" ]]; then
  printf 'backup=%s\n' "$backup_path"
fi
