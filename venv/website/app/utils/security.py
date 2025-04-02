from fastapi import Depends, HTTPException
from supabase import create_client
from app.config import settings

def get_supabase_client():
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

def verify_jwt_token(token: str):
    # Logique de vérification du token
    supabase = get_supabase_client()
    try:
        user = supabase.auth.get_user(token)
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")
