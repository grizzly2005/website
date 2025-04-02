from typing import List
from fastapi import APIRouter, Depends
from app.services.blog_service import BlogService
from app.models.blog import BlogCreate, Blog
from app.utils.security import verify_jwt_token

router = APIRouter(prefix="/blogs", tags=["Blogs"])

@router.post("/", response_model=Blog)
async def create_blog(
    blog: BlogCreate, 
    current_user = Depends(verify_jwt_token),
    blog_service: BlogService = Depends()
):
    return await blog_service.create_blog(blog, current_user.id)

@router.get("/", response_model=List[Blog])
async def get_blogs(
    current_user = Depends(verify_jwt_token),
    blog_service: BlogService = Depends()
):
    return await blog_service.get_blogs(current_user.id)
