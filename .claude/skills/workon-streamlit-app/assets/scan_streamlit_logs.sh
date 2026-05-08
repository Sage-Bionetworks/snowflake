#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Scan Streamlit runtime logs for error and warning patterns.

Usage:
  bash .github/skills/workon-streamlit-app/assets/scan_streamlit_logs.sh [options] [LOG_FILE]

If LOG_FILE is omitted or '-', input is read from stdin.

Options:
  --fail-on-warning     Exit non-zero when warning patterns are found.
  -h, --help            Show this help text.

Exit codes:
  0  No error patterns found (and no warning patterns when --fail-on-warning is set)
  1  Error patterns found
  2  Warning patterns found with --fail-on-warning

Patterns (case-insensitive):
  Errors:
    traceback
    exception
    streamlitapiexception
    snowparksqlexception
    error:

  Warnings:
    deprecation
    use_container_width
EOF
}

fail_on_warning=0
log_source="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fail-on-warning)
      fail_on_warning=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "$log_source" != "-" ]]; then
        echo "Only one LOG_FILE argument is allowed." >&2
        usage
        exit 64
      fi
      log_source="$1"
      shift
      ;;
  esac
done

if [[ "$log_source" != "-" && ! -f "$log_source" ]]; then
  echo "Log file not found: $log_source" >&2
  exit 66
fi

error_regex='traceback|exception|streamlitapiexception|snowparksqlexception|error:'
warning_regex='deprecation|use_container_width'

log_input=""
if [[ "$log_source" == "-" ]]; then
  log_input="$(cat)"
else
  log_input="$(cat "$log_source")"
fi

echo "$log_input" | grep -E -i "$error_regex" >/tmp/streamlit_scan_errors.$$ || true
echo "$log_input" | grep -E -i "$warning_regex" >/tmp/streamlit_scan_warnings.$$ || true

if [[ -s /tmp/streamlit_scan_errors.$$ ]]; then
  echo "FAIL: matched error patterns:" >&2
  cat /tmp/streamlit_scan_errors.$$ >&2
  rm -f /tmp/streamlit_scan_errors.$$ /tmp/streamlit_scan_warnings.$$
  exit 1
fi

if [[ -s /tmp/streamlit_scan_warnings.$$ ]]; then
  echo "WARN: matched warning patterns:" >&2
  cat /tmp/streamlit_scan_warnings.$$ >&2
  if [[ "$fail_on_warning" -eq 1 ]]; then
    rm -f /tmp/streamlit_scan_errors.$$ /tmp/streamlit_scan_warnings.$$
    exit 2
  fi
fi

rm -f /tmp/streamlit_scan_errors.$$ /tmp/streamlit_scan_warnings.$$
echo "PASS: no error patterns matched."
