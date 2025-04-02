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

# website/app/web3/service.py
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct
import time
import redis
from app.exceptions.custom import AuthenticationError, ValidationError

class Web3SecurityService:
    def __init__(self, provider_url: str, redis_client: redis.Redis):
        self.w3 = Web3(Web3.HTTPProvider(provider_url))
        self.redis = redis_client

    def validate_ethereum_signature(
        self, 
        message: str, 
        signature: str, 
        address: str
    ):
        try:
            # Vérifier le nonce
            cached_nonce = self.redis.get(f"nonce:{address}")
            if not cached_nonce:
                raise ValidationError("Nonce expired or invalid")

            # Validation de signature
            signable_message = encode_defunct(text=message)
            recovered_address = Account.recover_message(
                signable_message, 
                signature=signature
            )
            
            if recovered_address.lower() != address.lower():
                raise AuthenticationError("Invalid signature")
            
            # Supprimer le nonce après utilisation
            self.redis.delete(f"nonce:{address}")
            
            return True
        except Exception as e:
            raise AuthenticationError(f"Signature validation failed")

    def generate_nonce(self, address: str) -> str:
        """Générer un nonce avec Redis"""
        nonce = Web3.keccak(text=f"{address}{time.time()}").hex()
        self.redis.setex(f"nonce:{address}", 300, nonce)  # Expire après 5 min
        return nonce

    def verify_contract(self, address: str, abi: dict):
        """Vérification de contrat"""
        try:
            return self.w3.eth.contract(address=address, abi=abi)
        except Exception as e:
            raise ValidationError("Invalid contract")