from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional

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


class CreateItemRequest(BaseModel):
    name: str = Field(..., min_length=1)
    done: bool = False


class UpdateItemRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    done: Optional[bool] = None


@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.get("/api/items")
async def get_items():
    return {"items": ITEMS}


@app.post("/api/items", status_code=201)
async def create_item(body: CreateItemRequest):
    next_id = max((item["id"] for item in ITEMS), default=0) + 1
    new_item = {"id": next_id, "name": body.name, "done": body.done}
    ITEMS.append(new_item)
    return new_item


@app.patch("/api/items/{item_id}")
async def update_item(item_id: int, body: UpdateItemRequest):
    for item in ITEMS:
        if item["id"] == item_id:
            if body.name is not None:
                item["name"] = body.name
            if body.done is not None:
                item["done"] = body.done
            return item
    raise HTTPException(status_code=404, detail="Item not found")


@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    for i, item in enumerate(ITEMS):
        if item["id"] == item_id:
            removed = ITEMS.pop(i)
            return removed
    raise HTTPException(status_code=404, detail="Item not found")
