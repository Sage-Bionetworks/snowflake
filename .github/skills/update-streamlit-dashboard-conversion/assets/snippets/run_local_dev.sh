#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APP_DIR:-}" ]]; then
  echo "Usage: APP_DIR=<path> bash run_local_dev.sh" >&2
  exit 1
fi

ENV_NAME="$(basename "${APP_DIR}")"

mamba run -n "${ENV_NAME}" streamlit run "${APP_DIR}/streamlit_app.py" --server.headless true -- --local-dev