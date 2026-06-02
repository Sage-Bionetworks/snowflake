#!/usr/bin/env bash
# Format a single Streamlit app file using black.
# Installs black into the app's conda/mamba env if not already present.
#
# Required:
#   APP_FILE — path to the streamlit_app.py file to format
set -euo pipefail

if [[ -z "${APP_FILE:-}" ]]; then
  echo "Usage: APP_FILE=<path/to/streamlit_app.py> bash format_app.sh" >&2
  exit 1
fi

if [[ ! -f "${APP_FILE}" ]]; then
  echo "APP_FILE does not exist: ${APP_FILE}" >&2
  exit 1
fi

APP_DIR="$(dirname "${APP_FILE}")"
ENV_NAME="$(basename "${APP_DIR}")"

# Try the app's conda/mamba env first
if command -v mamba >/dev/null 2>&1; then MGR=mamba; elif command -v conda >/dev/null 2>&1; then MGR=conda; else MGR=""; fi

if [[ -n "${MGR}" ]] && ${MGR} env list 2>/dev/null | grep -q "^${ENV_NAME} "; then
  if ! ${MGR} run -n "${ENV_NAME}" black --version >/dev/null 2>&1; then
    ${MGR} run -n "${ENV_NAME}" pip install --quiet black
  fi
  ${MGR} run -n "${ENV_NAME}" black "${APP_FILE}"
  exit 0
fi

# Fall back to the app's local .venv
if [[ -x "${APP_DIR}/.venv/bin/black" ]]; then
  "${APP_DIR}/.venv/bin/black" "${APP_FILE}"
  exit 0
fi

if [[ -d "${APP_DIR}/.venv" ]]; then
  "${APP_DIR}/.venv/bin/pip" install --quiet black
  "${APP_DIR}/.venv/bin/black" "${APP_FILE}"
  exit 0
fi

# Fall back to whatever black is on PATH
if command -v black >/dev/null 2>&1; then
  black "${APP_FILE}"
  exit 0
fi

# Last resort: install into a temporary venv and run
echo "black not found; installing into a temporary environment..." >&2
TMP_VENV="$(mktemp -d)/venv"
python3 -m venv "${TMP_VENV}"
"${TMP_VENV}/bin/pip" install --quiet black
"${TMP_VENV}/bin/black" "${APP_FILE}"
