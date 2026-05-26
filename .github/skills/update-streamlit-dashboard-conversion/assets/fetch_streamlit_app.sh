#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Fetch a Streamlit app's staged source files from Snowflake into this repository.

Usage:
  bash .claude/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh \
    --database <database> \
    --schema <schema> \
    --name <streamlit_name> \
    [--version <live|last|default|VERSION$N>] \
    [--connection <connection_name>] \
    [--target-root <relative_or_absolute_path>]

Examples:
  bash .claude/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh \
    --database SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_451_STREAMLIT_CONVERSION_SKILL \
    --schema SYNAPSE \
    --name OWTYLBMJ_4CXKQGK

  bash .claude/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh \
    --database SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_451_STREAMLIT_CONVERSION_SKILL \
    --schema SYNAPSE \
    --name OWTYLBMJ_4CXKQGK \
    --version VERSION\$1 \
    --connection default

Notes:
  - Requires Snowflake CLI (`snow`) authenticated and available on PATH.
  - Files are mirrored to: <target-root>/<schema_lower>/streamlit/<title_identifier>/
  - title_identifier is derived from app title: lowercase, punctuation removed, spaces collapsed to underscores.
  - Default target-root is "sage".
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${script_dir}" rev-parse --show-toplevel 2>/dev/null || (cd "${script_dir}/../../../.." && pwd))"

database=""
schema=""
streamlit_name=""
version="live"
connection_name=""
target_root="sage"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --database)
      database="$2"
      shift 2
      ;;
    --schema)
      schema="$2"
      shift 2
      ;;
    --name)
      streamlit_name="$2"
      shift 2
      ;;
    --version)
      version="$2"
      shift 2
      ;;
    --connection)
      connection_name="$2"
      shift 2
      ;;
    --target-root)
      target_root="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${database}" || -z "${schema}" || -z "${streamlit_name}" ]]; then
  echo "--database, --schema, and --name are required." >&2
  usage
  exit 1
fi

if [[ "${target_root}" = /* ]]; then
  target_base="${target_root}"
else
  target_base="${repo_root}/${target_root}"
fi

schema_dir="$(printf '%s' "${schema}" | tr '[:upper:]' '[:lower:]')"

describe_cmd=(snow streamlit describe "${streamlit_name}" --database "${database}" --schema "${schema}" --format JSON)
if [[ -n "${connection_name}" ]]; then
  describe_cmd+=(--connection "${connection_name}")
fi

describe_json="$(${describe_cmd[@]})"

app_dir="$(printf '%s' "${describe_json}" | python3 -c '
import json
import re
import sys

doc = json.load(sys.stdin)
if not doc:
  raise SystemExit("No streamlit description returned.")

item = doc[0]
title = item.get("title")
fallback_name = item.get("name") or "streamlit_app"

base = title.strip() if isinstance(title, str) and title.strip() else fallback_name
normalized = base.lower()
normalized = re.sub(r"[^a-z0-9\s_]", "", normalized)
normalized = re.sub(r"[\s_]+", "_", normalized).strip("_")

if not normalized:
  normalized = "streamlit_app"

print(normalized)
')"

local_dir="${target_base}/${schema_dir}/streamlit/${app_dir}"
mkdir -p "${local_dir}"

streamlit_uri="$(printf '%s' "${describe_json}" | python3 -c '
import json
import re
import sys

version = sys.argv[1]
doc = json.load(sys.stdin)
if not doc:
    raise SystemExit("No streamlit description returned.")
item = doc[0]

if version == "live":
    uri = item.get("live_version_location_uri")
elif version == "last":
    uri = item.get("last_version_location_uri")
elif version == "default":
    uri = item.get("default_version_location_uri")
else:
    base = item.get("default_version_location_uri") or item.get("live_version_location_uri")
    if not base:
        raise SystemExit("Unable to determine streamlit version URI from description output.")
    uri = re.sub(r"/versions/[^/]+/$", f"/versions/{version}/", base)

if not uri:
    raise SystemExit(f"Unable to determine URI for version={version!r}.")

print(uri)
' "${version}")"

copy_cmd=(snow stage copy "${streamlit_uri}" "${local_dir}/" --recursive --overwrite)
if [[ -n "${connection_name}" ]]; then
  copy_cmd+=(--connection "${connection_name}")
fi

"${copy_cmd[@]}"

echo "Fetched ${streamlit_name} (${version}) from ${database}.${schema}."
echo "Mirrored files into: ${local_dir}"