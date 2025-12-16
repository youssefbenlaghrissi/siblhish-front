# 🔐 Plan d'implémentation OAuth2 (Google/Facebook) - Backend Spring Boot

## 📋 Vue d'ensemble

Après le déploiement sur Railway, nous implémenterons l'authentification OAuth2 directement dans le backend Spring Boot, sans Firebase.

---

## 🎯 Architecture

```
Flutter App → Backend Spring Boot → Google/Facebook OAuth2
                ↓
         PostgreSQL (User + OAuth tokens)
```

---

## 📦 Dépendances nécessaires (backend)

Ajouter dans `pom.xml` :

```xml
<!-- Spring Security OAuth2 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>

<!-- Spring Security JWT (optionnel, pour les tokens) -->
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.3</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
```

---

## 🔧 Configuration OAuth2

### 1. Configuration Google

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Créer un projet ou sélectionner un projet existant
3. Activer **Google+ API**
4. **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Type : **Web application**
6. **Authorized redirect URIs** :
   ```
   https://VOTRE_URL_RAILWAY/api/v1/auth/google/callback
   ```
7. Noter le **Client ID** et **Client Secret**

### 2. Configuration Facebook

1. Aller sur [Facebook Developers](https://developers.facebook.com)
2. Créer une application
3. Ajouter **Facebook Login**
4. **Settings** → **Basic** :
   - Noter **App ID** et **App Secret**
5. **Settings** → **Facebook Login** → **Settings** :
   - **Valid OAuth Redirect URIs** :
     ```
     https://VOTRE_URL_RAILWAY/api/v1/auth/facebook/callback
     ```

---

## 📝 Endpoints à créer

### 1. `/api/v1/auth/google` - Initier la connexion Google
### 2. `/api/v1/auth/google/callback` - Callback Google
### 3. `/api/v1/auth/facebook` - Initier la connexion Facebook
### 4. `/api/v1/auth/facebook/callback` - Callback Facebook
### 5. `/api/v1/auth/me` - Obtenir l'utilisateur connecté
### 6. `/api/v1/auth/logout` - Déconnexion

---

## 🗄️ Modifications de la base de données

Ajouter dans la table `users` :
- `oauth_provider` (GOOGLE, FACEBOOK, EMAIL)
- `oauth_provider_id` (ID unique du provider)
- `access_token` (optionnel, pour les appels API)
- `refresh_token` (optionnel)

---

## 📱 Intégration Flutter

Dans Flutter, nous utiliserons :
- `url_launcher` pour ouvrir le navigateur
- `flutter_web_auth` pour gérer le callback OAuth2
- Stocker le token JWT dans `shared_preferences`

---

## ✅ Étapes après déploiement Railway

1. ✅ Backend déployé sur Railway
2. ⏳ Ajouter les dépendances OAuth2 au backend
3. ⏳ Créer les controllers d'authentification
4. ⏳ Configurer OAuth2 dans `application.properties`
5. ⏳ Créer les endpoints d'authentification
6. ⏳ Modifier le modèle User pour OAuth2
7. ⏳ Intégrer dans Flutter

---

Une fois Railway configuré, je vous aiderai à implémenter OAuth2 !

