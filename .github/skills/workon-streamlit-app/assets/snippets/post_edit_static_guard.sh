#!/usr/bin/env bash
set -euo pipefail

APP_FILE="<APP_FILE>"

if rg -n 'use_container_width=|st\.connection\("snowflake"\)\.session\(' "${APP_FILE}"; then
  echo "FAIL: deprecated Streamlit/session patterns remain" >&2
  exit 1
fi

python3 -m py_compile "${APP_FILE}"
echo "PASS: static post-edit guard"