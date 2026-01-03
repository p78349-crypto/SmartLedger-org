#!/usr/bin/env bash
# Validate format of tools/INDEX_CODE_FEATURES.md
set -euo pipefail
FILE="$(dirname "$0")/INDEX_CODE_FEATURES.md"
if [ ! -f "$FILE" ]; then
  echo "INDEX file not found: $FILE" >&2
  exit 2
fi
# Ensure table header exists
grep -n -E "^#\s*Change Log" "$FILE" >/dev/null || { echo "Change Log section not found (# Change Log …)." >&2; exit 2; }

# Validate only the Change Log table (the one that requires date rows).
# Also: if Note contains Playbook=..., ensure it points to an existing '### Playbook: ...' heading.
invalid=0
awk -F"|" '
  # First pass: collect playbook headings
  FNR==NR {
    if ($0 ~ /^###\s*Playbook:/) {
      pb=$0
      sub(/^###\s*Playbook:\s*/, "", pb)
      sub(/\s*$/, "", pb)
      playbook[pb]=1
    }
    next
  }

  BEGIN { in_section=0; in_table=0; }
  /^#\s*Change Log/ { in_section=1; next }
  in_section && /^\|---/ { in_table=1; next }
  in_table {
    # End of table at first non-table line
    if ($0 !~ /^\|/) { exit }

    # Skip empty row lines
    if ($0 ~ /^\|[[:space:]]*\|/) { next }

    if ($0 !~ /^\|[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*\|/) {
      printf("Invalid INDEX row format at line %d: %s\n", NR, $0) > "/dev/stderr"
      invalid=1
    }
    cols = gsub(/\|/, "&", $0)
    if (cols < 4) {
      printf("INDEX row at line %d does not have enough columns: %s\n", NR, $0) > "/dev/stderr"
      invalid=1
    }

    note=$6
    if (note ~ /Playbook[[:space:]]*=/) {
      pb=note
      sub(/.*Playbook[[:space:]]*=[[:space:]]*/, "", pb)
      sub(/;.*$/, "", pb)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", pb)
      if (length(pb) > 0 && !(pb in playbook)) {
        printf("Unknown Playbook reference at line %d: Playbook=%s (no matching \"### Playbook: %s\" heading)\n", NR, pb, pb) > "/dev/stderr"
        invalid=1
      }
    }
  }
  END { exit invalid }
' "$FILE" "$FILE" || invalid=1

if [ "$invalid" -ne 0 ]; then
  echo "INDEX format validation failed." >&2
  exit 1
fi

echo "INDEX format validation passed."