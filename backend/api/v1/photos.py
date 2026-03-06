from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from supabase import Client

from api.deps import get_supabase
from middleware.auth import get_current_user
from schemas.photo import PhotoListResponse, PhotoResponse, PhotoUpdate
from services import storage_service

router = APIRouter()

ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


@router.post(
    "/upload",
    response_model=PhotoResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_photo(
    file: UploadFile = File(...),
    is_favorite: bool = False,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Upload a photo to storage and create a DB record."""
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Unsupported file type: {file.content_type}. "
                f"Allowed: {', '.join(ALLOWED_CONTENT_TYPES)}"
            ),
        )

    file_bytes = await file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds 10MB limit",
        )

    user_id = current_user["id"]

    # Upload to Supabase Storage
    storage_path = await storage_service.upload_photo(
        supabase=supabase,
        user_id=user_id,
        file_bytes=file_bytes,
        filename=file.filename or "photo.jpg",
        content_type=file.content_type or "image/jpeg",
    )

    # Create DB record
    photo_data = {
        "user_id": user_id,
        "storage_path": storage_path,
        "original_filename": file.filename,
        "file_size": len(file_bytes),
        "is_favorite": is_favorite,
    }

    try:
        result = (
            supabase.table("photos")
            .insert(photo_data)
            .execute()
        )
        photo = result.data[0]
    except Exception as e:
        # Clean up storage if DB insert fails
        await storage_service.delete_photo(supabase, storage_path)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create photo record: {e}",
        )

    url = await storage_service.get_photo_url(supabase, storage_path)

    return PhotoResponse(
        id=photo["id"],
        user_id=photo["user_id"],
        storage_path=photo["storage_path"],
        thumbnail_path=photo.get("thumbnail_path"),
        original_filename=photo.get("original_filename"),
        file_size=photo.get("file_size"),
        width=photo.get("width"),
        height=photo.get("height"),
        exif_data=photo.get("exif_data", {}),
        ai_tags=photo.get("ai_tags", []),
        is_favorite=photo.get("is_favorite", False),
        url=url,
        created_at=photo["created_at"],
    )


@router.get("/", response_model=PhotoListResponse)
async def list_photos(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    favorites_only: bool = Query(False),
    include_deleted: bool = Query(False),
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """List user's photos with pagination and filters."""
    user_id = current_user["id"]

    query = (
        supabase.table("photos")
        .select("*", count="exact")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
    )

    if not include_deleted:
        query = query.is_("deleted_at", "null")

    if favorites_only:
        query = query.eq("is_favorite", True)

    query = query.range(offset, offset + limit - 1)
    result = query.execute()

    items = []
    for photo in result.data:
        url = await storage_service.get_photo_url(
            supabase, photo["storage_path"]
        )
        items.append(
            PhotoResponse(
                id=photo["id"],
                user_id=photo["user_id"],
                storage_path=photo["storage_path"],
                thumbnail_path=photo.get("thumbnail_path"),
                original_filename=photo.get("original_filename"),
                file_size=photo.get("file_size"),
                width=photo.get("width"),
                height=photo.get("height"),
                exif_data=photo.get("exif_data", {}),
                ai_tags=photo.get("ai_tags", []),
                is_favorite=photo.get("is_favorite", False),
                url=url,
                created_at=photo["created_at"],
            )
        )

    return PhotoListResponse(
        items=items,
        total=result.count or 0,
        offset=offset,
        limit=limit,
    )


@router.get("/{photo_id}", response_model=PhotoResponse)
async def get_photo(
    photo_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Get a single photo by ID."""
    result = (
        supabase.table("photos")
        .select("*")
        .eq("id", str(photo_id))
        .eq("user_id", current_user["id"])
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not found",
        )

    photo = result.data
    url = await storage_service.get_photo_url(
        supabase, photo["storage_path"]
    )

    return PhotoResponse(
        id=photo["id"],
        user_id=photo["user_id"],
        storage_path=photo["storage_path"],
        thumbnail_path=photo.get("thumbnail_path"),
        original_filename=photo.get("original_filename"),
        file_size=photo.get("file_size"),
        width=photo.get("width"),
        height=photo.get("height"),
        exif_data=photo.get("exif_data", {}),
        ai_tags=photo.get("ai_tags", []),
        is_favorite=photo.get("is_favorite", False),
        url=url,
        created_at=photo["created_at"],
    )


@router.patch("/{photo_id}", response_model=PhotoResponse)
async def update_photo(
    photo_id: UUID,
    data: PhotoUpdate,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Update photo metadata."""
    update_data = data.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update",
        )

    try:
        result = (
            supabase.table("photos")
            .update(update_data)
            .eq("id", str(photo_id))
            .eq("user_id", current_user["id"])
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update photo: {e}",
        )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not found",
        )

    photo = result.data[0]
    url = await storage_service.get_photo_url(
        supabase, photo["storage_path"]
    )

    return PhotoResponse(
        id=photo["id"],
        user_id=photo["user_id"],
        storage_path=photo["storage_path"],
        thumbnail_path=photo.get("thumbnail_path"),
        original_filename=photo.get("original_filename"),
        file_size=photo.get("file_size"),
        width=photo.get("width"),
        height=photo.get("height"),
        exif_data=photo.get("exif_data", {}),
        ai_tags=photo.get("ai_tags", []),
        is_favorite=photo.get("is_favorite", False),
        url=url,
        created_at=photo["created_at"],
    )


@router.delete(
    "/{photo_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_photo(
    photo_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Soft delete a photo (set deleted_at timestamp)."""
    now = datetime.now(timezone.utc).isoformat()
    try:
        result = (
            supabase.table("photos")
            .update({"deleted_at": now})
            .eq("id", str(photo_id))
            .eq("user_id", current_user["id"])
            .is_("deleted_at", "null")
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete photo: {e}",
        )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not found",
        )


@router.get("/search/", response_model=PhotoListResponse)
async def search_photos(
    q: str = Query(..., min_length=1),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Search photos by AI tags."""
    user_id = current_user["id"]

    result = (
        supabase.table("photos")
        .select("*", count="exact")
        .eq("user_id", user_id)
        .is_("deleted_at", "null")
        .contains("ai_tags", [q])
        .order("created_at", desc=True)
        .range(offset, offset + limit - 1)
        .execute()
    )

    items = []
    for photo in result.data:
        url = await storage_service.get_photo_url(
            supabase, photo["storage_path"]
        )
        items.append(
            PhotoResponse(
                id=photo["id"],
                user_id=photo["user_id"],
                storage_path=photo["storage_path"],
                thumbnail_path=photo.get("thumbnail_path"),
                original_filename=photo.get("original_filename"),
                file_size=photo.get("file_size"),
                width=photo.get("width"),
                height=photo.get("height"),
                exif_data=photo.get("exif_data", {}),
                ai_tags=photo.get("ai_tags", []),
                is_favorite=photo.get("is_favorite", False),
                url=url,
                created_at=photo["created_at"],
            )
        )

    return PhotoListResponse(
        items=items,
        total=result.count or 0,
        offset=offset,
        limit=limit,
    )
