import os
from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "ChargeSure — Intelligent EV Charging Assurance"
    TAGLINE: str = "Always a Charge Ahead."
    API_V1_PREFIX: str = "/api"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "chargesure-super-secret-production-key-2026-ev-safe")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Database (SQLite fallback, PostgreSQL / PostGIS ready)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./chargesure.db")
    
    # Environment & Demo
    DEMO_MODE: bool = os.getenv("DEMO_MODE", "true").lower() in ("true", "1", "t")
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "*"
    ]
    
    # External APIs (optional, graceful mock fallbacks)
    MAPS_API_KEY: str = os.getenv("MAPS_API_KEY", "")
    PAYMENT_GATEWAY_KEY: str = os.getenv("PAYMENT_GATEWAY_KEY", "")
    FCM_SERVER_KEY: str = os.getenv("FCM_SERVER_KEY", "")
    
    # EV Defaults
    DEFAULT_MIN_SAFETY_RESERVE_PERCENT: float = 15.0
    DEFAULT_CONSUMPTION_WH_PER_KM: float = 160.0

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
