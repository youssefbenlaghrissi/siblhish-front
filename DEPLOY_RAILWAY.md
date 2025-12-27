# 🚂 Guide de déploiement sur Railway

## 📋 Vue d'ensemble

Railway est une plateforme simple et performante pour déployer votre backend Spring Boot et PostgreSQL.

**Coût estimé :** ~5-10$/mois (gratuit pour commencer avec 5$ de crédit)

---

## 🎯 Étape 1 : Créer un compte Railway

1. Aller sur [railway.app](https://railway.app)
2. Cliquer sur **"Start a New Project"**
3. Se connecter avec GitHub (recommandé) ou Email

---

## 🗄️ Étape 2 : Créer la base de données PostgreSQL

### 2.1 Créer le service PostgreSQL

1. Dans votre projet Railway, cliquer sur **"New"**
2. Sélectionner **"Database"** → **"Add PostgreSQL"**
3. Railway créera automatiquement une base PostgreSQL
4. Attendre que le service soit créé (~1-2 minutes)

### 2.2 Noter les variables de connexion

1. Cliquer sur le service PostgreSQL créé
2. Aller dans l'onglet **"Variables"**
3. Noter les variables suivantes :
   - `PGHOST` (ex: `containers-us-west-xxx.railway.app`)
   - `PGPORT` (ex: `5432`)
   - `PGDATABASE` (ex: `railway`)
   - `PGUSER` (ex: `postgres`)
   - `PGPASSWORD` (généré automatiquement)

### 2.3 Exécuter le script SQL

**Option A : Via Railway CLI**

1. Installer Railway CLI :
   ```bash
   npm i -g @railway/cli
   ```

2. Se connecter :
   ```bash
   railway login
   ```

3. Lier le projet :
   ```bash
   railway link
   ```

4. Exécuter le script SQL :
   ```bash
   railway connect postgres < scripts/seed_database.sql
   ```

**Option B : Via un client PostgreSQL**

1. Utiliser les variables de connexion notées précédemment
2. Se connecter avec pgAdmin, DBeaver, ou psql
3. Exécuter le script `scripts/seed_database.sql`

**Option C : Via Railway Dashboard**

1. Aller dans le service PostgreSQL
2. Onglet **"Data"** → **"Query"**
3. Copier-coller le contenu de `scripts/seed_database.sql`
4. Exécuter

---

## 🖥️ Étape 3 : Préparer le backend Spring Boot

### 3.1 Créer les fichiers de configuration

Créer `src/main/resources/application-prod.properties` :

```properties
spring.application.name=siblhish-api

# Database Configuration (Railway fournit DATABASE_URL)
spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${PGUSER}
spring.datasource.password=${PGPASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA/Hibernate Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.properties.hibernate.format_sql=false

# Server Configuration (Railway fournit PORT)
server.port=${PORT:8080}
server.address=0.0.0.0
```

### 3.2 Créer `railway.json` (optionnel)

Créer à la racine du projet backend :

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "java -jar build/libs/*.jar --spring.profiles.active=prod",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 3.3 Créer `Dockerfile` (optionnel mais recommandé)

Créer à la racine du projet backend :

```dockerfile
# Stage 1: Build
FROM gradle:8.5-jdk17 AS build
WORKDIR /app

# Copy Gradle files first for better caching
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (this layer will be cached)
RUN gradle dependencies --no-daemon || true

# Copy source code
COPY src ./src

# Build the application
RUN gradle clean build -x test --no-daemon

# Stage 2: Run
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy the JAR from build stage
# Gradle place le JAR dans build/libs/
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar", "--spring.profiles.active=prod"]
```

### 3.4 Créer `.railwayignore` (optionnel)

```
target/
.idea/
*.iml
.git/
.mvn/
```

---

## 🚀 Étape 4 : Déployer le backend

### 4.1 Créer le service Spring Boot

1. Dans votre projet Railway, cliquer sur **"New"**
2. Sélectionner **"GitHub Repo"** (ou **"Empty Service"**)
3. Si GitHub :
   - Sélectionner votre repo `siblhish-api`
   - Railway détectera automatiquement que c'est un projet Java/Maven
4. Si Empty Service :
   - Cliquer sur **"Deploy from GitHub repo"** et sélectionner votre repo

### 4.2 Configurer les variables d'environnement

1. Cliquer sur le service Spring Boot créé
2. Aller dans l'onglet **"Variables"**
3. Ajouter les variables suivantes :

**Variables de base de données (depuis le service PostgreSQL) :**
- `DATABASE_URL` : Copier depuis le service PostgreSQL
- `PGUSER` : Copier depuis le service PostgreSQL
- `PGPASSWORD` : Copier depuis le service PostgreSQL
- `PGHOST` : Copier depuis le service PostgreSQL
- `PGPORT` : Copier depuis le service PostgreSQL
- `PGDATABASE` : Copier depuis le service PostgreSQL

**Variables Spring Boot :**
- `SPRING_PROFILES_ACTIVE` : `prod`
- `PORT` : Railway le définit automatiquement, mais vous pouvez le forcer à `8080`

**Variables pour OAuth2 (à configurer plus tard) :**
- `GOOGLE_CLIENT_ID` : (à ajouter après configuration OAuth2)
- `GOOGLE_CLIENT_SECRET` : (à ajouter après configuration OAuth2)
- `FACEBOOK_APP_ID` : (à ajouter après configuration OAuth2)
- `FACEBOOK_APP_SECRET` : (à ajouter après configuration OAuth2)

### 4.3 Lier la base de données au service

1. Dans le service Spring Boot, cliquer sur **"Settings"**
2. Dans **"Service Settings"**, trouver **"Connect PostgreSQL"**
3. Sélectionner votre service PostgreSQL
4. Railway ajoutera automatiquement les variables de connexion

### 4.4 Déployer

Railway déploiera automatiquement votre application. Vous pouvez :
- Voir les logs en temps réel dans l'onglet **"Deployments"**
- Voir l'URL de déploiement dans l'onglet **"Settings"** → **"Networking"**

---

## 🌐 Étape 5 : Configurer le domaine personnalisé (optionnel)

1. Dans le service Spring Boot → **"Settings"** → **"Networking"**
2. Cliquer sur **"Generate Domain"** pour obtenir un domaine Railway
   - Exemple : `siblhish-api-production.up.railway.app`
3. Ou ajouter un domaine personnalisé :
   - Cliquer sur **"Custom Domain"**
   - Entrer votre domaine (ex: `api.siblhish.com`)
   - Configurer les DNS selon les instructions Railway

---

## ✅ Étape 6 : Vérifier le déploiement

### 6.1 Tester l'API

1. Noter l'URL de votre service (ex: `https://siblhish-api-production.up.railway.app`)
2. Tester dans le navigateur :
   ```
   https://siblhish-api-production.up.railway.app/api/v1/categories/1
   ```
3. Vous devriez voir la réponse JSON

### 6.2 Vérifier les logs

Dans Railway → Service Spring Boot → **"Deployments"** → Cliquer sur le dernier déploiement → Voir les logs

---

## 📱 Étape 7 : Mettre à jour Flutter

Mettre à jour `lib/config/api_config.dart` :

```dart
static const String baseUrl = 'https://siblhish-api-production.up.railway.app/api/v1';
```

---

## 🔄 Étape 8 : Automatiser les déploiements

Railway déploie automatiquement à chaque push sur la branche principale de votre repo GitHub.

Pour déployer manuellement :
1. Aller dans le service
2. **"Deployments"** → **"Redeploy"**

---

## 🐛 Dépannage

### L'application ne démarre pas

1. Vérifier les logs dans Railway
2. Vérifier que toutes les variables d'environnement sont définies
3. Vérifier que `SPRING_PROFILES_ACTIVE=prod`

### Erreur de connexion à la base de données

1. Vérifier que le service PostgreSQL est lié au service Spring Boot
2. Vérifier que les variables `DATABASE_URL`, `PGUSER`, `PGPASSWORD` sont correctes
3. Vérifier que le firewall de la base de données autorise les connexions

### Erreur 404

1. Vérifier que l'URL est correcte (avec `/api/v1`)
2. Vérifier que le backend est bien démarré (logs)
3. Vérifier que le port est correct (Railway utilise `PORT`)

---

## 📊 Monitoring

Railway fournit :
- **Logs en temps réel** : Voir les logs de l'application
- **Métriques** : CPU, RAM, Réseau
- **Déploiements** : Historique des déploiements

---

## 💰 Coûts

- **Gratuit** : 5$ de crédit par mois
- **Hobby** : 5$/mois (500 heures de compute)
- **Pro** : 20$/mois (plus de ressources)

Pour commencer, le plan gratuit est suffisant !

---

## ✅ Checklist de déploiement

- [ ] Compte Railway créé
- [ ] Service PostgreSQL créé
- [ ] Script SQL exécuté
- [ ] Service Spring Boot créé
- [ ] Variables d'environnement configurées
- [ ] Base de données liée au service
- [ ] Application déployée avec succès
- [ ] URL testée et fonctionnelle
- [ ] Application Flutter mise à jour avec la nouvelle URL

---

## 🎯 Prochaines étapes

Une fois le backend déployé sur Railway, nous pourrons :
1. Configurer OAuth2 pour Google et Facebook
2. Créer les endpoints d'authentification dans le backend
3. Intégrer l'authentification dans Flutter (sans Firebase)

---

Souhaitez-vous que je vous aide à préparer les fichiers de configuration pour Railway ?

