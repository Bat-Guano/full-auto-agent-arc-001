# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** that now contains a **full-stack web application scaffold**: Vite + React + TypeScript frontend with a FastAPI + Python backend. The harness runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops.

## Tech Stack (Application Level)

| Layer | Technology | Key Files |
|---|---|---|
| Frontend | Vite 7 + React 19 + TypeScript 5.9 | `frontend/package.json`, `frontend/vite.config.ts` |
| Backend | FastAPI 0.136 + Python 3.12 + Uvicorn 0.49 | `backend/main.py`, `backend/requirements.txt` |
| Frontend testing | Vitest 3 + React Testing Library 16 + jsdom 26 | `frontend/src/App.test.tsx`, `frontend/src/ItemsList.test.tsx`, `frontend/src/test-setup.ts` |
| Backend testing | pytest 8 + httpx + FastAPI TestClient | `backend/test_health.py`, `backend/test_items.py`, `backend/test_readiness.py` |
| Frontend package manager | npm | `frontend/package.json` (lockfile committed) |
| Backend package manager | pip + venv | `backend/requirements.txt` |

## Architecture Notes

- **Frontend** (`frontend/`): Vite dev server on port 5173, proxies `/api` to backend port 8000. Production build outputs to `frontend/dist/`. Scripts: `dev`, `build` (tsc + vite build), `lint` (eslint flat config), `typecheck` (tsc --noEmit), `test` (vitest run). Components: `App.tsx` (landing page + status), `ItemsList.tsx` (fetches/displays `/api/items`, includes inline creation form, inline toggle and delete controls).
- **Backend** (`backend/`): FastAPI app split across `main.py` (routes + models) and `storage.py` (SQLite persistence). CORS configured for `http://localhost:5173`. Endpoints: `GET /api/health` → `{"status": "ok"}`, `GET /api/ready` → `{"status": "ok", "database": "connected"}` (verifies SQLite connectivity; returns 503 if the database is unreachable), `GET /api/items` → `{"items": [...]}`, `POST /api/items` (body: `{name, done?}`, returns 201), `PATCH /api/items/{item_id}` (body: `{name?, done?}`, partial update), `DELETE /api/items/{item_id}` (returns deleted item). Items stored in SQLite (`./items.db` by default, overridable via `ITEMS_DB_PATH` env var) with auto-incrementing IDs. Database initialised and seeded with four default starter items on first import. Pydantic models: `CreateItemRequest` (name: required, done: optional), `UpdateItemRequest` (name: optional, done: optional — both with client-controlled semantics for partial updates).
- **App.tsx** (`frontend/src/App.tsx`): Landing page that fetches `/api/health` on mount, displays API status (ok / error / pending), and renders `<ItemsList />` in a side-by-side card layout.
- **ItemsList.tsx** (`frontend/src/ItemsList.tsx`): Full CRUD UI for items. Fetches `/api/items` on mount, renders loading/error/success states as a `<ul>`. Features: inline form (text input + "Add" button) to create items via POST; checkbox on each item to toggle done status via PATCH; "Delete" button on each item to remove via DELETE; per-action error messages rendered as `<p role="alert">`. Done items styled with `.item-done` (green, line-through); pending items styled with `.item-pending`.
- **Harness scripts** auto-detect ecosystem in subdirectories (`frontend/`, `backend/`), not in the repo root.
- **`.env.agent`** (gitignored, copied from `.env.agent.example`) controls branch name, permission mode, port (default 8000), health path (`/api/health`), and deployment flags.

## Implementation Status

