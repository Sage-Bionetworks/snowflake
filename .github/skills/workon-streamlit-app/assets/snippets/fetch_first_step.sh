set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
DATABASE="<DATABASE>"
SCHEMA="<SCHEMA>"
OBJECT_NAME="<OBJECT_NAME>"

source "${REPO_ROOT}/venv/snowflake/bin/activate"
bash "${REPO_ROOT}/.github/skills/workon-streamlit-app/assets/fetch_streamlit_app.sh" --database "${DATABASE}" --schema "${SCHEMA}" --name "${OBJECT_NAME}"
