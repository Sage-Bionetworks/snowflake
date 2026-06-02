#!/usr/bin/env bash
set -euo pipefail

# Required:
#   APP_DIR, ROLE

if [[ -z "${APP_DIR:-}" || -z "${ROLE:-}" ]]; then
  echo "Usage: APP_DIR=<sage/<schema>/streamlit/<slug>> ROLE=<sage_<schema>_admin> bash deploy_streamlit_prod.sh" >&2
  exit 1
fi

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Missing app directory: ${APP_DIR}" >&2
  exit 1
fi

# Ensure snow CLI is available in local dev shells.
if ! command -v snow >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [[ -f "${REPO_ROOT}/venv/snowflake/bin/activate" ]]; then
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/venv/snowflake/bin/activate"
  fi
fi

if ! command -v snow >/dev/null 2>&1; then
  echo "snow CLI not found. Activate venv/snowflake/bin/activate or install Snowflake CLI." >&2
  exit 1
fi

(
  cd "${APP_DIR}"
  snow streamlit deploy --role "${ROLE}" --replace --prune
)
