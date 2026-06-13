# Milestone 03 — Add Automated Test Foundation

## Goal

Add a basic automated test foundation for the scaffolded app: frontend component tests with Vitest + React Testing Library, backend endpoint tests with pytest + FastAPI TestClient, and integrate both into `validate-local.sh` as hard requirements.

## Changes Made

### Frontend Testing — 2 files created, 2 files modified

| File | Action | Purpose |
|---|---|---|
| `frontend/src/App.test.tsx` | Created | 3 Vitest tests: renders heading ("My App"), renders tagline, renders footer text |
| `frontend/src/test-setup.ts` | Created | Imports `@testing-library/jest-dom/vitest` for DOM matchers (`toBeInTheDocument`) |
| `frontend/package.json` | Modified | Added `"test": "vitest run"` script; added devDeps: `vitest@^3.0.0`, `@testing-library/react@^16.0.0`, `@testing-library/jest-dom@^6.0.0`, `jsdom@^26.0.0` |
| `frontend/vite.config.ts` | Modified | Added `/// <reference types="vitest/config" />` and `test:` block with jsdom environment, globals, and setup file |

### Backend Testing — 1 file created, 1 file modified

| File | Action | Purpose |
|---|---|---|
| `backend/test_health.py` | Created | 1 pytest test: `GET /api/health` returns HTTP 200 and `{"status": "ok"}` using FastAPI `TestClient` |
| `backend/requirements.txt` | Modified | Added `pytest>=8.0.0` and `httpx>=0.28.0` |

### Scripts — 1 modified

| File | Action | Purpose |
|---|---|---|
| `scripts/validate-local.sh` | Modified | Removed `--if-present` from `npm test`; removed `|| true` from pytest invocation — both test suites now run as hard requirements that fail validation if broken |

### Documentation — 2 modified

| File | Action | Purpose |
|---|---|---|
| `README.md` | Modified | Added Testing section with frontend and backend test commands; updated Validation section |
| `docs/dev-setup.md` | Modified | Added Running Tests section with frontend (Vitest) and backend (pytest) instructions; updated project structure diagram to show test files |

### Lockfile — 1 modified

| File | Action | Purpose |
|---|---|---|
| `frontend/package-lock.json` | Modified | Updated to include all new test dependencies (vitest, @testing-library/react, @testing-library/jest-dom, jsdom) |

## Files Touched Summary

| File | Action |
|---|---|
| `frontend/src/App.test.tsx` | Created |
| `frontend/src/test-setup.ts` | Created |
| `backend/test_health.py` | Created |
| `frontend/package.json` | Modified (added test script + 4 devDeps) |
| `frontend/package-lock.json` | Modified (lockfile update) |
| `frontend/vite.config.ts` | Modified (added vitest config) |
| `backend/requirements.txt` | Modified (added pytest + httpx) |
| `scripts/validate-local.sh` | Modified (tests as hard requirements) |
| `README.md` | Modified (added test instructions) |
| `docs/dev-setup.md` | Modified (added test section) |

## Commands/Tests Run

| Command | Result |
|---|---|
| `cd frontend && npm test` | **Passed** — 3/3 tests passed (heading, tagline, footer) |
| `cd backend && source .venv/bin/activate && pytest` | **Passed** — 1/1 test passed (health endpoint) |
| `scripts/validate-local.sh` | **Passed** — frontend lint/typecheck/test/build all green; backend pip install + pytest green |
| `scripts/smoke-local.sh` | **Passed** — health endpoint returned 200 |

`DEPLOY_STAGING=false` so staging deployment was skipped.

## Decisions Made

- **Vitest over Jest**: Chose Vitest 3 (native ESM, shares Vite config, nearly identical API to Jest). This avoids adding a separate Jest config and keeps the test runner aligned with the build tooling.
- **Testing Library ecosystem**: Used `@testing-library/react` for component rendering/queries and `@testing-library/jest-dom/vitest` for DOM matchers (`toBeInTheDocument`). This is the React Testing Library recommended setup for Vitest.
- **jsdom environment**: Tests run in jsdom (not node) so DOM APIs (`document`, `getByRole`, etc.) are available. Configured in `vite.config.ts` `test.environment`.
- **Test location**: Frontend tests live co-located with source files (`src/App.test.tsx` next to `src/App.tsx`). Backend tests are at the top level of `backend/` (`backend/test_health.py`).
- **Test as hard requirement**: In milestone-02, `npm test` used `--if-present` and pytest used `|| true`, so missing or failing tests wouldn't block validation. Milestone-03 removes these safety nets — tests must pass for `validate-local.sh` to succeed.
- **No snapshot tests**: Only behavioral assertions used. Snapshots can be brittle in early-stage projects.
- **Minimal test setup file**: `test-setup.ts` only imports the jest-dom matchers. No mocks or global config needed at this stage.

## Known Issues

- **npm vulnerabilities**: 2 high severity vulnerabilities remain from `npm install` (dev build dependencies). Not addressed in this milestone.
- **Vitest globals**: `test.globals: true` in vite.config.ts means `describe`/`it`/`expect` are available without imports, but `App.test.tsx` still imports them explicitly for clarity.
- **Staging deployment**: Still disabled. Test infrastructure will catch regressions locally but no CI/staging pipeline exists to run them on push.
- **No watch mode documented**: `npm run dev` starts Vite but there's no `npm run test:watch` script. `vitest` can be run directly for watch mode.

## Suggested Next Steps

1. **Milestone 04**: Define the application domain — add a domain-specific API endpoint with TDD, wire it into the frontend. Suggestions: a `/api/items` CRUD stub, a `/api/config` endpoint, or a simple counter/status endpoint.
2. **npm audit**: Review and address the 2 high severity npm vulnerabilities.
3. **CI pipeline**: Consider a GitHub Actions workflow that runs `validate-local.sh` on push/PR.
4. **More test coverage**: Add tests for error states (e.g., API unavailable rendering), edge cases, and any new components/endpoints added in future milestones.
5. **When ready for staging**: Set `DEPLOY_STAGING=true` and fill in `SERVER_HOST`, `SERVER_USER`, `APP_DIR`, `STAGING_URL` in `.env.agent`.
