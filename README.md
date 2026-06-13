# My App

Application scaffold with Vite + React + TypeScript frontend and FastAPI backend.

## Quick Start

### Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API health check: http://localhost:8000/api/health

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Dev server: http://localhost:5173

### Build

```bash
cd frontend
npm run build
```

## Testing

```bash
cd frontend && npm test       # Frontend tests (Vitest + React Testing Library)
cd backend && pytest          # Backend tests (pytest + FastAPI TestClient)
```

## Validation

```bash
./scripts/validate-local.sh   # Build + lint + test both frontend and backend
./scripts/smoke-local.sh      # Start backend and check health endpoint
```

## Documentation

- [Development Setup](docs/dev-setup.md) — detailed local development guide
