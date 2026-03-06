from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from httpx import AsyncClient

from api.deps import get_supabase
from main import app
from middleware.auth import get_current_user


@pytest.fixture(autouse=True)
def _cleanup_overrides():
    yield
    app.dependency_overrides.clear()


def _override_auth(sample_user):
    async def _dep():
        return sample_user
    return _dep


# ---- Tests ----------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_albums_empty(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/albums/ returns an empty list when no albums exist."""
    mock_supabase.execute.return_value = MagicMock(data=[])

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.get("/api/v1/albums/")

    assert response.status_code == 200
    body = response.json()
    assert body == []


@pytest.mark.asyncio
async def test_create_album(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """POST /api/v1/albums/ creates an album and returns 201."""
    album_id = str(uuid4())
    now = "2025-01-01T00:00:00+00:00"

    # The insert().execute() will return one album record
    mock_supabase.execute.return_value = MagicMock(
        data=[
            {
                "id": album_id,
                "user_id": sample_user["id"],
                "name": "Vacation",
                "cover_photo_id": None,
                "is_public": False,
                "share_token": "abc123",
                "photo_count": 0,
                "created_at": now,
                "updated_at": now,
            }
        ]
    )

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/albums/",
        json={"name": "Vacation"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Vacation"
    assert body["id"] == album_id
    assert body["photo_count"] == 0


@pytest.mark.asyncio
async def test_create_album_public(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """POST /api/v1/albums/ with is_public=True returns album with is_public set."""
    album_id = str(uuid4())
    now = "2025-01-01T00:00:00+00:00"

    mock_supabase.execute.return_value = MagicMock(
        data=[
            {
                "id": album_id,
                "user_id": sample_user["id"],
                "name": "Public Album",
                "cover_photo_id": None,
                "is_public": True,
                "share_token": "def456",
                "photo_count": 0,
                "created_at": now,
                "updated_at": now,
            }
        ]
    )

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/albums/",
        json={"name": "Public Album", "is_public": True},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["is_public"] is True


@pytest.mark.asyncio
async def test_delete_album_not_found(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """DELETE /api/v1/albums/{id} returns 404 when album does not exist."""
    mock_supabase.execute.return_value = MagicMock(data=[])

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    random_id = str(uuid4())
    response = await client.delete(f"/api/v1/albums/{random_id}")

    assert response.status_code == 404
    body = response.json()
    assert body["detail"] == "Album not found"


@pytest.mark.asyncio
async def test_get_album_not_found(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/albums/{id} returns 404 for non-existent album."""
    mock_supabase.execute.return_value = MagicMock(data=None)

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    random_id = str(uuid4())
    response = await client.get(f"/api/v1/albums/{random_id}")

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_list_albums_unauthenticated(client: AsyncClient):
    """GET /api/v1/albums/ without auth returns 403."""
    response = await client.get("/api/v1/albums/")
    assert response.status_code == 403
