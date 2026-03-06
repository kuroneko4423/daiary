import uuid

from fastapi import HTTPException, status
from supabase import Client

BUCKET_NAME = "photos"


async def upload_photo(
    supabase: Client,
    user_id: str,
    file_bytes: bytes,
    filename: str,
    content_type: str,
) -> str:
    """Upload photo to Supabase Storage. Returns storage path."""
    file_ext = filename.rsplit(".", 1)[-1] if "." in filename else "jpg"
    storage_path = f"{user_id}/{uuid.uuid4()}_{filename}"

    try:
        supabase.storage.from_(BUCKET_NAME).upload(
            path=storage_path,
            file=file_bytes,
            file_options={"content-type": content_type},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload photo: {e}",
        )

    return storage_path


async def get_photo_url(supabase: Client, storage_path: str) -> str:
    """Get a signed URL for a photo (valid for 1 hour)."""
    try:
        result = supabase.storage.from_(BUCKET_NAME).create_signed_url(
            path=storage_path,
            expires_in=3600,
        )
        return result["signedURL"]
    except Exception:
        return ""


async def delete_photo(supabase: Client, storage_path: str) -> None:
    """Delete photo from Supabase Storage."""
    try:
        supabase.storage.from_(BUCKET_NAME).remove([storage_path])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete photo: {e}",
        )


async def get_storage_usage(supabase: Client, user_id: str) -> int:
    """Get total storage used by a user in bytes."""
    try:
        files = supabase.storage.from_(BUCKET_NAME).list(path=user_id)
        total_bytes = sum(f.get("metadata", {}).get("size", 0) for f in files)
        return total_bytes
    except Exception:
        return 0
