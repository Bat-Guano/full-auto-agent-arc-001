# Milestone 07 — SQLite Persistence

**Status**: Complete

## What Changed

Replaced the process-local in-memory `ITEMS` list with SQLite-backed persistent storage.

### New Files

| File | Purpose |
|---|---|
| `backend/storage.py` | SQLite storage layer — init, seed, CRUD operations |
| `backend/conftest.py` | Test isolation — sets `ITEMS_DB_PATH` to a temp file before any test imports |
| `backend/test_persistence.py` | 6 persistence tests — seeding, POST/GET roundtrip, PATCH/GET roundtrip, DELETE/GET roundtrip, auto-increment |

### Modified Files

| File | Changes |
|---|---|
| `backend/main.py` | Replaced `ITEMS` list with `storage.*` calls. Added `storage.init_db()` + `storage.seed_if_empty()` at module level. Endpoint handlers now delegate to storage layer. |
| `backend/test_items.py` | Removed `from main import ITEMS`. Rewrote assertions to verify state via API (GET) instead of direct list access. Uses shared temp DB from `conftest.py`. |
| `backend/test_health.py` | Uses shared temp DB from `conftest.py` (no functional change). |
| `docs/agent-state/current-state.md` | Updated architecture notes, implementation status, test counts, known issues, next milestone. |
| `docs/dev-setup.md` | Added project structure entries for new files, environment variable table, database reset instructions. |

### Design Decisions

- **SQLite from stdlib** (`import sqlite3`) — no new dependencies.
- **Per-request connections** — each `storage.*` function opens and closes its own connection, avoiding threading issues with FastAPI's async runtime.
- **`ITEMS_DB_PATH` env var** — defaults to `./items.db` (relative to `backend/` cwd). Override for different environments.
- **WAL journal mode** — set on each connection for better read concurrency.
- **`AUTOINCREMENT`** — ensures IDs are never reused, even after deletes (matches previous in-memory auto-increment behavior).
- **Module-level init** — `init_db()` and `seed_if_empty()` called at import time in `main.py`. Tests control this via `ITEMS_DB_PATH` set in `conftest.py` before `main` is imported.
- **Pydantic `min_length=1`** — retained for `UpdateItemRequest.name` to keep validation consistent (this means you cannot clear a name with an empty string).
- **Test isolation** — `conftest.py` creates a single session-scoped temp database. All test files share it (matching the previous behavior where all tests shared the global `ITEMS` list).

### API Contract Preservation

All endpoints return the same shapes and status codes:

| Endpoint | Status | Body |
|---|---|---|
| `GET /api/items` | 200 | `{"items": [{"id": int, "name": str, "done": bool}, ...]}` |
| `POST /api/items` | 201 | `{"id": int, "name": str, "done": bool}` |
| `PATCH /api/items/{id}` | 200 | `{"id": int, "name": str, "done": bool}` |
| `DELETE /api/items/{id}` | 200 | `{"id": int, "name": str, "done": bool}` |
| All error responses | 404/422 | unchanged |

The frontend requires no changes — the API contract is identical.

### Test Counts

| Suite | Before | After |
|---|---|---|
| Backend (pytest) | 14 (1 health + 13 items) | 20 (1 health + 13 items + 6 persistence) |
| Frontend (Vitest) | 18 | 18 (unchanged) |

### Persistence Behavior

- Items survive server restarts when the same `ITEMS_DB_PATH` is used.
- Default starter items are seeded exactly once — the first time the database is created.
- To reset: delete the `.db` file and restart.
- Tests use a temp file that is discarded after the test run — the dev/production database is never touched by tests.

### Validation Commands

```bash
# Full validation (frontend + backend)
./scripts/validate-local.sh

# Backend tests only
cd backend && source .venv/bin/activate && pytest  # 20 tests (1 health + 13 items + 6 persistence)

# Frontend tests only
cd frontend && npm test  # 18 tests (4 App + 14 ItemsList)

# Local smoke (health check only — will be expanded in milestone-08)
./scripts/smoke-local.sh
```

### Known Issues Carried Forward

| Issue | Notes |
|---|---|
| npm vulnerabilities (2 high) | Deferred; `npm audit fix --force` not permitted |
| Starlette `httpx` deprecation | TestClient prefers `httpx2`; harmless, deferred to when `httpx2` stabilizes |
| Staging deployment disabled | `DEPLOY_STAGING=false`, no remote config |
| No inline name editing | ItemsList has create/toggle/delete but no inline edit mode |
| No delete confirmation | Delete is immediate with no confirmation dialog |
| Per-request SQLite connections | Fine for low-traffic dev; connection pooling would help under concurrency |
