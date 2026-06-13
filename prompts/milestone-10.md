/diagnose

Goal:
Investigate and safely reduce dependency/security warnings, especially the npm audit warnings that have appeared repeatedly during validation.

Context:
Milestones 03 through 08 repeatedly showed npm audit warnings in the frontend. This milestone is intentionally independent from UX work and staging/deployment work. It should improve the security posture without using unsafe breaking-change commands.

Constraints:
- Work in the app repo root.
- Do not touch secrets, .env files, API keys, tokens, or deployment credentials.
- Do not use npm audit fix --force.
- Do not accept breaking dependency upgrades unless they are clearly isolated, tested, and documented.
- Prefer minimal safe dependency updates.
- Preserve all application behavior and tests.
- If a vulnerability cannot be safely fixed in this milestone, document it clearly with the reason and next action.
- Do not change product UI except where required by dependency updates.

Steps:
1. Inspect frontend package files and current npm audit output.
2. Identify which packages introduce the high severity warnings.
3. Try safe remediation first:
   - npm audit fix, without --force, if appropriate
   - targeted non-breaking package upgrades where compatible
   - lockfile refresh if needed
4. Run frontend lint/typecheck/test/build after any dependency change.
5. Run backend pytest to confirm no unrelated regression.
6. Run ./scripts/validate-local.sh and ./scripts/smoke-local.sh.
7. Update documentation:
   - current-state known issues
   - milestone summary
   - any dependency/security notes in docs/dev-setup.md if useful
8. If vulnerabilities remain, add a clear table documenting:
   - package/advisory source from npm audit output
   - severity
   - whether it requires breaking changes
   - recommended future action
9. Archive this prompt when complete.

Definition of done:
- npm audit warnings are reduced where safe, or remaining warnings are explicitly documented.
- No --force dependency fix was used.
- Frontend lint/typecheck/test/build pass.
- Backend tests pass.
- Full validate-local and smoke-local pass.
- Runner auto-publishes the milestone and returns to agent/sequential-run.
