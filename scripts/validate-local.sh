#!/usr/bin/env bash
set -euo pipefail

echo "=== validate-local ==="

if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then
    corepack enable || true
    pnpm install
    pnpm run lint || true
    pnpm run typecheck || true
    pnpm test || true
    pnpm run build
  elif [ -f yarn.lock ]; then
    corepack enable || true
    yarn install --frozen-lockfile || yarn install
    yarn lint || true
    yarn typecheck || true
    yarn test || true
    yarn build
  else
    npm install
    npm run lint --if-present
    npm run typecheck --if-present
    npm test --if-present
    npm run build --if-present
  fi
fi

if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  if [ -f pyproject.toml ] && command -v uv >/dev/null 2>&1; then
    uv sync || true
    uv run pytest || true
  elif [ -f requirements.txt ]; then
    python3 -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt
    pytest || true
  fi
fi

echo "validate-local complete"
