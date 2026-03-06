from functools import lru_cache

from supabase import Client, create_client

from config.settings import settings


@lru_cache()
def get_supabase_client() -> Client:
    """Regular client using anon key (respects RLS)."""
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)


@lru_cache()
def get_admin_supabase_client() -> Client:
    """Admin client using service role key (bypasses RLS)."""
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
