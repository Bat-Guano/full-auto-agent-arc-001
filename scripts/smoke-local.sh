#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

PORT="${PORT:-3000}"
LOCAL_HEALTH_PATH="${LOCAL_HEALTH_PATH:-/}"
BASE_URL="http://localhost:${PORT}"
HEALTH_URL="${BASE_URL}${LOCAL_HEALTH_PATH}"

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ -f package.json ]; then
  if npm run | grep -qE '^  start'; then
    START_CMD="npm run start"
  elif npm run | grep -qE '^  dev'; then
    START_CMD="npm run dev -- --host 0.0.0.0 --port ${PORT}"
  else
    echo "No npm start/dev script found. Skipping local smoke test."
    exit 0
  fi
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  if [ -f main.py ]; then
    START_CMD="python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT}"
  elif [ -f app/main.py ]; then
    START_CMD="python3 -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"
  else
    echo "No FastAPI main.py detected. Skipping local smoke test."
    exit 0
  fi
else
  echo "No recognized web app found. Skipping local smoke test."
  exit 0
fi

echo "Starting local server with: $START_CMD"
bash -lc "$START_CMD" &
SERVER_PID=$!

echo "Waiting for local server at $HEALTH_URL"
for i in $(seq 1 60); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Local smoke test passed: $HEALTH_URL"
    exit 0
  fi
  sleep 2
done

echo "Local smoke test failed: $HEALTH_URL did not respond."
exit 1
