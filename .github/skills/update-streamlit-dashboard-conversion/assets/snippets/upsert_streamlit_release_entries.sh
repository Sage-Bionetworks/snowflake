#!/usr/bin/env bash
set -euo pipefail

# Required:
#   APP_TITLE, SCHEMA_LOWER, SLUG, OBJECT_NAME
# Optional:
#   REPO_ROOT (auto-detected)

if [[ -z "${APP_TITLE:-}" || -z "${SCHEMA_LOWER:-}" || -z "${SLUG:-}" || -z "${OBJECT_NAME:-}" ]]; then
  echo "Usage: APP_TITLE=<title> SCHEMA_LOWER=<schema_lower> SLUG=<slug> OBJECT_NAME=<snowflake_object_name> bash upsert_streamlit_release_entries.sh" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
GRANTS_FILE="${REPO_ROOT}/admin/grants.sql"
CI_FILE="${REPO_ROOT}/.github/workflows/ci.yaml"

if [[ ! -f "${GRANTS_FILE}" ]]; then
  echo "Missing file: ${GRANTS_FILE}" >&2
  exit 1
fi

if [[ ! -f "${CI_FILE}" ]]; then
  echo "Missing file: ${CI_FILE}" >&2
  exit 1
fi

SCHEMA_UPPER="$(printf '%s' "${SCHEMA_LOWER}" | tr '[:lower:]' '[:upper:]')"
OBJECT_UPPER="$(printf '%s' "${OBJECT_NAME}" | tr '[:lower:]' '[:upper:]')"
ANALYST_ROLE_UPPER="SAGE_${SCHEMA_UPPER}_ANALYST"
ADMIN_ROLE_LOWER="sage_${SCHEMA_LOWER}_admin"
APP_PATH="sage/${SCHEMA_LOWER}/streamlit/${SLUG}"

python3 - <<'PY' "${GRANTS_FILE}" "${CI_FILE}" "${APP_TITLE}" "${SCHEMA_UPPER}" "${OBJECT_UPPER}" "${ANALYST_ROLE_UPPER}" "${APP_PATH}" "${ADMIN_ROLE_LOWER}"
import re
import sys
from pathlib import Path

grants_file, ci_file, app_title, schema_upper, object_upper, analyst_role_upper, app_path, admin_role_lower = sys.argv[1:9]

# 1) Upsert grants.sql entry
p = Path(grants_file)
text = p.read_text(encoding="utf-8")
grant_stmt = f"GRANT USAGE ON STREAMLIT SAGE.{schema_upper}.{object_upper}"
role_stmt = f"\tTO ROLE {analyst_role_upper};"
block = f"{grant_stmt}\n{role_stmt}\n"

if grant_stmt not in text:
    anchor = "-- Streamlit app grants"
    if anchor in text:
        idx = text.index(anchor)
        after = text.index("\n", idx) + 1
        text = text[:after] + block + text[after:]
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += "\n-- Streamlit app grants\n" + block
    p.write_text(text, encoding="utf-8")

# 2) Upsert CI matrix entry under deploy_streamlit
p = Path(ci_file)
text = p.read_text(encoding="utf-8")
if app_path in text:
    sys.exit(0)

start = text.find("\n  deploy_streamlit:\n")
if start == -1:
    raise SystemExit("Could not locate deploy_streamlit job in ci.yaml")

steps_idx = text.find("\n    steps:\n", start)
if steps_idx == -1:
    raise SystemExit("Could not locate deploy_streamlit steps block in ci.yaml")

entry = (
    f"          - name: {app_title}\n"
    f"            path: {app_path}\n"
    f"            role: {admin_role_lower}\n"
)

text = text[:steps_idx] + entry + text[steps_idx:]
p.write_text(text, encoding="utf-8")
PY

echo "Updated ${GRANTS_FILE} and ${CI_FILE}"
