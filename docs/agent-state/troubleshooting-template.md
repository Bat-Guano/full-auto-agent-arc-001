/diagnose

# Troubleshooting Report

This report is created when an automated milestone phase fails.

It must be completed before repair work continues.

Goal:
Identify the smallest safe repair for a failed milestone phase using evidence from logs, failure context, server state, and project documentation.

Context:
- Milestone:
- Phase:
- Attempt:
- Timestamp:
- Runner:
- Branch:
- Commit before repair:
- Failure context file:
- Server log file, if applicable:
- Original milestone prompt:

Failure summary:
- What failed:
- First failing command:
- Expected behavior:
- Actual behavior:
- Error message or symptom:
- Is this blocking the milestone from continuing? yes/no

Constraints:
- Do not guess when evidence is missing.
- Do not edit application code during the troubleshooting report step.
- Do not edit `.env`, `.env.local`, `.env.agent`, API keys, tokens, or secret files.
- Do not hardcode secrets.
- Do not remove, skip, weaken, or bypass tests to make the pipeline pass.
- Do not disable linting, type checking, build checks, smoke tests, or deployment checks.
- Do not modify production targets unless explicitly required by the milestone.
- Do not refactor unrelated code.
- Prefer the smallest safe change.
- If the evidence points to infrastructure, credentials, DNS, firewall, disk space, missing services, missing secrets, or server outage, stop and mark manual intervention required.

Steps:

1. Classify the failure.

Choose one primary category:

- Application code issue
- Test or validation issue
- Local development environment issue
- Runner/orchestration issue
- Deployment script issue
- Server runtime issue
- DNS or network issue
- Secrets or configuration issue
- Database or service dependency issue
- Permission, user, or group issue
- Disk, memory, CPU, or resource issue
- External provider/API issue
- Unknown

Primary category:

Why this category fits:

Other categories considered:

2. Review available evidence.

Evidence reviewed:

- Git status:
- Git diff summary:
- Recent commits:
- Failure context:
- Local validation logs:
- Local smoke logs:
- Deployment logs:
- Server logs:
- Application logs:
- Environment/config files reviewed:
- Documentation reviewed:
- Relevant source files reviewed:

Evidence missing:

3. Identify the first real failure.

First failing command:

Where it ran:

Exit code, if known:

Relevant output:

Is this the root failure or a downstream symptom?

Reasoning:

4. Form a root-cause hypothesis.

Primary hypothesis:

Supporting evidence:

Alternative hypothesis 1:

Why it is less likely:

Alternative hypothesis 2:

Why it is less likely:

What would confirm the primary hypothesis?

5. Decide whether repair is safe to continue.

Repair can continue? yes/no

Manual intervention required? yes/no

If manual intervention is required, stop here and describe exactly what the human must do:

Manual action required:

Reason:

6. Create the repair plan.

Smallest safe repair:

Files expected to change:

Files that must not change:

Commands to rerun after repair:

Expected result after repair:

Rollback plan:

7. Repair result.

Files changed:

Commands rerun:

Results:

Did the original failing phase pass after repair? yes/no

Did any new failure appear? yes/no

Remaining risk:

8. Follow-up recommendation.

Should a future milestone address anything discovered here? yes/no

Recommended future milestone or issue:

Documentation:
Review these before completing the report when they exist:

- `CLAUDE.md`
- `README.md`
- `docs/dev-setup.md`
- `docs/agent-state/current-state.md`
- `docs/agent-state/milestones/`
- `docs/agent-state/troubleshooting-template.md`
- Relevant files under `scripts/`
- Relevant app source files
- Relevant deployment config
- Relevant logs under `agent-logs/`

Definition of done:
- The failure is classified.
- The first failing command is identified.
- Evidence reviewed is listed.
- A root-cause hypothesis is stated with supporting evidence.
- Manual intervention is clearly marked yes/no.
- A smallest-safe-repair plan is written.
- No code changes are made during the troubleshooting report step.
- The report is saved to the requested troubleshooting markdown file.
