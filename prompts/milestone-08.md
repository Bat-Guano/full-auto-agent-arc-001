/tdd

Goal:
Add production-readiness gates around the SQLite-backed app: readiness checks, stronger smoke tests, CI workflow, and cleanup of the remaining React act warning.

Context:
Milestone 07 should have moved item storage from in-memory data to SQLite-backed persistence while preserving the existing item CRUD API and UI.

Milestone 08 should harden the workflow as if this were preparing for a production deployment. It should add checks that catch broken backend storage, broken smoke behavior, and test instability before code is published.

Constraints:
- Build on the SQLite persistence from milestone 07.
- Do not add secrets or commit local environment files.
- Do not require paid services or external databases.
- Do not enable staging deployment unless it is already configured.
- Do not use npm audit fix --force.
- Do not make CI fail on the existing npm audit vulnerabilities unless they are actually fixed safely.
- Keep changes small enough for one milestone.
- Preserve existing API behavior.
- Fix or avoid React act(...) warnings in tests touched by this milestone.

Steps:
1. Add a backend readiness endpoint, preferably `GET /api/ready`, that verifies the app can reach and query the SQLite item store.
2. Add backend tests for readiness:
   - ready returns ok when the database is initialized/queryable
   - ready fails clearly if the database layer cannot be queried, if feasible without brittle mocking
3. Update `scripts/smoke-local.sh` to verify more than /api/health:
   - /api/health returns 200
   - /api/ready returns 200
   - /api/items returns valid JSON
4. If needed, add a small `scripts/smoke-api.sh` helper only if it keeps smoke-local cleaner.
5. Add or update docs explaining the production-readiness checks and local smoke expectations.
6. Add a GitHub Actions workflow at `.github/workflows/ci.yml` that runs the same core local validation steps:
   - frontend install/lint/typecheck/test/build
   - backend install/tests
   - avoid secrets
   - do not deploy
7. Fix the remaining React act(...) warning in the loading-state test without weakening the test.
8. Run:
   - ./scripts/validate-local.sh
   - ./scripts/smoke-local.sh
9. Update:
   - docs/agent-state/current-state.md
   - docs/agent-state/milestones/milestone-08.md
   - docs/dev-setup.md if useful
   - relevant memory files if the agent uses them
10. Archive this prompt when complete.

Definition of done:
- `GET /api/ready` exists and is tested.
- Local smoke checks health, readiness, and item API behavior.
- GitHub Actions CI workflow exists and mirrors the local validation strategy without deploying.
- React act(...) warning is gone from the frontend test output, or a clear reason is documented if it cannot be eliminated safely.
- Typecheck, lint, frontend tests, backend tests, build, and local smoke all pass.
- Runner processes milestone-07 and milestone-08 sequentially in one production-style run.
- Runner commits and publishes each milestone automatically, fast-forwards/pushes main after each, and returns to agent/sequential-run.
