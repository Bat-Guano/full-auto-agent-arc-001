# Current State

## App Purpose

This repository is an **agent-driven CI/CD harness** — not an application itself. It runs a sequence of milestone prompts through Claude Code, executing validate → smoke-local → deploy-staging → smoke-staging phases with auto-repair loops after each milestone. The harness has no application source code of its own; it orchestrates the development of a target app.

## Tech Stack (Harness Level)

- **Language**: POSIX-compatible Bash (all scripts in `scripts/`)
- **AI runner**: Claude Code CLI (`claude` / `claude-deepseek`)
- **Version control**: Git
- **Package manager**: None at the harness level (no `package.json`, `pyproject.toml`, or lock files)
- **Process manager (staging)**: pm2 (with systemd and Docker mentioned as alternatives in comments)

The harness dynamically detects the target app's ecosystem:
| Detected file | Package manager used |
|---|---|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package.json` (no lock) | npm |
| `pyproject.toml` | uv |
| `requirements.txt` | pip + venv |

## Architecture Notes

- **`scripts/run-milestones.sh`** is the top-level orchestrator. It reads `prompts/milestone-*.md` in sorted order, runs each through Claude Code, then executes validate → smoke-local → deploy-staging → smoke-staging with up to `MAX_REPAIRS` (default 2) auto-repair attempts per phase.
- **`scripts/validate-local.sh`** auto-detects the ecosystem and runs lint/typecheck/test/build. When no `package.json` or `pyproject.toml` exists, it is a no-op.
- **`scripts/smoke-local.sh`** starts a dev server and polls `LOCAL_HEALTH_PATH` on `PORT` (default 3000).
- **`.env.agent`** (gitignored, copied from `.env.agent.example`) controls branch name, permission mode, port, staging URL, and deployment flags.
- **Agent logs** go to `agent-logs/` (gitignored).
- **Project memory** lives in `docs/agent-state/` — `current-state.md` (rolling) and `milestones/` (per-milestone summaries).

## Implementation Status

- **Milestone 01** — Complete. Created `docs/agent-notes.md` with repo inspection results.
- **Application source code** — Does not exist yet. The repo is an empty harness waiting for a target app to be scaffolded.

## Validation Commands

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Lint, typecheck, test, build for detected ecosystem |
| `scripts/smoke-local.sh` | Start local server and poll health endpoint |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 |
| `scripts/smoke-staging.sh` | Poll staging health endpoint |
| `scripts/run-milestones.sh` | Run all milestones sequentially |
| `scripts/collect-failure-context.sh` | Gather git status + logs after failure |
| `scripts/collect-server-logs.sh` | SSH to staging and collect app logs |
| `scripts/sanitize-log.sh` | Redact secrets from log output |

## Known Issues

- No target application exists yet — validate and smoke scripts are no-ops.
- `DEPLOY_STAGING=false` in `.env.agent` — staging deployment is disabled.
- The `scripts/create-sample-apps.sh` script only prints starter commands; it doesn't scaffold anything.

## Next Recommended Milestone

**Milestone 02 — Bootstrap the application scaffold.** Choose a target stack (e.g., Vite React TypeScript frontend + FastAPI backend) and create the app source code. Once `package.json` or `pyproject.toml` exists, `validate-local.sh` will automatically detect the ecosystem and run lint/typecheck/test/build.

## Rules for the Next Agent

- Do NOT edit `.env`, `.env.local`, `.env.agent`, or any secret files.
- Do NOT hardcode secrets.
- Do NOT disable tests, linting, type checks, or build checks to make the pipeline pass.
- Do NOT remove tests to make the pipeline pass.
- Prefer small, reversible, testable changes.
- Follow existing project conventions.
- Before editing, read `docs/agent-state/current-state.md` and relevant milestone files in `docs/agent-state/milestones/`.
- The external runner (`run-milestones.sh`) owns deployment — do not deploy manually.
