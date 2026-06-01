#!/usr/bin/env bash
set -euo pipefail

# DATABASE and SCHEMA must be set in the calling context before sourcing this snippet.
cmd=(
  snow streamlit list
  --database "${DATABASE}"
  --schema "${SCHEMA}"
  --format JSON
)

if [[ -n "${ROLE:-}" ]]; then
  cmd+=(--role "${ROLE}")
fi

"${cmd[@]}"
