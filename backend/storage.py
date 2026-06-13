"""SQLite-backed item storage.

Reads ITEMS_DB_PATH from the environment; defaults to ./items.db.
Each function opens its own connection so callers are safe from
threading issues when used within FastAPI async endpoints.
"""

import os
import sqlite3

DEFAULT_ITEMS = [
    {"name": "Define project scope", "done": True},
    {"name": "Scaffold application", "done": True},
    {"name": "Add automated tests", "done": True},
    {"name": "Add domain feature", "done": False},
]


def get_db_path() -> str:
    """Return the database path from the environment or the default."""
    return os.environ.get("ITEMS_DB_PATH", "./items.db")


def get_connection() -> sqlite3.Connection:
    """Return a new connection for the current thread."""
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db() -> None:
    """Create the items table if it does not already exist."""
    conn = get_connection()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0
        )
        """
    )
    conn.commit()
    conn.close()


def seed_if_empty() -> None:
    """Insert default starter items when the items table is empty."""
    conn = get_connection()
    count = conn.execute("SELECT COUNT(*) FROM items").fetchone()[0]
    if count == 0:
        for item in DEFAULT_ITEMS:
            conn.execute(
                "INSERT INTO items (name, done) VALUES (?, ?)",
                (item["name"], 1 if item["done"] else 0),
            )
        conn.commit()
    conn.close()


def get_items() -> list[dict]:
    """Return all items ordered by id."""
    conn = get_connection()
    rows = conn.execute("SELECT id, name, done FROM items ORDER BY id").fetchall()
    items = [
        {"id": row["id"], "name": row["name"], "done": bool(row["done"])}
        for row in rows
    ]
    conn.close()
    return items


def create_item(name: str, done: bool = False) -> dict:
    """Insert a new item and return it with its auto-generated id."""
    conn = get_connection()
    cursor = conn.execute(
        "INSERT INTO items (name, done) VALUES (?, ?)",
        (name, 1 if done else 0),
    )
    item_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return {"id": item_id, "name": name, "done": done}


def update_item(item_id: int, name: str | None = None, done: bool | None = None) -> dict | None:
    """Partially update an item.  Returns the updated item or None if missing."""
    conn = get_connection()
    row = conn.execute(
        "SELECT id, name, done FROM items WHERE id = ?", (item_id,)
    ).fetchone()

    if row is None:
        conn.close()
        return None

    new_name = name if name is not None else row["name"]
    new_done = done if done is not None else bool(row["done"])

    conn.execute(
        "UPDATE items SET name = ?, done = ? WHERE id = ?",
        (new_name, 1 if new_done else 0, item_id),
    )
    conn.commit()
    conn.close()
    return {"id": item_id, "name": new_name, "done": new_done}


def delete_item(item_id: int) -> dict | None:
    """Delete an item by id.  Returns the deleted item or None if missing."""
    conn = get_connection()
    row = conn.execute(
        "SELECT id, name, done FROM items WHERE id = ?", (item_id,)
    ).fetchone()

    if row is None:
        conn.close()
        return None

    item = {"id": row["id"], "name": row["name"], "done": bool(row["done"])}
    conn.execute("DELETE FROM items WHERE id = ?", (item_id,))
    conn.commit()
    conn.close()
    return item
