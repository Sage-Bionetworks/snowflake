#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="<LOG_FILE>"
REPO_ROOT="$(git rev-parse --show-toplevel)"

cat "${LOG_FILE}" | bash "${REPO_ROOT}/.github/skills/update-streamlit-dashboard-conversion/assets/scan_streamlit_logs.sh" --fail-on-warning -