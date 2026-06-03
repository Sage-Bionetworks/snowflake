#!/usr/bin/env bash
set -euo pipefail

# Required:
#   APP_TITLE, SCHEMA_LOWER, SLUG, OBJECT_NAME, JIRA_KEY
# Optional:
#   BASE_BRANCH (default: dev)
#   REMOTE (default: origin)
#   FEATURE_BRANCH (default: <jira_key_lower>-<slug>)
#   REPO_ROOT (default: git top-level)

if [[ -z "${APP_TITLE:-}" || -z "${SCHEMA_LOWER:-}" || -z "${SLUG:-}" || -z "${OBJECT_NAME:-}" || -z "${JIRA_KEY:-}" ]]; then
  echo "Usage: APP_TITLE=<title> SCHEMA_LOWER=<schema_lower> SLUG=<slug> OBJECT_NAME=<object_name> JIRA_KEY=<SNOW-123> [BASE_BRANCH=dev] [FEATURE_BRANCH=<branch>] bash prepare_app_feature_branch_commit.sh" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
BASE_BRANCH="${BASE_BRANCH:-dev}"
REMOTE="${REMOTE:-origin}"
JIRA_KEY_LOWER="$(printf '%s' "${JIRA_KEY}" | tr '[:upper:]' '[:lower:]')"
FEATURE_BRANCH="${FEATURE_BRANCH:-${JIRA_KEY_LOWER}-${SLUG}}"

APP_DIR="sage/${SCHEMA_LOWER}/streamlit/${SLUG}"
APP_FILE="${APP_DIR}/streamlit_app.py"

REQUIRED_FILES=(
  "admin/grants.sql"
  ".github/workflows/ci.yaml"
  "${APP_DIR}/streamlit_app.py"
  "${APP_DIR}/snowflake.yml"
  "${APP_DIR}/environment.yml"
  "${APP_DIR}/.streamlit/config.toml"
)

cd "${REPO_ROOT}"

if ! git diff --cached --quiet; then
  echo "Staged changes detected. Please unstage them before running this helper." >&2
  exit 1
fi

start_ref="$(git symbolic-ref --quiet --short HEAD || git rev-parse --short HEAD)"
tmp_branch="__tmp_streamlit_app_commit_${SLUG}_$$"
tmp_branch_created=0
switched_feature_branch=0
completed=0

cleanup_on_error() {
  local exit_code=$?
  if [[ ${completed} -eq 1 ]]; then
    return
  fi

  if [[ ${switched_feature_branch} -eq 1 ]]; then
    git switch "${start_ref}" >/dev/null 2>&1 || true
  fi

  if [[ ${tmp_branch_created} -eq 1 ]]; then
    git branch -D "${tmp_branch}" >/dev/null 2>&1 || true
  fi

  exit "${exit_code}"
}

trap cleanup_on_error EXIT

git switch -c "${tmp_branch}" >/dev/null
tmp_branch_created=1

APP_TITLE="${APP_TITLE}" \
SCHEMA_LOWER="${SCHEMA_LOWER}" \
SLUG="${SLUG}" \
OBJECT_NAME="${OBJECT_NAME}" \
bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/upsert_streamlit_release_entries.sh

APP_FILE="${APP_FILE}" \
bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/format_app.sh

git add "${REQUIRED_FILES[@]}"

expected_sorted="$(printf '%s\n' "${REQUIRED_FILES[@]}" | sort)"
staged_sorted="$(git diff --cached --name-only | sort)"

if [[ "${expected_sorted}" != "${staged_sorted}" ]]; then
  echo "Staged files do not match required commit scope." >&2
  echo "Expected:" >&2
  printf '%s\n' "${REQUIRED_FILES[@]}" >&2
  echo "Actual:" >&2
  git diff --cached --name-only >&2
  exit 1
fi

git commit -m "Transition ${APP_TITLE} from dashboard to Streamlit" >/dev/null
app_commit_sha="$(git rev-parse HEAD)"

git fetch "${REMOTE}" "${BASE_BRANCH}" >/dev/null
git switch -C "${FEATURE_BRANCH}" "${REMOTE}/${BASE_BRANCH}" >/dev/null
switched_feature_branch=1
git cherry-pick "${app_commit_sha}" >/dev/null
git branch -D "${tmp_branch}" >/dev/null
tmp_branch_created=0

if git ls-remote --exit-code --heads "${REMOTE}" "${FEATURE_BRANCH}" >/dev/null 2>&1; then
  next_push_cmd="git push --force-with-lease -u ${REMOTE} ${FEATURE_BRANCH}"
else
  next_push_cmd="git push -u ${REMOTE} ${FEATURE_BRANCH}"
fi

completed=1
trap - EXIT

echo "feature_branch=${FEATURE_BRANCH}"
echo "base_branch=${BASE_BRANCH}"
echo "head_sha=$(git rev-parse HEAD)"
echo "next_push=${next_push_cmd}"
