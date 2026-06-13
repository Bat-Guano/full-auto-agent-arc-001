# Milestone 02 - Bootstrap application scaffold

Goal:
Create the initial web application scaffold for this project.

Target architecture:
- Frontend: Vite + React + TypeScript
- Backend: FastAPI + Python
- Local development should be simple and documented
- Validation should work through the existing scripts/validate-local.sh and scripts/smoke-local.sh where possible

Required structure:
- frontend/
- backend/
- docs/dev-setup.md
- README.md updated with basic setup and run instructions

Frontend requirements:
- Create a Vite React TypeScript app in frontend/
- Add a simple landing page that says the app scaffold is running
- Add a basic health/status display placeholder
- Ensure npm run build works

Backend requirements:
- Create a FastAPI app in backend/
- Add GET /api/health returning JSON with status ok
- Add a minimal requirements.txt or pyproject.toml
- Add a README note explaining how to run it locally

Script updates:
- Update scripts/validate-local.sh if needed so it validates both frontend and backend
- Update scripts/smoke-local.sh if needed so it can smoke-test the backend health endpoint
- Keep changes simple and avoid over-engineering

Rules:
- Do not add authentication yet
- Do not add database logic yet
- Do not deploy
- Do not hardcode secrets
- Do not remove the existing agent harness

Definition of done:
- frontend builds successfully
- backend health endpoint exists
- docs/dev-setup.md explains how to run the app
- scripts/validate-local.sh passes
- scripts/smoke-local.sh either passes or clearly explains any required manual startup limitation
