# Agent Notes — Repository Inspection

## Detected Tech Stack

- **Primary language:** Bash (all scripts are POSIX-compatible shell scripts)
- **AI runner:** Claude Code CLI (invoked as `claude-deepseek` in scripts)
- **Orchestration:** `scripts/run-milestones.sh` — the main pipeline driver
- **Version control:** Git
- **Deployment target detection:** Scripts dynamically detect Node.js (npm/pnpm/yarn) and Python (uv/pip) projects in a target app repo, but the harness itself has no runtime dependencies
- **Process manager (staging):** pm2 (with systemd and Docker mentioned as alternatives in comments)

## Package Manager

**None at the harness level.** This repo defines no `package.json`, `pyproject.toml`, or lock files. It is a shell-script-only orchestration layer. The validate and smoke scripts detect package managers in the target application repo:

| Detected file | Package manager used |
|---|---|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package.json` (no lock file) | npm |
| `pyproject.toml` | uv |
| `requirements.txt` | pip + venv |

## Available Validation Commands

All scripts live in `scripts/` and are meant to be invoked by the harness, though many can run standalone:

| Command | Purpose |
|---|---|
| `scripts/validate-local.sh` | Lint, typecheck, test, build for detected ecosystem |
| `scripts/smoke-local.sh` | Start local server and poll health endpoint |
| `scripts/deploy-staging.sh` | Push branch, SSH deploy, build, restart via pm2 |
| `scripts/smoke-staging.sh` | Poll staging health endpoint |
| `scripts/run-milestones.sh` | **Main entry point** — runs all milestones sequentially |
| `scripts/collect-failure-context.sh` | Gather git status + logs after a failure |
| `scripts/collect-server-logs.sh` | SSH to staging and collect app logs |
| `scripts/sanitize-log.sh` | Redact secrets from log output |
| `scripts/create-sample-apps.sh` | Print starter commands (Vite, FastAPI) — reference only |

## App Entry Points

There is **no application source code** in this repo. The repository is an agent-driven CI/CD harness. The entry points are:

1. **`scripts/run-milestones.sh`** — top-level orchestrator. Reads `prompts/milestone-*.md` files in sorted order, runs each through Claude Code, then executes validate → smoke-local → deploy-staging → smoke-staging (if `DEPLOY_STAGING=true`), with auto-repair loops.

2. **`prompts/milestone-01.md`** — current (and only) milestone prompt. It asks Claude to inspect the app structure and create `docs/agent-notes.md`.

3. **Environment config:** `.env.agent` (copied from `.env.agent.example`) controls branch name, permission mode, port, staging URL, and deployment flags.

## Repository Structure

```
my-app/
├── prompts/              # Milestone prompt files (milestone-NN.md)
├── scripts/              # Pipeline shell scripts
├── docs/
│   └── agent-state/      # Handoff/state docs (populated after milestones run)
├── agent-logs/           # Claude interaction logs (gitignored)
├── .env.agent            # Local env config (gitignored)
├── .env.agent.example    # Template for .env.agent
└── .gitignore
```

## Recommended First Implementation Milestone

**Milestone 02 — Bootstrap the application scaffold.** Use `scripts/create-sample-apps.sh` as a reference to choose a target stack (e.g., Vite React TypeScript frontend + FastAPI backend), then create the app source code that subsequent milestones will build upon. This would populate the repo with actual `package.json`, `pyproject.toml`, source files, and tests.

The harness is ready: `validate-local.sh` will detect the chosen ecosystem and run lint/typecheck/test/build automatically once `package.json` or `pyproject.toml` exists. `smoke-local.sh` will start the dev server and poll the health endpoint on port 3000.
