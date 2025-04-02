from pydantic import BaseModel, Field
from uuid import UUID
from typing import List, Optional
from datetime import datetime

class BlogBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    content: str = Field(..., min_length=10)
    category: Optional[str] = None
    tags: List[str] = []

class BlogCreate(BlogBase):
    pass

class Blog(BlogBase):
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime
