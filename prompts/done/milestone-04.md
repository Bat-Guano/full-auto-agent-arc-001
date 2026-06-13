/tdd
Goal:
Add the first domain-specific feature slice to the scaffolded app and clean up known non-blocking test warnings.
Context:
Milestone 03 added Vitest/Testing Library frontend tests and pytest backend tests. Validation and smoke-local pass.
Remaining warnings include React act(...) test warnings and a FastAPI/Starlette TestClient deprecation warning.
Constraints:
- Do not add authentication yet.
- Do not add database logic unless required by the feature.
- Do not disable or weaken validation.
- Do not commit secrets or local environment files.
Steps:
1. Inspect docs/agent-state/current-state.md and milestone summaries.
2. Add a small domain endpoint with a backend test first.
3. Add a frontend display/use of that endpoint with a frontend test.
4. Clean up React act(...) warnings if safely in scope.
5. Document any dependency/deprecation follow-up if not safely fixed.
6. Run ./scripts/validate-local.sh and ./scripts/smoke-local.sh.
Definition of done:
- Backend and frontend tests pass.
- validate-local and smoke-local pass.
- No test/check is weakened.
- Current-state and milestone docs are updated.
