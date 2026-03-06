from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class PhotoInDB(BaseModel):
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
    deleted_at: datetime | None = None
    created_at: datetime
