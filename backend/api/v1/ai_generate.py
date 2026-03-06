import logging
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from api.deps import get_supabase
from config.settings import settings
from middleware.auth import get_current_user
from schemas.ai_generate import (
    CaptionRequest,
    CaptionResponse,
    HashtagRequest,
    HashtagResponse,
    UsageResponse,
)
from services.ai_service import AIService

logger = logging.getLogger(__name__)

router = APIRouter()

FREE_DAILY_LIMIT = 10


def _get_ai_service() -> AIService:
    return AIService(api_key=settings.GEMINI_API_KEY)


async def _check_and_increment_usage(
    supabase: Client, user: dict
) -> None:
    """Check daily AI usage limit and increment counter.

    Resets the counter if daily_ai_reset_at is before today.
    Raises HTTP 429 if limit exceeded for free users.
    """
    user_id = user["id"]
    is_premium = user.get("plan") == "premium"
    today = date.today().isoformat()

    # Fetch current user record
    profile = (
        supabase.table("users")
        .select("daily_ai_count, daily_ai_reset_at")
        .eq("id", user_id)
        .single()
        .execute()
    )
    data = profile.data or {}
    daily_count = data.get("daily_ai_count", 0)
    reset_at = data.get("daily_ai_reset_at")

    # Reset counter if it's a new day
    if reset_at is None or str(reset_at) < today:
        daily_count = 0

    # Check limit for free users
    if not is_premium and daily_count >= FREE_DAILY_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Daily AI generation limit reached. Upgrade to premium for unlimited generations.",
        )

    # Increment counter
    supabase.table("users").update(
        {
            "daily_ai_count": daily_count + 1,
            "daily_ai_reset_at": today,
        }
    ).eq("id", user_id).execute()


async def _get_photo_bytes(
    supabase: Client, photo_id: str, user_id: str
) -> bytes:
    """Fetch photo record and download bytes from storage."""
    result = (
        supabase.table("photos")
        .select("storage_path")
        .eq("id", photo_id)
        .eq("user_id", user_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not found",
        )

    storage_path = result.data["storage_path"]
    try:
        file_bytes = supabase.storage.from_("photos").download(storage_path)
        return file_bytes
    except Exception as e:
        logger.error("Failed to download photo %s: %s", photo_id, e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to download photo from storage",
        )


@router.post(
    "/hashtags",
    response_model=HashtagResponse,
    status_code=status.HTTP_201_CREATED,
)
async def generate_hashtags(
    data: HashtagRequest,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Generate hashtags for a photo using AI."""
    await _check_and_increment_usage(supabase, current_user)

    image_bytes = await _get_photo_bytes(
        supabase, str(data.photo_id), current_user["id"]
    )

    ai = _get_ai_service()
    result = await ai.generate_hashtags(
        image_bytes=image_bytes,
        language=data.language,
        count=data.count,
        usage=data.usage,
    )

    # Log generation to ai_generations table
    gen_record = {
        "user_id": current_user["id"],
        "photo_id": str(data.photo_id),
        "generation_type": "hashtag",
        "model": ai.model,
        "prompt": f"hashtags lang={data.language} count={data.count} usage={data.usage}",
        "result": {"hashtags": result["hashtags"]},
        "language": data.language,
        "latency_ms": result.get("latency_ms"),
    }

    try:
        gen_result = (
            supabase.table("ai_generations")
            .insert(gen_record)
            .execute()
        )
        generation_id = gen_result.data[0]["id"]
    except Exception as e:
        logger.error("Failed to log AI generation: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to log generation",
        )

    return HashtagResponse(
        hashtags=result["hashtags"],
        generation_id=generation_id,
    )


@router.post(
    "/caption",
    response_model=CaptionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def generate_caption(
    data: CaptionRequest,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Generate a caption for a photo using AI."""
    await _check_and_increment_usage(supabase, current_user)

    image_bytes = await _get_photo_bytes(
        supabase, str(data.photo_id), current_user["id"]
    )

    ai = _get_ai_service()
    result = await ai.generate_caption(
        image_bytes=image_bytes,
        language=data.language,
        style=data.style,
        length=data.length,
        custom_prompt=data.custom_prompt,
    )

    # Log generation to ai_generations table
    gen_record = {
        "user_id": current_user["id"],
        "photo_id": str(data.photo_id),
        "generation_type": "caption",
        "model": ai.model,
        "prompt": f"caption lang={data.language} style={data.style} length={data.length}",
        "result": {"caption": result["caption"]},
        "style": data.style,
        "language": data.language,
        "latency_ms": result.get("latency_ms"),
    }

    try:
        gen_result = (
            supabase.table("ai_generations")
            .insert(gen_record)
            .execute()
        )
        generation_id = gen_result.data[0]["id"]
    except Exception as e:
        logger.error("Failed to log AI generation: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to log generation",
        )

    return CaptionResponse(
        caption=result["caption"],
        generation_id=generation_id,
    )


@router.get("/usage", response_model=UsageResponse)
async def get_usage(
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Get remaining AI generations for today."""
    user_id = current_user["id"]
    is_premium = current_user.get("plan") == "premium"
    today = date.today().isoformat()

    profile = (
        supabase.table("users")
        .select("daily_ai_count, daily_ai_reset_at")
        .eq("id", user_id)
        .single()
        .execute()
    )
    data = profile.data or {}
    daily_count = data.get("daily_ai_count", 0)
    reset_at = data.get("daily_ai_reset_at")

    # Reset counter if it's a new day
    if reset_at is None or str(reset_at) < today:
        daily_count = 0
        supabase.table("users").update(
            {"daily_ai_count": 0, "daily_ai_reset_at": today}
        ).eq("id", user_id).execute()

    limit = 999999 if is_premium else FREE_DAILY_LIMIT
    remaining = max(0, limit - daily_count)

    return UsageResponse(
        used=daily_count,
        limit=limit,
        remaining=remaining,
        is_premium=is_premium,
    )
