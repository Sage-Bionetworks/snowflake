#!/usr/bin/env bash
set -euo pipefail

# Required:
#   DATABASE, SCHEMA, OBJECT_NAME, ROLE
# Optional:
#   TARGET_ROOT (default: sage)
#   STREAMLIT_MAJOR (default: 1)

if [[ -z "${DATABASE:-}" || -z "${SCHEMA:-}" || -z "${OBJECT_NAME:-}" || -z "${ROLE:-}" ]]; then
  echo "Usage: DATABASE=<db> SCHEMA=<schema> OBJECT_NAME=<name> ROLE=<role> [TARGET_ROOT=sage] [STREAMLIT_MAJOR=1] bash ensure_warehouse_runtime_and_artifacts.sh" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
TARGET_ROOT="${TARGET_ROOT:-sage}"
STREAMLIT_MAJOR="${STREAMLIT_MAJOR:-1}"

source "${REPO_ROOT}/venv/snowflake/bin/activate"

describe_json="$(snow streamlit describe "${OBJECT_NAME}" --database "${DATABASE}" --schema "${SCHEMA}" --role "${ROLE}" --format JSON)"

meta_tsv="$(python3 - "${describe_json}" <<'PY'
import json
import re
import sys

doc = json.loads(sys.argv[1])
if not doc:
    raise SystemExit("No streamlit description returned")
item = doc[0]
name = item.get("name", "")
title = item.get("title") or name or "streamlit_app"
runtime = item.get("runtime_name") or ""
slug = title.strip().lower()
slug = re.sub(r"[^a-z0-9\s_]", "", slug)
slug = re.sub(r"[\s_]+", "_", slug).strip("_")
if not slug:
    slug = "streamlit_app"
print(f"{slug}\t{title}\t{runtime}")
PY
)"

slug="$(printf '%s' "${meta_tsv}" | awk -F '\t' '{print $1}')"
title="$(printf '%s' "${meta_tsv}" | awk -F '\t' '{print $2}')"
runtime_name="$(printf '%s' "${meta_tsv}" | awk -F '\t' '{print $3}')"
schema_lower="$(printf '%s' "${SCHEMA}" | tr '[:upper:]' '[:lower:]')"
app_dir="${REPO_ROOT}/${TARGET_ROOT}/${schema_lower}/streamlit/${slug}"

if [[ "${runtime_name}" != "SYSTEM\$WAREHOUSE_RUNTIME" ]]; then
  snow sql -q "ALTER STREAMLIT ${DATABASE}.${SCHEMA}.${OBJECT_NAME} SET RUNTIME_NAME = 'SYSTEM\$WAREHOUSE_RUNTIME';" --role "${ROLE}"
fi

verified_runtime="$(python3 - "$(snow streamlit describe "${OBJECT_NAME}" --database "${DATABASE}" --schema "${SCHEMA}" --role "${ROLE}" --format JSON)" <<'PY'
import json
import sys

doc = json.loads(sys.argv[1])
if not doc:
    raise SystemExit("No streamlit description returned")
print(doc[0].get("runtime_name") or "")
PY
)"

if [[ "${verified_runtime}" != "SYSTEM\$WAREHOUSE_RUNTIME" ]]; then
  echo "Runtime verification failed: expected SYSTEM\$WAREHOUSE_RUNTIME, got '${verified_runtime}'" >&2
  exit 1
fi

mkdir -p "${app_dir}" "${app_dir}/.streamlit"

extra_requirements="$(python3 - "${app_dir}" <<'PY'
import pathlib
import re
import sys

app_dir = pathlib.Path(sys.argv[1])
items = []

req = app_dir / "requirements.txt"
if req.exists():
    for raw in req.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        items.append(line)

pyproject = app_dir / "pyproject.toml"
if pyproject.exists():
    try:
        import tomllib
    except ModuleNotFoundError:
        tomllib = None
    if tomllib is not None:
        data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
        for dep in data.get("project", {}).get("dependencies", []):
            if isinstance(dep, str):
                items.append(dep.strip())

filtered = []
seen = set()
for dep in items:
    normalized = dep.strip()
    if not normalized:
        continue
    lowered = normalized.lower()
    lowered = lowered.replace("[snowflake]", "")
    lowered = re.sub(r"\s+", "", lowered)
    if lowered.startswith("streamlit"):
        continue
    if lowered.startswith("snowflake-snowpark-python"):
        continue
    if lowered.startswith("python"):
        continue
    key = lowered
    if key in seen:
        continue
    seen.add(key)
    filtered.append(normalized)

for dep in filtered:
    print(dep)
PY
)"

{
  echo "name: ${slug}"
  echo "channels:"
  echo "  - snowflake"
  echo "dependencies:"
  echo "  - python=3.11.*"
  echo "  - snowflake-snowpark-python"
  echo "  - streamlit=${STREAMLIT_MAJOR}.*"
  if [[ -n "${extra_requirements}" ]]; then
    while IFS= read -r dep; do
      [[ -z "${dep}" ]] && continue
      echo "  - ${dep}"
    done <<< "${extra_requirements}"
  fi
} > "${app_dir}/environment.yml"

config_file="${app_dir}/.streamlit/config.toml"
if [[ -f "${config_file}" ]]; then
  if ! grep -q "^\[snowflake.sleep\]" "${config_file}"; then
    printf '\n[snowflake.sleep]\nstreamlitSleepTimeoutMinutes = 5\n' >> "${config_file}"
  elif ! grep -q "^streamlitSleepTimeoutMinutes\s*=\s*5\s*$" "${config_file}"; then
    awk '
      BEGIN{in_block=0; set=0}
      /^\[snowflake.sleep\]/{in_block=1; print; next}
      /^\[/{
        if (in_block && !set) { print "streamlitSleepTimeoutMinutes = 5"; set=1 }
        in_block=0
      }
      {
        if (in_block && $0 ~ /^streamlitSleepTimeoutMinutes\s*=/) {
          print "streamlitSleepTimeoutMinutes = 5"; set=1; next
        }
        print
      }
      END{ if (in_block && !set) print "streamlitSleepTimeoutMinutes = 5" }
    ' "${config_file}" > "${config_file}.tmp"
    mv "${config_file}.tmp" "${config_file}"
  fi
else
  cat > "${config_file}" <<'EOF'
[snowflake.sleep]
streamlitSleepTimeoutMinutes = 5
EOF
fi

cat > "${app_dir}/snowflake.yml" <<EOF
definition_version: 2
entities:
  streamlit_app:
    type: streamlit
    identifier:
      name: ${slug}
      database: ${DATABASE}
      schema: ${SCHEMA}
    query_warehouse: STREAMLIT_XSMALL
    main_file: streamlit_app.py
    title: "${title}"
    artifacts:
      - environment.yml
      - streamlit_app.py
      - .streamlit/config.toml
EOF

rm -f "${app_dir}/pyproject.toml" "${app_dir}/requirements.txt" "${app_dir}/.folder"

printf 'slug=%s\n' "${slug}"
printf 'title=%s\n' "${title}"
printf 'app_dir=%s\n' "${app_dir}"
printf 'runtime_name=%s\n' "${verified_runtime}"
