# Milestone 06 — Add Item Update and Delete Mutations

## Goal

Add `PATCH /api/items/{item_id}` and `DELETE /api/items/{item_id}` with backend TDD and toggle/delete controls in the existing `ItemsList` UI. Achieve full CRUD coverage for the in-memory item store.

## Changes Made

### Backend — 2 files modified

| File | Action | Purpose |
|---|---|---|
| `backend/test_items.py` | Modified | Added 7 new pytest tests: update item name 200, update item done 200, update missing item 404, update empty name 422, delete item 200, delete missing item 404, deleted item not in GET |
| `backend/main.py` | Modified | Added `UpdateItemRequest` Pydantic model (name: Optional[str] with min_length=1, done: Optional[bool]), `PATCH /api/items/{item_id}` (partial update), `DELETE /api/items/{item_id}` (returns deleted item) |

### Frontend — 3 files modified

| File | Action | Purpose |
|---|---|---|
| `frontend/src/ItemsList.tsx` | Modified | Added `handleToggle` (calls PATCH, updates item in local state), `handleDelete` (calls DELETE, removes item from local state), `actionError` state for mutation errors, checkbox with `aria-label` per item, delete button with `aria-label` per item |
| `frontend/src/ItemsList.test.tsx` | Modified | Added `mockFetchForGetPostPatchDelete` helper, 6 new tests in "toggle and delete" describe: renders checkbox per item (checked state verified), toggles done on click, renders delete button per item, removes item on delete, error on toggle failure, error on delete failure |
| `frontend/src/App.css` | Modified | Added styles for `.item-done` (green, line-through), `.item-pending`, checkbox layout, delete button (red outlined, red solid on hover), action error alert |

## Files Touched Summary

| File | Action |
|---|---|
| `backend/test_items.py` | Modified (added 7 mutation tests: 4 PATCH + 3 DELETE) |
| `backend/main.py` | Modified (added UpdateItemRequest model + PATCH + DELETE endpoints) |
| `frontend/src/ItemsList.tsx` | Modified (added toggle + delete handlers, checkbox + delete button UI, actionError state) |
| `frontend/src/ItemsList.test.tsx` | Modified (added mockFetchForGetPostPatchDelete helper, 6 toggle/delete tests) |
| `frontend/src/App.css` | Modified (added checkbox, delete button, done/pending, action error styles) |
| `docs/agent-state/milestones/milestone-06.md` | Created |
| `docs/agent-state/current-state.md` | Modified (updated status, endpoints, test counts, next milestone) |

## Decisions Made

- **PATCH for partial updates**: Used `PATCH /api/items/{item_id}` with `UpdateItemRequest` where both `name` and `done` are optional. The endpoint only updates fields that are provided. This allows clients to toggle done status without sending the full item body.
- **Pydantic `Optional[str]` with `min_length=1`**: The `name` field on `UpdateItemRequest` uses `Field(None, min_length=1)` — `None` means "not provided" (skip update), while providing an empty string triggers 422 validation. This is a clean partial-update pattern.
- **DELETE returns 200 with deleted item**: Standard REST convention. The client receives the deleted item as confirmation, then removes it from local state optimistically.
- **Optimistic local state updates**: On successful PATCH, the item is updated in local state via `setItems(prev => prev.map(...))`. On successful DELETE, the item is removed via `setItems(prev => prev.filter(...))`. No re-fetch of the full list. Simple and responsive.
- **Separate `actionError` state**: Mutation errors (toggle/delete failures) use `actionError` state, distinct from `submitError` (create failures) and the initial fetch `error` state. Each error type has its own `<p role="alert">` element, so multiple errors don't overwrite each other.
- **Checkbox `aria-label` for testability**: Each checkbox and delete button uses `aria-label` (e.g., `Toggle ${item.name}`, `Delete ${item.name}`) so tests can target specific items by label text rather than relying on DOM traversal or data attributes.
- **fireEvent over userEvent**: Continued using `fireEvent` for all interactions (checkbox clicks, button clicks) to avoid adding `@testing-library/user-event` as a dependency.
- **CSS classes for done/pending**: `.item-done` (green, line-through) and `.item-pending` styles applied via className on each `<li>`. No conditional rendering of the item name — visual strikethrough is CSS-only.

## Commands/Tests Run

| Command | Expected Result |
|---|---|
| `cd backend && source .venv/bin/activate && pytest` | **14/14 pass** — test_health (1) + test_items: GET (1) + POST (5) + PATCH (4) + DELETE (3) |
| `cd frontend && npm test` | **18/18 pass** — 4 App tests + 4 original ItemsList tests + 4 form tests + 6 toggle/delete tests |
| `scripts/validate-local.sh` | **Pass** — full validation (no regressions) |
| `scripts/smoke-local.sh` | **Pass** — health endpoint responds; items list returns data; items can be created, toggled, and deleted end-to-end |

## Endpoints Summary (Post-Milestone)

| Method | Path | Status | Body | Response |
|---|---|---|---|---|
| GET | `/api/health` | 200 | — | `{"status": "ok"}` |
| GET | `/api/items` | 200 | — | `{"items": [...]}` |
| POST | `/api/items` | 201 | `{name, done?}` | created item |
| PATCH | `/api/items/{id}` | 200 | `{name?, done?}` | updated item |
| PATCH | `/api/items/{id}` | 404 | `{name?, done?}` | `{"detail": "Item not found"}` |
| PATCH | `/api/items/{id}` | 422 | `{name: ""}` | validation error |
| DELETE | `/api/items/{id}` | 200 | — | deleted item |
| DELETE | `/api/items/{id}` | 404 | — | `{"detail": "Item not found"}` |

## Known Issues

- Same as milestone-05: 2 high-severity npm vulnerabilities, Starlette TestClient httpx deprecation, no database, staging deployment disabled.
- In-memory items reset on server restart — expected until a database is added.
- Item names cannot be edited inline (only toggled and deleted) — inline editing is deferred to a future milestone.
- All mutation controls live in `ItemsList.tsx` — component may benefit from extraction if complexity grows.

## What Was Not Done

- No inline name editing (deferred — scope kept to toggle + delete)
- No confirmation dialog for delete (deferred — simplicity)
- No database or persistence (by design — milestone constraint)
- No authentication (by design — milestone constraint)
- No npm audit fix (deferred)

## Suggested Next Steps

1. **Milestone 07**: Add a database for persistence (SQLite or PostgreSQL) with migrations and test database support.
2. **Address npm vulnerabilities**: `npm audit fix` or targeted resolution.
3. **httpx2 migration**: Once confirmed stable, replace `httpx` with `httpx2` in `requirements.txt`.
4. **Inline name editing**: Add edit mode for item names in the UI.
5. **Extract components**: Split `ItemsList.tsx` into `ItemRow`, `CreateItemForm`, etc. as complexity grows.
