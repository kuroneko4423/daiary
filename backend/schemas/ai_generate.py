from uuid import UUID

from pydantic import BaseModel, Field


class HashtagRequest(BaseModel):
    photo_id: UUID
    language: str = "ja"
    count: int = Field(default=15, ge=1, le=30)
    usage: str = "instagram"


class HashtagResponse(BaseModel):
    hashtags: list[str]
    generation_id: UUID


class CaptionRequest(BaseModel):
    photo_id: UUID
    language: str = "ja"
    style: str = "casual"
    length: str = "medium"
    custom_prompt: str | None = None


class CaptionResponse(BaseModel):
    caption: str
    generation_id: UUID


class UsageResponse(BaseModel):
    used: int
    limit: int
    remaining: int
    is_premium: bool
