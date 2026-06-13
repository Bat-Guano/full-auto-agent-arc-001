# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** that now contains a **full-stack web application scaffold**: Vite + React + TypeScript frontend with a FastAPI + Python backend. The harness runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops.

## Tech Stack (Application Level)

| Layer | Technology | Key Files |
|---|---|---|
| Frontend | Vite 7 + React 19 + TypeScript 5.9 | `frontend/package.json`, `frontend/vite.config.ts` |
| Backend | FastAPI 0.136 + Python 3.12 + Uvicorn 0.49 | `backend/main.py`, `backend/requirements.txt` |
| Frontend testing | Vitest 3 + React Testing Library 16 + jsdom 26 | `frontend/src/App.test.tsx`, `frontend/src/test-setup.ts` |
| Backend testing | pytest 8 + httpx + FastAPI TestClient | `backend/test_health.py` |
| Frontend package manager | npm | `frontend/package.json` (lockfile committed) |
| Backend package manager | pip + venv | `backend/requirements.txt` |

## Architecture Notes

- **Frontend** (`frontend/`): Vite dev server on port 5173, proxies `/api` to backend port 8000. Production build outputs to `frontend/dist/`. Scripts: `dev`, `build` (tsc + vite build), `lint` (eslint flat config), `typecheck` (tsc --noEmit), `test` (vitest run).
- **Backend** (`backend/`): Single-file FastAPI app in `main.py`. CORS configured for `http://localhost:5173`. Only endpoint: `GET /api/health` → `{"status": "ok"}`.
- **App.tsx** (`frontend/src/App.tsx`): Landing page that fetches `/api/health` on mount and displays API status (ok / error / pending).
- **Harness scripts** auto-detect ecosystem in subdirectories (`frontend/`, `backend/`), not in the repo root.
- **`.env.agent`** (gitignored, copied from `.env.agent.example`) controls branch name, permission mode, port (default 8000), health path (`/api/health`), and deployment flags.

## Implementation Status

- **Milestone 01** — Complete. Repo inspection, created `docs/agent-notes.md`.
- **Milestone 02** — Complete. Scaffold created: frontend builds, backend health endpoint works, scripts updated, docs written.
- **Milestone 03** — Complete. Test foundation added: 3 frontend component tests (Vitest + React Testing Library), 1 backend health endpoint test (pytest + TestClient), test deps added to both package files, validate-local.sh runs tests as hard requirements, documentation updated.
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
cd frontend && npm test       # Frontend tests (Vitest + React Testing Library)
cd backend && source .venv/bin/activate && pytest  # Backend tests (pytest)
```

## Known Issues

- **npm vulnerabilities**: 2 high severity vulnerabilities reported on `npm install`. May need `npm audit fix` in a future milestone.
- **Staging deployment**: Not configured (`DEPLOY_STAGING=false`, staging env vars empty).
- **smoke-local.sh non-reload mode**: Starts uvicorn without `--reload` since it's a one-shot health check, not a dev server.

## Next Recommended Milestone

**Milestone 04 — Define the application domain.** Add at least one domain-specific API endpoint (e.g., `GET /api/items` or similar) with corresponding tests, and wire it into the frontend with a basic UI component. Use TDD — write the backend test first, then the endpoint, then the frontend test, then the UI.

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
