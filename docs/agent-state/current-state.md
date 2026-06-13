# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** that now contains a **full-stack web application scaffold**: Vite + React + TypeScript frontend with a FastAPI + Python backend. The harness runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops.

## Tech Stack (Application Level)

| Layer | Technology | Key Files |
|---|---|---|
| Frontend | Vite 7 + React 19 + TypeScript 5.9 | `frontend/package.json`, `frontend/vite.config.ts` |
| Backend | FastAPI 0.136 + Python 3.12 + Uvicorn 0.49 | `backend/main.py`, `backend/requirements.txt` |
| Frontend testing | Vitest 3 + React Testing Library 16 + jsdom 26 | `frontend/src/App.test.tsx`, `frontend/src/ItemsList.test.tsx`, `frontend/src/test-setup.ts` |
| Backend testing | pytest 8 + httpx + FastAPI TestClient | `backend/test_health.py`, `backend/test_items.py` |
| Frontend package manager | npm | `frontend/package.json` (lockfile committed) |
| Backend package manager | pip + venv | `backend/requirements.txt` |

## Architecture Notes

- **Frontend** (`frontend/`): Vite dev server on port 5173, proxies `/api` to backend port 8000. Production build outputs to `frontend/dist/`. Scripts: `dev`, `build` (tsc + vite build), `lint` (eslint flat config), `typecheck` (tsc --noEmit), `test` (vitest run). Components: `App.tsx` (landing page + status), `ItemsList.tsx` (fetches/displays `/api/items`, includes inline creation form).
- **Backend** (`backend/`): Single-file FastAPI app in `main.py`. CORS configured for `http://localhost:5173`. Endpoints: `GET /api/health` → `{"status": "ok"}`, `GET /api/items` → `{"items": [...]}`, `POST /api/items` (body: `{name, done?}`, returns 201 with created item). Items stored in-memory with auto-incrementing IDs. Pydantic `CreateItemRequest` validates `name` is non-empty.
- **App.tsx** (`frontend/src/App.tsx`): Landing page that fetches `/api/health` on mount, displays API status (ok / error / pending), and renders `<ItemsList />` in a side-by-side card layout.
- **ItemsList.tsx** (`frontend/src/ItemsList.tsx`): Fetches `/api/items` on mount, renders loading/error/success states as a `<ul>`, and includes an inline form with text input + "Add" button to create new items via POST /api/items. On success, appends the new item to local state and clears the input. Button disabled while submitting or when input is empty.
- **Harness scripts** auto-detect ecosystem in subdirectories (`frontend/`, `backend/`), not in the repo root.
- **`.env.agent`** (gitignored, copied from `.env.agent.example`) controls branch name, permission mode, port (default 8000), health path (`/api/health`), and deployment flags.

## Implementation Status

- **Milestone 01** — Complete. Repo inspection, created `docs/agent-notes.md`.
- **Milestone 02** — Complete. Scaffold created: frontend builds, backend health endpoint works, scripts updated, docs written.
- **Milestone 03** — Complete. Test foundation added: 3 frontend component tests (Vitest + React Testing Library), 1 backend health endpoint test (pytest + TestClient), test deps added to both package files, validate-local.sh runs tests as hard requirements, documentation updated.
- **Milestone 04** — Complete. Domain feature slice added: `GET /api/items` endpoint with pytest test, `ItemsList` component with Vitest tests, wired into `App.tsx`. React act() warnings cleaned up in `App.test.tsx`. TestClient deprecation documented as follow-up.
- **Milestone 05** — Complete. Item mutation added: `POST /api/items` endpoint with Pydantic validation, 5 new backend tests, inline creation form in `ItemsList.tsx`, 4 new frontend form tests (`fireEvent`-based, no extra deps). Auto-incrementing IDs for new items.
- **Deployment** — Disabled (`DEPLOY_STAGING=false` in `.env.agent`).

## Validation Commands

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Full validation: frontend (npm install, lint, typecheck, test, build) + backend (venv setup, pip install, pytest) |
| `scripts/smoke-local.sh` | Start backend on port 8000, poll `/api/health` for up to 60s |
| `scripts/run-milestones.sh` | Run all milestones sequentially |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 (disabled) |
| `scripts/smoke-staging.sh` | Poll staging health endpoint (disabled) |

## Quick Test Commands

```bash
cd frontend && npm test       # Frontend tests: 12 (4 App + 8 ItemsList)
cd backend && source .venv/bin/activate && pytest  # Backend tests: 7 (1 health + 6 items)
```

## Known Issues

- **npm vulnerabilities**: 2 high severity vulnerabilities reported on `npm install`. May need `npm audit fix` in a future milestone.
- **Staging deployment**: Not configured (`DEPLOY_STAGING=false`, staging env vars empty).
- **smoke-local.sh non-reload mode**: Starts uvicorn without `--reload` since it's a one-shot health check, not a dev server.
- **Starlette TestClient uses httpx, not httpx2**: `starlette.testclient` prefers `httpx2` over `httpx`. Currently using `httpx>=0.28.0` in `requirements.txt`. The deprecation warning is non-blocking but should be addressed when `httpx2` stabilizes.
- **No persistence**: Items are stored in-memory and reset on server restart. A database (SQLite or PostgreSQL) should be added when persistence is needed.

## Next Recommended Milestone

**Milestone 06 — Add item update or delete.** Add `PUT/PATCH /api/items/{id}` or `DELETE /api/items/{id}` with TDD, or address npm vulnerabilities and CI pipeline setup.

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
