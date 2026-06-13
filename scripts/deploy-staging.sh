#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

SERVER_HOST="${SERVER_HOST:?SERVER_HOST is required in .env.agent}"
SERVER_USER="${SERVER_USER:?SERVER_USER is required in .env.agent}"
APP_DIR="${APP_DIR:?APP_DIR is required in .env.agent}"
APP_NAME="${APP_NAME:-my-app}"
AGENT_BRANCH="${AGENT_BRANCH:-agent/sequential-run}"
REMOTE_NAME="${REMOTE_NAME:-origin}"

echo "Deploying branch $AGENT_BRANCH to $SERVER_USER@$SERVER_HOST:$APP_DIR"

git push "$REMOTE_NAME" "$AGENT_BRANCH"

ssh "$SERVER_USER@$SERVER_HOST" <<EOF_REMOTE
set -euo pipefail

cd "$APP_DIR"

git fetch "$REMOTE_NAME"
git checkout "$AGENT_BRANCH"
git pull --ff-only "$REMOTE_NAME" "$AGENT_BRANCH"

if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then
    corepack enable || true
    pnpm install --prod=false
    pnpm run build
  elif [ -f yarn.lock ]; then
    corepack enable || true
    yarn install --frozen-lockfile || yarn install
    yarn build
  else
    npm install
    npm run build --if-present
  fi
fi

if [ -f pyproject.toml ] && command -v uv >/dev/null 2>&1; then
  uv sync || true
fi

if command -v pm2 >/dev/null 2>&1; then
  pm2 restart "$APP_NAME" || pm2 start npm --name "$APP_NAME" -- start
  pm2 save || true
else
  echo "pm2 not found on staging server."
  echo "Customize scripts/deploy-staging.sh for systemd, Docker, or your deployment method."
fi
EOF_REMOTE
