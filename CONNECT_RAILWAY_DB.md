# 🔌 Comment se connecter à PostgreSQL sur Railway

## ⚠️ Votre erreur

L'erreur `failed to resolve host 'maglev.proxy.rlwy.net'` signifie que l'URL publique de Railway n'est pas accessible depuis votre réseau.

---

## ✅ Solution : Utiliser Railway Dashboard (Le plus simple)

### Étape 1 : Accéder à l'éditeur SQL

1. Aller sur [railway.app](https://railway.app)
2. Ouvrir votre projet
3. Cliquer sur le service **Postgres**
4. Cliquer sur l'onglet **"Database"** (ou **"Query"**)
5. Un éditeur SQL s'ouvre

### Étape 2 : Exécuter le script SQL

1. Ouvrir le fichier :
   ```
   C:\Users\youssef.benlaghrissi\Documents\siblhish-front\scripts\seed_database.sql
   ```

2. **Sélectionner tout** (Ctrl+A) et **Copier** (Ctrl+C)

3. Dans Railway Dashboard, **Coller** (Ctrl+V) le script dans l'éditeur

4. Cliquer sur **"Run Query"** ou appuyer sur **F5**

5. ✅ Le script s'exécute et la base de données est alimentée !

---

## 🔄 Alternative : Railway CLI

Si vous préférez utiliser la ligne de commande :

### 1. Installer Railway CLI

```powershell
npm i -g @railway/cli
```

### 2. Se connecter

```powershell
railway login
```

### 3. Lier le projet

```powershell
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
railway link
```

Sélectionner votre projet Railway.

### 4. Se connecter à PostgreSQL

```powershell
railway connect postgres
```

Cela ouvre un shell PostgreSQL interactif.

### 5. Exécuter le script

Dans le shell PostgreSQL, copier-coller le contenu de `seed_database.sql`.

---

## 📝 Note importante pour le backend Spring Boot

**Vous n'avez PAS besoin de vous connecter manuellement !**

Quand vous liez PostgreSQL au service Spring Boot dans Railway :
- Railway ajoute automatiquement `DATABASE_URL`
- Le backend se connecte automatiquement
- Aucune configuration manuelle nécessaire ✅

---

## 🎯 Résumé

**Pour exécuter le script SQL :**
- ✅ **Railway Dashboard** → Postgres → Database → Query (le plus simple)
- ✅ **Railway CLI** → `railway connect postgres`

**Pour le backend Spring Boot :**
- ✅ Railway gère tout automatiquement quand vous liez PostgreSQL
- ✅ Utilisez `DATABASE_URL` (pas `DATABASE_PUBLIC_URL`)

---

**Recommandation :** Utilisez Railway Dashboard, c'est la méthode la plus simple et la plus fiable ! 🚀

