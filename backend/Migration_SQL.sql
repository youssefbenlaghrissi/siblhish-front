-- Migration SQL pour ajouter le champ fcm_token à la table users
-- 
-- À exécuter dans votre base de données ou à ajouter dans vos migrations (Flyway/Liquibase)
--
-- Si vous utilisez Flyway, créez un fichier :
-- src/main/resources/db/migration/Vxxx__add_fcm_token_to_users.sql
-- (remplacez xxx par le prochain numéro de version)

ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500) NULL;

-- Optionnel : Ajouter un index pour améliorer les performances lors des recherches
CREATE INDEX idx_users_fcm_token ON users(fcm_token);

-- Commentaire sur la colonne
COMMENT ON COLUMN users.fcm_token IS 'Token FCM (Firebase Cloud Messaging) pour envoyer des notifications push à l''utilisateur';

