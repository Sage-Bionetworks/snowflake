#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
TMP_DIR="${TMP_DIR:-${REPO_ROOT}/.github/tmp}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/preflight.json" <<'JSON'
{"status":"pending"}
JSON
cat > "${TMP_DIR}/sql_edits.json" <<'JSON'
{"status":"pending"}
JSON
cat > "${TMP_DIR}/browser_validation.json" <<'JSON'
{"status":"pending"}
JSON
cat > "${TMP_DIR}/cleanup.json" <<'JSON'
{"status":"pending"}
JSON

echo "Initialized validation artifacts in ${TMP_DIR}"