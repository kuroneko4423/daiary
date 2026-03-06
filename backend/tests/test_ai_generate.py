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


def _override_auth(user):
    async def _dep():
        return user
    return _dep


# ---- Tests ----------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_usage_free_user(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/ai/usage returns usage info for a free user."""
    # Profile query returns current usage
    mock_supabase.execute.return_value = MagicMock(
        data={"daily_ai_count": 3, "daily_ai_reset_at": "2099-12-31"}
    )

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.get("/api/v1/ai/usage")

    assert response.status_code == 200
    body = response.json()
    assert body["used"] == 3
    assert body["limit"] == 10  # FREE_DAILY_LIMIT
    assert body["remaining"] == 7
    assert body["is_premium"] is False


@pytest.mark.asyncio
async def test_get_usage_premium_user(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/ai/usage returns high limit for premium user."""
    premium_user = {**sample_user, "plan": "premium"}

    mock_supabase.execute.return_value = MagicMock(
        data={"daily_ai_count": 50, "daily_ai_reset_at": "2099-12-31"}
    )

    app.dependency_overrides[get_current_user] = _override_auth(premium_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.get("/api/v1/ai/usage")

    assert response.status_code == 200
    body = response.json()
    assert body["used"] == 50
    assert body["limit"] == 999999
    assert body["is_premium"] is True


@pytest.mark.asyncio
async def test_get_usage_counter_reset_on_new_day(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """GET /api/v1/ai/usage resets counter when daily_ai_reset_at is in the past."""
    # Return a reset date in the past so the counter resets to 0
    mock_supabase.execute.return_value = MagicMock(
        data={"daily_ai_count": 5, "daily_ai_reset_at": "2020-01-01"}
    )

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.get("/api/v1/ai/usage")

    assert response.status_code == 200
    body = response.json()
    # Counter should have been reset to 0
    assert body["used"] == 0
    assert body["remaining"] == 10


@pytest.mark.asyncio
async def test_usage_limit_respected_free_user(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """Verify that free users who have exhausted their daily limit get 429.

    We test this through the hashtag generation endpoint which calls
    _check_and_increment_usage internally.
    """
    # Simulate a free user with count already at the limit
    mock_supabase.execute.return_value = MagicMock(
        data={"daily_ai_count": 10, "daily_ai_reset_at": "2099-12-31"}
    )

    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    photo_id = str(uuid4())
    response = await client.post(
        "/api/v1/ai/hashtags",
        json={"photo_id": photo_id},
    )

    assert response.status_code == 429
    body = response.json()
    assert "limit reached" in body["detail"].lower()


@pytest.mark.asyncio
async def test_usage_limit_not_applied_to_premium(
    client: AsyncClient, mock_supabase: MagicMock, sample_user: dict
):
    """Verify that premium users are NOT blocked even at high usage counts.

    We check that _check_and_increment_usage does not raise 429 for
    premium users. The request will proceed further (and may fail for
    other reasons, e.g. missing photo), but importantly NOT with 429.
    """
    premium_user = {**sample_user, "plan": "premium"}

    # Use side_effect to return different data for sequential calls:
    # 1st call: _check_and_increment_usage reads user profile
    # 2nd call: _check_and_increment_usage updates counter (ignored)
    # 3rd call: _get_photo_bytes reads photo record - returns no data (404)
    mock_supabase.execute.side_effect = [
        MagicMock(data={"daily_ai_count": 9999, "daily_ai_reset_at": "2099-12-31"}),
        MagicMock(data=None),  # update counter result
        MagicMock(data=None),  # photo lookup returns empty -> 404
    ]

    app.dependency_overrides[get_current_user] = _override_auth(premium_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    photo_id = str(uuid4())
    response = await client.post(
        "/api/v1/ai/hashtags",
        json={"photo_id": photo_id},
    )

    # The request should NOT be 429 for premium users.
    # It should be 404 (photo not found) since mock returns no photo data.
    assert response.status_code != 429
    assert response.status_code == 404
