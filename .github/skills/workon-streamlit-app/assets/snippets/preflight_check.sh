#!/usr/bin/env bash
set -euo pipefail

DATABASE="${1:-<DATABASE>}"
SCHEMA="${2:-<SCHEMA>}"

if [[ "${DATABASE}" == "<DATABASE>" || "${SCHEMA}" == "<SCHEMA>" ]]; then
      echo "Usage: bash .github/skills/workon-streamlit-app/assets/snippets/preflight_check.sh <DATABASE> <SCHEMA>" >&2
      exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
TMP_DIR="${TMP_DIR:-${REPO_ROOT}/.github/tmp}"
mkdir -p "${TMP_DIR}"

command -v snow >/dev/null
command -v python3 >/dev/null
if command -v mamba >/dev/null 2>&1; then :; elif command -v conda >/dev/null 2>&1; then :; else
   echo "Missing mamba/conda" >&2
   exit 1
fi

if command -v rg >/dev/null 2>&1; then
   SEARCH_TOOL="rg"
else
   SEARCH_TOOL="grep"
   echo "rg missing; using grep fallback" >&2
fi

# Fail fast on authentication/access issues and keep machine-readable evidence.
snow streamlit list --database "${DATABASE}" --schema "${SCHEMA}" --format JSON > "${TMP_DIR}/preflight_streamlit_list.json"

# Robust settings check (supports JSON-with-comments by stripping comments first).
USER_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
WORKSPACE_SETTINGS="${REPO_ROOT}/.vscode/settings.json"

python3 - <<'PY' "${USER_SETTINGS}" "${WORKSPACE_SETTINGS}" > "${TMP_DIR}/preflight_browser_setting.json"
import json
import pathlib
import re
import sys

user_path = pathlib.Path(sys.argv[1])
workspace_path = pathlib.Path(sys.argv[2])

def load_jsonc(path: pathlib.Path):
      if not path.exists():
            return None
      text = path.read_text(encoding="utf-8")
      text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
      text = re.sub(r"(^|\s)//.*?$", "", text, flags=re.M)
      text = re.sub(r",\s*([}\]])", r"\1", text)
      return json.loads(text)

result = {
      "setting": "workbench.browser.enableChatTools",
      "workspace": None,
      "user": None,
      "effective": None,
}

ws = load_jsonc(workspace_path)
us = load_jsonc(user_path)
if isinstance(ws, dict):
      result["workspace"] = ws.get("workbench.browser.enableChatTools")
if isinstance(us, dict):
      result["user"] = us.get("workbench.browser.enableChatTools")

result["effective"] = result["workspace"] if result["workspace"] is not None else result["user"]
print(json.dumps(result))
if result["effective"] is not True:
      raise SystemExit(2)
PY

echo "Preflight complete. Artifacts written to ${TMP_DIR}" >&2
