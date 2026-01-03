#!/usr/bin/env bash
# Simple release notes generator: prints INDEX lines since a given date (YYYY-MM-DD)
set -euo pipefail
SINCE=${1:-}
FILE="$(dirname "$0")/INDEX_CODE_FEATURES.md"
if [ ! -f "$FILE" ]; then
  echo "INDEX file not found: $FILE" >&2
  exit 2
fi
if [ -z "$SINCE" ]; then
  echo "Usage: $0 <since-date YYYY-MM-DD>" >&2
  exit 2
fi
awk -v since="$SINCE" '
  BEGIN { in_table=0 }
  /^\|---/ { in_table=1; next }
  in_table && /^\| *[0-9]{4}-[0-9]{2}-[0-9]{2} *\|/ {
    # extract date and the rest
    date=$2
    gsub(/^[ |]+|[ |]+$/, "", date)
    if (date >= since) print $0
  }
' FS='|' "$FILE" | sed 's/^|/ - /g'
