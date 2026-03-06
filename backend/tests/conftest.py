from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from httpx import ASGITransport, AsyncClient

from main import app
from middleware.auth import get_current_user


@pytest.fixture
def sample_user():
    return {
        "id": str(uuid4()),
        "email": "test@example.com",
        "plan": "free",
        "username": "testuser",
        "daily_ai_count": 0,
        "storage_used_bytes": 0,
    }


@pytest.fixture
def mock_supabase():
    client = MagicMock()
    client.table.return_value = client
    client.select.return_value = client
    client.insert.return_value = client
    client.update.return_value = client
    client.delete.return_value = client
    client.eq.return_value = client
    client.is_.return_value = client
    client.single.return_value = client
    client.order.return_value = client
    client.range.return_value = client
    client.contains.return_value = client
    client.execute.return_value = MagicMock(data=[], count=0)
    client.storage.from_.return_value = client
    client.auth = MagicMock()
    return client


@pytest.fixture
def override_auth(sample_user):
    async def _override():
        return sample_user

    app.dependency_overrides[get_current_user] = _override
    yield
    app.dependency_overrides.clear()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as ac:
        yield ac
