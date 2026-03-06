from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

import pytest
from httpx import AsyncClient

from api.deps import get_settings_dep, get_supabase
from config.settings import Settings
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


@pytest.fixture
def mock_settings():
    """Return a Settings instance with test values."""
    return Settings(
        SUPABASE_URL="https://fake.supabase.co",
        SUPABASE_KEY="fake-key",
        SUPABASE_SERVICE_KEY="fake-service-key",
        GEMINI_API_KEY="fake-gemini-key",
        APPLE_SHARED_SECRET="fake-apple-secret",
        APP_ENV="development",
    )


def _setup_overrides(sample_user, mock_supabase, mock_settings):
    """Helper to install all dependency overrides for payment endpoints."""
    app.dependency_overrides[get_current_user] = _override_auth(sample_user)
    app.dependency_overrides[get_supabase] = lambda: mock_supabase
    app.dependency_overrides[get_settings_dep] = lambda: mock_settings


# ---- Tests ----------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_subscription(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """GET /api/v1/payments/subscription returns current subscription status."""
    expires = (datetime.now(timezone.utc) + timedelta(days=15)).isoformat()
    mock_supabase.execute.return_value = MagicMock(
        data={"plan": "premium", "plan_expires_at": expires}
    )

    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.get("/api/v1/payments/subscription")

    assert response.status_code == 200
    body = response.json()
    assert body["plan"] == "premium"
    assert body["is_active"] is True


@pytest.mark.asyncio
async def test_get_subscription_free_user(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """GET /api/v1/payments/subscription returns free plan for non-subscriber."""
    mock_supabase.execute.return_value = MagicMock(
        data={"plan": "free", "plan_expires_at": None}
    )

    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.get("/api/v1/payments/subscription")

    assert response.status_code == 200
    body = response.json()
    assert body["plan"] == "free"
    assert body["is_active"] is False


@pytest.mark.asyncio
async def test_get_subscription_expired(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """GET /api/v1/payments/subscription returns inactive when premium has expired."""
    past = (datetime.now(timezone.utc) - timedelta(days=5)).isoformat()
    mock_supabase.execute.return_value = MagicMock(
        data={"plan": "premium", "plan_expires_at": past}
    )

    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.get("/api/v1/payments/subscription")

    assert response.status_code == 200
    body = response.json()
    assert body["plan"] == "premium"
    assert body["is_active"] is False


@pytest.mark.asyncio
async def test_cancel_subscription(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """POST /api/v1/payments/cancel reverts to free plan."""
    mock_supabase.execute.return_value = MagicMock(data=[{}])

    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.post("/api/v1/payments/cancel")

    assert response.status_code == 200
    body = response.json()
    assert body["plan"] == "free"
    assert body["is_active"] is False


@pytest.mark.asyncio
async def test_verify_receipt_invalid_platform(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """POST /api/v1/payments/verify-receipt with invalid platform returns 400."""
    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.post(
        "/api/v1/payments/verify-receipt",
        json={
            "platform": "windows",
            "receipt_data": "fake-receipt",
            "product_id": "com.app.premium",
        },
    )

    assert response.status_code == 400
    body = response.json()
    assert "ios" in body["detail"] or "android" in body["detail"]


@pytest.mark.asyncio
async def test_verify_receipt_android_success(
    client: AsyncClient,
    mock_supabase: MagicMock,
    sample_user: dict,
    mock_settings: Settings,
):
    """POST /api/v1/payments/verify-receipt with android platform succeeds."""
    mock_supabase.execute.return_value = MagicMock(data=[{}])

    _setup_overrides(sample_user, mock_supabase, mock_settings)

    response = await client.post(
        "/api/v1/payments/verify-receipt",
        json={
            "platform": "android",
            "receipt_data": "fake-google-token",
            "product_id": "com.app.premium.monthly",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["plan"] == "premium"
    assert body["is_active"] is True


@pytest.mark.asyncio
async def test_webhook_appstore(client: AsyncClient):
    """POST /api/v1/payments/webhook/appstore returns ok."""
    response = await client.post(
        "/api/v1/payments/webhook/appstore",
        json={"notificationType": "DID_RENEW", "data": {}},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"


@pytest.mark.asyncio
async def test_webhook_playstore(client: AsyncClient):
    """POST /api/v1/payments/webhook/playstore returns ok."""
    response = await client.post(
        "/api/v1/payments/webhook/playstore",
        json={"message": {"data": "base64encodeddata"}},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"


@pytest.mark.asyncio
async def test_webhook_appstore_invalid_json(client: AsyncClient):
    """POST /api/v1/payments/webhook/appstore with invalid JSON returns 400."""
    response = await client.post(
        "/api/v1/payments/webhook/appstore",
        content=b"not json",
        headers={"content-type": "application/json"},
    )

    assert response.status_code == 400


@pytest.mark.asyncio
async def test_webhook_playstore_invalid_json(client: AsyncClient):
    """POST /api/v1/payments/webhook/playstore with invalid JSON returns 400."""
    response = await client.post(
        "/api/v1/payments/webhook/playstore",
        content=b"not json",
        headers={"content-type": "application/json"},
    )

    assert response.status_code == 400
