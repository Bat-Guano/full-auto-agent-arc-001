#!/usr/bin/env bash
set -euo pipefail

echo "Common starter commands. Run manually as needed."
echo
echo "Vite React TypeScript:"
echo "  npm create vite@latest frontend -- --template react-ts"
echo
echo "FastAPI:"
echo "  mkdir backend && cd backend"
echo "  python3 -m venv .venv"
echo "  . .venv/bin/activate"
echo "  pip install fastapi 'uvicorn[standard]'"
echo
echo "Docker Compose example can be added per project."
