# 🚂 Railway - Déploiement Rapide (5 minutes)

## ⚡ Étapes rapides

### 1. Préparer le backend

```powershell
# Depuis siblhish-api
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api

# Copier les fichiers
Copy-Item ..\siblhish-front\railway-config\application-prod.properties src\main\resources\
Copy-Item ..\siblhish-front\railway-config\Dockerfile .
Copy-Item ..\siblhish-front\railway-config\railway.json .
Copy-Item ..\siblhish-front\railway-config\.railwayignore .
```

### 2. Modifier application.properties

Ajouter dans `src/main/resources/application.properties` :
```properties
spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}
```

### 3. Créer le repository GitHub (si pas déjà fait)

1. Aller sur GitHub
2. Créer un nouveau repository : `siblhish-api`
3. Pousser le code :
   ```bash
   cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
   git init
   git add .
   git commit --no-verify -m "Initial commit"
   git remote add origin https://github.com/VOTRE_USERNAME/siblhish-api.git
   git push -u origin main
   ```

### 4. Déployer sur Railway

1. **Créer un compte** : [railway.app](https://railway.app)
2. **Créer PostgreSQL** :
   - New → Database → Add PostgreSQL
   - Attendre la création
3. **Créer Spring Boot** :
   - New → GitHub Repo
   - Sélectionner `siblhish-api`
4. **Lier PostgreSQL** :
   - Service Spring Boot → Settings → Connect PostgreSQL
5. **Ajouter variable** :
   - Variables → `SPRING_PROFILES_ACTIVE=prod`
6. **Exécuter SQL** :
   - Service PostgreSQL → Data → Query
   - Copier-coller `seed_database.sql`
   - Run Query

### 5. Noter l'URL

- Service Spring Boot → Settings → Networking
- Noter l'URL (ex: `https://siblhish-api-production.up.railway.app`)

### 6. Mettre à jour Flutter

Dans `lib/config/api_config.dart` :
```dart
static const String baseUrl = 'https://VOTRE_URL_RAILWAY/api/v1';
```

---

## ✅ Test

Ouvrir : `https://VOTRE_URL_RAILWAY/api/v1/categories/1`

Vous devriez voir la réponse JSON !

---

**C'est tout !** Railway déploie automatiquement à chaque push sur GitHub.
