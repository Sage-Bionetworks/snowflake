#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${LOG_FILE:-}" ]]; then
  echo "Usage: LOG_FILE=<path> bash smoke_scan_logs_fail_on_warning.sh" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

cat "${LOG_FILE}" | bash "${REPO_ROOT}/.claude/skills/update-streamlit-dashboard-conversion/assets/scan_streamlit_logs.sh" --fail-on-warning -