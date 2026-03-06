import time
from collections import defaultdict

from fastapi import HTTPException, Request, status
from starlette.middleware.base import BaseHTTPMiddleware

FREE_DAILY_AI_LIMIT = 10


class RateLimitStore:
    """In-memory store for rate limiting per user per endpoint."""

    def __init__(self):
        # {user_id: {endpoint: {"count": int, "reset_at": float}}}
        self._store: dict[str, dict[str, dict]] = defaultdict(dict)

    def check_and_increment(
        self, user_id: str, endpoint: str, limit: int, window_seconds: int = 86400
    ) -> tuple[bool, int]:
        """Check if request is within limit. Returns (allowed, remaining)."""
        now = time.time()
        user_limits = self._store[user_id]

        if endpoint not in user_limits or now >= user_limits[endpoint]["reset_at"]:
            user_limits[endpoint] = {
                "count": 0,
                "reset_at": now + window_seconds,
            }

        entry = user_limits[endpoint]
        if entry["count"] >= limit:
            remaining = 0
            return False, remaining

        entry["count"] += 1
        remaining = limit - entry["count"]
        return True, remaining

    def get_usage(self, user_id: str, endpoint: str) -> int:
        now = time.time()
        user_limits = self._store.get(user_id, {})
        entry = user_limits.get(endpoint)
        if entry is None or now >= entry["reset_at"]:
            return 0
        return entry["count"]


rate_limit_store = RateLimitStore()


def check_ai_rate_limit(user: dict) -> None:
    """Check AI generation rate limit for a user. Raises 429 if exceeded."""
    user_id = user["id"]
    plan = user.get("plan", "free")

    if plan == "premium":
        return  # Unlimited for premium users

    allowed, remaining = rate_limit_store.check_and_increment(
        user_id=user_id,
        endpoint="ai_generation",
        limit=FREE_DAILY_AI_LIMIT,
    )

    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Daily AI generation limit ({FREE_DAILY_AI_LIMIT}) exceeded. Upgrade to premium for unlimited access.",
        )
