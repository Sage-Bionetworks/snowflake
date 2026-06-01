#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APP_DIR:-}" ]]; then
  echo "Usage: APP_DIR=<path> bash bootstrap_local_env.sh" >&2
  exit 1
fi

if [[ ! -d "${APP_DIR}" ]]; then
  echo "APP_DIR does not exist: ${APP_DIR}" >&2
  exit 1
fi

ENV_NAME="$(basename "${APP_DIR}")"

if [[ -f "${APP_DIR}/environment.yml" ]]; then
  if command -v mamba >/dev/null 2>&1; then MGR=mamba; else MGR=conda; fi

  if $MGR env list | grep -q "^${ENV_NAME} "; then
    $MGR env update -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml" --prune
  else
    $MGR env create -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml"
  fi
  exit 0
fi

if [[ ! -f "${APP_DIR}/pyproject.toml" && ! -f "${APP_DIR}/requirements.txt" ]]; then
  echo "No supported dependency manifest found in ${APP_DIR}. Expected one of: environment.yml, pyproject.toml, requirements.txt" >&2
  exit 1
fi

if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3.11)"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
else
  echo "python3 is required to build a virtual environment." >&2
  exit 1
fi

VENV_DIR="${APP_DIR}/.venv"

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi

source "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip wheel

if [[ -f "${APP_DIR}/requirements.txt" ]]; then
  python -m pip install -r "${APP_DIR}/requirements.txt"
fi

if [[ -f "${APP_DIR}/pyproject.toml" ]]; then
  mapfile -t PYPROJECT_DEPS < <(
    python - <<'PY' "${APP_DIR}/pyproject.toml"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
content = path.read_text(encoding="utf-8")

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib

doc = tomllib.loads(content)
deps = doc.get("project", {}).get("dependencies", [])
for dep in deps:
    print(dep)
PY
  )

  if [[ ${#PYPROJECT_DEPS[@]} -gt 0 ]]; then
    python -m pip install "${PYPROJECT_DEPS[@]}"
  fi
fi

# Keep parity with Snowflake defaults expected by local-dev session wiring.
python -m pip install snowflake-snowpark-python

