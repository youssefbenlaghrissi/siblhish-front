# 🚂 Déploiement Railway - Guide Rapide

## ⚡ Déploiement en 5 minutes

### 1. Créer un compte Railway
- Aller sur [railway.app](https://railway.app)
- Se connecter avec GitHub

### 2. Créer PostgreSQL
- **New** → **Database** → **Add PostgreSQL**
- Attendre la création (~1 min)

### 3. Copier les fichiers de configuration

Copier les fichiers depuis `railway-config/` vers votre projet backend :

```bash
# Depuis le répertoire siblhish-api
cp ../siblhish-front/railway-config/application-railway.properties src/main/resources/
cp ../siblhish-front/railway-config/Dockerfile .
cp ../siblhish-front/railway-config/railway.json .
cp ../siblhish-front/railway-config/.railwayignore .
```

### 4. Modifier application.properties

Ajouter dans `src/main/resources/application.properties` :

```properties
spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}
```

### 5. Créer le service Spring Boot
- Dans Railway : **New** → **GitHub Repo**
- Sélectionner votre repo `siblhish-api`
- Railway détectera automatiquement Maven/Java

### 6. Lier PostgreSQL
- Dans le service Spring Boot → **Settings**
- **Connect PostgreSQL** → Sélectionner votre PostgreSQL
- Railway ajoutera automatiquement les variables

### 7. Ajouter les variables d'environnement

Dans le service Spring Boot → **Variables** :

```
SPRING_PROFILES_ACTIVE=railway
```

### 8. Exécuter le script SQL

**Via Railway Dashboard :**
- Service PostgreSQL → **Data** → **Query**
- Copier-coller le contenu de `scripts/seed_database.sql`
- Exécuter

### 9. Noter l'URL

- Service Spring Boot → **Settings** → **Networking**
- Noter l'URL (ex: `https://siblhish-api-production.up.railway.app`)

### 10. Mettre à jour Flutter

Dans `lib/config/api_config.dart` :

```dart
static const String baseUrl = 'https://VOTRE_URL_RAILWAY/api/v1';
```

---

## ✅ Test

Ouvrir dans le navigateur :
```
https://VOTRE_URL_RAILWAY/api/v1/categories/1
```

Vous devriez voir la réponse JSON !

---

## 🎯 Après le déploiement

Une fois que le backend est déployé et fonctionnel, nous pourrons :
1. Configurer OAuth2 (Google/Facebook) dans le backend
2. Créer les endpoints d'authentification
3. Intégrer dans Flutter (sans Firebase)

---

C'est tout ! Railway déploie automatiquement à chaque push sur GitHub.

