#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APP_DIR:-}" ]]; then
  echo "Usage: APP_DIR=<path> bash run_local_dev.sh" >&2
  exit 1
fi

ENV_NAME="$(basename "${APP_DIR}")"

if [[ -x "${APP_DIR}/.venv/bin/streamlit" ]]; then
  "${APP_DIR}/.venv/bin/streamlit" run "${APP_DIR}/streamlit_app.py" --server.headless true -- --local-dev
  exit 0
fi

if [[ -f "${APP_DIR}/environment.yml" ]]; then
  if command -v mamba >/dev/null 2>&1; then MGR=mamba; else MGR=conda; fi
  $MGR run -n "${ENV_NAME}" streamlit run "${APP_DIR}/streamlit_app.py" --server.headless true -- --local-dev
  exit 0
fi

if command -v streamlit >/dev/null 2>&1; then
  streamlit run "${APP_DIR}/streamlit_app.py" --server.headless true -- --local-dev
  exit 0
fi

echo "Unable to find a runnable Streamlit environment for ${APP_DIR}." >&2
exit 1