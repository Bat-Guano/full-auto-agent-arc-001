/diagnose

Goal:
Harden staging/deployment readiness so the project can safely distinguish local validation, staging dry-run, and real staging deployment.

Context:
The app has local validation, local smoke checks, readiness checks, CI, and an existing deploy-staging/smoke-staging script area. This milestone is independent from UX polish and dependency/security hardening. It should improve deployability without requiring real secrets or a real staging target to be present.

Constraints:
- Work in the app repo root.
- Do not create, modify, print, or commit secrets.
- Do not require real staging credentials for the milestone to pass.
- Preserve DEPLOY_STAGING=false as a safe default unless all required staging variables are present.
- Do not perform a destructive deployment.
- Use dry-run/preflight behavior when staging is not configured.
- Preserve existing validation and smoke behavior.
- Keep staging settings env-driven and documented.

Steps:
1. Inspect existing staging-related scripts and .env.agent.example settings.
2. Add or improve a staging preflight check that validates required variables without printing secrets.
3. Add or improve dry-run mode for deployment scripts so the runner can verify deployment readiness safely.
4. Ensure smoke-staging.sh has clear behavior:
   - if staging URL is configured, check health/readiness/items as applicable
   - if not configured, fail or skip according to an explicit env setting, with a clear message
5. Update docs to explain:
   - local validation vs local smoke vs staging smoke
   - required staging variables
   - how to enable real staging deployment
   - how to run dry-run/preflight only
6. Add tests or shell syntax checks where practical for touched scripts.
7. Run ./scripts/validate-local.sh and ./scripts/smoke-local.sh.
8. Do not enable real deployment unless the repo already has complete non-secret staging configuration.
9. Update current-state and milestone documentation.
10. Archive this prompt when complete.

Definition of done:
- Staging deploy/smoke scripts have safer preflight and dry-run behavior.
- Missing staging config produces clear guidance, not confusing failure.
- No secrets are committed or printed.
- Local validation and smoke still pass.
- Documentation explains how to move from dry-run to real staging.
- Runner auto-publishes the milestone and returns to agent/sequential-run.
