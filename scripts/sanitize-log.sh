#!/usr/bin/env bash
set -euo pipefail

sed -E \
  -e 's/(password|passwd|pwd|token|secret|api[_-]?key)=([^[:space:]]+)/\1=REDACTED/Ig' \
  -e 's/(Authorization: Bearer )[A-Za-z0-9._~+\/=-]+/\1REDACTED/Ig' \
  -e 's/(ANTHROPIC_API_KEY=)[^[:space:]]+/\1REDACTED/Ig' \
  -e 's/(OPENAI_API_KEY=)[^[:space:]]+/\1REDACTED/Ig' \
  -e 's/(DATABASE_URL=)[^[:space:]]+/\1REDACTED/Ig' \
  -e 's/(MYSQL_PWD=)[^[:space:]]+/\1REDACTED/Ig'
