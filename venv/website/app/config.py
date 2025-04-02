# website/app/config.py
from pydantic import SecretStr, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import Optional
from secrets import compare_digest

class Settings(BaseSettings):
    # Supabase Configuration
    SUPABASE_URL: str
    SUPABASE_KEY: SecretStr
    
    # Authentication
    SECRET_KEY: SecretStr
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Web3 Configuration
    WEB3_PROVIDER_URL: Optional[str] = None
    
    # Security Defaults
    PASSWORD_MIN_LENGTH: int = 12
    MAX_LOGIN_ATTEMPTS: int = 5
    
    # Logging
    LOG_LEVEL: str = "INFO"
    
    # Redis Configuration
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_PASSWORD: SecretStr
    REDIS_SSL: bool = True
    REDIS_DB: int = 0
    CACHE_TTL: int = 600
    
    # Model configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra='ignore'
    )
    
    def verify_secret(self, provided_secret: str, stored_secret: SecretStr) -> bool:
        """Timing-safe secret comparison"""
        return compare_digest(provided_secret, stored_secret.get_secret_value())
    
    def get_redis_config(self) -> dict:
        """Génère la configuration Redis"""
        return {
            'host': self.REDIS_HOST,
            'port': self.REDIS_PORT,
            'password': self.REDIS_PASSWORD.get_secret_value(),
            'ssl': self.REDIS_SSL,
            'db': self.REDIS_DB,
            'decode_responses': True
        }

@lru_cache()
def get_settings():
    return Settings()

settings = get_settings()