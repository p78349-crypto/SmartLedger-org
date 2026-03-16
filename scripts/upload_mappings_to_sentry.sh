#!/usr/bin/env bash
set -euo pipefail
PLATFORM=${1:-android}

if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  echo "SENTRY_AUTH_TOKEN not set. Aborting." >&2
  exit 1
fi
if [ -z "${SENTRY_ORG:-}" ] || [ -z "${SENTRY_PROJECT:-}" ]; then
  echo "SENTRY_ORG or SENTRY_PROJECT not set. Aborting." >&2
  exit 1
fi

MAPPING_DIR="build/debug-info/${PLATFORM}"
if [ ! -d "$MAPPING_DIR" ]; then
  echo "Mapping directory '$MAPPING_DIR' not found. Run obfuscated build first." >&2
  exit 1
fi

if ! command -v sentry-cli >/dev/null 2>&1; then
  echo "Installing sentry-cli..."
  curl -sL https://sentry.io/get-cli/ | bash
fi

echo "Uploading debug info to Sentry..."
sentry-cli upload-dif --org "$SENTRY_ORG" --project "$SENTRY_PROJECT" "$MAPPING_DIR"

echo "Done."
