/tdd
Goal:
Add a basic automated test foundation for the scaffolded app.
Context:
Milestone 02 created a Vite React TypeScript frontend and a FastAPI backend. The next step is to add lightweight tests so
future milestones have a safety net.
Constraints:
- Do not add authentication.
- Do not add database logic.
- Do not deploy.
- Do not hardcode secrets.
- Do not remove the existing app scaffold.
- Do not disable or weaken existing validation.
Steps:
1. Add a simple frontend test setup for the Vite React TypeScript app.
2. Add at least one frontend test that verifies the landing page renders.
3. Add or update npm scripts so frontend tests can run from scripts/validate-local.sh.
4. Add pytest support for the FastAPI backend.
5. Add at least one backend test for GET /api/health verifying HTTP 200 and {"status": "ok"}.
6. Add required test dependencies to backend/requirements.txt.
7. Update scripts/validate-local.sh so it runs frontend lint, typecheck, build, tests, and backend tests.
8. Update README.md or docs/dev-setup.md with test instructions.
Documentation:
- README.md
- docs/dev-setup.md
- docs/agent-state/current-state.md
Definition of done:
- ./scripts/validate-local.sh passes.
- ./scripts/smoke-local.sh passes.
- Frontend has at least one meaningful test.
- Backend has at least one meaningful test.
- Documentation explains how to run tests.
