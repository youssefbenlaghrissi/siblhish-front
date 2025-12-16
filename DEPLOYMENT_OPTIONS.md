# 🚀 Options de déploiement Backend + Base de données

## Options recommandées (par ordre de préférence)

### 1. 🥇 **Railway** (Recommandé - Facile et performant)

**Avantages :**
- ✅ Déploiement très simple (Git push)
- ✅ PostgreSQL inclus (gratuit jusqu'à 5$ de crédit/mois)
- ✅ HTTPS automatique
- ✅ Bonne performance
- ✅ Interface intuitive
- ✅ Variables d'environnement faciles

**Prix :** Gratuit pour commencer (5$ de crédit/mois), puis ~5-10$/mois

**Déploiement :**
1. Créer un compte sur [railway.app](https://railway.app)
2. Connecter votre repo GitHub
3. Créer un service PostgreSQL
4. Créer un service Spring Boot
5. Configurer les variables d'environnement
6. Déployer !

**Documentation :** https://docs.railway.app

---

### 2. 🥈 **Render** (Excellent pour débuter)

**Avantages :**
- ✅ PostgreSQL gratuit (limité)
- ✅ HTTPS automatique
- ✅ Déploiement depuis GitHub
- ✅ Interface simple
- ✅ Bonne documentation

**Prix :** Gratuit pour PostgreSQL (limité), ~7$/mois pour le backend

**Déploiement :**
1. Créer un compte sur [render.com](https://render.com)
2. Créer une base PostgreSQL
3. Créer un Web Service Spring Boot
4. Configurer les variables d'environnement

**Documentation :** https://render.com/docs

---

### 3. 🥉 **Fly.io** (Performant et moderne)

**Avantages :**
- ✅ Très performant (edge computing)
- ✅ PostgreSQL géré
- ✅ HTTPS automatique
- ✅ Déploiement via Docker
- ✅ Bon pour la scalabilité

**Prix :** Gratuit pour commencer, puis ~5-15$/mois

**Déploiement :**
1. Installer Fly CLI
2. Créer un compte sur [fly.io](https://fly.io)
3. Créer une app PostgreSQL
4. Créer une app Spring Boot
5. Déployer avec `fly deploy`

**Documentation :** https://fly.io/docs

---

### 4. **DigitalOcean** (Performant et flexible)

**Avantages :**
- ✅ Très performant
- ✅ Contrôle total
- ✅ PostgreSQL géré (Managed Database)
- ✅ Droplets flexibles
- ✅ Bon rapport qualité/prix

**Prix :** ~12-20$/mois (Droplet + Database)

**Déploiement :**
1. Créer un compte sur [digitalocean.com](https://digitalocean.com)
2. Créer un Droplet (Ubuntu)
3. Créer une Managed Database PostgreSQL
4. Installer Java et déployer Spring Boot
5. Configurer Nginx + SSL (Let's Encrypt)

**Documentation :** https://docs.digitalocean.com

---

### 5. **Supabase** (PostgreSQL + Backend API)

**Avantages :**
- ✅ PostgreSQL géré gratuit
- ✅ API REST automatique
- ✅ Authentification incluse
- ✅ Interface moderne
- ✅ Très facile à utiliser

**Prix :** Gratuit jusqu'à 500MB, puis ~25$/mois

**Note :** Supabase génère automatiquement une API REST, mais vous pouvez aussi déployer votre Spring Boot séparément.

**Documentation :** https://supabase.com/docs

---

## 🎯 Recommandation finale : **Railway**

Pour votre cas, je recommande **Railway** car :
1. ✅ Déploiement le plus simple
2. ✅ PostgreSQL inclus
3. ✅ HTTPS automatique
4. ✅ Bonne performance
5. ✅ Prix raisonnable
6. ✅ Interface intuitive

---

## 📋 Étapes de déploiement sur Railway

### Préparation

1. **Créer un compte Railway**
   - Aller sur [railway.app](https://railway.app)
   - Se connecter avec GitHub

2. **Préparer le backend Spring Boot**
   - S'assurer que le projet est sur GitHub
   - Créer un `Dockerfile` (optionnel, Railway peut builder automatiquement)
   - Créer un `railway.json` pour la configuration

3. **Variables d'environnement à configurer**
   - `DATABASE_URL` (fournie par Railway PostgreSQL)
   - `SPRING_PROFILES_ACTIVE=prod`
   - `SERVER_PORT` (Railway fournit `PORT`)

### Déploiement

1. **Créer un nouveau projet Railway**
2. **Ajouter PostgreSQL**
   - Cliquer sur "New" → "Database" → "Add PostgreSQL"
   - Railway créera automatiquement la base de données
3. **Ajouter le service Spring Boot**
   - Cliquer sur "New" → "GitHub Repo"
   - Sélectionner votre repo `siblhish-api`
   - Railway détectera automatiquement que c'est un projet Java/Spring Boot
4. **Configurer les variables d'environnement**
   - Dans les settings du service Spring Boot
   - Ajouter les variables nécessaires
5. **Déployer**
   - Railway déploiera automatiquement
   - L'URL HTTPS sera générée automatiquement

---

## 🔧 Configuration nécessaire pour le backend

### 1. Créer `application-prod.properties`

```properties
spring.application.name=siblhish-api

# Database Configuration (Railway fournit DATABASE_URL)
spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA/Hibernate Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Server Configuration (Railway fournit PORT)
server.port=${PORT:8081}
server.address=0.0.0.0
```

### 2. Modifier `application.properties`

```properties
spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}
```

### 3. Créer `Dockerfile` (optionnel mais recommandé)

```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 4. Créer `.railwayignore` (optionnel)

```
target/
.idea/
*.iml
.git/
```

---

## 🔄 Migration de la base de données

### Option 1 : Utiliser le script SQL existant

1. Se connecter à la base PostgreSQL Railway
2. Exécuter le script `seed_database.sql`

### Option 2 : Utiliser Flyway/Liquibase

Ajouter Flyway au projet pour gérer les migrations automatiquement.

---

## 🔐 Configuration HTTPS dans Flutter

Une fois déployé, Railway fournira une URL HTTPS automatique, par exemple :
```
https://siblhish-api-production.up.railway.app
```

Mettre à jour `lib/config/api_config.dart` :

```dart
static const String baseUrl = 'https://siblhish-api-production.up.railway.app/api/v1';
```

Plus besoin de configuration réseau spéciale Android ! HTTPS fonctionne nativement.

---

## 📊 Comparaison rapide

| Service | Prix/mois | Facilité | Performance | PostgreSQL |
|---------|-----------|----------|-------------|------------|
| Railway | 5-10$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Inclus |
| Render | 7$ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ Inclus |
| Fly.io | 5-15$ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Inclus |
| DigitalOcean | 12-20$ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Géré |
| Supabase | 0-25$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Inclus |

---

## 🚀 Prochaines étapes

1. Choisir une plateforme (recommandation : Railway)
2. Créer un compte
3. Préparer le backend (ajouter les fichiers de configuration)
4. Déployer PostgreSQL
5. Déployer Spring Boot
6. Configurer les variables d'environnement
7. Exécuter le script SQL
8. Mettre à jour l'URL dans Flutter
9. Tester !

Souhaitez-vous que je vous aide à préparer les fichiers de configuration pour Railway ?

