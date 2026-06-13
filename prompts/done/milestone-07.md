/tdd

Goal:
Add SQLite-backed persistence for items while preserving the existing item API and UI behavior.

Context:
Milestone 06 delivered full in-memory CRUD for items:
- GET /api/items
- POST /api/items
- PATCH /api/items/{item_id}
- DELETE /api/items/{item_id}
- frontend create/toggle/delete controls
- 14 backend tests and 18 frontend tests
- runner auto-publish and idempotent prompt archive behavior are proven

This milestone starts moving the app toward production behavior by replacing the process-local in-memory item list with durable local SQLite storage.

Constraints:
- Use SQLite from the Python standard library unless there is a clear reason not to.
- Do not introduce Docker or a separate database server yet.
- Do not add secrets or commit local environment files.
- Preserve the existing API contracts as much as possible.
- Preserve existing frontend behavior and tests.
- Keep tests isolated. Do not let tests write to a shared production/dev database file.
- Prefer an environment-configurable database path such as ITEMS_DB_PATH.
- Use TDD: write failing backend persistence tests first, then implement.
- Do not use npm audit fix --force.
- Keep staging deployment disabled unless already configured.

Steps:
1. Inspect the current backend item implementation and tests.
2. Add a small SQLite storage layer, for example `backend/storage.py` or `backend/db.py`.
3. Add database initialization that creates an `items` table when missing.
4. Seed the default starter items only when the database is empty.
5. Update GET/POST/PATCH/DELETE item endpoints to use SQLite instead of the in-memory list.
6. Add backend tests for persistence behavior:
   - default items are created for a fresh empty database
   - POST creates an item that appears in later GET responses
   - PATCH changes persist across a re-read
   - DELETE removes the item from later GET responses
   - tests use a temporary database path and do not touch the normal dev database
7. Keep existing backend tests passing.
8. Keep existing frontend tests passing. Update frontend tests only if required by unchanged API behavior.
9. Update local setup docs to mention the SQLite database path and reset behavior.
10. Update:
    - docs/agent-state/current-state.md
    - docs/agent-state/milestones/milestone-07.md
    - relevant memory files if the agent uses them
11. Run:
    - ./scripts/validate-local.sh
    - ./scripts/smoke-local.sh
12. Archive this prompt when complete.

Definition of done:
- Backend no longer relies on a process-local item list for normal operation.
- Items persist in SQLite across API calls and app restarts when the same database path is used.
- Backend tests prove isolated persistence with a temporary database.
- Existing frontend create/toggle/delete behavior still works.
- Typecheck, lint, frontend tests, backend tests, build, and local smoke all pass.
- Runner commits, pushes agent/sequential-run, fast-forwards/pushes main, and returns to agent/sequential-run automatically.
