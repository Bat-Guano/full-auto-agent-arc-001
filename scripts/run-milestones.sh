#!/usr/bin/env bash
set -euo pipefail

# scripts/run-milestones.sh
#
# Sequential coding-agent milestone runner.
#
# Current workflow:
# 1. Run each active prompts/milestone-*.md file in lexical order.
# 2. Use a fresh Claude Code session for each milestone.
# 3. Run local validation and smoke tests.
# 4. Optionally deploy to staging and run staging smoke tests.
# 5. On failure:
#    - collect failure context
#    - collect server logs for staging failures
#    - create a structured troubleshooting report
#    - repair based on the troubleshooting report
#    - rerun the failed phase
# 6. Generate/update handoff memory files.
# 7. Archive the completed milestone prompt to prompts/done/.
# 8. Commit all milestone changes.
#
# Logging policy:
# - Logs are persistent.
# - Log files are appended with section headers.
# - Attempt-specific failure context and troubleshooting files are preserved.

if [ -f .env.agent ]; then
  set -a
  # shellcheck disable=SC1091
  source .env.agent
  set +a
fi

MAX_REPAIRS="${MAX_REPAIRS:-2}"
DEPLOY_STAGING="${DEPLOY_STAGING:-false}"
CLAUDE_PERMISSION_MODE="${CLAUDE_PERMISSION_MODE:-acceptEdits}"
AGENT_BRANCH="${AGENT_BRANCH:-agent/sequential-run}"
REMOTE_NAME="${REMOTE_NAME:-origin}"
CLAUDE_CMD="${CLAUDE_CMD:-claude-deepseek}"

mkdir -p agent-logs
mkdir -p docs/agent-state/milestones
mkdir -p prompts/done

RUN_STARTED_AT="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="agent-logs/run-history.log"

{
  echo
  echo "================================================================"
  echo "Run started: $(date -Is)"
  echo "Run id: $RUN_STARTED_AT"
  echo "Branch target: $AGENT_BRANCH"
  echo "Deploy staging: $DEPLOY_STAGING"
  echo "Max repairs: $MAX_REPAIRS"
  echo "Claude command: $CLAUDE_CMD"
  echo "================================================================"
} | tee -a "$RUN_LOG"

log_section() {
  local file="$1"
  local title="$2"

  {
    echo
    echo "================================================================"
    echo "$title"
    echo "Timestamp: $(date -Is)"
    echo "Run id: $RUN_STARTED_AT"
    echo "================================================================"
  } >> "$file"
}

if ! command -v "$CLAUDE_CMD" >/dev/null 2>&1; then
  echo "$CLAUDE_CMD command not found."
  echo "Set CLAUDE_CMD in .env.agent or ensure the command is on PATH."
  echo "Example:"
  echo "  CLAUDE_CMD=claude-deepseek"
  exit 1
fi

if [ ! -x scripts/sanitize-log.sh ]; then
  echo "scripts/sanitize-log.sh is missing or not executable."
  echo "Run: chmod +x scripts/*.sh"
  exit 1
fi

if [ ! -x scripts/collect-failure-context.sh ]; then
  echo "scripts/collect-failure-context.sh is missing or not executable."
  echo "Run: chmod +x scripts/*.sh"
  exit 1
fi

if [ ! -f docs/agent-state/troubleshooting-template.md ]; then
  echo "docs/agent-state/troubleshooting-template.md is missing."
  echo "Create the troubleshooting template before running milestones."
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
- README.md
- docs/dev-setup.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- docs/agent-state/troubleshooting-template.md
- package.json
- pyproject.toml

The current milestone prompt should follow the user's Matt Pocock slash-command skill format when useful:
- /diagnose for debugging, broken behavior, failing workflows, unclear runtime issues, or "it runs but does not work."
- /tdd for test-first implementation.
- /grill-with-docs when requirements are fuzzy and project docs are involved.
- /grill-me when requirements are fuzzy and no project docs are involved.
- /to-issues for turning plans into tickets.
- /to-prd for product requirements.
- /zoom-out for broad architecture/context discovery.
- /improve-codebase-architecture for refactoring or maintainability work.
- /handoff for compact continuation prompts.
- /prototype for throwaway exploration.

Current milestone prompt:
$(cat "$prompt")

Global execution rules:
- Keep the change bounded to this milestone.
- Prefer small, reversible, testable changes.
- Follow existing project conventions.
- Do not edit .env, .env.local, .env.agent, API keys, tokens, or secret files.
- Do not hardcode secrets.
- Do not deploy manually. The external runner owns deployment.
- Do not disable tests, linting, type checks, build checks, smoke tests, or deployment checks.
- Do not remove tests to make the pipeline pass.
- If the milestone requires scope beyond the prompt, stop and explain what is needed.
- Update relevant documentation when behavior or workflow changes.

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
  log_section "agent-logs/${name}.handoff.claude.log" "Handoff generation: $name"

  "$CLAUDE_CMD" -p "
/handoff

