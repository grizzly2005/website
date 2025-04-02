# website/app/security/validators.py
# website/app/security/validators.py
import re
from typing import Optional, Annotated
from pydantic import BaseModel, EmailStr, field_validator, Field
from pydantic.types import StringConstraints
from app.exceptions.custom import ValidationError

class UserRegistration(BaseModel):
    email: EmailStr
    password: Annotated[str, StringConstraints(min_length=12)]
    username: Optional[str] = Field(None, min_length=3, max_length=20)

    @field_validator('password')
    @classmethod
    def validate_password(cls, password: str) -> str:
        """Valide la complexité du mot de passe"""
        if not all([
            re.search(r'[A-Z]', password),
            re.search(r'[0-9]', password),
            re.search(r'[!@#$%^&*(),.?":{}|<>]', password)
        ]):
            raise ValidationError("Format de mot de passe invalide")
        
        return password

    @field_validator('username')
    @classmethod
    def validate_username(cls, username: Optional[str]) -> Optional[str]:
        """Valide le format du nom d'utilisateur"""
        if username and (len(username) < 3 or len(username) > 20):
            raise ValidationError("Nom d'utilisateur invalide")
        return username