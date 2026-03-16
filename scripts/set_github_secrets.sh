#!/usr/bin/env bash
set -euo pipefail

# Script to set required GitHub Actions secrets using gh CLI.
# Usage:
#   export SENTRY_AUTH_TOKEN=... SENTRY_ORG=... SENTRY_PROJECT=...
#   ./scripts/set_github_secrets.sh

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install GitHub CLI and authenticate first." >&2
  exit 1
fi

REPO=${GITHUB_REPOSITORY:-}
if [ -z "$REPO" ]; then
  echo "GITHUB_REPOSITORY not set. Either run inside GH Actions or set GITHUB_REPOSITORY=user/repo." >&2
  read -p "Enter target repository (owner/repo): " REPO
fi

echo "Setting secrets for $REPO"

set_secret() {
  name=$1
  var=${!1}
  if [ -z "$var" ]; then
    read -p "Enter value for $name: " -r var
  fi
  echo "Setting $name..."
  echo "$var" | gh secret set "$name" --repo "$REPO" --body -
}

set_secret SENTRY_AUTH_TOKEN
set_secret SENTRY_ORG
set_secret SENTRY_PROJECT

echo "All done. Secrets set for $REPO." 