Goal:
Create or update project memory files after a successful milestone so the next fresh coding-agent session can continue safely.

Context:
Milestone name:
$name

Original milestone prompt:
$(cat "$prompt")

Current git status:
$(git status --short)

Diff summary:
$(git diff --stat)

Required files:
- docs/agent-state/current-state.md
- docs/agent-state/milestones/${name}.md

Constraints:
- Do not include secrets.
- Do not include huge logs.
- Use file paths instead of pasting large code blocks.
- Keep current-state.md concise and useful.
- Keep the milestone summary factual.
- Preserve workflow rules from docs/agent-state/current-state.md if they are still valid.
- Include any changes to the milestone runner, logging policy, troubleshooting process, or prompt format.

Steps:
1. Inspect existing project memory files.
2. Update docs/agent-state/current-state.md as rolling memory.
3. Create or update docs/agent-state/milestones/${name}.md as a factual milestone record.
4. Include validation commands and known issues.
5. Identify the next recommended milestone.

Documentation:
Review these files when present:
- CLAUDE.md
- README.md
- docs/dev-setup.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- docs/agent-state/troubleshooting-template.md
- scripts/run-milestones.sh

Definition of done:
- current-state.md reflects the latest implementation and workflow state.
- docs/agent-state/milestones/${name}.md summarizes the completed milestone.
- No secrets or bulky logs are included.
" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee -a "agent-logs/${name}.handoff.claude.log"
}

archive_prompt() {
  local name="$1"
  local prompt="$2"

  echo "=== Archiving completed prompt for $name ==="
  mkdir -p prompts/done

  local archived_prompt="prompts/done/$(basename "$prompt")"

  if [ -e "$archived_prompt" ]; then
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    archived_prompt="prompts/done/${name}-${timestamp}.md"
  fi

  mv "$prompt" "$archived_prompt"

  echo "Archived prompt:"
  echo "  $archived_prompt"
}

repair_with_claude() {
  local name="$1"
  local prompt="$2"
  local phase="$3"
  local attempt="$4"
  local context_file="agent-logs/${name}.${phase}.attempt-${attempt}.failure-context.md"
  local troubleshooting_file="agent-logs/${name}.${phase}.attempt-${attempt}.troubleshooting.md"

  ./scripts/collect-failure-context.sh "$context_file" "$name" "$phase"

  if [ "$phase" = "deploy-staging" ] || [ "$phase" = "smoke-staging" ]; then
    if [ -x scripts/collect-server-logs.sh ]; then
      log_section "agent-logs/${name}.${phase}.server-tail.log" "Server log collection: $name / $phase / attempt $attempt"

      ./scripts/collect-server-logs.sh 2>&1 \
        | ./scripts/sanitize-log.sh \
        | tee -a "agent-logs/${name}.${phase}.server-tail.log" || true

      ./scripts/collect-failure-context.sh "$context_file" "$name" "$phase"
    fi
  fi

  echo "=== Creating troubleshooting report for $name / $phase / attempt $attempt ==="
  log_section "agent-logs/${name}.${phase}.troubleshooting.claude.log" "Troubleshooting report: $name / $phase / attempt $attempt"

  "$CLAUDE_CMD" -p "
/diagnose

Goal:
Complete a structured troubleshooting report for a failed milestone phase before any repair work continues.

Context:
Milestone name:
$name

Failure phase:
$phase

Repair attempt:
$attempt

Original milestone prompt:
$(cat "$prompt")

Failure context:
$(cat "$context_file")

Troubleshooting template:
$(cat docs/agent-state/troubleshooting-template.md)

Target troubleshooting report file:
$troubleshooting_file

Constraints:
- Do not make code changes during this troubleshooting report step.
- Do not guess. If evidence is missing, say what is missing.
- Do not edit .env, .env.local, .env.agent, API keys, tokens, or secret files.
- Do not hardcode secrets.
- Do not remove, skip, weaken, or bypass tests.
- If this appears to require manual intervention, state that clearly.

Steps:
1. Read the failure context.
2. Review relevant project documentation and scripts.
3. Classify the failure.
4. Identify the first failing command.
5. State the root-cause hypothesis and supporting evidence.
6. Decide whether repair is safe to continue.
7. Write the smallest safe repair plan.
8. Save the completed report to:
   $troubleshooting_file

Documentation:
Review these when present:
- CLAUDE.md
- README.md
- docs/dev-setup.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- docs/agent-state/troubleshooting-template.md
- scripts/
- agent-logs/

Definition of done:
- $troubleshooting_file exists.
- It uses the troubleshooting template structure.
- It states whether manual intervention is required.
- It includes a smallest-safe-repair plan.
- No application files are changed during this step.
" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee -a "agent-logs/${name}.${phase}.troubleshooting.claude.log"

  if [ ! -f "$troubleshooting_file" ]; then
    echo "Troubleshooting file was not created:"
    echo "  $troubleshooting_file"
    echo "Creating placeholder troubleshooting file so repair prompt can continue."
    {
      echo "/diagnose"
      echo
      echo "# Troubleshooting Report"
      echo
      echo "Milestone: $name"
      echo "Phase: $phase"
      echo "Attempt: $attempt"
      echo
      echo "Manual intervention required? unknown"
      echo
      echo "Note: The troubleshooting subprocess did not create the expected file."
    } > "$troubleshooting_file"
  fi

  if grep -qiE '^Manual intervention required\?[[:space:]]*yes|Manual intervention required:[[:space:]]*yes' "$troubleshooting_file"; then
    echo "Troubleshooting report indicates manual intervention is required."
    echo "Stopping automated repair for $name / $phase."
    return 1
  fi

  echo "=== Claude repair attempt $attempt for $name / $phase ==="
  log_section "agent-logs/${name}.${phase}.repair-${attempt}.claude.log" "Repair attempt: $name / $phase / attempt $attempt"

  "$CLAUDE_CMD" -p "
/diagnose

Goal:
Repair only the issue causing the failed milestone phase, using the troubleshooting report as the primary repair plan.

Context:
Milestone name:
$name

Failure phase:
$phase

Repair attempt:
$attempt

Original milestone prompt:
$(cat "$prompt")

Failure context:
$(cat "$context_file")

Structured troubleshooting report:
$(cat "$troubleshooting_file")

Constraints:
- Use the troubleshooting report as the primary repair plan.
- Stay within the original milestone scope unless the failure is clearly caused by validation, deployment, or runner configuration.
- Do not refactor unrelated code.
- Do not edit .env, .env.local, .env.agent, API keys, tokens, or secret files.
- Do not hardcode secrets.
- Do not remove tests to make the pipeline pass.
- Do not disable lint, typecheck, build, smoke, deployment, or test checks.
- Do not modify production targets unless explicitly required.
- If this is infrastructure, credentials, DNS, disk space, missing secrets, unavailable database, external provider outage, or server outage, do not fake a code fix. Explain the required manual action.
- Prefer the smallest safe fix.

Steps:
1. Read the troubleshooting report.
2. Confirm whether repair can continue safely.
3. Apply the smallest safe repair.
4. Do not run deployment manually.
5. Summarize changed files and validation to rerun.

Documentation:
Review these when relevant:
- CLAUDE.md
- README.md
- docs/dev-setup.md
- docs/agent-state/current-state.md
- docs/agent-state/milestones/
- docs/agent-state/troubleshooting-template.md
- scripts/
- relevant source files

Definition of done:
- The smallest safe repair is applied.
- No unrelated refactor is performed.
- No tests or checks are weakened.
- No secrets are modified or exposed.
- Final response includes root cause, troubleshooting report used, files changed, why the fix is safe, validation to rerun, and remaining risk.
" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee -a "agent-logs/${name}.${phase}.repair-${attempt}.claude.log"
}

