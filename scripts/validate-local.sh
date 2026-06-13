#!/usr/bin/env bash
set -euo pipefail

echo "=== validate-local ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Frontend validation ---
if [ -f "$ROOT_DIR/frontend/package.json" ]; then
  echo "--- Validating frontend ---"
  cd "$ROOT_DIR/frontend"

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

  echo "--- Frontend validation complete ---"
fi

# --- Backend validation ---
if [ -f "$ROOT_DIR/backend/pyproject.toml" ] || [ -f "$ROOT_DIR/backend/requirements.txt" ]; then
  echo "--- Validating backend ---"
  cd "$ROOT_DIR/backend"

  if [ -f pyproject.toml ] && command -v uv >/dev/null 2>&1; then
    uv sync || true
    uv run pytest
  elif [ -f requirements.txt ]; then
    if [ ! -d .venv ]; then
      python3 -m venv .venv
    fi
    ./.venv/bin/pip install -r requirements.txt
    ./.venv/bin/pytest
  fi

  echo "--- Backend validation complete ---"
fi

echo "validate-local complete"
