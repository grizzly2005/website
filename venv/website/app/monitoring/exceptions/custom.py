# Copyright 2025 tatam
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# website/app/exceptions/custom.py
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from loguru import logger
import traceback

class AuthenticationError(HTTPException):
    def __init__(self, detail: str = "Authentication failed"):
        super().__init__(status_code=401, detail=detail)

class ValidationError(HTTPException):
    def __init__(self, detail: str = "Validation failed"):
        super().__init__(status_code=400, detail=detail)

class PermissionDeniedError(HTTPException):
    def __init__(self, detail: str = "Permission denied"):
        super().__init__(status_code=403, detail=detail)

async def global_exception_handler(request: Request, exc: Exception):
    """Gestionnaire global des exceptions"""
    if isinstance(exc, (AuthenticationError, ValidationError, PermissionDeniedError)):
        return JSONResponse(
            status_code=exc.status_code, 
            content={"detail": "An error occurred"}
        )
    
    # Logger l'erreur complète pour débogage interne
    logger.error(f"Unhandled exception: {traceback.format_exc()}")
    
    return JSONResponse(
        status_code=500, 
        content={"detail": "Internal server error"}
    )