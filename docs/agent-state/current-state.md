# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** that now contains a **full-stack web application scaffold**: Vite + React + TypeScript frontend with a FastAPI + Python backend. The harness runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops.

## Tech Stack (Application Level)

| Layer | Technology | Key Files |
|---|---|---|
| Frontend | Vite 7 + React 19 + TypeScript 5.9 | `frontend/package.json`, `frontend/vite.config.ts` |
| Backend | FastAPI 0.136 + Python 3.12 + Uvicorn 0.49 | `backend/main.py`, `backend/requirements.txt` |
| Frontend testing | Vitest 3 + React Testing Library 16 + jsdom 26 | `frontend/src/App.test.tsx`, `frontend/src/ItemsList.test.tsx`, `frontend/src/test-setup.ts` |
| Backend testing | pytest 8 + httpx2 + FastAPI TestClient | `backend/test_health.py`, `backend/test_items.py`, `backend/test_readiness.py` |
| Frontend package manager | npm | `frontend/package.json` (lockfile committed) |
| Backend package manager | pip + venv | `backend/requirements.txt` |

## Architecture Notes

- **Frontend** (`frontend/`): Vite dev server on port 5173, proxies `/api` to backend port 8000. Production build outputs to `frontend/dist/`. Scripts: `dev`, `build` (tsc + vite build), `lint` (eslint flat config), `typecheck` (tsc --noEmit), `test` (vitest run). Components:
  - `App.tsx` — Landing page that fetches `/api/health` on mount, displays API status (ok / error / pending), and renders `<ItemsList />` in a side-by-side card layout.
  - `ItemsList.tsx` — Container component: fetches `/api/items` on mount, manages items state, provides `handleSubmit` (POST), `handleToggle` (PATCH done), `handleDelete` (DELETE), and `handleUpdate` (PATCH name) callbacks. Renders loading/error/empty/success states, the inline creation form, and delegates row rendering to `<ItemRow />`. Returns a `Promise<boolean>` from `handleUpdate` so the child can react to save success/failure.
  - `ItemRow.tsx` — Presentational row component with three visual modes:
    - **Display**: checkbox (for toggle) + item name + Edit button + Delete button
    - **Editing**: disabled checkbox + text input (pre-filled with current name) + Save button + Cancel button. Save calls `onUpdate` (PATCH name) and exits edit mode on success.
    - **Delete confirmation**: confirmation text ("Delete "name"?") + Confirm Delete button (triggers actual DELETE) + Cancel button (returns to display mode).
  - Styles in `App.css` cover all three modes, including `.btn-edit`, `.btn-save`, `.btn-cancel`, `.btn-confirm-delete`, `.btn-cancel-delete`, `.btn-delete`, `.edit-input`, `.confirm-text`, `.empty-message`, disabled states, and hover effects.
- **Backend** (`backend/`): FastAPI app split across `main.py` (routes + models) and `storage.py` (SQLite persistence). CORS configured for `http://localhost:5173`. Endpoints: `GET /api/health` → `{"status": "ok"}`, `GET /api/ready` → `{"status": "ok", "database": "connected"}` (verifies SQLite connectivity; returns 503 if the database is unreachable), `GET /api/items` → `{"items": [...]}`, `POST /api/items` (body: `{name, done?}`, returns 201), `PATCH /api/items/{item_id}` (body: `{name?, done?}`, partial update), `DELETE /api/items/{item_id}` (returns deleted item). Items stored in SQLite (`./items.db` by default, overridable via `ITEMS_DB_PATH` env var) with auto-incrementing IDs. Database initialised and seeded with four default starter items on first import. Pydantic models: `CreateItemRequest` (name: required, done: optional), `UpdateItemRequest` (name: optional, done: optional — both with client-controlled semantics for partial updates).
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
- **Milestone 09** — Complete. UX polish without backend changes:
  - Extracted `ItemRow.tsx` as a separate presentational component with three visual modes (display, editing, delete confirmation).
  - Added inline name editing via existing PATCH endpoint — Edit button → text input + Save/Cancel.
  - Added delete confirmation — Delete button → "Delete 'name'?" with Confirm Delete/Cancel.
  - Improved empty state — "No items yet. Add one above." message when items list is empty.
  - Polished CSS: new button classes for edit/save/cancel/confirm-delete/cancel-delete, disabled states, hover effects, edit input styling, confirmation text styling, empty message styling.
  - 6 new frontend tests: inline editing (enter edit, save, cancel, error on update failure) + delete confirmation (confirm, cancel). ItemsList tests grew from 14 to 20, total frontend tests from 18 to 24. Backend unchanged (22 tests).
- **Milestone 10** — Complete. Dependency and security hardening:
  - Fixed Starlette httpx deprecation: `requirements.txt` updated from `httpx>=0.28.0` to `httpx2>=2.0.0`. httpx2 2.4.0 installed. No deprecation warnings in pytest output.
  - Regenerated `frontend/package-lock.json` for fresh dependency resolution (267 packages).
  - `npm audit fix` (without `--force`) applied 0 changes — no semver-compatible fixes exist for remaining vulnerabilities.
  - 5 high-severity npm vulnerabilities remain, all from the esbuild → vite → vitest chain. Root cause: esbuild < 0.28.0 (locked at 0.27.7 via vite 7.3.5). Fix requires vite ^8.0.16 (breaking change). Documented with advisory URLs, risk assessment, and upgrade path. See `docs/agent-state/milestones/milestone-10.md` for full vulnerability table.
  - validate-local and smoke-local both pass cleanly.
