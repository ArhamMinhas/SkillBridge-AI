"""Central application settings, loaded from environment variables.

Never hardcode secrets here — every value must come from the environment
(see .env.example). In Docker, these are supplied via docker-compose.yml's
`env_file` / `environment` directives, never baked into the image.
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    env: str = "development"
    app_name: str = "SkillBridge AI API"
    api_v1_prefix: str = "/api/v1"

    # CORS — comma-separated origins, e.g. "https://app.skillbridge.ai,http://localhost:3000"
    cors_origins: str = "http://localhost:3000"

    # Firebase
    firebase_project_id: str = ""
    # Path to the service account JSON file (mounted into the container, never committed).
    firebase_credentials_path: str = "/run/secrets/firebase-service-account.json"

    # AI provider
    ai_provider: str = "gemini"  # "gemini" or "openai"
    gemini_api_key: str = ""
    openai_api_key: str = ""

    # Stripe
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    stripe_price_id_premium_monthly: str = ""
    stripe_price_id_premium_yearly: str = ""

    # Rate limiting (AI endpoints)
    ai_rate_limit_per_minute: int = 10

    @property
    def cors_origin_list(self) -> List[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def is_production(self) -> bool:
        return self.env == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()
