# Milestone 04 — Add Domain Feature Slice

## Goal

Add the first domain-specific feature slice (`GET /api/items`) with TDD, wire it into the frontend with an `ItemsList` component, clean up React `act(...)` test warnings, and document the Starlette TestClient deprecation.

## Changes Made

### Backend — 1 file created, 1 file modified

| File | Action | Purpose |
|---|---|---|
| `backend/test_items.py` | Created | 1 pytest test: `GET /api/items` returns HTTP 200, response contains `items` list with `id` and `name` fields |
| `backend/main.py` | Modified | Added `ITEMS` in-memory list (4 items), added `GET /api/items` endpoint returning `{"items": ITEMS}` |

### Frontend — 2 files created, 3 files modified

| File | Action | Purpose |
|---|---|---|
| `frontend/src/ItemsList.tsx` | Created | Component that fetches `/api/items` on mount, renders loading/error/success states as a `<ul>` with `item-done`/`item-pending` CSS classes |
| `frontend/src/ItemsList.test.tsx` | Created | 4 Vitest tests: loading state, rendered items list, list items count, error state (fetch rejection) |
| `frontend/src/App.tsx` | Modified | Imported `ItemsList`, added `<section className="items-card">` with heading and `<ItemsList />` in side-by-side layout |
| `frontend/src/App.css` | Modified | Added `.items-card`, `.items-card h2`, `.items-card ul`, `.items-card li`, `.item-done`, `.item-pending` styles |
| `frontend/src/App.test.tsx` | Modified | Fixed act() warnings by mocking `globalThis.fetch` with a never-resolving promise in `beforeEach`; added `beforeEach`/`afterEach` lifecycle hooks; added test for "Items" section heading |

### Documentation — 2 files

| File | Action | Purpose |
|---|---|---|
| `docs/agent-state/current-state.md` | Modified | Updated implementation status, architecture notes, tech stack, known issues, and next recommended milestone |
| `docs/agent-state/milestones/milestone-04.md` | Created | This summary |

## Files Touched Summary

| File | Action |
|---|---|
| `backend/test_items.py` | Created |
| `frontend/src/ItemsList.tsx` | Created |
| `frontend/src/ItemsList.test.tsx` | Created |
| `docs/agent-state/milestones/milestone-04.md` | Created |
| `backend/main.py` | Modified (added ITEMS constant + /api/items endpoint) |
| `frontend/src/App.tsx` | Modified (imported ItemsList, added items section) |
| `frontend/src/App.css` | Modified (added items card styles) |
| `frontend/src/App.test.tsx` | Modified (fixed act warnings, added items test) |
| `docs/agent-state/current-state.md` | Modified (updated status/arch) |

## Decisions Made

- **Domain choice — items list**: A minimal todo-style items endpoint. No database, no authentication — just an in-memory constant. This keeps the milestone bounded and avoids introducing DB dependencies before they're needed.
- **Side-by-side layout**: Added `.items-card` next to `.status-card` using `margin-left: 1.5rem`. Both cards inside the existing flex `app-main` container.
- **ItemsList as separate component**: Rather than inlining items fetch/display in `App.tsx`, created `ItemsList.tsx` as its own component. This follows single-responsibility, makes tests focused, and sets the pattern for future components.
- **TDD order**: Backend test (`test_items.py`) written before the endpoint. Frontend test (`ItemsList.test.tsx`) and component written together since they're co-dependent.
- **act() warning fix — never-resolving fetch mock**: `App.test.tsx` previously triggered "not wrapped in act(...)" warnings because `useEffect` in App called `fetch` which resolved after the test completed. Fix: mock `globalThis.fetch` to return a never-resolving promise. This prevents any async state update from firing after test cleanup. Tests that need fetch to resolve (like `ItemsList.test.tsx`) override this with their own mock.
- **No httpx→httpx2 migration yet**: `starlette.testclient` (used by `fastapi.testclient.TestClient`) emits a `StarletteDeprecationWarning` recommending `httpx2` over `httpx`. The `httpx2` package availability is uncertain; documented as a known issue for a future milestone rather than making a breaking dependency change.

## Commands/Tests Run

| Command | Expected Result |
|---|---|
| `cd backend && source .venv/bin/activate && pytest` | **2/2 pass** — test_health + test_items |
| `cd frontend && npm test` | **8/8 pass** — 4 App tests + 4 ItemsList tests (loading, items render, list item count, error state) |
| `scripts/validate-local.sh` | **Pass** — full validation (no regressions) |
| `scripts/smoke-local.sh` | **Pass** — health endpoint responds; items endpoint returns data |

## Known Issues

- **Starlette TestClient httpx deprecation**: `starlette.testclient` warns "Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead." This is non-blocking. When `httpx2` is confirmed stable on PyPI, update `backend/requirements.txt` to replace `httpx` with `httpx2`.
- **npm vulnerabilities**: 2 high severity vulnerabilities remain from milestone-03.

## What Was Not Done

- No database or persistence added (by design — milestone constraint)
- No authentication added (by design — milestone constraint)
- `httpx→httpx2` dependency change (documented as follow-up)
- Deploy not attempted (`DEPLOY_STAGING=false`)

## Suggested Next Steps

1. **Milestone 05**: Add `POST /api/items` mutation with backend TDD and a frontend form to create new items.
2. **Address npm vulnerabilities**: `npm audit fix` or targeted resolution.
3. **httpx2 migration**: Once confirmed stable, replace `httpx` with `httpx2` in `requirements.txt`.
4. **CI pipeline setup**: GitHub Actions workflow running `validate-local.sh`.
