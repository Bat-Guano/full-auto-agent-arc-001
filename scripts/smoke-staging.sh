#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

STAGING_URL="${STAGING_URL:?STAGING_URL is required in .env.agent}"
STAGING_HEALTH_PATH="${STAGING_HEALTH_PATH:-/api/health}"
HEALTH_URL="${STAGING_URL%/}${STAGING_HEALTH_PATH}"

echo "Testing staging URL: $HEALTH_URL"

for i in $(seq 1 30); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Staging smoke test passed: $HEALTH_URL"
    exit 0
  fi
  sleep 3
done

echo "Staging smoke test failed: $HEALTH_URL did not respond."
exit 1
