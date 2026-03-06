from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class PhotoUpload(BaseModel):
    original_filename: str | None = None
    width: int | None = None
    height: int | None = None
    exif_data: dict[str, Any] = {}


class PhotoResponse(BaseModel):
    id: UUID
    user_id: UUID
    storage_path: str
    thumbnail_path: str | None = None
    original_filename: str | None = None
    file_size: int | None = None
    width: int | None = None
    height: int | None = None
    exif_data: dict[str, Any] = {}
    ai_tags: list[str] = []
    is_favorite: bool = False
    url: str | None = None
    created_at: datetime


class PhotoUpdate(BaseModel):
    is_favorite: bool | None = None
    ai_tags: list[str] | None = None


class PhotoListResponse(BaseModel):
    items: list[PhotoResponse]
    total: int
    offset: int
    limit: int
