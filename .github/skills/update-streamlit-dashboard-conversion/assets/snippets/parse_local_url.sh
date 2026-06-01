#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${LOG_FILE:-}" ]]; then
  echo "Usage: LOG_FILE=<path> bash parse_local_url.sh" >&2
  exit 1
fi

if [[ ! -f "${LOG_FILE}" ]]; then
  echo "Log file not found: ${LOG_FILE}" >&2
  exit 1
fi

app_url="$(awk '/Local URL:/{print $NF; exit}' "${LOG_FILE}")"
if [[ -z "${app_url}" || ! "${app_url}" =~ ^http://localhost:[0-9]+/?$ ]]; then
  echo "Failed to parse valid Local URL from ${LOG_FILE}" >&2
  exit 1
fi

printf '%s\n' "${app_url%/}"
