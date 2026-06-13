# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** that now contains a **full-stack web application scaffold**: Vite + React + TypeScript frontend with a FastAPI + Python backend. The harness runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops.

## Tech Stack (Application Level)

| Layer | Technology | Key Files |
|---|---|---|
| Frontend | Vite 7 + React 19 + TypeScript 5.9 | `frontend/package.json`, `frontend/vite.config.ts` |
| Backend | FastAPI 0.136 + Python 3.12 + Uvicorn 0.49 | `backend/main.py`, `backend/requirements.txt` |
| Frontend package manager | npm | `frontend/package.json` (no lockfile committed) |
| Backend package manager | pip + venv | `backend/requirements.txt` |

## Architecture Notes

- **Frontend** (`frontend/`): Vite dev server on port 5173, proxies `/api` to backend port 8000. Production build outputs to `frontend/dist/`. Scripts: `dev`, `build` (tsc + vite build), `lint` (eslint flat config), `typecheck` (tsc --noEmit).
- **Backend** (`backend/`): Single-file FastAPI app in `main.py`. CORS configured for `http://localhost:5173`. Only endpoint: `GET /api/health` → `{"status": "ok"}`.
- **App.tsx** (`frontend/src/App.tsx`): Landing page that fetches `/api/health` on mount and displays API status (ok / error / pending).
- **Harness scripts** auto-detect ecosystem in subdirectories (`frontend/`, `backend/`), not in the repo root.
- **`.env.agent`** (gitignored, copied from `.env.agent.example`) controls branch name, permission mode, port (default 8000), health path (`/api/health`), and deployment flags.

## Implementation Status

- **Milestone 01** — Complete. Repo inspection, created `docs/agent-notes.md`.
- **Milestone 02** — Complete. Scaffold created: frontend builds, backend health endpoint works, scripts updated, docs written. **No pytest tests exist yet** (non-blocking; harness treats missing pytest as `|| true`).
- **Deployment** — Disabled (`DEPLOY_STAGING=false` in `.env.agent`).

## Validation Commands

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Build + lint both `frontend/` (npm install, lint, typecheck, build) and `backend/` (pip install, pytest if present) |
| `scripts/smoke-local.sh` | Start backend on port 8000, poll `/api/health` for up to 60s |
| `scripts/run-milestones.sh` | Run all milestones sequentially |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 (disabled) |
| `scripts/smoke-staging.sh` | Poll staging health endpoint (disabled) |

## Known Issues

- **No pytest tests**: `backend/requirements.txt` does not include `pytest`. `validate-local.sh` runs `.venv/bin/pytest || true` which silently passes. Add `pytest` to requirements.txt and write tests before milestone-03 validation.
- **npm vulnerabilities**: 2 high severity vulnerabilities reported on `npm install`. May need `npm audit fix` in a future milestone.
- **smoke-local.sh venv handling**: Script now correctly creates venv and installs deps before starting uvicorn, but the initial milestone-02 run required a repair pass because the original smoke script tried `python3 -m uvicorn` without ensuring the venv was set up. Current version has proper fallback logic — if `requirements.txt` exists and `.venv/bin/uvicorn` is missing, it auto-creates the venv.
- **Staging deployment**: Not configured (`DEPLOY_STAGING=false`, staging env vars empty).

## Next Recommended Milestone

**Milestone 03 — Add backend tests and frontend component tests.** Write pytest tests for the `/api/health` endpoint (and any new endpoints). Add Vitest or similar for frontend component tests. Ensure `validate-local.sh` catches real failures.

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
