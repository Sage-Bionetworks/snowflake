#!/usr/bin/env bash
set -euo pipefail

# TABLE_NAMES: comma-separated uppercase table names to look up
# e.g. TABLE_NAMES=FILE_LATEST,OBJECTDOWNLOAD_EVENT
if [[ -z "${TABLE_NAMES:-}" ]]; then
  echo "Usage: TABLE_NAMES=<NAME1,NAME2,...> bash lookup_unqualified_tables.sh" >&2
  exit 1
fi

IN_LIST=$(echo "${TABLE_NAMES}" | tr ',' '\n' | sed "s/^[[:space:]]*/'/;s/[[:space:]]*$/'/" | paste -sd ',')

snow sql -q "SELECT table_schema, table_name, table_type
FROM SYNAPSE_DATA_WAREHOUSE.information_schema.tables
WHERE table_name IN (${IN_LIST})
ORDER BY table_schema, table_name" --format JSON
