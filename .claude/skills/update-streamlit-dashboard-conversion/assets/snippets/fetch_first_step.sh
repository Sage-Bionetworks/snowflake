#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

if [[ -z "${DATABASE:-}" || -z "${SCHEMA:-}" || -z "${OBJECT_NAME:-}" ]]; then
  echo "Usage: DATABASE=<db> SCHEMA=<schema> OBJECT_NAME=<name> bash fetch_first_step.sh" >&2
  exit 1
fi

source "${REPO_ROOT}/venv/snowflake/bin/activate"
bash "${REPO_ROOT}/.claude/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh" --database "${DATABASE}" --schema "${SCHEMA}" --name "${OBJECT_NAME}"
