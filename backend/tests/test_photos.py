from io import BytesIO
from unittest.mock import AsyncMock, MagicMock, patch
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
async def test_list_photos_empty(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/photos/ returns an empty list when no photos exist."""
    mock_supabase.execute.return_value = MagicMock(data=[], count=0)

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.get("/api/v1/photos/")

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total"] == 0


@pytest.mark.asyncio
async def test_list_photos_with_results(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/photos/ returns photos when data exists."""
    photo_id = str(uuid4())
    photo_data = {
        "id": photo_id,
        "user_id": sample_user["id"],
        "storage_path": f"{sample_user['id']}/photo.jpg",
        "thumbnail_path": None,
        "original_filename": "photo.jpg",
        "file_size": 12345,
        "width": 1920,
        "height": 1080,
        "exif_data": {},
        "ai_tags": ["nature"],
        "is_favorite": False,
        "created_at": "2025-01-01T00:00:00+00:00",
    }
    mock_supabase.execute.return_value = MagicMock(data=[photo_data], count=1)

    # Mock the storage URL generation
    with patch(
        "services.storage_service.get_photo_url",
        new_callable=AsyncMock,
        return_value="https://example.com/signed-url",
    ):
        app.dependency_overrides[get_current_user] = _override_auth(sample_user)
        app.dependency_overrides[get_supabase] = lambda: mock_supabase

        response = await client.get("/api/v1/photos/")

    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["id"] == photo_id


@pytest.mark.asyncio
async def test_upload_photo_invalid_type(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """POST /api/v1/photos/upload with text/plain returns 400."""
    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/photos/upload",
        files={"file": ("test.txt", BytesIO(b"not an image"), "text/plain")},
    )

    assert response.status_code == 400
    body = response.json()
    assert "Unsupported file type" in body["detail"]


@pytest.mark.asyncio
async def test_upload_photo_success(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """POST /api/v1/photos/upload with a valid image returns 201."""
    photo_id = str(uuid4())
    photo_record = {
        "id": photo_id,
        "user_id": sample_user["id"],
        "storage_path": f"{sample_user['id']}/img.jpg",
        "thumbnail_path": None,
        "original_filename": "img.jpg",
        "file_size": 1024,
        "width": None,
        "height": None,
        "exif_data": {},
        "ai_tags": [],
        "is_favorite": False,
        "created_at": "2025-01-01T00:00:00+00:00",
    }
    mock_supabase.execute.return_value = MagicMock(data=[photo_record])

    with (
        patch(
            "services.storage_service.upload_photo",
            new_callable=AsyncMock,
            return_value=f"{sample_user['id']}/img.jpg",
        ),
        patch(
            "services.storage_service.get_photo_url",
            new_callable=AsyncMock,
            return_value="https://example.com/signed-url",
        ),
    ):
        app.dependency_overrides[get_current_user] = _override_auth(sample_user)
        app.dependency_overrides[get_supabase] = lambda: mock_supabase

        # Create a small valid JPEG header (minimum bytes to pass content_type check)
        jpeg_bytes = b"\xff\xd8\xff\xe0" + b"\x00" * 100
        response = await client.post(
            "/api/v1/photos/upload",
            files={"file": ("img.jpg", BytesIO(jpeg_bytes), "image/jpeg")},
        )

    assert response.status_code == 201
    body = response.json()
    assert body["id"] == photo_id


@pytest.mark.asyncio
async def test_delete_photo_not_found(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """DELETE /api/v1/photos/{id} returns 404 when mock returns empty data."""
    mock_supabase.execute.return_value = MagicMock(data=[])

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    random_id = str(uuid4())
    response = await client.delete(f"/api/v1/photos/{random_id}")

    assert response.status_code == 404
    body = response.json()
    assert body["detail"] == "Photo not found"


@pytest.mark.asyncio
async def test_get_photo_not_found(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/photos/{id} returns 404 for non-existent photo."""
    mock_supabase.execute.return_value = MagicMock(data=None)

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    random_id = str(uuid4())
    response = await client.get(f"/api/v1/photos/{random_id}")

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_list_photos_unauthenticated(client: AsyncClient):
    """GET /api/v1/photos/ without auth returns 403."""
    response = await client.get("/api/v1/photos/")
    assert response.status_code == 403
