# Milestone 05 — Add Item Mutation (POST /api/items)

## Goal

Add `POST /api/items` to create new in-memory items, with backend TDD first and a frontend form wired into the existing `ItemsList` UI.

## Changes Made

### Backend — 1 file modified

| File | Action | Purpose |
|---|---|---|
| `backend/test_items.py` | Modified | Added 5 new pytest tests: create item 201, create with done=true, missing name 422, empty name 422, created item appears in GET |
| `backend/main.py` | Modified | Added `CreateItemRequest` Pydantic model (name: str with min_length=1, done: bool=false), added `POST /api/items` endpoint returning 201 with auto-assigned id |

### Frontend — 2 files modified, 1 new dependency avoided

| File | Action | Purpose |
|---|---|---|
| `frontend/src/ItemsList.tsx` | Modified | Added form with text input and submit button. On submit: POSTs to /api/items, appends new item to list, clears input. Shows submit error on failure. Button disabled while submitting or when input is empty. |
| `frontend/src/ItemsList.test.tsx` | Modified | Added 4 new tests in "create item form" describe block: form renders, successful creation appends item and clears input, POST error shows alert, button disabled when input empty. Uses `fireEvent` (no new deps). |
| `frontend/src/App.css` | Modified | Added `.add-item-form` styles for input, button (primary blue), disabled state, and error alert |

### Documentation — 3 files

| File | Action | Purpose |
|---|---|---|
| `docs/agent-state/current-state.md` | Modified | Updated implementation status, architecture notes, endpoints list, test counts, next milestone |
| `docs/agent-state/milestones/milestone-05.md` | Created | This summary |
| Project memory | Modified | Updated `project-state-m04.md` → renamed to reflect m05 state |

## Files Touched Summary

| File | Action |
|---|---|
| `backend/test_items.py` | Modified (added 5 POST tests) |
| `backend/main.py` | Modified (added CreateItemRequest model + POST /api/items) |
| `frontend/src/ItemsList.tsx` | Modified (added creation form) |
| `frontend/src/ItemsList.test.tsx` | Modified (added 4 form tests) |
| `frontend/src/App.css` | Modified (added form styles) |
| `docs/agent-state/milestones/milestone-05.md` | Created |
| `docs/agent-state/current-state.md` | Modified (updated status/arch) |

## Decisions Made

- **Pydantic validation for name**: Used `Field(..., min_length=1)` on `name` to enforce non-empty. FastAPI automatically returns 422 for missing or empty name fields.
- **Auto-incrementing IDs**: `next_id = max(existing_ids) + 1` pattern. Simple, deterministic, works for in-memory storage. Not thread-safe — acceptable until a database is added.
- **POST returns 201**: Standard REST semantics for resource creation.
- **Form in ItemsList, not separate component**: Kept the form inside `ItemsList.tsx` rather than creating a separate `CreateItemForm` component. The form is tightly coupled to the items list (it appends to it), so keeping them together avoids prop-drilling. Can be extracted later if complexity grows.
- **fireEvent instead of userEvent**: Used `fireEvent` from `@testing-library/react` (already installed) instead of adding `@testing-library/user-event` as a new dependency. Keeps the dependency footprint minimal.
- **Optimistic UI append**: On successful POST, the new item is appended to local state via `setItems(prev => [...prev, newItem])`. No re-fetch of the full list. Simple and responsive.

## Commands/Tests Run

| Command | Expected Result |
|---|---|
| `cd backend && source .venv/bin/activate && pytest` | **7/7 pass** — test_health (1) + test_items original (1) + test_items new POST tests (5) |
| `cd frontend && npm test` | **12/12 pass** — 4 App tests + 4 original ItemsList tests + 4 new form tests |
| `scripts/validate-local.sh` | **Pass** — full validation (no regressions) |
| `scripts/smoke-local.sh` | **Pass** — health endpoint responds; items endpoint returns data; POST creates items |

## Known Issues

- Same as milestone-04: 2 high-severity npm vulnerabilities, Starlette TestClient httpx deprecation, no database, staging deployment disabled.
- In-memory items reset on server restart — expected until a database is added.

## What Was Not Done

- No database or persistence (by design — milestone constraint)
- No authentication (by design — milestone constraint)
- No item deletion or update (only POST — future milestone)
- No npm audit fix (deferred)

## Suggested Next Steps

1. **Milestone 06**: Add item update (PUT/PATCH) or delete (DELETE) mutation with TDD.
2. **Address npm vulnerabilities**: `npm audit fix` or targeted resolution.
3. **httpx2 migration**: Once confirmed stable, replace `httpx` with `httpx2` in `requirements.txt`.
4. **Add a database**: SQLite or PostgreSQL for persistence.
