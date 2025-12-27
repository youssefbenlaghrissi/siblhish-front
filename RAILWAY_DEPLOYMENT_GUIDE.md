# 🚂 Guide complet : Déployer Spring Boot + PostgreSQL sur Railway

## 📋 Prérequis

- ✅ Compte GitHub (pour connecter le repo)
- ✅ Projet backend Spring Boot prêt
- ✅ Compte Railway (créer sur [railway.app](https://railway.app))

---

## 🎯 Étape 1 : Préparer le projet backend

### 1.1 Copier les fichiers de configuration

Depuis le répertoire `siblhish-api`, copier les fichiers depuis `siblhish-front/railway-config/` :

**Sur Windows (PowerShell) :**
```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api

# Copier les fichiers de configuration
Copy-Item ..\siblhish-front\railway-config\application-prod.properties src\main\resources\
Copy-Item ..\siblhish-front\railway-config\Dockerfile .
Copy-Item ..\siblhish-front\railway-config\railway.json .
Copy-Item ..\siblhish-front\railway-config\.railwayignore .
```

**Sur Mac/Linux :**
```bash
cd ~/Documents/siblhish-api

cp ../siblhish-front/railway-config/application-prod.properties src/main/resources/
cp ../siblhish-front/railway-config/Dockerfile .
cp ../siblhish-front/railway-config/railway.json .
cp ../siblhish-front/railway-config/.railwayignore .
```

**Note :** Le Dockerfile est configuré pour **Gradle** (votre projet utilise Gradle, pas Maven).

### 1.2 Modifier application.properties

Ouvrir `src/main/resources/application.properties` et ajouter :

```properties
# Activer le profil prod par défaut en production
spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}
```

### 1.3 Vérifier la structure du projet

Votre projet doit avoir :
```
siblhish-api/
├── build.gradle (Gradle)
├── settings.gradle
├── gradlew (Gradle wrapper)
├── src/
│   └── main/
│       ├── java/
│       └── resources/
│           ├── application.properties
│           └── application-prod.properties
├── Dockerfile
├── railway.json
└── .railwayignore
```

**Note :** Votre projet utilise **Gradle**, le Dockerfile est déjà configuré pour Gradle.

---

## 🚀 Étape 2 : Créer un compte Railway

1. Aller sur [railway.app](https://railway.app)
2. Cliquer sur **"Start a New Project"**
3. Se connecter avec **GitHub** (recommandé) ou **Email**
4. Autoriser Railway à accéder à vos repositories GitHub

---

## 🗄️ Étape 3 : Créer la base de données PostgreSQL

### 3.1 Créer le service PostgreSQL

1. Dans le dashboard Railway, cliquer sur **"New Project"**
2. Cliquer sur **"New"** → **"Database"** → **"Add PostgreSQL"**
3. Railway créera automatiquement une base PostgreSQL
4. Attendre que le service soit créé (~1-2 minutes)

### 3.2 Noter les variables de connexion

1. Cliquer sur le service **PostgreSQL** créé
2. Aller dans l'onglet **"Variables"**
3. Noter ces variables (vous en aurez besoin) :
   - `PGHOST` (ex: `containers-us-west-xxx.railway.app`)
   - `PGPORT` (ex: `5432`)
   - `PGDATABASE` (ex: `railway`)
   - `PGUSER` (ex: `postgres`)
   - `PGPASSWORD` (généré automatiquement)

### 3.3 Exécuter le script SQL

**Option A : Via Railway Dashboard (le plus simple)**

1. Cliquer sur le service PostgreSQL
2. Aller dans l'onglet **"Data"** → **"Query"**
3. Copier le contenu de `scripts/seed_database.sql` depuis `siblhish-front`
4. Coller dans l'éditeur de requête
5. Cliquer sur **"Run Query"**

**Option B : Via Railway CLI**

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
   cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
   railway link
   ```

4. Se connecter à PostgreSQL :
   ```bash
   railway connect postgres
   ```

5. Exécuter le script :
   ```bash
   # Dans le shell PostgreSQL qui s'ouvre
   \i C:\Users\youssef.benlaghrissi\Documents\siblhish-front\scripts\seed_database.sql
   ```

**Option C : Via un client PostgreSQL externe**

1. Utiliser les variables de connexion notées précédemment
2. Se connecter avec pgAdmin, DBeaver, ou psql
3. Exécuter le script `seed_database.sql`

---

## 🖥️ Étape 4 : Déployer le backend Spring Boot

### 4.1 Créer le service Spring Boot

1. Dans votre projet Railway, cliquer sur **"New"**
2. Sélectionner **"GitHub Repo"**
3. Si c'est la première fois :
   - Autoriser Railway à accéder à vos repositories
   - Sélectionner votre repository `siblhish-api`
4. Railway détectera automatiquement que c'est un projet Java/Maven

### 4.2 Lier la base de données

1. Cliquer sur le service **Spring Boot** créé
2. Aller dans **"Settings"**
3. Dans **"Service Settings"**, trouver **"Connect PostgreSQL"**
4. Sélectionner votre service PostgreSQL
5. Railway ajoutera automatiquement toutes les variables de connexion

### 4.3 Configurer les variables d'environnement

1. Dans le service Spring Boot, aller dans l'onglet **"Variables"**
2. Ajouter les variables suivantes :

**Variables obligatoires :**
```
SPRING_PROFILES_ACTIVE=prod
```

**Variables optionnelles (si nécessaire) :**
```
JAVA_OPTS=-Xmx512m
```

**Note** : Les variables de base de données (`DATABASE_URL`, `PGUSER`, `PGPASSWORD`, etc.) sont ajoutées automatiquement quand vous liez PostgreSQL.

### 4.4 Vérifier le build

Railway va automatiquement :
1. Détecter que c'est un projet Gradle (via le Dockerfile)
2. Exécuter `gradle clean build -x test`
3. Créer le JAR dans `build/libs/`
4. Démarrer l'application avec `java -jar build/libs/*.jar`

**Alternative :** Si Railway utilise Nixpacks (détection automatique), il peut builder avec Gradle automatiquement.

Vous pouvez voir les logs dans l'onglet **"Deployments"**

---

## 🌐 Étape 5 : Configurer le domaine

### 5.1 Générer un domaine Railway

1. Dans le service Spring Boot → **"Settings"** → **"Networking"**
2. Cliquer sur **"Generate Domain"**
3. Railway générera une URL, par exemple :
   ```
   https://siblhish-api-production.up.railway.app
   ```

### 5.2 Domaine personnalisé (optionnel)

1. Cliquer sur **"Custom Domain"**
2. Entrer votre domaine (ex: `api.siblhish.com`)
3. Suivre les instructions pour configurer les DNS

---

## ✅ Étape 6 : Vérifier le déploiement

### 6.1 Vérifier les logs

1. Aller dans **"Deployments"**
2. Cliquer sur le dernier déploiement
3. Vérifier les logs pour voir si l'application démarre correctement

Vous devriez voir :
```
Started SiblhishApiApplication in X.XXX seconds
Tomcat started on port(s): 8080 (http)
```

### 6.2 Tester l'API

Ouvrir dans le navigateur :
```
https://VOTRE_URL_RAILWAY/api/v1/categories/1
```

Vous devriez voir la réponse JSON avec les catégories.

### 6.3 Tester d'autres endpoints

```
https://VOTRE_URL_RAILWAY/api/v1/users/1/profile
https://VOTRE_URL_RAILWAY/api/v1/goals/1
```

---

## 📱 Étape 7 : Mettre à jour Flutter

Mettre à jour `lib/config/api_config.dart` :

```dart
static const String baseUrl = 'https://VOTRE_URL_RAILWAY/api/v1';
```

**Exemple :**
```dart
static const String baseUrl = 'https://siblhish-api-production.up.railway.app/api/v1';
```

---

## 🔄 Étape 8 : Automatisation (déjà configuré)

Railway déploie automatiquement à chaque push sur la branche principale de votre repo GitHub.

Pour déployer manuellement :
1. Aller dans le service
2. **"Deployments"** → **"Redeploy"**

---

## 🐛 Dépannage

### L'application ne démarre pas

**Vérifier les logs :**
1. Service Spring Boot → **"Deployments"** → Cliquer sur le dernier déploiement
2. Vérifier les erreurs dans les logs

**Problèmes courants :**
- ❌ Variables d'environnement manquantes → Ajouter `SPRING_PROFILES_ACTIVE=prod`
- ❌ Base de données non liée → Lier PostgreSQL dans Settings
- ❌ Port incorrect → Railway fournit `PORT`, vérifier dans `application-prod.properties`

### Erreur de connexion à la base de données

1. Vérifier que PostgreSQL est lié au service Spring Boot
2. Vérifier les variables dans l'onglet **"Variables"**
3. Vérifier que `DATABASE_URL` est présent

### Erreur 404

1. Vérifier que l'URL inclut `/api/v1` (si vous avez `server.servlet.context-path=/api/v1`)
2. Vérifier que le backend est démarré (logs)
3. Tester avec `/api/v1/categories/1`

### Build échoue

1. Vérifier que `build.gradle` est présent
2. Vérifier les logs de build dans **"Deployments"**
3. Vérifier que Gradle peut builder le projet localement :
   ```bash
   cd siblhish-api
   ./gradlew clean build
   ```
4. Vérifier que Java 17 est utilisé (Railway utilise Java 17 par défaut)

---

## 📊 Monitoring

Railway fournit :
- **Logs en temps réel** : Voir les logs de l'application
- **Métriques** : CPU, RAM, Réseau
- **Déploiements** : Historique des déploiements
- **Variables** : Gestion des variables d'environnement

---

## 💰 Coûts

- **Gratuit** : 5$ de crédit par mois (suffisant pour commencer)
- **Hobby** : 5$/mois (500 heures de compute)
- **Pro** : 20$/mois (plus de ressources)

Pour un projet de développement, le plan gratuit est généralement suffisant.

---

## ✅ Checklist de déploiement

- [ ] Fichiers de configuration copiés dans `siblhish-api`
- [ ] `application.properties` modifié avec `spring.profiles.active`
- [ ] Compte Railway créé
- [ ] Service PostgreSQL créé
- [ ] Script SQL exécuté
- [ ] Service Spring Boot créé et connecté à GitHub
- [ ] PostgreSQL lié au service Spring Boot
- [ ] Variable `SPRING_PROFILES_ACTIVE=prod` ajoutée
- [ ] Application déployée avec succès
- [ ] URL testée et fonctionnelle
- [ ] Application Flutter mise à jour avec la nouvelle URL

---

## 🎯 Prochaines étapes

Une fois le backend déployé et fonctionnel :

1. ✅ Tester tous les endpoints depuis le navigateur
2. ✅ Vérifier que Flutter peut se connecter
3. ⏳ Implémenter OAuth2 (Google/Facebook) dans le backend
4. ⏳ Créer les endpoints d'authentification
5. ⏳ Intégrer l'authentification dans Flutter

---

## 📚 Ressources

- [Railway Documentation](https://docs.railway.app)
- [Railway Discord](https://discord.gg/railway) (support communautaire)
- [Spring Boot on Railway](https://docs.railway.app/guides/java)

---

**Besoin d'aide ?** Vérifiez les logs dans Railway ou consultez la documentation Railway.

