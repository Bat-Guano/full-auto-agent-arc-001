#!/usr/bin/env bash
set -euo pipefail

# staging-preflight.sh
# Validates that all required staging variables are present without printing secrets.
#
# Usage:
#   ./scripts/staging-preflight.sh            # check all staging vars
#   ./scripts/staging-preflight.sh --deploy   # check deploy vars only
#   ./scripts/staging-preflight.sh --smoke    # check smoke vars only
#
# Exit codes:
#   0 - all checked variables are present and non-empty
#   1 - one or more required variables are missing or empty
#   2 - usage error

MODE="${1:-}"

# Load agent env if present (safe — only reads, never writes)
if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

DEPLOY_VARS=("SERVER_HOST" "SERVER_USER" "APP_DIR")
SMOKE_VARS=("STAGING_URL")
ALL_VARS=("${DEPLOY_VARS[@]}" "${SMOKE_VARS[@]}")

declare -A DESCRIPTIONS
DESCRIPTIONS["SERVER_HOST"]="Staging server hostname or IP"
DESCRIPTIONS["SERVER_USER"]="SSH user for staging server"
DESCRIPTIONS["APP_DIR"]="Application directory on staging server"
DESCRIPTIONS["STAGING_URL"]="Base URL of the staging application"
DESCRIPTIONS["DEPLOY_STAGING"]="Enable real staging deployment (true/false)"
DESCRIPTIONS["APP_NAME"]="Application name for pm2 (default: my-app)"
DESCRIPTIONS["STAGING_HEALTH_PATH"]="Health endpoint path (default: /api/health)"

echo "=== staging-preflight ==="
echo ""

declare -a MISSING=()
declare -a PRESENT=()

check_var() {
  local var_name="$1"
  local desc="${2:-}"
  local value="${!var_name:-}"

  if [ -n "$value" ]; then
    PRESENT+=("$var_name")
    return 0
  else
    MISSING+=("$var_name")
    return 1
  fi
}

case "$MODE" in
  --deploy)
    echo "Mode: deploy vars only"
    TARGET_VARS=("${DEPLOY_VARS[@]}")
    ;;
  --smoke)
    echo "Mode: smoke vars only"
    TARGET_VARS=("${SMOKE_VARS[@]}")
    ;;
  "")
    echo "Mode: all staging vars"
    TARGET_VARS=("${ALL_VARS[@]}")
    ;;
  -h|--help)
    echo "Usage: staging-preflight.sh [--deploy|--smoke]"
    echo ""
    echo "Validates that required staging environment variables are set."
    echo "Reports which variables are present or missing WITHOUT printing values."
    echo ""
    echo "Modes:"
    echo "  (none)     Check all staging vars"
    echo "  --deploy   Check deploy vars only (SERVER_HOST, SERVER_USER, APP_DIR)"
    echo "  --smoke    Check smoke vars only (STAGING_URL)"
    exit 0
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Usage: staging-preflight.sh [--deploy|--smoke]"
    exit 2
    ;;
esac

echo ""

# Check DEPLOY_STAGING flag
DEPLOY_STAGING="${DEPLOY_STAGING:-false}"
echo "DEPLOY_STAGING = $DEPLOY_STAGING"
if [ "$DEPLOY_STAGING" = "true" ]; then
  echo "  → Real staging deployment is enabled."
else
  echo "  → Real staging deployment is disabled (dry-run / preflight mode)."
fi

echo ""
echo "--- Checking required variables ---"

for var_name in "${TARGET_VARS[@]}"; do
  desc="${DESCRIPTIONS[$var_name]:-}"
  printf "  %-25s" "$var_name"
  if check_var "$var_name" "$desc"; then
    printf "✓ set"
    if [ -n "$desc" ]; then
      printf " (%s)" "$desc"
    fi
    echo ""
  else
    printf "✗ MISSING"
    if [ -n "$desc" ]; then
      printf " — %s" "$desc"
    fi
    echo ""
  fi
done

echo ""

if [ "${#MISSING[@]}" -eq 0 ]; then
  echo "✓ All required staging variables are set."
  echo ""

  # Additional sanity checks for deploy mode
  if [ "$MODE" = "--deploy" ] || [ -z "$MODE" ]; then
    APP_NAME="${APP_NAME:-my-app}"
    STAGING_HEALTH_PATH="${STAGING_HEALTH_PATH:-/api/health}"
    echo "--- Optional / defaulted variables ---"
    printf "  %-25s" "APP_NAME"
    printf "= %s\n" "$APP_NAME"
    printf "  %-25s" "STAGING_HEALTH_PATH"
    printf "= %s\n" "$STAGING_HEALTH_PATH"
    echo ""
  fi

  echo "staging-preflight: PASSED"
  exit 0
else
  echo "✗ Missing required staging variables: ${MISSING[*]}"
  echo ""
  echo "To enable staging deployment:"
  echo "  1. Copy .env.agent.example if you haven't already:"
  echo "       cp .env.agent.example .env.agent"
  echo "  2. Edit .env.agent and set the missing variables."
  echo "  3. Set DEPLOY_STAGING=true when ready for real deployment."
  echo "  4. Run staging-preflight.sh again to confirm."
  echo ""
  echo "For dry-run / preflight-only testing, no changes are needed —"
  echo "deploy-staging.sh and smoke-staging.sh will operate in dry-run mode"
  echo "when staging is not fully configured."
  echo ""
  echo "staging-preflight: FAILED"
  exit 1
fi
