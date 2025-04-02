// Copyright 2025 tatam
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     https://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

# Installation
sudo apt-get update
sudo apt-get install redis-server

# Démarrer le service
sudo systemctl start redis-server

# Vérifier le statut
sudo systemctl status redis-server



backup suppabase with error collumn:
"
/* === Extensions === */
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

/* === Configuration de Sécurité Avancée === */
CREATE SCHEMA IF NOT EXISTS security_management;

/* === Tables de Base === */
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.permissions CASCADE;
-- Table des profils utilisateurs avec contraintes améliorées
CREATE TABLE IF NOT EXISTS public.profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE 
        CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT username_lowercase CHECK (username = LOWER(username))
    
);
-- Recréation propre de la table permission
CREATE TABLE public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name TEXT NOT NULL UNIQUE
        CHECK (permission_name ~ '^[a-z_]{3,50}$'),
    description TEXT,
    permission_category TEXT, -- Colonne garantie
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- Table des rôles avec optimisations
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT NOT NULL UNIQUE
        CHECK (role_name ~ '^[a-z_]{3,30}$'),
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des permissions avec indexation
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name TEXT NOT NULL UNIQUE
        CHECK (permission_name ~ '^[a-z_]{3,50}$'),
    description TEXT,
    permission_category TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_permissions_category ON public.permissions(permission_category);

-- Tables de liaison avec contraintes améliorées
CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
    granted_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

/* === Fonctions de Sécurité Avancées === */
-- Fonction de validation améliorée
CREATE OR REPLACE FUNCTION public.secure_input_validation(
    input_text TEXT, 
    max_length INTEGER DEFAULT 255,
    allow_special_chars BOOLEAN DEFAULT FALSE
) RETURNS TEXT AS $$
BEGIN
    IF input_text IS NULL OR input_text = '' THEN
        RAISE EXCEPTION 'Input cannot be empty';
    ELSIF length(input_text) > max_length THEN
        RAISE EXCEPTION 'Input exceeds maximum length of %', max_length;
    ELSIF NOT allow_special_chars AND input_text ~ '[^a-zA-Z0-9\s]' THEN
        RAISE EXCEPTION 'Input contains invalid characters';
    END IF;
    RETURN trim(input_text);
END;
$$ LANGUAGE plpgsql STRICT SECURITY DEFINER;

/* === Politiques de Sécurité RLS === */
-- Nouvelles politiques pour la table profiles
DROP POLICY IF EXISTS "Lecture profil utilisateur" ON public.profiles;
DROP POLICY IF EXISTS "Mise à jour profil utilisateur" ON public.profiles;

CREATE POLICY "Création de profil utilisateur"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Lecture publique des profils"
ON public.profiles FOR SELECT
USING (true);

CREATE POLICY "Mise à jour profil propriétaire"
ON public.profiles FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Politique RLS améliorée pour les posts
CREATE OR REPLACE FUNCTION public.check_post_access(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = user_uuid 
        AND r.role_name IN ('admin', 'moderator', 'content_creator')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


/* === Procédures Sécurisées === */
-- Procédure d'assignation de rôle optimisée
CREATE OR REPLACE PROCEDURE public.secure_role_assignment(
    target_user_id UUID, 
    new_role_name TEXT,
    assigning_user_id UUID
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    role_id_var UUID;
BEGIN
    -- Vérification des permissions
    PERFORM 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = assigning_user_id
    AND r.role_name IN ('admin', 'user_manager');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Permissions insuffisantes pour assigner des rôles';
    END IF;

    -- Récupération de l'ID du rôle
    SELECT id INTO role_id_var 
    FROM public.roles 
    WHERE role_name = new_role_name;

    IF role_id_var IS NULL THEN
        RAISE EXCEPTION 'Rôle % inexistant', new_role_name;
    END IF;

    -- Insertion avec gestion de conflit
    INSERT INTO public.user_roles (user_id, role_id, assigned_by)
    VALUES (target_user_id, role_id_var, assigning_user_id)
    ON CONFLICT (user_id, role_id) DO UPDATE 
    SET assigned_by = EXCLUDED.assigned_by;

    -- Journalisation
    INSERT INTO public.security_logs (
        log_level, 
        user_id, 
        action, 
        details
    ) VALUES (
        'INFO', 
        assigning_user_id, 
        'ROLE_ASSIGNED', 
        jsonb_build_object(
            'target_user', target_user_id,
            'role', new_role_name
        )
    );
END;
$$;

/* === Configuration Finale === */
-- Activation RLS avec optimisations
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Permissions ajustées
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT INSERT ON TABLE public.profiles TO authenticated;
DROP INDEX IF EXISTS public.idx_permissions_category;


-- Recréer l'index correctement
CREATE INDEX idx_permissions_category ON public.permissions(permission_category);
/* === Correction de la table permissions === */
-- Suppression sécurisée de la table existante
DROP TABLE IF EXISTS public.permissions CASCADE;

-- Recréation de la table avec la colonne manquante
CREATE TABLE public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name TEXT NOT NULL UNIQUE
        CHECK (permission_name ~ '^[a-z_]{3,50}$'),
    description TEXT,
    permission_category TEXT, -- Colonne ajoutée
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recréation de l'index
CREATE INDEX idx_permissions_category ON public.permissions(permission_category);
"