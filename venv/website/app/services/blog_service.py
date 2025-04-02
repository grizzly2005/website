# app/services/blog_service.py
from typing import Dict, List, Optional
from uuid import UUID
from datetime import datetime
from fastapi import Depends, HTTPException, status

from app.utils.cache import cache, cached
from app.config import settings
from app.models.blog import BlogCreate, Blog

CACHE_TTL = 600  # 10 minutes

class BlogService:
    
    @cached(key_template="blog:{blog_id}", ttl=CACHE_TTL, model=Blog)
    async def get_blog(self, blog_id: UUID) -> Optional[Blog]:
        # Logique existante...
        pass

    @cached(key_template="user_blogs:{user_id}:page:{page}", ttl=CACHE_TTL)
    async def get_blogs(
        self, 
        user_id: Optional[UUID] = None, 
        page: int = 1, 
        per_page: int = 10
    ) -> Dict:
        # Logique existante...
        pass

    async def _invalidate_blog_cache(self, blog_id: UUID):
        """Invalide toutes les entrées liées à un blog"""
        keys_to_delete = [
            f"blog:{blog_id}",
            "recent_blogs", 
            "blog_list:*"  # Invalide les patterns globaux si nécessaire
        ]
        await cache.delete(*keys_to_delete)

    async def create_blog(self, blog_data: BlogCreate, user_id: UUID) -> Blog:
        result = await self._create_blog_in_db(blog_data, user_id)
        await self._invalidate_blog_cache(result.id)
        return result

    async def update_blog(self, blog_id: UUID, blog_data: BlogCreate, user_id: UUID) -> Blog:
        result = await self._update_blog_in_db(blog_id, blog_data, user_id)
        await self._invalidate_blog_cache(blog_id)
        return result

    async def delete_blog(self, blog_id: UUID, user_id: UUID) -> bool:
        success = await self._delete_blog_in_db(blog_id, user_id)
        if success:
            await self._invalidate_blog_cache(blog_id)
        return success