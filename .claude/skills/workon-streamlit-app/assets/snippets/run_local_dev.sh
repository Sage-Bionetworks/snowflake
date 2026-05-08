#!/usr/bin/env bash
set -euo pipefail

APP_DIR="<APP_DIR>"
ENV_NAME="$(basename "${APP_DIR}")"

mamba run -n "${ENV_NAME}" streamlit run "${APP_DIR}/streamlit_app.py" --server.headless true -- --local-dev