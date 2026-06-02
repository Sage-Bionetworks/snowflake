#!/usr/bin/env bash
set -euo pipefail

APP_FILE="${APP_FILE:-${1:-}}"
UNQUALIFIED_NAMES_CSV="${UNQUALIFIED_NAMES_CSV:-${2:-}}" # e.g. processedaccess,filedownload
DEPRECATED_FQ_CSV="${DEPRECATED_FQ_CSV:-${3:-}}"          # e.g. synapse_data_warehouse.synapse.processedaccess

if [[ -z "${APP_FILE}" || -z "${UNQUALIFIED_NAMES_CSV}" || -z "${DEPRECATED_FQ_CSV}" ]]; then
    echo "Usage: APP_FILE=<path> UNQUALIFIED_NAMES_CSV=<csv> DEPRECATED_FQ_CSV=<csv> bash sql_replacement_guard.sh" >&2
    exit 1
fi

python3 - <<'PY' "${APP_FILE}" "${UNQUALIFIED_NAMES_CSV}" "${DEPRECATED_FQ_CSV}"
import re
import sys

app_file, unqualified_csv, deprecated_csv = sys.argv[1:4]
text = open(app_file, encoding='utf-8').read()

# Restrict checks to SQL payloads assigned to sql_query = r"""...""" or rf"""...""".
sql_blocks = re.findall(r'sql_query\s*=\s*r?f?"""(.*?)"""', text, flags=re.IGNORECASE | re.DOTALL)
sql_text = "\n".join(sql_blocks) if sql_blocks else text

# Strip SQL comments before structural checks to reduce false positives.
sql_wo_comments = re.sub(r'--.*$', '', sql_text, flags=re.MULTILINE)
sql_wo_comments = re.sub(r'/\*.*?\*/', '', sql_wo_comments, flags=re.DOTALL)

# Guard against accidental duplicate FROM/JOIN lines introduced by naive replacement.
dupe_from = re.findall(r'\b(FROM|JOIN)\b\s+[^\n]+\n\s*\b\1\b\s+', sql_wo_comments, flags=re.IGNORECASE)
if dupe_from:
    print('FAIL: duplicate FROM/JOIN chain detected after replacement')
    sys.exit(1)

# Ensure listed unqualified names are no longer used as base objects in FROM/JOIN.
remaining_unqualified = []
for raw in [x.strip() for x in unqualified_csv.split(',') if x.strip()]:
    pat = re.compile(rf'\b(?:FROM|JOIN)\s+{re.escape(raw)}\b', re.IGNORECASE)
    if pat.search(sql_wo_comments):
        remaining_unqualified.append(raw)
if remaining_unqualified:
    print('FAIL: unqualified references remain: ' + ','.join(sorted(set(remaining_unqualified))))
    sys.exit(1)

# Ensure deprecated fully-qualified identifiers are gone.
remaining_deprecated = []
for raw in [x.strip() for x in deprecated_csv.split(',') if x.strip()]:
    if re.search(re.escape(raw), sql_wo_comments, flags=re.IGNORECASE):
        remaining_deprecated.append(raw)
if remaining_deprecated:
    print('FAIL: deprecated fully-qualified identifiers remain: ' + ','.join(sorted(set(remaining_deprecated))))
    sys.exit(1)

print('PASS: sql replacement guard')
PY