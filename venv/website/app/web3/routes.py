# website/app/web3/routes.py
from fastapi import APIRouter, Depends, Request
from fastapi_limiter.depends import RateLimiter 
from app.web3.service import Web3SecurityService
from app.security.dependencies import get_current_user
from app.models.user import User
from app.exceptions.custom import AuthenticationError
import time

router = APIRouter(prefix="/web3", tags=["Web3"])

@router.post("/generate-nonce", dependencies=[Depends(RateLimiter(times=5, seconds=60))])
async def generate_wallet_nonce(
    request: Request,
    address: str, 
    web3_service: Web3SecurityService = Depends()
):
    """Générer un nonce pour signature Ethereum"""
    # Vérifier l'adresse IP et limiter les requêtes
    client_ip = request.client.host
    
    nonce = web3_service.generate_nonce(address)
    return {"nonce": nonce}

@router.post("/connect-wallet", dependencies=[Depends(RateLimiter(times=3, seconds=60))])
async def connect_wallet(
    address: str,
    signature: str,
    nonce: str,
    current_user: User = Depends(get_current_user),
    web3_service: Web3SecurityService = Depends()
):
    """Connecter un portefeuille Ethereum au compte utilisateur"""
    web3_service.validate_ethereum_signature(
        message=nonce, 
        signature=signature, 
        address=address
    )
    
    # Logique de liaison du portefeuille à l'utilisateur
    return {"status": "wallet_connected"}