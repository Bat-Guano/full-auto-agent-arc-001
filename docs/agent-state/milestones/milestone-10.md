# Milestone 10 — Dependency and Security Hardening

**Status:** Complete  
**Date:** 2026-06-13  
**Validation:** Passed (validate-local + smoke-local)

## Summary

Investigated and reduced dependency/security warnings. Fixed the Starlette httpx deprecation by upgrading to `httpx2`. The frontend lockfile was regenerated for fresh resolution. 5 high-severity npm vulnerabilities remain — all from the esbuild → vite → vitest chain and require a breaking vite major version bump (7.x → 8.x) to fix. These are documented as known issues with a clear upgrade path.

## What was done

1. **Fixed Starlette httpx deprecation** — Updated `backend/requirements.txt`: `httpx>=0.28.0` → `httpx2>=2.0.0`. Starlette 1.3.1's testclient prefers `httpx2` (with `import httpx2 as httpx` for API compatibility). Installed httpx2 2.4.0. No application code changes needed. Deprecation warning resolved — backend tests (22) pass cleanly with no warnings.

2. **Regenerated frontend lockfile** — Deleted `frontend/package-lock.json` and `frontend/node_modules/`, then ran `npm install` which resolved to latest versions within existing `^` ranges. New lockfile: 267 packages. 5 high severity vulnerabilities detected (same root cause as before).

3. **npm audit fix (safe)** — `npm audit fix` (without `--force`) applied 0 changes — no semver-compatible fixes exist for the remaining vulnerabilities.

4. **Full validation passed** — `scripts/validate-local.sh` and `scripts/smoke-local.sh` both pass:
   - Frontend: lint, typecheck, 24 tests, build — all pass
   - Backend: 22 tests pass, httpx2 installed, no deprecation warnings
   - Smoke: health, readiness, and items API all pass

## Files changed

| File | Change |
|---|---|
| `backend/requirements.txt` | `httpx>=0.28.0` → `httpx2>=2.0.0` |
| `frontend/package-lock.json` | Regenerated (fresh resolution, 267 packages) |
| `docs/agent-state/current-state.md` | Updated known issues and milestone status |
| `docs/agent-state/milestones/milestone-10.md` | This file |

## npm audit vulnerability table

All 5 high-severity vulnerabilities share a single root cause: **esbuild < 0.28.0** in the Vite toolchain. The fix is a single upgrade (vite → 8.x) but it is a breaking change.

| # | Package | Advisory | Severity | Fixable without `--force`? | Requires breaking change? | Recommended action |
|---|---|---|---|---|---|---|
| 1 | esbuild (0.27.7, via vite) | [GHSA-gv7w-rqvm-qjhr](https://github.com/advisories/GHSA-gv7w-rqvm-qjhr) — Missing binary integrity verification in Deno module enables RCE via `NPM_CONFIG_REGISTRY` | high | No | Yes (vite 7.x → 8.x) | Upgrade vite to ^8.0.16 in a dedicated milestone with test/validation |
| 2 | esbuild (0.27.7, via vite) | [GHSA-g7r4-m6w7-qqqr](https://github.com/advisories/GHSA-g7r4-m6w7-qqqr) — Arbitrary file read when running dev server on Windows | high | No | Yes (vite 7.x → 8.x) | Same fix: upgrade vite to ^8.0.16 |
| 3–5 | vitest / @vitest/mocker / vite-node | Inherited from esbuild via vite dependency chain | high | No | Yes (vite 7.x → 8.x) | Resolved automatically with vite ^8.0.16 upgrade |

**Root cause chain:** `vitest 3.x` → depends on `@vitest/mocker` → depends on `vite 7.x` → depends on `esbuild 0.27.x` (vulnerable). Upgrading vite to 8.0.16+ brings esbuild ≥ 0.28.0 which fixes all 5 advisories.

**Why not fixed now:** The fix requires `npm audit fix --force` which upgrades vite from ^7.2.0 to ^8.0.16 — a major version bump. This milestone's policy prohibits `--force` and breaking changes without isolated testing.

**Risk assessment:**
- GHSA-gv7w-rqvm-qjhr (RCE): only exploitable via Deno module resolution with a malicious `NPM_CONFIG_REGISTRY` — low practical risk in standard Node.js/npm workflows
- GHSA-g7r4-m6w7-qqqr (file read): Windows-only, only affects dev server — this project runs on Linux; CI runs on Linux runners
- All 5 are build/dev tooling (esbuild, vite, vitest), not production runtime dependencies

**Recommendation:** Defer vite major upgrade to a future milestone (suggest m12 or later) with dedicated testing of build output and dev server behavior.

## Starlette deprecation fix

| Issue | Fix | Result |
|---|---|---|
| `starlette.testclient` prefers `httpx2` over `httpx` | `httpx>=0.28.0` → `httpx2>=2.0.0` in `requirements.txt` | httpx2 2.4.0 installed, 22 tests pass, no deprecation warnings in pytest output |

## Definition of done

- [x] npm audit warnings reduced where safe, or remaining warnings documented — 5 remain, all documented with root cause and upgrade path
- [x] No `--force` dependency fix used — confirmed (audit fix applied 0 changes)
- [x] Frontend lint passes — eslint --max-warnings 0 clean
- [x] Frontend typecheck passes — tsc --noEmit clean
- [x] Frontend tests pass — 24/24 (2 files)
- [x] Frontend build passes — vite build produces dist/ (198 kB JS, 3.5 kB CSS)
- [x] Backend tests pass — 22/22 (4 files)
- [x] validate-local passes — full pipeline clean
- [x] smoke-local passes — health, readiness, items API all OK
- [x] Starlette deprecation warning resolved — no warnings in pytest output
- [x] Documentation updated with remaining vulnerabilities — table above with advisory URLs, severity, and fix path

## Validation commands used

```bash
./scripts/validate-local.sh    # Full validation: npm install, lint, typecheck, test, build, pip install, pytest
./scripts/smoke-local.sh       # Start server on port 3000, verify health, readiness, items API
```

## Backend

No application code changes. `httpx2>=2.0.0` replaces `httpx>=0.28.0` in `requirements.txt`. Starlette 1.3.1 internally does `import httpx2 as httpx`, so the FastAPI TestClient API is unchanged. Backend tests pass unchanged (22 tests, 0.48s).

## Next milestone

**Milestone 11 — Staging/Deployment Readiness** (`prompts/milestone-11.md`): Enable and harden the staging deployment pipeline, configure SSH deploy, and verify smoke-staging.
