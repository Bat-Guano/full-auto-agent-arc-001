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