- **Milestone 11** — Complete. Staging/Deployment readiness hardening:
  - Created `scripts/staging-preflight.sh` (160 lines) — validates staging env vars without printing secrets, three modes (all/`--deploy`/`--smoke`), DEPLOY_STAGING flag awareness, actionable guidance on missing vars, exit codes 0/1/2.
  - All three staging scripts pass `bash -n` syntax checks.
  - `deploy-staging.sh` and `smoke-staging.sh` still use `:?` hard-fail — dry-run modes deferred to milestone-12.
  - See `docs/agent-state/milestones/milestone-11.md` for full details.
- **Deployment** — Disabled (`DEPLOY_STAGING=false` in `.env.agent`). Preflight check available to validate staging readiness.

## Test Counts

| Suite | Count | Breakdown |
|---|---|---|
| Backend (pytest) | 22 | 1 health + 2 readiness + 13 items + 6 persistence |
| Frontend (Vitest) | 24 | 4 App + 20 ItemsList |

## Validation Commands

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Full validation: frontend (npm install, lint, typecheck, test, build) + backend (venv setup, pip install, pytest) |
| `scripts/smoke-local.sh` | Start backend, check `/api/health`, `/api/ready`, and `/api/items` |
| `scripts/run-milestones.sh` | Run all milestones sequentially |
| `scripts/staging-preflight.sh` | Validate staging env vars (no secrets printed). Modes: default, `--deploy`, `--smoke` |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 (disabled; dry-run pending m12) |
| `scripts/smoke-staging.sh` | Poll staging health endpoint (disabled; graceful skip pending m12) |

## Quick Test Commands

```bash
cd frontend && npm test       # Frontend tests: 24 (4 App + 20 ItemsList)
cd backend && source .venv/bin/activate && pytest  # Backend tests: 22 (1 health + 2 readiness + 13 items + 6 persistence)
```

## Known Issues

- **npm vulnerabilities (5 high)**: All from esbuild < 0.28.0 in the Vite toolchain (`vite 7.3.5` → `esbuild 0.27.7`). Fix requires vite 8.0.16+ (breaking change, needs `npm audit fix --force`). Details: GHSA-gv7w-rqvm-qjhr (Deno RCE via `NPM_CONFIG_REGISTRY`) and GHSA-g7r4-m6w7-qqqr (Windows dev server file read). Both are dev-tooling issues, not production runtime risks. Linux-only project; Windows advisory not applicable. Documented in `docs/agent-state/milestones/milestone-10.md`. Recommendation: defer vite upgrade to m12+.
- **Staging deployment**: Not configured (`DEPLOY_STAGING=false`, staging env vars empty). Preflight check available (`scripts/staging-preflight.sh`) — validates readiness without printing secrets. `deploy-staging.sh` and `smoke-staging.sh` still use `:?` hard-fail when vars are missing — dry-run modes targeted by milestone-12.
- **smoke-local.sh non-reload mode**: Starts uvicorn without `--reload` since it's a one-shot health check, not a dev server.
- **CI detects npm vulnerabilities but does not fail on them**: The GitHub Actions workflow runs `npm ci` which reports the 5 high-severity advisories but does not block the pipeline.
- **Per-request SQLite connections**: Fine for low-traffic dev; connection pooling would help under concurrency.

## Next Recommended Milestone

**Milestone 12 — Staging dry-run modes** (`prompts/milestone-12.md`): Add `--dry-run` flag to `deploy-staging.sh` (run preflight + print what would happen without actually deploying), update `smoke-staging.sh` to gracefully skip when `STAGING_URL` is unset (with a clear message), create `docs/staging-setup.md` with end-to-end configuration guide, write shell-level tests for the preflight script.

**Milestone 13 — Vite 8.x upgrade**: Resolve the 5 remaining high-severity npm vulnerabilities by upgrading vite to ^8.0.16 (brings esbuild ≥ 0.28.0). Requires isolated testing of build output and dev server behavior.

## Rules for the Next Agent

- Do NOT edit `.env`, `.env.local`, `.env.agent`, or any secret files.
- Do NOT hardcode secrets.
- Do NOT disable tests, linting, type checks, or build checks to make the pipeline pass.
- Do NOT remove tests to make the pipeline pass.
- Do NOT use `npm audit fix --force`.
- Prefer small, reversible, testable changes.
- Follow existing project conventions.
- Before editing, read `docs/agent-state/current-state.md` and relevant milestone files in `docs/agent-state/milestones/`.
- The external runner (`run-milestones.sh`) owns deployment — do not deploy manually.
- The frontend is in `frontend/`, backend in `backend/` — scripts reference these subdirectories, not the repo root.
- `ItemRow.tsx` is the row-level presentational component; `ItemsList.tsx` is the container. Keep this separation — add new per-item features to `ItemRow.tsx`.
- When adding tests, use `fireEvent` for all interactions, `aria-label` for targeting, and progressive mock helpers as established in `ItemsList.test.tsx`.
- 5 high npm vulnerabilities are documented and accepted as known issues (esbuild→vite chain, requires breaking vite upgrade). Do not re-investigate unless a new advisory appears.
