# app/__init__.py
"""
Initialisation du package de l'application
Permet d'importer et configurer les composants principaux
"""

from fastapi import FastAPI
from app.routes import auth_routes, blog_routes
from app.config import settings

def create_app() -> FastAPI:
    """
    Fonction de création de l'application FastAPI
    Centralise la configuration et l'initialisation
    """
    app = FastAPI(
        title="Blog Platform",
        description="Plateforme de blogs sécurisée",
        version="0.1.0"
    )

    # Inclusion des routeurs
    app.include_router(auth_routes.router, prefix="/auth")
    app.include_router(blog_routes.router, prefix="/blogs")

    return app
