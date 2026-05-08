#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APP_FILE:-}" ]]; then
  echo "Usage: APP_FILE=<path> bash post_edit_static_guard.sh" >&2
  exit 1
fi

if rg -n 'use_container_width=|st\.connection\("snowflake"\)\.session\(' "${APP_FILE}"; then
  echo "FAIL: deprecated Streamlit/session patterns remain" >&2
  exit 1
fi

python3 -m py_compile "${APP_FILE}"
echo "PASS: static post-edit guard"