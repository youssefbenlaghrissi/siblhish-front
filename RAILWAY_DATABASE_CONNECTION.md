# 🔌 Guide de connexion à PostgreSQL sur Railway

## ⚠️ Problème : "failed to resolve host"

L'erreur `failed to resolve host 'maglev.proxy.rlwy.net'` signifie que vous essayez de vous connecter depuis un client externe (pgAdmin, DBeaver, etc.) à une URL qui n'est accessible que depuis les services Railway.

---

## ✅ Solution 1 : Utiliser Railway CLI (Recommandé)

### 1.1 Installer Railway CLI

```powershell
npm i -g @railway/cli
```

### 1.2 Se connecter

```powershell
railway login
```

### 1.3 Lier le projet

```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
railway link
```

Sélectionner votre projet Railway.

### 1.4 Se connecter à PostgreSQL

```powershell
railway connect postgres
```

Cela ouvrira un shell PostgreSQL interactif où vous pouvez exécuter des commandes SQL.

### 1.5 Exécuter le script SQL

```powershell
# Depuis le shell P-ostgreSQL
\i C:\Users\youssef.benlaghrissi\Documents\siblhish-front\scripts\seed_database.sql
```

**OU** copier-coller le contenu du script directement dans le shell.

---

## ✅ Solution 2 : Utiliser Railway Dashboard (Le plus simple)

### 2.1 Via l'interface Railway

1. Aller sur votre projet Railway
2. Cliquer sur le service **Postgres**
3. Onglet **"Database"** → **"Query"**
4. Copier-coller le contenu de `scripts/seed_database.sql`
5. Cliquer sur **"Run Query"**

✅ C'est la méthode la plus simple et la plus fiable !

---

## ✅ Solution 3 : Connexion depuis un client externe (pgAdmin, DBeaver)

### 3.1 Comprendre les URLs Railway

Railway fournit deux types d'URLs :

- **`DATABASE_URL`** : URL privée (accessible uniquement depuis les services Railway)
- **`DATABASE_PUBLIC_URL`** : URL publique (accessible depuis l'extérieur, mais peut nécessiter une configuration)

### 3.2 Utiliser DATABASE_PUBLIC_URL

1. Dans Railway → Service Postgres → **"Variables"**
2. Trouver **`DATABASE_PUBLIC_URL`**
3. Cliquer sur l'icône **"👁️"** pour révéler la valeur
4. Copier l'URL complète

L'URL ressemble à :
```
postgresql://postgres:PASSWORD@maglev.proxy.rlwy.net:PORT/railway
```

### 3.3 Parser l'URL pour votre client

Décomposer l'URL :
- **Host** : `maglev.proxy.rlwy.net`
- **Port** : `47896` (dans votre cas)
- **Database** : `railway`
- **Username** : `postgres`
- **Password** : `BcJSnyQbCbsdaHtZhqMjpFPeNLcWGpME` (dans votre cas)

### 3.4 Configuration dans pgAdmin/DBeaver

**pgAdmin :**
1. Créer une nouvelle connexion
2. **Host** : `maglev.proxy.rlwy.net`
3. **Port** : `47896`
4. **Database** : `railway`
5. **Username** : `postgres`
6. **Password** : (copier depuis `DATABASE_PUBLIC_URL`)

**DBeaver :**
1. Nouvelle connexion → PostgreSQL
2. **Host** : `maglev.proxy.rlwy.net`
3. **Port** : `47896`
4. **Database** : `railway`
5. **Username** : `postgres`
6. **Password** : (copier depuis `DATABASE_PUBLIC_URL`)

### 3.5 Si ça ne fonctionne toujours pas

Railway peut bloquer les connexions externes pour des raisons de sécurité. Dans ce cas :

1. Utiliser **Solution 1** (Railway CLI) ou **Solution 2** (Dashboard)
2. Vérifier que votre firewall/autorouteur n'bloque pas la connexion
3. Essayer depuis un autre réseau (mobile hotspot)

---

## ✅ Solution 4 : Utiliser DATABASE_URL pour le backend Spring Boot

Pour le backend Spring Boot, utilisez **`DATABASE_URL`** (pas `DATABASE_PUBLIC_URL`).

### 4.1 Vérifier application-prod.properties

Le fichier `application-prod.properties` doit utiliser `DATABASE_URL` :

```properties
spring.datasource.url=${DATABASE_URL:jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=require}
spring.datasource.username=${PGUSER:postgres}
spring.datasource.password=${PGPASSWORD}
```

### 4.2 Railway ajoute automatiquement ces variables

Quand vous liez PostgreSQL au service Spring Boot dans Railway :
- Railway ajoute automatiquement `DATABASE_URL`
- Railway ajoute automatiquement `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`

Vous n'avez **rien à faire** ! ✅

---

## 🔍 Vérification

### Vérifier que PostgreSQL est accessible

1. Railway → Service Postgres → **"Database"** → **"Query"**
2. Exécuter :
   ```sql
   SELECT version();
   ```
3. Vous devriez voir la version de PostgreSQL

### Vérifier les tables

```sql
\dt
```

Ou :
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

---

## 📝 Exécuter le script SQL

### Via Railway Dashboard (Recommandé)

1. Railway → Postgres → **"Database"** → **"Query"**
2. Ouvrir `C:\Users\youssef.benlaghrissi\Documents\siblhish-front\scripts\seed_database.sql`
3. Copier tout le contenu
4. Coller dans l'éditeur Railway
5. Cliquer sur **"Run Query"**

### Via Railway CLI

```powershell
railway connect postgres
```

Puis dans le shell :
```sql
-- Copier-coller le contenu de seed_database.sql
```

---

## ⚠️ Notes importantes

1. **`DATABASE_PUBLIC_URL`** peut ne pas être accessible depuis tous les réseaux
2. **`DATABASE_URL`** est privée et fonctionne uniquement entre services Railway
3. Pour le backend Spring Boot, utilisez toujours **`DATABASE_URL`**
4. Pour les clients externes, essayez d'abord **Railway Dashboard** ou **Railway CLI**

---

## 🎯 Recommandation

**Pour exécuter le script SQL :**
- ✅ Utiliser **Railway Dashboard** → Postgres → Database → Query
- ✅ C'est le plus simple et le plus fiable

**Pour le backend Spring Boot :**
- ✅ Utiliser **`DATABASE_URL`** (ajoutée automatiquement par Railway)
- ✅ Aucune configuration manuelle nécessaire

---

## 🐛 Dépannage

### Erreur : "failed to resolve host"

**Cause :** Vous essayez de vous connecter depuis un client externe à une URL privée.

**Solution :**
1. Utiliser Railway Dashboard ou Railway CLI
2. Ou utiliser `DATABASE_PUBLIC_URL` si disponible

### Erreur : "Connection refused"

**Cause :** Le port est bloqué ou l'URL n'est pas accessible.

**Solution :**
1. Vérifier que vous utilisez `DATABASE_PUBLIC_URL` (pas `DATABASE_URL`)
2. Vérifier votre firewall
3. Essayer depuis un autre réseau

### Erreur : "Authentication failed"

**Cause :** Mot de passe incorrect.

**Solution :**
1. Vérifier que vous copiez le bon mot de passe depuis Railway
2. Vérifier qu'il n'y a pas d'espaces avant/après
3. Utiliser Railway Dashboard pour éviter les erreurs de copie

---

**Besoin d'aide ?** Utilisez Railway Dashboard → Postgres → Database → Query, c'est la méthode la plus simple ! ✅

