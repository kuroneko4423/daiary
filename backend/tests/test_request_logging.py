from middleware.logging import _redact


class TestRedact:
    def test_removes_sensitive_fields(self):
        data = {
            "email": "test@example.com",
            "password": "secret123",
            "username": "testuser",
        }
        result = _redact(data)
        assert "email" not in result
        assert "password" not in result
        assert result["username"] == "testuser"

    def test_removes_token_fields(self):
        data = {
            "refresh_token": "abc123",
            "access_token": "xyz789",
            "token": "tok",
            "platform": "ios",
        }
        result = _redact(data)
        assert "refresh_token" not in result
        assert "access_token" not in result
        assert "token" not in result
        assert result["platform"] == "ios"

    def test_removes_receipt_data(self):
        data = {
            "receipt_data": "long_receipt_string",
            "product_id": "premium_monthly",
        }
        result = _redact(data)
        assert "receipt_data" not in result
        assert result["product_id"] == "premium_monthly"

    def test_preserves_safe_fields(self):
        data = {
            "photo_id": "abc-123",
            "language": "ja",
            "count": 15,
            "usage": "instagram",
        }
        result = _redact(data)
        assert result == data

    def test_empty_dict(self):
        assert _redact({}) == {}
