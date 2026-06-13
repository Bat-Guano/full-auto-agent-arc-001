#!/usr/bin/env bash
set -euo pipefail

OUT="${1:?Output file required}"
MILESTONE_NAME="${2:-unknown}"
PHASE="${3:-unknown}"

sanitize() {
  if [ -x scripts/sanitize-log.sh ]; then
    scripts/sanitize-log.sh
  else
    cat
  fi
}

{
  echo "# Failure Context"
  echo
  echo "Milestone: $MILESTONE_NAME"
  echo "Phase: $PHASE"
  echo "Timestamp: $(date -Is)"
  echo
  echo "## Git status"
  git status --short || true
  echo
  echo "## Current branch"
  git branch --show-current || true
  echo
  echo "## Last commit"
  git log -1 --oneline || true
  echo
  echo "## Changed files"
  git diff --name-only || true
  echo
  echo "## Diff summary"
  git diff --stat || true
  echo
  echo "## Recent code diff"
  git diff -- . \
    ':(exclude)package-lock.json' \
    ':(exclude)pnpm-lock.yaml' \
    ':(exclude)yarn.lock' \
    | head -n 500 || true
  echo
  echo "## Logs"
  for file in "agent-logs/${MILESTONE_NAME}"*.log; do
    if [ -f "$file" ]; then
      echo
      echo "### $file"
      tail -n 250 "$file" | sanitize
    fi
  done
} > "$OUT"
