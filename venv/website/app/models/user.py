from pydantic import BaseModel, EmailStr, SecretStr, field_validator
from typing import Optional
from uuid import UUID

class UserCreate(BaseModel):
    email: EmailStr
    password: SecretStr
    username: Optional[str] = None

    @field_validator('password')
    def validate_password(cls, v):
        password = v.get_secret_value()
        if len(password) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caractères")
        if not any(c.isupper() for c in password):
            raise ValueError("Doit contenir au moins une majuscule")
        return v

class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_at: int