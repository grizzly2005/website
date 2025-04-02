# website/app/utils/cache.py
import json
import logging
from functools import wraps
from typing import Callable, Optional, Any
import redis.asyncio as redis
from pydantic import BaseModel
from app.config import settings

logger = logging.getLogger(__name__)

class RedisCache:
    """Client Redis avec gestion de connexion et sérialisation JSON"""

    def __init__(self):
        self.client = None
        self._connect()

    def _connect(self):
        try:
            redis_config = settings.get_redis_config()
            self.client = redis.Redis(**redis_config)
            logger.info("Connecté à Redis avec succès")
        except Exception as e:
            logger.critical(f"Échec connexion Redis: {str(e)}")
            raise

    async def get(self, key: str, model: Optional[BaseModel] = None) -> Any:
        """Récupère une donnée avec désérialisation optionnelle"""
        try:
            data = await self.client.get(key)
            if not data:
                return None

            decoded = json.loads(data)
            return model(**decoded) if model else decoded

        except redis.ConnectionError:
            logger.warning("Reconnexion à Redis...")
            self._connect()
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """Stocke une donnée avec sérialisation et TTL"""
        try:
            serialized = json.dumps(
                value.dict() if isinstance(value, BaseModel) else value
            )
            return await self.client.setex(key, ttl, serialized)
        except (TypeError, redis.ConnectionError) as e:
            logger.error(f"Échec mise en cache: {str(e)}")
            return False

    async def delete(self, *keys: str) -> int:
        """Supprime une ou plusieurs clés"""
        return await self.client.delete(*keys)

    async def healthcheck(self) -> bool:
        """Vérifie l'état de la connexion Redis"""
        try:
            return await self.client.ping()
        except redis.ConnectionError:
            return False

# Singleton du client Redis
cache = RedisCache()

def cached(key_template: str, ttl: int = 300, model: Optional[BaseModel] = None):
    """Décorateur de cache générique"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cache_key = key_template.format(*args, **kwargs)
            cached_data = await cache.get(cache_key, model)
            
            if cached_data:
                return cached_data
                
            result = await func(*args, **kwargs)
            
            if result is not None:
                await cache.set(cache_key, result, ttl)
                
            return result
        return wrapper
    return decorator

# Exportez explicitement le décorateur
__all__ = ['cache', 'cached']