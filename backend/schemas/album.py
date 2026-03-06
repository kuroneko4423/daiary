from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from schemas.photo import PhotoResponse


class AlbumCreate(BaseModel):
    name: str
    cover_photo_id: UUID | None = None
    is_public: bool = False


class AlbumResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    cover_photo_id: UUID | None = None
    is_public: bool = False
    share_token: str | None = None
    photo_count: int = 0
    created_at: datetime
    updated_at: datetime


class AlbumDetailResponse(AlbumResponse):
    photos: list[PhotoResponse] = []


class AlbumUpdate(BaseModel):
    name: str | None = None
    cover_photo_id: UUID | None = None
    is_public: bool | None = None


class AlbumPhotosAdd(BaseModel):
    photo_ids: list[UUID]
