"""Tests for the readiness endpoint."""

from fastapi.testclient import TestClient
from main import app
import storage
from unittest import mock

client = TestClient(app)


def test_ready_returns_200_when_database_is_queryable():
    """The readiness probe should return 200 when the database is reachable."""
    response = client.get("/api/ready")
    assert response.status_code == 200

    body = response.json()
    assert body["status"] == "ok"
    assert body["database"] == "connected"


def test_ready_returns_503_when_database_is_unreachable():
    """The readiness probe should return 503 when the database layer fails."""
    with mock.patch.object(
        storage,
        "get_items",
        side_effect=Exception("Cannot connect to database"),
    ):
        response = client.get("/api/ready")
        assert response.status_code == 503

        body = response.json()
        assert "detail" in body
        assert "Database not ready" in body["detail"]
