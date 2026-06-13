# Development Setup

This document explains how to run the application locally for development.

## Prerequisites

- **Node.js** >= 18 (tested with v24)
- **npm** >= 9
- **Python** >= 3.10 (tested with 3.12)
- **pip**

## Project Structure

```
my-app/
├── frontend/          # Vite + React + TypeScript
│   ├── src/
│   │   ├── App.tsx            # Main app component (health + items)
│   │   ├── App.test.tsx       # App component tests
│   │   ├── App.css            # App styles (status-card, items-card)
│   │   ├── ItemsList.tsx      # Items list component (fetches /api/items)
│   │   ├── ItemsList.test.tsx # ItemsList component tests
│   │   ├── main.tsx           # React entry point
│   │   └── index.css          # Global styles
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
├── backend/           # FastAPI + Python + SQLite
│   ├── main.py            # API app with /api/health and /api/items
│   ├── storage.py         # SQLite storage layer
│   ├── conftest.py        # Test database isolation
│   ├── test_health.py     # Health endpoint tests
│   ├── test_items.py      # Items endpoint tests
│   ├── test_persistence.py # Persistence-specific tests
│   ├── requirements.txt
│   └── .venv/             # Local Python venv (gitignored)
├── scripts/
│   ├── validate-local.sh  # Build + lint both frontend and backend
│   └── smoke-local.sh     # Start backend and check health endpoint
└── docs/
    └── dev-setup.md       # This file
```

## Quick Start

### 1. Backend (FastAPI)

```bash
cd backend

# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the development server (port 8000)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API is now running at http://localhost:8000.

Verify it works:

```bash
curl http://localhost:8000/api/health
# Expected: {"status":"ok"}

curl http://localhost:8000/api/items
# Expected: {"items":[{"id":1,"name":"Define project scope","done":true},...]}
```

### 2. Frontend (Vite + React)

```bash
cd frontend

# Install dependencies
npm install

# Run the development server (port 5173)
npm run dev
```

The frontend is now running at http://localhost:5173.

The Vite dev server proxies `/api` requests to the backend at `http://localhost:8000`, so the frontend can call `/api/health` without CORS issues during development.

### 3. Build Frontend for Production

```bash
cd frontend
npm run build
```

Output goes to `frontend/dist/`.

## Running Tests

### Frontend Tests

```bash
cd frontend
npm test
```

Frontend tests use [Vitest](https://vitest.dev/) with [React Testing Library](https://testing-library.com/react) and jsdom. Tests are located alongside source files (e.g., `src/App.test.tsx`, `src/ItemsList.test.tsx`).

### Backend Tests

```bash
cd backend
source .venv/bin/activate
pytest
```

Backend tests use [pytest](https://docs.pytest.org/) and FastAPI's `TestClient`. Tests are located in the `backend/` directory (e.g., `test_health.py`, `test_items.py`).

## Running Validation Scripts

### validate-local.sh

Validates both frontend and backend:

```bash
./scripts/validate-local.sh
```

This runs:
- Frontend: `npm install`, `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`
- Backend: virtualenv setup, `pip install`, `pytest`

### smoke-local.sh

Starts the backend and checks the health endpoint:

```bash
./scripts/smoke-local.sh
```

This starts the FastAPI server on port 8000 and polls `/api/health` until it responds.

## Environment Variables

The application uses `.env.agent` for agent automation. Do not commit this file.

For local development, no environment variables are required — the defaults work out of the box.

| Variable | Default | Purpose |
|---|---|---|
| `ITEMS_DB_PATH` | `./items.db` (relative to `backend/`) | SQLite database file path for item storage |
| `PORT` | `8000` | Backend listen port |

**Resetting the database:** Delete `backend/items.db` and restart the server — the database will be recreated with default starter items automatically.
