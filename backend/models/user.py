from datetime import date, datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, EmailStr


class UserPlan(str, Enum):
    free = "free"
    premium = "premium"


class UserInDB(BaseModel):
    id: UUID
    email: str
    username: str | None = None
    avatar_url: str | None = None
    plan: UserPlan = UserPlan.free
    plan_expires_at: datetime | None = None
    daily_ai_count: int = 0
    daily_ai_reset_at: date | None = None
    storage_used_bytes: int = 0
    created_at: datetime
    updated_at: datetime
