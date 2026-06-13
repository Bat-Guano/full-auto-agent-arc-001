"""Tests for SQLite persistence of items.

These tests verify that items persist in a database across API calls.
The shared temp database is set up by conftest.py — these tests
exercise read-after-write, read-after-update, and read-after-delete
patterns to confirm the data is durably stored.
"""

from fastapi.testclient import TestClient
from main import app
import storage

client = TestClient(app)


def setup_module():
    """Reset the database to pristine state before persistence tests.

    test_items.py runs before this module (alphabetical ordering) and mutates
    the shared session-scoped database.  Drop and recreate the table so the
    persistence tests start from a known clean state with the four default
    starter items at their original ids (1-4).
    """
    conn = storage.get_connection()
    conn.execute("DROP TABLE IF EXISTS items")
    conn.commit()
    conn.close()
    storage.init_db()
    storage.seed_if_empty()


def test_default_items_are_present():
    """The database should contain the four starter items."""
    response = client.get("/api/items")
    assert response.status_code == 200

    items = response.json()["items"]
    names = {i["name"] for i in items}

    for expected in (
        "Define project scope",
        "Scaffold application",
        "Add automated tests",
        "Add domain feature",
    ):
        assert expected in names, f"Expected default item '{expected}' not found"


def test_post_persists_across_get():
    """POST creates an item that appears in later GET responses."""
    create_resp = client.post("/api/items", json={"name": "Persistent item"})
    assert create_resp.status_code == 201
    created_id = create_resp.json()["id"]

    # Re-fetch and confirm the new item is present
    get_resp = client.get("/api/items")
    assert get_resp.status_code == 200

    items = get_resp.json()["items"]
    found = [i for i in items if i["id"] == created_id]
    assert len(found) == 1
    assert found[0]["name"] == "Persistent item"
    assert found[0]["done"] is False


def test_patch_changes_persist_across_re_read():
    """PATCH changes should be visible in a later GET."""
    # Use a known item that still exists (id 2 should survive other tests)
    patch_resp = client.patch("/api/items/2", json={"name": "Patched name"})
    assert patch_resp.status_code == 200
    assert patch_resp.json()["name"] == "Patched name"

    # Re-read and confirm the change persisted
    get_resp = client.get("/api/items")
    items = get_resp.json()["items"]
    item = next(i for i in items if i["id"] == 2)
    assert item["name"] == "Patched name"


def test_patch_done_persists_across_re_read():
    """PATCH done should be visible in a later GET."""
    patch_resp = client.patch("/api/items/3", json={"done": True})
    assert patch_resp.status_code == 200
    assert patch_resp.json()["done"] is True

    get_resp = client.get("/api/items")
    items = get_resp.json()["items"]
    item = next(i for i in items if i["id"] == 3)
    assert item["done"] is True


def test_delete_removes_item_from_later_get():
    """DELETE should remove the item from subsequent GET responses."""
    # Create a new item first
    create_resp = client.post("/api/items", json={"name": "To be removed"})
    created_id = create_resp.json()["id"]

    # Delete it
    delete_resp = client.delete(f"/api/items/{created_id}")
    assert delete_resp.status_code == 200

    # Verify it's gone from GET
    get_resp = client.get("/api/items")
    items = get_resp.json()["items"]
    ids = [i["id"] for i in items]
    assert created_id not in ids


def test_auto_increment_ids_never_reused():
    """Creating a new item after a delete should give a larger id (no reuse)."""
    # Create and delete an item to consume an id
    create_resp = client.post("/api/items", json={"name": "Temp for id test"})
    temp_id = create_resp.json()["id"]
    client.delete(f"/api/items/{temp_id}")

    # Create another item — its id should be > temp_id
    create_resp2 = client.post("/api/items", json={"name": "After temp"})
    new_id = create_resp2.json()["id"]
    assert new_id > temp_id, f"Expected new id {new_id} > previous {temp_id}"
