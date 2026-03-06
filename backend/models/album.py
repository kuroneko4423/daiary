from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AlbumInDB(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    cover_photo_id: UUID | None = None
    is_public: bool = False
    share_token: str | None = None
    created_at: datetime
    updated_at: datetime


class AlbumPhotoInDB(BaseModel):
    album_id: UUID
    photo_id: UUID
    sort_order: int = 0
    added_at: datetime
