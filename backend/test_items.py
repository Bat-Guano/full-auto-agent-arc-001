from fastapi.testclient import TestClient
from main import app, ITEMS

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
    initial_count = len(ITEMS)

    response = client.post("/api/items", json={"name": "Test item"})
    assert response.status_code == 201

    body = response.json()
    assert body["name"] == "Test item"
    assert body["done"] is False
    assert "id" in body
    assert isinstance(body["id"], int)

    # Verify it was appended to the list
    assert len(ITEMS) == initial_count + 1
    assert ITEMS[-1]["name"] == "Test item"


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
