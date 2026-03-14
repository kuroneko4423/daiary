from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    GEMINI_API_KEY: str = ""

    APPLE_SHARED_SECRET: str = ""
    GOOGLE_PLAY_SERVICE_ACCOUNT_KEY: str = ""

    APP_ENV: str = "development"
    APP_DEBUG: bool = True
    SECRET_KEY: str = ""
    CORS_ORIGINS: str = "http://localhost:3000"
    LOG_TO_DB: bool = True

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    model_config = {"env_file": ".env"}


settings = Settings()
