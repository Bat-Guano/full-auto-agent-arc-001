#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

SERVER_HOST="${SERVER_HOST:?SERVER_HOST is required in .env.agent}"
SERVER_USER="${SERVER_USER:?SERVER_USER is required in .env.agent}"
APP_NAME="${APP_NAME:-my-app}"

ssh "$SERVER_USER@$SERVER_HOST" <<EOF_REMOTE
set -euo pipefail

if command -v pm2 >/dev/null 2>&1; then
  pm2 logs "$APP_NAME" --lines 150 --nostream || true
elif command -v journalctl >/dev/null 2>&1; then
  journalctl -u "$APP_NAME" --no-pager -n 150 || true
elif command -v docker >/dev/null 2>&1; then
  docker logs --tail 150 "$APP_NAME" || true
else
  echo "No supported log collector found."
fi
EOF_REMOTE