- **Milestone 01** — Complete. Repo inspection, created `docs/agent-notes.md`.
- **Milestone 02** — Complete. Scaffold created: frontend builds, backend health endpoint works, scripts updated, docs written.
- **Milestone 03** — Complete. Test foundation added: 3 frontend component tests (Vitest + React Testing Library), 1 backend health endpoint test (pytest + TestClient), test deps added to both package files, validate-local.sh runs tests as hard requirements, documentation updated.
- **Milestone 04** — Complete. Domain feature slice added: `GET /api/items` endpoint with pytest test, `ItemsList` component with Vitest tests, wired into `App.tsx`. React act() warnings cleaned up in `App.test.tsx`. TestClient deprecation documented as follow-up.
- **Milestone 05** — Complete. Item mutation added: `POST /api/items` endpoint with Pydantic validation, 5 new backend tests, inline creation form in `ItemsList.tsx`, 4 new frontend form tests (`fireEvent`-based, no extra deps). Auto-incrementing IDs for new items.
- **Milestone 06** — Complete. Item update and delete mutations added: `PATCH /api/items/{item_id}` (partial update via `UpdateItemRequest`), `DELETE /api/items/{item_id}`. 7 new backend tests (4 PATCH + 3 DELETE), 6 new frontend tests for toggle/delete controls and error handling. Inline checkbox toggle and delete button in `ItemsList.tsx`. Full CRUD now supported end-to-end.
- **Milestone 07** — Complete. SQLite persistence added: `backend/storage.py` module with `init_db`, `seed_if_empty`, `get_items`, `create_item`, `update_item`, `delete_item`. Database path configurable via `ITEMS_DB_PATH` env var (default `./items.db`). `conftest.py` isolates tests with a temp database. 6 new persistence tests (`test_persistence.py`). Existing tests updated to verify state via API instead of direct `ITEMS` access. Items survive server restarts when the same database path is used.
- **Milestone 08** — Complete. Production-readiness gates added: `GET /api/ready` endpoint with 2 tests, enhanced `smoke-local.sh` (health + readiness + items API checks), GitHub Actions CI workflow (`.github/workflows/ci.yml`) covering frontend and backend validation. React act() warning fixed in loading-state test.
- **Deployment** — Disabled (`DEPLOY_STAGING=false` in `.env.agent`).

## Validation Commands

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Full validation: frontend (npm install, lint, typecheck, test, build) + backend (venv setup, pip install, pytest) |
| `scripts/smoke-local.sh` | Start backend, check `/api/health`, `/api/ready`, and `/api/items` |
| `scripts/run-milestones.sh` | Run all milestones sequentially |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 (disabled) |
| `scripts/smoke-staging.sh` | Poll staging health endpoint (disabled) |

## Quick Test Commands

```bash
cd frontend && npm test       # Frontend tests: 18 (4 App + 14 ItemsList)
cd backend && source .venv/bin/activate && pytest  # Backend tests: 22 (1 health + 2 readiness + 13 items + 6 persistence)
```

## Known Issues

- **npm vulnerabilities**: 2 high severity vulnerabilities reported on `npm install`. May need `npm audit fix` in a future milestone.
- **Staging deployment**: Not configured (`DEPLOY_STAGING=false`, staging env vars empty).
- **smoke-local.sh non-reload mode**: Starts uvicorn without `--reload` since it's a one-shot health check, not a dev server.
- **Starlette TestClient uses httpx, not httpx2**: `starlette.testclient` prefers `httpx2` over `httpx`. Currently using `httpx>=0.28.0` in `requirements.txt`. The deprecation warning is non-blocking but should be addressed when `httpx2` stabilizes.
- **SQLite persistence added (milestone-07)**: Items persist in `./items.db` (configurable via `ITEMS_DB_PATH`). To reset, delete the database file. Different `ITEMS_DB_PATH` values effectively create separate databases.
- **Inline form and controls in ItemsList**: The creation form, toggle checkbox, and delete button all live inside `ItemsList.tsx` rather than separate components. This is acceptable at current complexity but should be extracted if component size grows (e.g., inline editing, confirmation dialogs, or validation feedback).
- **CI detects npm vulnerabilities but does not fail on them**: The GitHub Actions workflow runs `npm ci` which reports the 2 high-severity advisories but does not block the pipeline.

## Next Recommended Milestone

**Milestone 09 — Error handling and UX polish.** Potential areas: add inline editing for item names, confirmation dialogs before delete, improved error boundary coverage, input validation feedback on the frontend, or addressing the npm audit vulnerabilities. The specific scope should be defined in a new milestone prompt.

## Rules for the Next Agent

- Do NOT edit `.env`, `.env.local`, `.env.agent`, or any secret files.
- Do NOT hardcode secrets.
- Do NOT disable tests, linting, type checks, or build checks to make the pipeline pass.
- Do NOT remove tests to make the pipeline pass.
- Prefer small, reversible, testable changes.
- Follow existing project conventions.
- Before editing, read `docs/agent-state/current-state.md` and relevant milestone files in `docs/agent-state/milestones/`.
- The external runner (`run-milestones.sh`) owns deployment — do not deploy manually.
- The frontend is in `frontend/`, backend in `backend/` — scripts reference these subdirectories, not the repo root.
