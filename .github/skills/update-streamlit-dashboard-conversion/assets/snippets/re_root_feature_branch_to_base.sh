#!/usr/bin/env bash
set -euo pipefail

FEATURE_BRANCH="${FEATURE_BRANCH:-${1:-}}"
BASE_BRANCH="${BASE_BRANCH:-${2:-dev}}"
COMMIT_SHA="${COMMIT_SHA:-${3:-HEAD}}"
REMOTE="${REMOTE:-origin}"

if [[ -z "${FEATURE_BRANCH}" ]]; then
  echo "Usage: FEATURE_BRANCH=<branch> [BASE_BRANCH=<base>] [COMMIT_SHA=<sha>] bash re_root_feature_branch_to_base.sh" >&2
  exit 1
fi

if ! git rev-parse --verify "${COMMIT_SHA}^{commit}" >/dev/null 2>&1; then
  echo "Commit not found: ${COMMIT_SHA}" >&2
  exit 1
fi

# Re-rooting rewrites branch pointers; require a clean tree for safety.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes before re-rooting." >&2
  exit 1
fi

start_ref="$(git symbolic-ref --quiet --short HEAD || git rev-parse --short HEAD)"
git fetch "${REMOTE}" "${BASE_BRANCH}" >/dev/null

tmp_branch="__tmp_re_root_${FEATURE_BRANCH//\//_}_$$"
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

git switch -C "${tmp_branch}" "${REMOTE}/${BASE_BRANCH}" >/dev/null
tmp_branch_created=1
git cherry-pick "${COMMIT_SHA}" >/dev/null

new_sha="$(git rev-parse HEAD)"

git branch -f "${FEATURE_BRANCH}" "${new_sha}" >/dev/null
git switch "${FEATURE_BRANCH}" >/dev/null
switched_feature_branch=1
git branch -D "${tmp_branch}" >/dev/null
tmp_branch_created=0

completed=1
trap - EXIT

echo "re_rooted_branch=${FEATURE_BRANCH}"
echo "base_branch=${BASE_BRANCH}"
echo "head_sha=${new_sha}"
echo "next_push=git push --force-with-lease -u ${REMOTE} ${FEATURE_BRANCH}"