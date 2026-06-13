/tdd

Goal:
Polish the item UI so the current sample app feels more production-ready, without changing the backend data model or adding new infrastructure.

Context:
The app currently has FastAPI + SQLite persistence, readiness checks, CI, and React item CRUD controls. Milestone 09 focuses only on UX polish. It should be independent from dependency/security hardening and staging/deployment work.

Constraints:
- Work in the app repo root.
- Do not touch secrets, .env files, API keys, tokens, or deployment credentials.
- Do not change database schema unless absolutely necessary.
- Preserve existing endpoints and test behavior:
  - GET /api/health
  - GET /api/ready
  - GET /api/items
  - POST /api/items
  - PATCH /api/items/{item_id}
  - DELETE /api/items/{item_id}
- Do not use npm audit fix --force.
- Keep frontend tests deterministic.
- Avoid React act(...) warnings in tests touched by this milestone.
- Keep the milestone small enough to validate, smoke, archive, commit, and auto-publish cleanly.

Steps:
1. Inspect the current ItemsList UI and tests.
2. Add inline editing for item names using the existing PATCH endpoint.
3. Add delete confirmation so accidental deletes are less likely.
4. Improve empty/loading/error states where the current UI is weak.
5. If ItemsList is becoming too large, split small presentational pieces into separate components only if it reduces complexity.
6. Add or update frontend tests for:
   - entering edit mode
   - saving an edited item name
   - cancelling edit mode
   - delete confirmation required before delete
   - empty state when no items are returned
   - relevant error states
7. Run the full local validation and smoke flow through the normal runner.
8. Update current-state and milestone documentation.
9. Archive this prompt when complete.

Definition of done:
- Existing backend tests still pass.
- Existing frontend tests still pass.
- New frontend UX tests pass.
- Typecheck passes.
- Build passes.
- Local smoke passes.
- UI supports create, edit, toggle, delete with confirmation, and clear empty/error states.
- Runner auto-publishes the milestone and returns to agent/sequential-run.
