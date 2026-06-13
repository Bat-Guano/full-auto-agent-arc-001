#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env.agent" ]; then
  set -a
  source "$ROOT_DIR/.env.agent"
  set +a
fi

PORT="${PORT:-8000}"
HEALTH_PATH="${HEALTH_PATH:-/api/health}"
BASE_URL="http://localhost:${PORT}"
HEALTH_URL="${BASE_URL}${HEALTH_PATH}"

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Determine the backend start command
if [ -f "$ROOT_DIR/backend/main.py" ]; then
  START_CMD="python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT}"
  START_DIR="$ROOT_DIR/backend"
elif [ -f "$ROOT_DIR/backend/app/main.py" ]; then
  START_CMD="python3 -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"
  START_DIR="$ROOT_DIR/backend"
elif [ -f "$ROOT_DIR/main.py" ]; then
  START_CMD="python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT}"
  START_DIR="$ROOT_DIR"
elif [ -f "$ROOT_DIR/package.json" ]; then
  # Fallback: try frontend dev server
  cd "$ROOT_DIR"
  if npm run | grep -qE '^  start'; then
    START_CMD="npm run start"
  elif npm run | grep -qE '^  dev'; then
    START_CMD="npm run dev -- --host 0.0.0.0 --port ${PORT}"
  else
    echo "No start/dev script found. Skipping local smoke test."
    echo "To run smoke tests manually: start the backend and check ${HEALTH_URL}"
    exit 0
  fi
  START_DIR="$ROOT_DIR"
else
  echo "No recognized app entry point found. Skipping local smoke test."
  echo "To run smoke tests manually: start the backend and check ${HEALTH_URL}"
  exit 0
fi

# Ensure backend venv is set up if using Python
if [ -f "$START_DIR/requirements.txt" ]; then
  if [ ! -d "$START_DIR/.venv" ]; then
    python3 -m venv "$START_DIR/.venv"
  fi
  if [ ! -f "$START_DIR/.venv/bin/uvicorn" ]; then
    "$START_DIR/.venv/bin/pip" install -r "$START_DIR/requirements.txt" >/dev/null 2>&1
  fi
  START_CMD="$START_DIR/.venv/bin/uvicorn main:app --host 0.0.0.0 --port ${PORT}"
fi

echo "Starting server with: $START_CMD"
cd "$START_DIR"
bash -lc "$START_CMD" &
SERVER_PID=$!

echo "Waiting for server at $HEALTH_URL"
for i in $(seq 1 30); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Local smoke test passed: $HEALTH_URL"
    exit 0
  fi
  sleep 2
done

echo "Local smoke test failed: $HEALTH_URL did not respond after 60s."
exit 1
