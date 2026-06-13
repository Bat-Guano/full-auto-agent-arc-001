# Milestone 09 — UI Polish (Inline Editing, Delete Confirmation, Empty State)

**Status:** Complete  
**Date:** 2026-06-13

## What was done

Polished the item UI to feel more production-ready without changing the backend data model, API contract, or infrastructure:

1. **Extracted `ItemRow.tsx`** — New presentational component for each item row. Separated from `ItemsList.tsx` to keep the container component manageable. `ItemRow` manages its own local UI state (`editing`, `confirmingDelete`, `editName`, `saving`) and receives callbacks via props (`onToggle`, `onDelete`, `onUpdate`).

2. **Inline name editing** — Edit button on each item switches to edit mode: a text input pre-filled with the current name, a Save button, and a Cancel button. Save calls `onUpdate` (which delegates to `handleUpdate` in `ItemsList` → PATCH `/api/items/{id}` with `{name}`). Save button is disabled while saving or when input is empty. Cancel reverts to display mode without changes.

3. **Delete confirmation** — Delete button now requires a second click: first click shows a confirmation row ("Delete 'name'?" with Confirm Delete and Cancel buttons). Confirm Delete triggers the actual DELETE request. Cancel returns to display mode. This prevents accidental deletions.

4. **Improved empty state** — When the items list is empty, shows "No items yet. Add one above." with italic styling (`className="empty-message"`).

5. **CSS polish** (`frontend/src/App.css`) — Added styles for:
   - `.btn-edit` (blue outline, turns solid on hover)
   - `.btn-save` (green outline, disabled state with reduced opacity)
   - `.btn-cancel` (grey outline, disabled state)
   - `.btn-confirm-delete` (red, reuses base delete button styles)
   - `.btn-cancel-delete` (grey outline)
   - `.edit-input` (blue-bordered text input, flex: 1)
   - `.confirm-text` (red text, flex: 1)
   - `.empty-message` (grey italic)
   - Hover and disabled states for all new buttons

6. **Item list rendering**: When items exist, they're rendered as a `<ul>` with `<ItemRow>` children. When empty, the empty message replaces the list entirely.

## Files changed

| File | Change |
|---|---|
| `frontend/src/ItemRow.tsx` | **New**: Presentational row component with display/edit/confirm-delete modes |
| `frontend/src/ItemsList.tsx` | Added `handleUpdate` callback (returns `Promise<boolean>`), delegates row rendering to `<ItemRow />`, shows empty state, imports `ItemRow` |
| `frontend/src/ItemsList.test.tsx` | Added 4 inline editing tests + 2 delete confirmation tests + 1 empty state test. Restructured toggle/delete tests for confirmation flow. Updated mock helpers. |
| `frontend/src/App.css` | Added styles for edit, save, cancel, confirm-delete, cancel-delete buttons, edit input, confirmation text, empty message, disabled states, hover effects |
| `docs/agent-state/current-state.md` | Updated for milestone 09 |
| `docs/agent-state/milestones/milestone-09.md` | This file |

## Backend

No backend changes. All 22 backend tests pass unchanged. API contract preserved:
- `GET /api/health`, `GET /api/ready`, `GET /api/items`
- `POST /api/items`, `PATCH /api/items/{item_id}`, `DELETE /api/items/{item_id}`

## Test counts

| Suite | Before | After | Change |
|---|---|---|---|
| Backend (pytest) | 22 | 22 | No change |
| Frontend (Vitest) | 18 | 24 | +6 (4 App unchanged, ItemsList 14→20) |

### New frontend tests

**Inline editing** (4 tests):
- Enters edit mode when edit button is clicked — verifies edit input, Save, and Cancel buttons appear with correct pre-filled value
- Saves an edited item name — verifies edit mode exits after save
- Cancels edit mode without saving changes — verifies original name remains, edit UI is gone
- Shows error when name update fails — verifies error message appears and edit mode stays

**Delete confirmation** (2 tests):
- Shows delete confirmation and removes item on confirm — two-click flow: Delete → Confirm Delete → item removed from list
- Cancels delete confirmation without removing item — Delete → Cancel → item still in list

**Empty state** (1 test):
- Shows empty state when no items are returned — verifies "No items yet" message appears

## Component architecture

```
ItemsList (container)
├── loading → <p>Loading items...</p>
├── error → <p role="alert">Error loading items: ...</p>
├── empty → <p className="empty-message">No items yet. Add one above.</p>
├── items → <ul>
│   └── ItemRow (presentational, one per item)
│       ├── display mode: checkbox + name + Edit + Delete
│       ├── edit mode: disabled checkbox + text input + Save + Cancel
│       └── confirm-delete mode: confirmation text + Confirm Delete + Cancel
├── actionError → <p role="alert">{actionError}</p>
└── add form → input + Add button + submitError
```

`ItemsList.handleUpdate(item, name)` returns `Promise<boolean>` so `ItemRow` can react to save success (exit edit mode) or failure (stay in edit mode, error shown via `actionError`).

## Design decisions

- **Three-mode ItemRow** rather than separate EditRow/ConfirmRow components — keeps all per-item interactions in one place at current complexity level.
- **`handleUpdate` returns `Promise<boolean>`** — lets the child component manage its own edit-mode state based on outcome, without needing to pass setState functions down.
- **Edit mode disables the checkbox** — prevents confusion between toggling done status and editing the name.
- **Save button disabled when input is empty or trimmed empty** — matches the Add button behavior.
- **Delete confirmation shows the item name** — quotes using `&ldquo;`/`&rdquo;` HTML entities for typographic quality.
- **No backend changes** — inline editing uses the existing `PATCH /api/items/{item_id}` endpoint with `{name}` body, which already supported partial name updates.

## Definition of done

- [x] Inline editing for item names using existing PATCH endpoint
- [x] Delete confirmation before actual delete
- [x] Empty state when no items are returned
- [x] Loading and error states preserved
- [x] ItemRow extracted as separate presentational component
- [x] 6 new frontend tests pass (4 inline editing + 2 delete confirmation)
- [x] Existing frontend tests updated and pass (24 total)
- [x] Existing backend tests pass (22 total)
- [x] Typecheck passes
- [x] Build passes
- [x] Local smoke passes
- [x] No backend data model changes
- [x] No new dependencies
