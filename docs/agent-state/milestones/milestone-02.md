# Milestone 02 — Bootstrap Application Scaffold

## Goal

Create the initial web application scaffold with Vite + React + TypeScript frontend and FastAPI + Python backend. Update validation scripts to work with both services and document local development setup.

## Changes Made

### Frontend (`frontend/`) — 12 files created

Scaffolded via `npm create vite@latest` with React + TypeScript template, then customized:

| File | Purpose |
|---|---|
| `frontend/package.json` | Vite 7 + React 19 + TypeScript 5.9, scripts: dev/build/lint/typecheck/preview |
| `frontend/vite.config.ts` | Vite config with React plugin and `/api` proxy to `localhost:8000` |
| `frontend/tsconfig.json` | Project references to app + node TS configs |
| `frontend/tsconfig.app.json` | Strict TS config for React source |
| `frontend/tsconfig.node.json` | TS config for vite.config.ts |
| `frontend/eslint.config.js` | ESLint flat config with TS + React hooks + refresh plugins |
| `frontend/index.html` | Entry HTML |
| `frontend/src/main.tsx` | React entry point |
| `frontend/src/App.tsx` | Landing page ("Application scaffold is running") + health status display that fetches `/api/health` |
| `frontend/src/App.css` | App layout styles |
| `frontend/src/index.css` | Global reset + base styles |
| `frontend/src/vite-env.d.ts` | Vite client type reference |

### Backend (`backend/`) — 2 files created

| File | Purpose |
|---|---|
| `backend/main.py` | FastAPI app with CORS (allow `localhost:5173`) + `GET /api/health` → `{"status": "ok"}` |
| `backend/requirements.txt` | `fastapi>=0.115.0` + `uvicorn[standard]>=0.34.0` |

### Scripts — 2 updated

| File | Change |
|---|---|
| `scripts/validate-local.sh` | Now validates `frontend/` (npm install, lint, typecheck, build) and `backend/` (venv setup, pip install, pytest if present) as separate steps with their own subdirectories |
| `scripts/smoke-local.sh` | Rewritten to detect backend entry points (`backend/main.py`, `backend/app/main.py`, etc.), auto-create venv if needed, start uvicorn, and poll `/api/health`. Default port changed from 3000 to 8000. Health path changed from `/` to `/api/health`. |

### Documentation — 2 created

| File | Purpose |
|---|---|
| `README.md` | Quick-start instructions for frontend + backend + validation |
| `docs/dev-setup.md` | Detailed dev setup guide with prerequisites, project structure, step-by-step run instructions, and validation script usage |

### Configuration — 1 updated

| File | Change |
|---|---|
| `.gitignore` | Added `frontend/node_modules/`, `frontend/dist/`, `backend/.venv/`, `backend/__pycache__/`, `*.pyc` |

## Files Touched

| File | Action |
|---|---|
| `frontend/` (12 files) | Created — full Vite React TS scaffold |
| `backend/main.py` | Created |
| `backend/requirements.txt` | Created |
| `README.md` | Created |
| `docs/dev-setup.md` | Created |
| `scripts/validate-local.sh` | Modified — added frontend + backend sections |
| `scripts/smoke-local.sh` | Modified — backend detection, venv auto-setup, health check |
| `.gitignore` | Modified — added frontend/backend exclusions |
| `prompts/milestone-01.md` | Deleted (consumed by harness) |

## Commands/Tests Run

| Command | Result |
|---|---|
| `scripts/validate-local.sh` | **Passed** — frontend lint/typecheck/build all green; backend pip install succeeded; `pytest` not found (non-fatal, no tests exist) |
| `scripts/smoke-local.sh` (attempt 1) | **Failed** — script used `python3 -m uvicorn` but venv wasn't set up; uvicorn not installed globally |
| `scripts/smoke-local.sh` (attempt 2, after repair) | **Passed** — script auto-created venv, installed deps, started uvicorn, health check returned 200 |
| `npm run build` (frontend) | **Passed** — produced `frontend/dist/` (index.html 0.39 KB, CSS 0.94 KB, JS 194 KB gzipped to 61 KB) |
| `curl /api/health` | **Passed** — returned `{"status":"ok"}` |

`DEPLOY_STAGING=false` so staging deployment was skipped.

## Decisions Made

- **Stack**: Vite + React 19 + TypeScript 5.9 (latest stable at scaffold time) and FastAPI 0.136 + Python 3.12 + Uvicorn 0.49. Chosen to match the milestone prompt's target architecture.
- **Monorepo layout**: Frontend in `frontend/`, backend in `backend/`. Scripts detect each by checking for `package.json` / `requirements.txt` in subdirectories. No root-level `package.json` or `pyproject.toml` — the harness itself remains Bash-only.
- **Vite proxy**: Configured `/api` → `http://localhost:8000` in `vite.config.ts` so the React dev server can call the backend without CORS issues during local development.
- **CORS**: Backend allows `http://localhost:5173` (Vite dev server origin). No wildcard — explicit origin only.
- **Smoke script repair approach**: When the first smoke run failed (no uvicorn in system Python), the script was repaired to auto-create the venv and install dependencies if `.venv/bin/uvicorn` is missing. The repair added a `> /dev/null 2>&1` install step and re-pointed `START_CMD` to use `.venv/bin/uvicorn`.
- **No tests yet**: pytest is not in `requirements.txt` and no test files exist. The validate script runs `pytest || true` so missing tests don't block the pipeline, but this should be addressed in the next milestone.
- **ESLint flat config**: Used the modern ESLint 9 flat config format (`eslint.config.js`) with TypeScript ESLint 8.x, React Hooks plugin, and React Refresh plugin.

## Known Issues

- **No pytest tests**: `backend/requirements.txt` does not include `pytest`. `validate-local.sh` runs `.venv/bin/pytest || true` which silently passes when pytest is absent. This means backend validation is currently a no-op beyond dependency installation.
- **npm vulnerabilities**: `npm install` reports 2 high severity vulnerabilities. These are in dev/build dependencies; review and fix with `npm audit fix` in a future milestone if safe.
- **Smoke script first-run failure**: The initial smoke script tried `python3 -m uvicorn` without checking if the venv existed. Fixed in a repair pass, but the first milestone-02 smoke run failed. The repaired version is in the working tree.
- **No hot-reload for backend in smoke**: `smoke-local.sh` starts uvicorn without `--reload` since it's a one-shot health check, not a dev server.

## Suggested Next Steps

1. **Milestone 03**: Add pytest to `backend/requirements.txt`, write backend tests (at minimum: test `/api/health` returns 200 and `{"status": "ok"}`). Consider adding Vitest for frontend component tests.
2. **npm audit**: Review and address the 2 high severity npm vulnerabilities.
3. **Add more API endpoints**: Beyond health, define the actual application domain endpoints.
4. **Frontend routing**: Add React Router if the app needs multiple pages.
5. **After tests exist**: `validate-local.sh` will actually catch regressions.
6. **When ready for staging**: Set `DEPLOY_STAGING=true` and fill in `SERVER_HOST`, `SERVER_USER`, `APP_DIR`, `STAGING_URL` in `.env.agent`.
