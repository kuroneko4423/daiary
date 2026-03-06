from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from api.deps import get_supabase
from middleware.auth import get_current_user
from schemas.user import TokenResponse, UserCreate, UserLogin, UserResponse

router = APIRouter()


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    data: UserCreate,
    supabase: Client = Depends(get_supabase),
):
    """Create a new user via Supabase Auth."""
    try:
        result = supabase.auth.sign_up(
            {
                "email": data.email,
                "password": data.password,
                "options": {
                    "data": {"username": data.username or data.email.split("@")[0]},
                },
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    if result.user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signup failed",
        )

    session = result.session
    if session is None:
        # Email confirmation required
        return TokenResponse(
            access_token="",
            refresh_token="",
            expires_in=0,
            user=UserResponse(
                id=result.user.id,
                email=result.user.email,
                username=data.username,
                created_at=result.user.created_at,
            ),
        )

    # Fetch user profile
    profile = (
        supabase.table("users")
        .select("*")
        .eq("id", str(result.user.id))
        .single()
        .execute()
    )

    return TokenResponse(
        access_token=session.access_token,
        refresh_token=session.refresh_token,
        expires_in=session.expires_in,
        user=UserResponse(
            id=result.user.id,
            email=result.user.email,
            username=profile.data.get("username") if profile.data else data.username,
            plan=profile.data.get("plan", "free") if profile.data else "free",
            storage_used_bytes=profile.data.get("storage_used_bytes", 0) if profile.data else 0,
            created_at=result.user.created_at,
        ),
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    data: UserLogin,
    supabase: Client = Depends(get_supabase),
):
    """Login with email and password."""
    try:
        result = supabase.auth.sign_in_with_password(
            {"email": data.email, "password": data.password}
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    session = result.session
    user = result.user

    # Fetch user profile
    profile = (
        supabase.table("users")
        .select("*")
        .eq("id", str(user.id))
        .single()
        .execute()
    )

    return TokenResponse(
        access_token=session.access_token,
        refresh_token=session.refresh_token,
        expires_in=session.expires_in,
        user=UserResponse(
            id=user.id,
            email=user.email,
            username=profile.data.get("username") if profile.data else None,
            avatar_url=profile.data.get("avatar_url") if profile.data else None,
            plan=profile.data.get("plan", "free") if profile.data else "free",
            storage_used_bytes=profile.data.get("storage_used_bytes", 0) if profile.data else 0,
            created_at=user.created_at,
        ),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    refresh_token: str,
    supabase: Client = Depends(get_supabase),
):
    """Refresh access token using refresh token."""
    try:
        result = supabase.auth.refresh_session(refresh_token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )

    session = result.session
    user = result.user

    profile = (
        supabase.table("users")
        .select("*")
        .eq("id", str(user.id))
        .single()
        .execute()
    )

    return TokenResponse(
        access_token=session.access_token,
        refresh_token=session.refresh_token,
        expires_in=session.expires_in,
        user=UserResponse(
            id=user.id,
            email=user.email,
            username=profile.data.get("username") if profile.data else None,
            plan=profile.data.get("plan", "free") if profile.data else "free",
            storage_used_bytes=profile.data.get("storage_used_bytes", 0) if profile.data else 0,
            created_at=user.created_at,
        ),
    )


@router.post("/password-reset")
async def password_reset(
    email: str,
    supabase: Client = Depends(get_supabase),
):
    """Send password reset email."""
    try:
        supabase.auth.reset_password_email(email)
    except Exception:
        pass  # Don't reveal if email exists
    return {"message": "If the email exists, a password reset link has been sent."}


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase),
):
    """Delete user account."""
    from config.database import get_admin_supabase_client

    try:
        admin = get_admin_supabase_client()
        admin.auth.admin.delete_user(current_user["id"])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete account: {e}",
        )
