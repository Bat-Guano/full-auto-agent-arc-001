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
│   │   ├── App.tsx    # Main app component
│   │   ├── App.css    # App styles
│   │   ├── main.tsx   # React entry point
│   │   └── index.css  # Global styles
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
├── backend/           # FastAPI + Python
│   ├── main.py        # API app with /api/health
│   ├── requirements.txt
│   └── .venv/         # Local Python venv (gitignored)
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

## Running Validation Scripts

### validate-local.sh

Validates both frontend and backend:

```bash
./scripts/validate-local.sh
```

This runs:
- Frontend: `npm install`, `npm run lint`, `npm run typecheck`, `npm run build`
- Backend: virtualenv setup, `pip install`, `pytest` (if tests exist)

### smoke-local.sh

Starts the backend and checks the health endpoint:

```bash
./scripts/smoke-local.sh
```

This starts the FastAPI server on port 8000 and polls `/api/health` until it responds.

## Environment Variables

The application uses `.env.agent` for agent automation. Do not commit this file.

For local development, no environment variables are required — the defaults work out of the box.
