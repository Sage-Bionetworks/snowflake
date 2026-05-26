#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APP_DIR:-}" ]]; then
  echo "Usage: APP_DIR=<path> bash bootstrap_local_env.sh" >&2
  exit 1
fi

ENV_NAME="$(basename "${APP_DIR}")"

if command -v mamba >/dev/null 2>&1; then MGR=mamba; else MGR=conda; fi

if $MGR env list | grep -q "^${ENV_NAME} "; then
  $MGR env update -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml" --prune
else
  $MGR env create -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml"
fi
