# Milestone 08 — Production-Readiness Gates

**Status:** Complete  
**Date:** 2026-06-13

## What was done

Added production-readiness checks to harden the workflow before a production deployment:

1. **Readiness endpoint** (`GET /api/ready`): New endpoint in `backend/main.py` that verifies the SQLite item store is reachable and queryable. Returns `{"status": "ok", "database": "connected"}` on success, or 503 with a detail message on failure.

2. **Readiness tests** (`backend/test_readiness.py`): Two new tests:
   - `test_ready_returns_200_when_database_is_queryable` — verifies the happy path
   - `test_ready_returns_503_when_database_is_unreachable` — uses `unittest.mock.patch` to simulate a database failure without brittle filesystem manipulation

3. **Enhanced smoke tests** (`scripts/smoke-local.sh`): Expanded from a single health check to three sequential checks:
   - `/api/health` returns status=ok
   - `/api/ready` returns status=ok, database=connected
   - `/api/items` returns valid JSON with at least one item
   Each check is independently validated and fails with a clear message.

4. **CI workflow** (`.github/workflows/ci.yml`): GitHub Actions pipeline with two parallel jobs:
   - `frontend`: checkout → setup-node → npm ci → lint → typecheck → test → build
   - `backend`: checkout → setup-python → venv → pip install → pytest
   No secrets, no deploy step, no staging environment required.

5. **React act() warning fix** (`frontend/src/ItemsList.test.tsx`): The "shows loading message initially" test was using the resolved mock from `beforeEach`, causing an async state update after unmount. Fixed by overriding the mock with a non-resolving promise for that specific test, matching the pattern already used in `App.test.tsx`.

## Files changed

| File | Change |
|---|---|
| `backend/main.py` | Added `GET /api/ready` endpoint |
| `backend/test_readiness.py` | New: 2 readiness tests |
| `scripts/smoke-local.sh` | Enhanced with readiness and items checks |
| `.github/workflows/ci.yml` | New: CI workflow |
| `frontend/src/ItemsList.test.tsx` | Fixed act() warning in loading test |
| `docs/agent-state/current-state.md` | Updated for milestone 08 |
| `docs/agent-state/milestones/milestone-08.md` | This file |
| `docs/dev-setup.md` | Updated with readiness and CI info |

## Backend test count

22 total: 1 health + 2 readiness + 13 items + 6 persistence

## Definition of done

- [x] `GET /api/ready` exists and is tested
- [x] Local smoke checks health, readiness, and item API behavior
- [x] GitHub Actions CI workflow mirrors local validation without deploying
- [x] React act(...) warning fixed in frontend loading-state test
- [x] Typecheck, lint, frontend tests, backend tests, build, and local smoke all pass
