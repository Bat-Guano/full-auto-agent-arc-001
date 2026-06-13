from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional

import storage

# Initialise the database on first import.
storage.init_db()
storage.seed_if_empty()

app = FastAPI(title="My App API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Vite dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    return {"items": storage.get_items()}


@app.post("/api/items", status_code=201)
async def create_item(body: CreateItemRequest):
    return storage.create_item(name=body.name, done=body.done)


@app.patch("/api/items/{item_id}")
async def update_item(item_id: int, body: UpdateItemRequest):
    result = storage.update_item(
        item_id,
        name=body.name,
        done=body.done,
    )
    if result is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return result


@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    result = storage.delete_item(item_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return result