run_with_repairs() {
  local name="$1"
  local prompt="$2"
  local phase="$3"
  shift 3

  local attempt=0

  log_section "agent-logs/${name}.${phase}.log" "Phase execution: $name / $phase"

  until "$@" 2>&1 | ./scripts/sanitize-log.sh | tee -a "agent-logs/${name}.${phase}.log"; do
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
  echo "No active prompts found. Add files like:"
  echo "  prompts/milestone-03.md"
  echo
  echo "Completed prompts should live under:"
  echo "  prompts/done/"
  exit 0
fi

for prompt in prompts/milestone-*.md; do
  name="$(basename "$prompt" .md)"

  echo
  echo "=== Starting $name ==="
  log_section "agent-logs/${name}.claude.log" "Milestone execution: $name"

  "$CLAUDE_CMD" -p "$(build_milestone_prompt "$prompt")" \
    --permission-mode "$CLAUDE_PERMISSION_MODE" \
    --output-format text \
    2>&1 | ./scripts/sanitize-log.sh | tee -a "agent-logs/${name}.claude.log"

  run_with_repairs "$name" "$prompt" "validate-local" ./scripts/validate-local.sh
  run_with_repairs "$name" "$prompt" "smoke-local" ./scripts/smoke-local.sh

  if [ "$DEPLOY_STAGING" = "true" ]; then
    run_with_repairs "$name" "$prompt" "deploy-staging" ./scripts/deploy-staging.sh
    run_with_repairs "$name" "$prompt" "smoke-staging" ./scripts/smoke-staging.sh
  fi

  generate_handoff "$name" "$prompt"
  archive_prompt "$name" "$prompt"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    git commit -m "$name"
  else
    echo "No changes to commit for $name"
  fi

  echo "=== Finished $name ==="
done

{
  echo
  echo "================================================================"
  echo "Run finished: $(date -Is)"
  echo "Run id: $RUN_STARTED_AT"
  echo "Current branch: $(git branch --show-current)"
  echo "================================================================"
} | tee -a "$RUN_LOG"

echo
echo "=== Milestone run complete ==="
echo "Current branch: $(git branch --show-current)"
echo "Push with:"
echo "  git push -u $REMOTE_NAME $AGENT_BRANCH"
