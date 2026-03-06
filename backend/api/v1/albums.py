import secrets
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from api.deps import get_supabase
from middleware.auth import get_current_user
from schemas.album import (
    AlbumCreate,
    AlbumDetailResponse,
    AlbumPhotosAdd,
    AlbumResponse,
    AlbumUpdate,
)
from schemas.photo import PhotoResponse
from services import storage_service

router = APIRouter()


def _album_to_response(album: dict) -> AlbumResponse:
    return AlbumResponse(
        id=album["id"],
        user_id=album["user_id"],
        name=album["name"],
        cover_photo_id=album.get("cover_photo_id"),
        is_public=album.get("is_public", False),
        share_token=album.get("share_token"),
        photo_count=album.get("photo_count", 0),
        created_at=album["created_at"],
        updated_at=album["updated_at"],
    )


@router.post(
    "/",
    response_model=AlbumResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_album(
    data: AlbumCreate,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Create a new album."""
    album_data = {
        "user_id": current_user["id"],
        "name": data.name,
        "is_public": data.is_public,
        "share_token": secrets.token_urlsafe(16),
        "photo_count": 0,
    }
    if data.cover_photo_id:
        album_data["cover_photo_id"] = str(data.cover_photo_id)

    try:
        result = (
            supabase.table("albums")
            .insert(album_data)
            .execute()
        )
        album = result.data[0]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create album: {e}",
        )

    return _album_to_response(album)


@router.get("/", response_model=list[AlbumResponse])
async def list_albums(
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """List user's albums."""
    result = (
        supabase.table("albums")
        .select("*")
        .eq("user_id", current_user["id"])
        .order("created_at", desc=True)
        .execute()
    )

    return [_album_to_response(a) for a in result.data]


@router.get("/{album_id}", response_model=AlbumDetailResponse)
async def get_album(
    album_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Get album details with photos."""
    result = (
        supabase.table("albums")
        .select("*")
        .eq("id", str(album_id))
        .eq("user_id", current_user["id"])
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    album = result.data

    # Fetch album photos via join table
    ap_result = (
        supabase.table("album_photos")
        .select("photo_id, sort_order")
        .eq("album_id", str(album_id))
        .order("sort_order")
        .execute()
    )

    photos = []
    for ap in ap_result.data:
        photo_result = (
            supabase.table("photos")
            .select("*")
            .eq("id", ap["photo_id"])
            .is_("deleted_at", "null")
            .single()
            .execute()
        )
        if photo_result.data:
            p = photo_result.data
            url = await storage_service.get_photo_url(
                supabase, p["storage_path"]
            )
            photos.append(
                PhotoResponse(
                    id=p["id"],
                    user_id=p["user_id"],
                    storage_path=p["storage_path"],
                    thumbnail_path=p.get("thumbnail_path"),
                    original_filename=p.get("original_filename"),
                    file_size=p.get("file_size"),
                    width=p.get("width"),
                    height=p.get("height"),
                    exif_data=p.get("exif_data", {}),
                    ai_tags=p.get("ai_tags", []),
                    is_favorite=p.get("is_favorite", False),
                    url=url,
                    created_at=p["created_at"],
                )
            )

    return AlbumDetailResponse(
        id=album["id"],
        user_id=album["user_id"],
        name=album["name"],
        cover_photo_id=album.get("cover_photo_id"),
        is_public=album.get("is_public", False),
        share_token=album.get("share_token"),
        photo_count=album.get("photo_count", 0),
        created_at=album["created_at"],
        updated_at=album["updated_at"],
        photos=photos,
    )


@router.patch("/{album_id}", response_model=AlbumResponse)
async def update_album(
    album_id: UUID,
    data: AlbumUpdate,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Update album metadata."""
    update_data = data.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update",
        )

    # Convert UUID to string for JSON serialization
    if "cover_photo_id" in update_data:
        update_data["cover_photo_id"] = str(update_data["cover_photo_id"])

    try:
        result = (
            supabase.table("albums")
            .update(update_data)
            .eq("id", str(album_id))
            .eq("user_id", current_user["id"])
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update album: {e}",
        )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    return _album_to_response(result.data[0])


@router.delete(
    "/{album_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_album(
    album_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Delete an album (does not delete the photos)."""
    # Delete album_photos entries first
    try:
        supabase.table("album_photos").delete().eq(
            "album_id", str(album_id)
        ).execute()
    except Exception:
        pass  # OK if no entries

    try:
        result = (
            supabase.table("albums")
            .delete()
            .eq("id", str(album_id))
            .eq("user_id", current_user["id"])
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete album: {e}",
        )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )


@router.post(
    "/{album_id}/photos",
    status_code=status.HTTP_201_CREATED,
)
async def add_photos_to_album(
    album_id: UUID,
    data: AlbumPhotosAdd,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Add photos to an album."""
    # Verify album ownership
    album_result = (
        supabase.table("albums")
        .select("id")
        .eq("id", str(album_id))
        .eq("user_id", current_user["id"])
        .single()
        .execute()
    )
    if not album_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    # Get current max sort_order
    existing = (
        supabase.table("album_photos")
        .select("sort_order")
        .eq("album_id", str(album_id))
        .order("sort_order", desc=True)
        .limit(1)
        .execute()
    )
    max_order = existing.data[0]["sort_order"] if existing.data else -1

    # Insert photo associations
    records = []
    for i, photo_id in enumerate(data.photo_ids):
        records.append(
            {
                "album_id": str(album_id),
                "photo_id": str(photo_id),
                "sort_order": max_order + 1 + i,
            }
        )

    try:
        supabase.table("album_photos").insert(records).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add photos to album: {e}",
        )

    # Update photo_count
    count_result = (
        supabase.table("album_photos")
        .select("*", count="exact")
        .eq("album_id", str(album_id))
        .execute()
    )
    new_count = count_result.count or 0
    supabase.table("albums").update(
        {"photo_count": new_count}
    ).eq("id", str(album_id)).execute()

    return {"added": len(data.photo_ids)}


@router.delete(
    "/{album_id}/photos/{photo_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_photo_from_album(
    album_id: UUID,
    photo_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Remove a photo from an album."""
    # Verify album ownership
    album_result = (
        supabase.table("albums")
        .select("id")
        .eq("id", str(album_id))
        .eq("user_id", current_user["id"])
        .single()
        .execute()
    )
    if not album_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    try:
        result = (
            supabase.table("album_photos")
            .delete()
            .eq("album_id", str(album_id))
            .eq("photo_id", str(photo_id))
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove photo from album: {e}",
        )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not in album",
        )

    # Update photo_count
    count_result = (
        supabase.table("album_photos")
        .select("*", count="exact")
        .eq("album_id", str(album_id))
        .execute()
    )
    new_count = count_result.count or 0
    supabase.table("albums").update(
        {"photo_count": new_count}
    ).eq("id", str(album_id)).execute()
