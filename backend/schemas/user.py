from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr

from models.user import UserPlan


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    username: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: UUID
    email: str
    username: str | None = None
    avatar_url: str | None = None
    plan: UserPlan = UserPlan.free
    storage_used_bytes: int = 0
    created_at: datetime


class UserUpdate(BaseModel):
    username: str | None = None
    avatar_url: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse
