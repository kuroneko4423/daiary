from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class GenerationType(str, Enum):
    hashtag = "hashtag"
    caption = "caption"


class AIGenerationInDB(BaseModel):
    id: UUID
    user_id: UUID
    photo_id: UUID
    generation_type: GenerationType
    model: str = "gemini-3-flash-preview"
    prompt: str | None = None
    result: dict[str, Any] = {}
    style: str | None = None
    language: str = "ja"
    latency_ms: int | None = None
    created_at: datetime
