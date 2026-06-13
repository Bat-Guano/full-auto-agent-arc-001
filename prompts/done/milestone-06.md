/tdd

Goal:
Add item update and delete mutations with backend TDD and frontend controls in the existing ItemsList UI.

Context:
Milestone 05 added:
- `POST /api/items`
- backend create-item tests
- frontend inline add-item form
- auto-publish behavior in `scripts/run-milestones.sh`
- idempotent prompt archive handling

This milestone should prove the full corrected flow:
prompt -> implement -> validate -> smoke -> handoff -> archive -> commit -> push agent branch -> fast-forward/push main -> return to agent branch.

Constraints:
- Keep storage in-memory only. Do not add a database yet.
- Use TDD: backend failing tests first, then implementation.
- Preserve existing endpoints:
  - `GET /api/health`
  - `GET /api/items`
  - `POST /api/items`
- Add update/delete without breaking existing tests.
- Do not touch secrets or local environment files.
- Do not use `npm audit fix --force`.
- Keep frontend tests deterministic.
- Fix or avoid React `act(...)` warnings in any tests touched.
- Keep the UI simple and practical.

Steps:
1. Add backend tests for updating an item:
   - successful update of item name
   - successful update of item done status
   - 404 for missing item
   - 422 for invalid empty name
2. Implement an update endpoint, preferably:
   - `PATCH /api/items/{item_id}`
3. Add backend tests for deleting an item:
   - successful delete
   - 404 for missing item
   - deleted item no longer appears in `GET /api/items`
4. Implement a delete endpoint:
   - `DELETE /api/items/{item_id}`
5. Update `ItemsList.tsx` with simple UI controls:
   - toggle done status
   - delete item
   - optionally edit item name if safe within scope
6. Add/update frontend tests for:
   - toggling done status
   - deleting an item
   - API error handling for update/delete
7. Run:
   - `./scripts/validate-local.sh`
   - `./scripts/smoke-local.sh`
8. Update:
   - `docs/agent-state/current-state.md`
   - `docs/agent-state/milestones/milestone-06.md`
   - relevant memory files if the agent uses them
9. Archive this prompt when complete.

Definition of done:
- Backend tests pass.
- Frontend tests pass.
- Typecheck passes.
- Build passes.
- Local smoke passes.
- Items can be created, updated/toggled, and deleted through the UI.
- Runner automatically archives the prompt without failing if it was already archived.
- Runner automatically commits, pushes `agent/sequential-run`, fast-forwards/pushes `main`, and returns to `agent/sequential-run`.
