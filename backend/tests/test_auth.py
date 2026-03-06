from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from httpx import AsyncClient

from api.deps import get_supabase
from main import app


@pytest.fixture(autouse=True)
def _cleanup_overrides():
    """Clear dependency overrides after every test in this module."""
    yield
    app.dependency_overrides.clear()


def _make_mock_user(user_id: str, email: str = "new@example.com"):
    """Build a mock object that mimics a Supabase AuthResponse user."""
    user = MagicMock()
    user.id = user_id
    user.email = email
    user.created_at = "2025-01-01T00:00:00+00:00"
    return user


def _make_mock_session(access_token="tok-access", refresh_token="tok-refresh"):
    session = MagicMock()
    session.access_token = access_token
    session.refresh_token = refresh_token
    session.expires_in = 3600
    return session


# ---- Tests ----------------------------------------------------------------


@pytest.mark.asyncio
async def test_signup_success(client: AsyncClient, mock_supabase: MagicMock):
    """POST /api/v1/auth/signup creates user and returns token."""
    user_id = str(uuid4())
    mock_user = _make_mock_user(user_id, "new@example.com")
    mock_session = _make_mock_session()

    # Configure auth.sign_up to return a result with user + session
    signup_result = MagicMock()
    signup_result.user = mock_user
    signup_result.session = mock_session
    mock_supabase.auth.sign_up.return_value = signup_result

    # Configure the profile query (table("users").select("*")...execute())
    mock_supabase.execute.return_value = MagicMock(
        data={
            "username": "newuser",
            "plan": "free",
            "storage_used_bytes": 0,
        }
    )

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "new@example.com",
            "password": "Str0ngP@ss!",
            "username": "newuser",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["access_token"] == "tok-access"
    assert body["refresh_token"] == "tok-refresh"
    assert body["user"]["email"] == "new@example.com"


@pytest.mark.asyncio
async def test_signup_email_confirmation(
    client: AsyncClient, mock_supabase: MagicMock
):
    """POST /api/v1/auth/signup with email confirmation returns empty tokens."""
    user_id = str(uuid4())
    mock_user = _make_mock_user(user_id, "confirm@example.com")

    signup_result = MagicMock()
    signup_result.user = mock_user
    signup_result.session = None  # email confirmation required
    mock_supabase.auth.sign_up.return_value = signup_result

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "confirm@example.com",
            "password": "Str0ngP@ss!",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["access_token"] == ""
    assert body["expires_in"] == 0


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, mock_supabase: MagicMock):
    """POST /api/v1/auth/login returns token for valid credentials."""
    user_id = str(uuid4())
    mock_user = _make_mock_user(user_id, "test@example.com")
    mock_session = _make_mock_session()

    login_result = MagicMock()
    login_result.user = mock_user
    login_result.session = mock_session
    mock_supabase.auth.sign_in_with_password.return_value = login_result

    # Profile data returned by chained query
    mock_supabase.execute.return_value = MagicMock(
        data={
            "username": "testuser",
            "avatar_url": None,
            "plan": "free",
            "storage_used_bytes": 0,
        }
    )

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "Str0ngP@ss!"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["access_token"] == "tok-access"
    assert body["token_type"] == "bearer"
    assert body["user"]["email"] == "test@example.com"


@pytest.mark.asyncio
async def test_login_invalid(client: AsyncClient, mock_supabase: MagicMock):
    """POST /api/v1/auth/login returns 401 for bad credentials."""
    mock_supabase.auth.sign_in_with_password.side_effect = Exception(
        "Invalid login credentials"
    )

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "bad@example.com", "password": "wrong"},
    )

    assert response.status_code == 401
    body = response.json()
    assert "Invalid" in body["detail"]


@pytest.mark.asyncio
async def test_password_reset(client: AsyncClient, mock_supabase: MagicMock):
    """POST /api/v1/auth/password-reset returns message even for non-existent email."""
    mock_supabase.auth.reset_password_email.return_value = None

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/password-reset",
        params={"email": "nobody@example.com"},
    )

    assert response.status_code == 200
    body = response.json()
    assert "password reset link" in body["message"].lower()


@pytest.mark.asyncio
async def test_password_reset_exception_is_swallowed(
    client: AsyncClient, mock_supabase: MagicMock
):
    """POST /api/v1/auth/password-reset returns 200 even when Supabase throws."""
    mock_supabase.auth.reset_password_email.side_effect = Exception("boom")

    app.dependency_overrides[get_supabase] = lambda: mock_supabase

    response = await client.post(
        "/api/v1/auth/password-reset",
        params={"email": "nobody@example.com"},
    )

    assert response.status_code == 200
