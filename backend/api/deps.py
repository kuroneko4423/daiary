from supabase import Client

from config.database import get_admin_supabase_client, get_supabase_client
from config.settings import Settings, settings


async def get_settings_dep() -> Settings:
    return settings


async def get_supabase() -> Client:
    return get_supabase_client()


async def get_admin_supabase() -> Client:
    return get_admin_supabase_client()
