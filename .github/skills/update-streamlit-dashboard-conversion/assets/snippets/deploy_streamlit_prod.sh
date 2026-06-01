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

(
  cd "${APP_DIR}"
  snow streamlit deploy --role "${ROLE}" --replace --prune
)
