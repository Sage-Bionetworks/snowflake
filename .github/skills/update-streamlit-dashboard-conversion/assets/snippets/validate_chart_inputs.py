#!/usr/bin/env python3
"""
Validate that a query result contains only numeric columns (excluding the chart index).

Pipe JSON output from `snow sql --format JSON` to this script.

Usage:
    snow sql -q "..." --format JSON | python validate_chart_inputs.py --index-col DATE_BUCKET

Exit codes:
  0  All non-index columns are numeric (PASS)
  1  One or more non-index columns are non-numeric (FAIL)
  2  Input could not be parsed
"""
import argparse
import json
import sys

import pandas as pd


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--index-col",
        required=True,
        help="Column name used as the chart index (excluded from dtype check)",
    )
    args = parser.parse_args()

    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        print(f"ERROR: Could not parse JSON input: {exc}", file=sys.stderr)
        sys.exit(2)

    if not data:
        print("WARN: Query returned no rows — cannot validate column types.")
        sys.exit(0)

    df = pd.DataFrame(data)
    index_col = args.index_col.upper()

    if index_col not in df.columns:
        matches = [c for c in df.columns if c.upper() == index_col]
        if matches:
            index_col = matches[0]
        else:
            print(f"WARN: Index column '{args.index_col}' not found in result. Available: {list(df.columns)}")
            sys.exit(0)

    non_index_cols = [c for c in df.columns if c != index_col]
    non_numeric = [c for c in non_index_cols if not pd.api.types.is_numeric_dtype(df[c])]

    if non_numeric:
        print(f"FAIL: Non-numeric columns in chart input: {non_numeric}", file=sys.stderr)
        print(
            "Non-numeric columns cause mixed-type chart errors at render time.\n"
            "Pivot categorical columns into separate numeric series before charting.",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"PASS: All {len(non_index_cols)} non-index columns are numeric: {non_index_cols}")


if __name__ == "__main__":
    main()
