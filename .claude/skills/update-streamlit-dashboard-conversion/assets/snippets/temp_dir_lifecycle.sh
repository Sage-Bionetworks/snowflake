#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
TMP_DIR="${REPO_ROOT}/.claude/tmp"
mkdir -p "${TMP_DIR}"

# ...run workflow, writing temp artifacts under ${TMP_DIR}...

rm -rf "${TMP_DIR}"
if [[ -e "${TMP_DIR}" ]]; then
  echo "FAIL: cleanup failed; ${TMP_DIR} still exists" >&2
  find "${TMP_DIR}" -maxdepth 3 -print 2>/dev/null || true
  exit 1
fi

echo "PASS: cleaned ${TMP_DIR}"