#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.agent ]; then
  set -a
  source .env.agent
  set +a
fi

MAX_REPAIRS="${MAX_REPAIRS:-2}"
DEPLOY_STAGING="${DEPLOY_STAGING:-false}"
CLAUDE_PERMISSION_MODE="${CLAUDE_PERMISSION_MODE:-acceptEdits}"
AGENT_BRANCH="${AGENT_BRANCH:-agent/sequential-run}"
REMOTE_NAME="${REMOTE_NAME:-origin}"

mkdir -p agent-logs
mkdir -p docs/agent-state/milestones

if ! command -v claude >/dev/null 2>&1; then
  echo "claude command not found. Install/authenticate Claude Code first."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a git repo."
  echo "Initialize or clone a repo before running milestones."
  exit 1
fi

if ! git config user.email >/dev/null 2>&1; then
  git config user.email "agent@local.vm"
fi

if ! git config user.name >/dev/null 2>&1; then
  git config user.name "Claude Agent"
fi

echo "=== Preparing branch $AGENT_BRANCH ==="

if git show-ref --verify --quiet "refs/heads/$AGENT_BRANCH"; then
  git checkout "$AGENT_BRANCH"
else
  git checkout -b "$AGENT_BRANCH"
fi

build_milestone_prompt() {
  local prompt="$1"

  cat <<EOF_PROMPT
You are Claude Code working in this repository.

Treat this as a fresh session. Do not assume prior chat context.

Before editing, inspect relevant project memory files if they exist:
- CLAUDE.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- README.md
- package.json
- pyproject.toml

Current milestone prompt:
$(cat "$prompt")

Global execution rules:
- Keep the change bounded to this milestone.
- Prefer small, reversible, testable changes.
- Follow existing project conventions.
- Do not edit .env, .env.local, .env.agent, or secret files.
- Do not hardcode secrets.
- Do not deploy manually. The external runner owns deployment.
- Do not disable tests, linting, type checks, or build checks.
- Do not remove tests to make the pipeline pass.
- If the milestone requires scope beyond the prompt, stop and explain what is needed.

Final response:
- Files changed
- Summary of changes
- Commands/tests run
- Risks or follow-up work
EOF_PROMPT
}

generate_handoff() {
  local name="$1"
  local prompt="$2"

  mkdir -p docs/agent-state/milestones

  echo "=== Generating handoff docs for $name ==="

  claude-deepseek -p "
You are Claude Code working in this repository.

The milestone has passed validation.

Milestone name:
$name

Original milestone prompt:
$(cat "$prompt")

Current git status:
$(git status --short)

Diff summary:
$(git diff --stat)

Task:
Create or update these files:
- docs/agent-state/current-state.md
- docs/agent-state/milestones/${name}.md

Purpose:
These files are project memory for the next fresh Claude Code session.

docs/agent-state/current-state.md should be concise rolling memory. Include:
- current app purpose
- detected tech stack
- important architecture notes
- current implementation status
- validation commands
- known issues
- next recommended milestone
- any rules the next agent must not forget

docs/agent-state/milestones/${name}.md should summarize this milestone. Include:
- goal
- changes made
- files touched
- commands/tests run
- decisions made
- known issues
- suggested next steps

Rules:
- Do not include secrets.
- Do not include huge logs.
- Use file paths instead of pasting large code blocks.
- Keep current-state.md concise and useful.
- Keep the milestone summary factual.
" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee "agent-logs/${name}.handoff.claude.log"
}

repair_with_claude() {
  local name="$1"
  local prompt="$2"
  local phase="$3"
  local attempt="$4"
  local context_file="agent-logs/${name}.${phase}.failure-context.md"

  ./scripts/collect-failure-context.sh "$context_file" "$name" "$phase"

  if [ "$phase" = "deploy-staging" ] || [ "$phase" = "smoke-staging" ]; then
    if [ -x scripts/collect-server-logs.sh ]; then
      ./scripts/collect-server-logs.sh 2>&1 \
        | ./scripts/sanitize-log.sh \
        | tee "agent-logs/${name}.${phase}.server-tail.log" || true

      ./scripts/collect-failure-context.sh "$context_file" "$name" "$phase"
    fi
  fi

  echo "=== Claude repair attempt $attempt for $name / $phase ==="

  claude-deepseek -p "
You are Claude Code working locally in this repository.

Treat this as a focused repair session. Do not assume prior chat context.

Before editing, inspect relevant project memory files if they exist:
- CLAUDE.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- README.md
- package.json
- pyproject.toml

The automated sequential milestone pipeline failed.

Milestone name:
$name

Failure phase:
$phase

Original milestone prompt:
$(cat "$prompt")

Failure context:
$(cat "$context_file")

Task:
Fix only the issue causing this failure.

Rules:
- Stay within the original milestone scope unless the failure is clearly caused by validation or deployment configuration.
- Do not refactor unrelated code.
- Do not edit .env, .env.local, .env.agent, or secret files.
- Do not hardcode secrets.
- Do not remove tests to make the pipeline pass.
- Do not disable lint, typecheck, build, or test checks.
- Do not modify production deployment targets.
- If this appears to be infrastructure, credentials, DNS, disk space, missing secrets, unavailable database, or server outage, do not fake a code fix. Explain the required manual action.
- Prefer the smallest safe fix.

Final response:
- Root cause
- Files changed
- Why the fix is safe
- Validation to rerun
- Any remaining risk
" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee "agent-logs/${name}.${phase}.repair-${attempt}.claude.log"
}

run_with_repairs() {
  local name="$1"
  local prompt="$2"
  local phase="$3"
  shift 3

  local attempt=0

  until "$@" 2>&1 | ./scripts/sanitize-log.sh | tee "agent-logs/${name}.${phase}.log"; do
    attempt=$((attempt + 1))

    if [ "$attempt" -gt "$MAX_REPAIRS" ]; then
      echo "$phase failed after $MAX_REPAIRS repair attempts."
      return 1
    fi

    repair_with_claude "$name" "$prompt" "$phase" "$attempt"
  done
}

prompt_count=$(find prompts -maxdepth 1 -name 'milestone-*.md' | wc -l)

if [ "$prompt_count" -eq 0 ]; then
  echo "No prompts found. Add files like:"
  echo "  prompts/milestone-01.md"
  exit 1
fi

for prompt in prompts/milestone-*.md; do
  name="$(basename "$prompt" .md)"

  echo
  echo "=== Starting $name ==="

  claude-deepseek -p "$(build_milestone_prompt "$prompt")" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee "agent-logs/${name}.claude.log"

  run_with_repairs "$name" "$prompt" "validate-local" ./scripts/validate-local.sh
  run_with_repairs "$name" "$prompt" "smoke-local" ./scripts/smoke-local.sh

  if [ "$DEPLOY_STAGING" = "true" ]; then
    run_with_repairs "$name" "$prompt" "deploy-staging" ./scripts/deploy-staging.sh
    run_with_repairs "$name" "$prompt" "smoke-staging" ./scripts/smoke-staging.sh
  fi

  generate_handoff "$name" "$prompt"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    git commit -m "$name"
  else
    echo "No changes to commit for $name"
  fi

  echo "=== Finished $name ==="
done

echo
echo "=== Milestone run complete ==="
echo "Current branch: $(git branch --show-current)"
echo "Push with:"
echo "  git push -u $REMOTE_NAME $AGENT_BRANCH"
