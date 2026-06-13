from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_items_returns_200_and_list():
    response = client.get("/api/items")
    assert response.status_code == 200

    body = response.json()
    assert "items" in body
    assert isinstance(body["items"], list)
    assert len(body["items"]) > 0

    # Each item should have id and name
    for item in body["items"]:
        assert "id" in item
        assert "name" in item


def test_create_item_returns_201_and_item():
    initial = client.get("/api/items").json()["items"]
    initial_count = len(initial)

    response = client.post("/api/items", json={"name": "Test item"})
    assert response.status_code == 201

    body = response.json()
    assert body["name"] == "Test item"
    assert body["done"] is False
    assert "id" in body
    assert isinstance(body["id"], int)

    # Verify it was appended to the database
    after = client.get("/api/items").json()["items"]
    assert len(after) == initial_count + 1
    assert after[-1]["name"] == "Test item"


def test_create_item_with_done_true():
    response = client.post("/api/items", json={"name": "Done item", "done": True})
    assert response.status_code == 201

    body = response.json()
    assert body["name"] == "Done item"
    assert body["done"] is True


def test_create_item_missing_name_returns_422():
    response = client.post("/api/items", json={"done": False})
    assert response.status_code == 422


def test_create_item_empty_name_returns_422():
    response = client.post("/api/items", json={"name": ""})
    assert response.status_code == 422


def test_created_item_appears_in_get():
    response = client.post("/api/items", json={"name": "GET visible item"})
    assert response.status_code == 201
    created_id = response.json()["id"]

    # Fetch all items and verify the new one is present
    get_response = client.get("/api/items")
    assert get_response.status_code == 200
    items = get_response.json()["items"]

    found = [i for i in items if i["id"] == created_id]
    assert len(found) == 1
    assert found[0]["name"] == "GET visible item"


# --- PATCH /api/items/{item_id} ---


def test_update_item_name_returns_200_and_updated_item():
    response = client.patch("/api/items/1", json={"name": "Updated name"})
    assert response.status_code == 200

    body = response.json()
    assert body["id"] == 1
    assert body["name"] == "Updated name"
    assert body["done"] is True  # unchanged

    # Verify state was persisted via a GET
    get_resp = client.get("/api/items")
    items = get_resp.json()["items"]
    item = next(i for i in items if i["id"] == 1)
    assert item["name"] == "Updated name"
    assert item["done"] is True


def test_update_item_done_returns_200_and_toggled_item():
    response = client.patch("/api/items/4", json={"done": True})
    assert response.status_code == 200

    body = response.json()
    assert body["id"] == 4
    assert body["done"] is True
    assert body["name"] == "Add domain feature"  # unchanged

    # Verify state was persisted via a GET
    get_resp = client.get("/api/items")
    items = get_resp.json()["items"]
    item = next(i for i in items if i["id"] == 4)
    assert item["done"] is True


def test_update_missing_item_returns_404():
    response = client.patch("/api/items/9999", json={"name": "Not found"})
    assert response.status_code == 404


def test_update_item_empty_name_returns_422():
    response = client.patch("/api/items/1", json={"name": ""})
    assert response.status_code == 422


# --- DELETE /api/items/{item_id} ---


def test_delete_item_returns_200():
    initial = client.get("/api/items").json()["items"]
    initial_count = len(initial)

    response = client.delete("/api/items/1")
    assert response.status_code == 200

    body = response.json()
    assert body["id"] == 1
    assert "name" in body

    # Verify it was removed from the database
    after = client.get("/api/items").json()["items"]
    assert len(after) == initial_count - 1
    ids = [i["id"] for i in after]
    assert 1 not in ids


def test_delete_missing_item_returns_404():
    response = client.delete("/api/items/9999")
    assert response.status_code == 404


def test_deleted_item_not_in_get():
    # Create an item, delete it, then verify it's gone from GET
    create_resp = client.post("/api/items", json={"name": "To be deleted"})
    assert create_resp.status_code == 201
    created_id = create_resp.json()["id"]

    delete_resp = client.delete(f"/api/items/{created_id}")
    assert delete_resp.status_code == 200

    get_response = client.get("/api/items")
    assert get_response.status_code == 200
    items = get_response.json()["items"]
    ids = [i["id"] for i in items]
    assert created_id not in ids
