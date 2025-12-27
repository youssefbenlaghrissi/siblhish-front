# 🚂 Railway - Guide Étape par Étape

## 📋 Checklist complète

### ✅ Étape 1 : Préparer le backend (5 min)

#### 1.1 Copier les fichiers de configuration

**Option A : Script automatique (Windows PowerShell)**
```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
..\siblhish-front\prepare-railway.ps1
```

**Option B : Manuel**
```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api

# Copier les fichiers
Copy-Item ..\siblhish-front\railway-config\application-prod.properties src\main\resources\
Copy-Item ..\siblhish-front\railway-config\Dockerfile .
Copy-Item ..\siblhish-front\railway-config\railway.json .
Copy-Item ..\siblhish-front\railway-config\.railwayignore .
```

#### 1.2 Modifier application.properties

Ouvrir `src/main/resources/application.properties` et ajouter à la fin :

```properties
# Profile configuration
spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}
```

#### 1.3 Vérifier la structure

Votre projet doit maintenant avoir :
```
siblhish-api/
├── build.gradle ✅
├── Dockerfile ✅
├── railway.json ✅
├── .railwayignore ✅
└── src/main/resources/
    ├── application.properties ✅ (modifié)
    └── application-prod.properties ✅
```

---

### ✅ Étape 2 : Créer le repository GitHub (5 min)

1. Aller sur [github.com](https://github.com)
2. **"+"** → **"New repository"**
3. Nom : `siblhish-api`
4. Description : `Backend Spring Boot pour Siblhish`
5. **Public** ou **Private**
6. **NE PAS** cocher "Initialize with README"
7. **Create repository**

#### 2.1 Pousser le code

```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api

# Initialiser Git (si pas déjà fait)
git init

# Ajouter tous les fichiers
git add .

# Premier commit
git commit --no-verify -m "Initial commit: Backend Spring Boot pour Railway"

# Ajouter le remote
git remote add origin https://github.com/VOTRE_USERNAME/siblhish-api.git

# Pousser
git branch -M main
git push -u origin main
```

---

### ✅ Étape 3 : Créer un compte Railway (2 min)

1. Aller sur [railway.app](https://railway.app)
2. **"Start a New Project"**
3. Se connecter avec **GitHub** (recommandé)
4. Autoriser Railway à accéder à vos repositories

---

### ✅ Étape 4 : Créer PostgreSQL (2 min)

1. Dans Railway, cliquer sur **"New Project"**
2. **"New"** → **"Database"** → **"Add PostgreSQL"**
3. Attendre la création (~1-2 minutes)
4. ✅ PostgreSQL créé !

---

### ✅ Étape 5 : Exécuter le script SQL (3 min)

1. Cliquer sur le service **PostgreSQL**
2. Onglet **"Data"** → **"Query"**
3. Ouvrir le fichier `C:\Users\youssef.benlaghrissi\Documents\siblhish-front\scripts\seed_database.sql`
4. Copier tout le contenu
5. Coller dans l'éditeur de requête Railway
6. Cliquer sur **"Run Query"**
7. ✅ Base de données alimentée !

---

### ✅ Étape 6 : Déployer Spring Boot (5 min)

#### 6.1 Créer le service

1. Dans votre projet Railway, cliquer sur **"New"**
2. **"GitHub Repo"**
3. Sélectionner `siblhish-api`
4. Railway va détecter Gradle et commencer le build

#### 6.2 Lier PostgreSQL

1. Cliquer sur le service **Spring Boot** créé
2. **"Settings"**
3. **"Connect PostgreSQL"** → Sélectionner votre PostgreSQL
4. ✅ Variables de connexion ajoutées automatiquement

#### 6.3 Ajouter les variables

1. Onglet **"Variables"**
2. Cliquer sur **"New Variable"**
3. Ajouter :
   - **Name** : `SPRING_PROFILES_ACTIVE`
   - **Value** : `prod`
4. ✅ Variable ajoutée

#### 6.4 Vérifier le déploiement

1. Onglet **"Deployments"**
2. Cliquer sur le dernier déploiement
3. Vérifier les logs :
   - ✅ `Started SiblhishApiApplication`
   - ✅ `Tomcat started on port(s): 8080`

---

### ✅ Étape 7 : Obtenir l'URL (1 min)

1. Service Spring Boot → **"Settings"** → **"Networking"**
2. Cliquer sur **"Generate Domain"**
3. Noter l'URL, par exemple :
   ```
   https://siblhish-api-production.up.railway.app
   ```

---

### ✅ Étape 8 : Tester l'API (2 min)

Ouvrir dans le navigateur :

1. **Catégories** :
   ```
   https://VOTRE_URL/api/v1/categories/1
   ```

2. **Profil utilisateur** :
   ```
   https://VOTRE_URL/api/v1/users/1/profile
   ```

3. **Objectifs** :
   ```
   https://VOTRE_URL/api/v1/goals/1
   ```

Vous devriez voir les réponses JSON ! ✅

---

### ✅ Étape 9 : Mettre à jour Flutter (1 min)

Ouvrir `lib/config/api_config.dart` et modifier :

```dart
static const String baseUrl = 'https://VOTRE_URL_RAILWAY/api/v1';
```

**Exemple :**
```dart
static const String baseUrl = 'https://siblhish-api-production.up.railway.app/api/v1';
```

---

## 🎯 Résumé des URLs importantes

- **Railway Dashboard** : https://railway.app
- **Votre API** : `https://VOTRE_URL_RAILWAY/api/v1`
- **Documentation Railway** : https://docs.railway.app

---

## 🔄 Déploiements automatiques

Railway déploie automatiquement à chaque push sur la branche principale de GitHub.

Pour redéployer manuellement :
- Service → **"Deployments"** → **"Redeploy"**

---

## 🐛 Problèmes courants

### ❌ Build échoue

**Solution :**
1. Vérifier les logs dans **"Deployments"**
2. Vérifier que `build.gradle` est présent
3. Tester localement : `./gradlew clean build`

### ❌ Erreur de connexion à la base

**Solution :**
1. Vérifier que PostgreSQL est lié (Settings → Connect PostgreSQL)
2. Vérifier les variables dans l'onglet **"Variables"**
3. Vérifier que `DATABASE_URL` est présent

### ❌ 404 Not Found

**Solution :**
1. Vérifier que l'URL inclut `/api/v1`
2. Vérifier que `server.servlet.context-path=/api/v1` est dans `application.properties`
3. Tester avec `/api/v1/categories/1`

---

## ✅ Checklist finale

- [ ] Fichiers de configuration copiés
- [ ] `application.properties` modifié
- [ ] Code poussé sur GitHub
- [ ] Compte Railway créé
- [ ] PostgreSQL créé et SQL exécuté
- [ ] Spring Boot déployé
- [ ] PostgreSQL lié
- [ ] Variable `SPRING_PROFILES_ACTIVE=prod` ajoutée
- [ ] Application démarrée (logs OK)
- [ ] URL testée et fonctionnelle
- [ ] Flutter mis à jour

---

**Temps total estimé : ~20 minutes**

Une fois tout cela fait, votre backend sera en ligne et accessible depuis Flutter ! 🎉

