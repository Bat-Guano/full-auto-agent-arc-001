/tdd

Goal:
Add a `POST /api/items` mutation to create a new in-memory item, with backend TDD first and a frontend form wired into the existing ItemsList UI.

Context:
Milestone 04 added:
- `GET /api/items`
- backend test coverage for items
- frontend `ItemsList.tsx`
- frontend `ItemsList.test.tsx`
- automatic milestone publishing in `scripts/run-milestones.sh`

This milestone should prove the updated runner by completing, committing, pushing `agent/sequential-run`, fast-forwarding/pushing `main`, and returning to `agent/sequential-run` automatically.

Constraints:
- Keep storage in-memory only. Do not add a database yet.
- Use TDD: backend failing test first, then implementation.
- Preserve existing `/api/health` and `GET /api/items`.
- Do not touch secrets or local environment files.
- Keep frontend tests deterministic.
- Fix or avoid React `act(...)` warnings in any tests touched.
- Do not use `npm audit fix --force`.

Steps:
1. Add backend tests for `POST /api/items`.
2. Implement `POST /api/items` in `backend/main.py`.
3. Add a simple frontend form to create an item.
4. Add/update frontend tests for successful item creation and error handling.
5. Run `./scripts/validate-local.sh`.
6. Run `./scripts/smoke-local.sh`.
7. Update handoff/current-state docs.
8. Archive this prompt when complete.

Definition of done:
- Backend tests pass.
- Frontend tests pass.
- Build passes.
- Local smoke passes.
- New item creation works through the UI.
- `scripts/run-milestones.sh` automatically pushes `agent/sequential-run`, fast-forwards/pushes `main`, and returns to `agent/sequential-run`.
