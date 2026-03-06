from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from config.database import get_supabase_client

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Verify JWT token via Supabase and return user info."""
    token = credentials.credentials
    try:
        supabase = get_supabase_client()
        user_response = supabase.auth.get_user(token)
        supabase_user = user_response.user
        if supabase_user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )

        # Fetch user profile from public.users table
        profile = (
            supabase.table("users")
            .select("*")
            .eq("id", str(supabase_user.id))
            .single()
            .execute()
        )

        return {
            "id": str(supabase_user.id),
            "email": supabase_user.email,
            "plan": profile.data.get("plan", "free") if profile.data else "free",
            "username": profile.data.get("username") if profile.data else None,
            "daily_ai_count": profile.data.get("daily_ai_count", 0)
            if profile.data
            else 0,
            "storage_used_bytes": profile.data.get("storage_used_bytes", 0)
            if profile.data
            else 0,
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
