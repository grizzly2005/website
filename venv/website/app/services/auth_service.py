from supabase import create_client
from app.config import settings
from app.models.user import UserCreate, UserResponse, TokenResponse
from app.exceptions.custom import (
    UserAlreadyExistsError, 
    InvalidCredentialsError,
    TokenExpiredError
)
import uuid
import re
from typing import Optional, Dict, Any

class AuthService:
    def __init__(self):
        """
        Initialisation du service d'authentification avec le client Supabase
        """
        try:
            self.client = create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_KEY.get_secret_value()
            )
        except Exception as e:
            print(f"Erreur d'initialisation du client Supabase : {e}")
            raise RuntimeError("Impossible d'initialiser le service d'authentification")
    
    async def register_user(self, user_data: UserCreate) -> UserResponse:
        """
        Enregistrement d'un nouvel utilisateur
        
        :param user_data: Données de création de l'utilisateur
        :return: Réponse avec les informations de l'utilisateur
        """
        try:
            # Validation préalable (peut être déplacée dans un validateur séparé)
            self._validate_registration_data(user_data)

            # Création du compte dans auth.users
            auth_response = self.client.auth.sign_up({
                "email": user_data.email,
                "password": user_data.password.get_secret_value()
            })
            
            if not auth_response or not auth_response.user:
                raise RuntimeError("Échec de la création de l'utilisateur")

            # Préparation des données de profil
            profile_data = {
                "user_id": auth_response.user.id,
                "username": self._prepare_username(user_data.username, user_data.email),
                "email": user_data.email
            }
            
            # Insertion du profil
            profile_response = (
                self.client.table('profiles')
                .insert(profile_data)
                .execute()
            )

            # Assignation du rôle par défaut
            await self._assign_default_role(auth_response.user.id)

            return UserResponse(
                id=auth_response.user.id,
                email=auth_response.user.email,
                username=profile_data['username']
            )

        except Exception as e:
            # Gestion des erreurs spécifiques
            if 'User already registered' in str(e):
                raise UserAlreadyExistsError()
            
            # Log de l'erreur (à remplacer par un système de logging approprié)
            print(f"Erreur lors de l'inscription : {str(e)}")
            raise RuntimeError(f"Erreur lors de l'inscription : {str(e)}")

    def _validate_registration_data(self, user_data: UserCreate):
        """
        Validation des données d'inscription
        
        :param user_data: Données de l'utilisateur à valider
        """
        # Validation de l'email
        if not re.match(r"[^@]+@[^@]+\.[^@]+", user_data.email):
            raise ValueError("Format d'email invalide")
        
        # Validation du mot de passe (déjà fait par le validateur Pydantic)
        password = user_data.password.get_secret_value()
        
        # Validation du username si fourni
        if user_data.username:
            if not re.match(r'^[a-zA-Z0-9_]{3,30}$', user_data.username):
                raise ValueError("Le nom d'utilisateur doit contenir 3-30 caractères alphanumériques ou underscores")

    def _prepare_username(self, username: Optional[str], email: str) -> str:
        """
        Préparer un username unique
        
        :param username: Username proposé
        :param email: Email de l'utilisateur
        :return: Username unique
        """
        if username:
            # Vérifier l'unicité du username
            existing_username = (
                self.client.table('profiles')
                .select('username')
                .eq('username', username.lower())
                .execute()
            )
            
            if existing_username.data:
                # Si le username existe, on ajoute un suffixe
                username = f"{username}_{str(uuid.uuid4())[:4]}"
        
        if not username:
            # Générer un username à partir de l'email
            base_username = email.split('@')[0]
            username = f"{base_username}_{str(uuid.uuid4())[:8]}"
        
        return username.lower()

    async def login_user(self, username: str, password: str) -> TokenResponse:
        """
        Authentification d'un utilisateur
        
        :param username: Nom d'utilisateur
        :param password: Mot de passe
        :return: Tokens d'authentification
        """
        try:
            # Étape 1 : Rechercher le profil par username
            profile_response = (
                self.client.table('profiles')
                .select('user_id, email')
                .eq('username', username.lower())
                .execute()
            )

            # Vérifier si le profil existe
            if not profile_response.data:
                raise InvalidCredentialsError("Nom d'utilisateur non trouvé")

            # Récupérer l'email
            email = profile_response.data[0]['email']

            # Étape 2 : Tentative de connexion
            try:
                response = self.client.auth.sign_in_with_password({
                    "email": email,
                    "password": password
                })
            except Exception as auth_error:
                # Gestion des erreurs d'authentification spécifiques
                error_message = str(auth_error).lower()
                
                if "invalid login credentials" in error_message:
                    raise InvalidCredentialsError("Mot de passe incorrect")
                elif "user not found" in error_message:
                    raise InvalidCredentialsError("Utilisateur non trouvé")
                else:
                    raise InvalidCredentialsError("Erreur d'authentification")

            # Vérification de la session
            if not response.session:
                raise TokenExpiredError("Impossible de créer une session")

            # Récupération des rôles (optionnel)
            roles = self._get_user_roles(profile_response.data[0]['user_id'])

            # Retourner les tokens
            return TokenResponse(
                access_token=response.session.access_token,
                refresh_token=response.session.refresh_token,
                expires_at=response.session.expires_at or 0,
                token_type="bearer"
            )

        except (InvalidCredentialsError, TokenExpiredError) as e:
            # Réutilisation des exceptions personnalisées
            raise e
        except Exception as e:
            # Logging de l'erreur (à remplacer par un système de logging approprié)
            print(f"Erreur de connexion inattendue : {str(e)}")
            raise InvalidCredentialsError("Erreur de connexion")

    def _get_user_roles(self, user_id: str) -> list:
        """
        Récupérer les rôles de l'utilisateur
        
        :param user_id: ID de l'utilisateur
        :return: Liste des rôles
        """
        try:
            roles_response = (
                self.client.table('user_roles')
                .select('roles!inner(role_name)')
                .eq('user_id', user_id)
                .execute()
            )
            return [role['role_name'] for role in roles_response.data] if roles_response.data else []
        except Exception as e:
            print(f"Erreur lors de la récupération des rôles : {e}")
            return []

    async def _assign_default_role(self, user_id: str):
        """
        Assignation du rôle par défaut
        
        :param user_id: ID de l'utilisateur
        """
        try:
            # Utiliser la procédure stockée pour l'assignation de rôle
            self.client.rpc('secure_role_assignment', {
                "target_user_id": user_id,
                "new_role_name": "user",
                "assigning_user_id": user_id
            })

        except Exception as e:
            print(f"Erreur d'assignation de rôle : {e}")

    # Méthodes supplémentaires potentielles
    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """
        Rafraîchissement du token
        
        :param refresh_token: Token de rafraîchissement
        :return: Nouveaux tokens
        """
        try:
            response = self.client.auth.refresh_session(refresh_token)
            
            if not response.session:
                raise TokenExpiredError("Impossible de rafraîchir la session")

            return TokenResponse(
                access_token=response.session.access_token,
                refresh_token=response.session.refresh_token,
                expires_at=response.session.expires_at or 0,
                token_type="bearer"
            )
        except Exception as e:
            print(f"Erreur de rafraîchissement du token : {e}")
            raise TokenExpiredError("Impossible de rafraîchir le token")