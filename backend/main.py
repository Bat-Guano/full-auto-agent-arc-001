from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="My App API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Vite dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


ITEMS = [
    {"id": 1, "name": "Define project scope", "done": True},
    {"id": 2, "name": "Scaffold application", "done": True},
    {"id": 3, "name": "Add automated tests", "done": True},
    {"id": 4, "name": "Add domain feature", "done": False},
]


@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.get("/api/items")
async def get_items():
    return {"items": ITEMS}
