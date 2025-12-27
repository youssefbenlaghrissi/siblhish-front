# 🗄️ Changer le nom de la base de données vers "siblhish"

## 📋 Méthode 1 : Créer une nouvelle base de données (Recommandé)

### Étape 1 : Créer la base de données "siblhish"

1. Aller sur Railway → Service Postgres → **"Database"** → **"Query"**
2. Exécuter cette commande SQL :

```sql
CREATE DATABASE siblhish;
```

### Étape 2 : Mettre à jour la variable d'environnement

1. Railway → Service Postgres → **"Variables"**
2. Trouver **`PGDATABASE`**
3. Cliquer sur l'icône **"✏️"** pour modifier
4. Changer la valeur de `railway` à `siblhish`
5. **Save**

### Étape 3 : Mettre à jour DATABASE_URL

Railway mettra automatiquement à jour `DATABASE_URL` pour pointer vers `siblhish`.

### Étape 4 : Exécuter le script SQL

1. Railway → Postgres → **"Database"** → **"Query"**
2. **Important :** Sélectionner la base `siblhish` dans le menu déroulant (en haut de l'éditeur)
3. Copier-coller le contenu de `seed_database.sql`
4. Cliquer sur **"Run Query"**

---

## 📋 Méthode 2 : Renommer la base existante

### Étape 1 : Renommer la base de données

1. Railway → Service Postgres → **"Database"** → **"Query"**
2. Exécuter :

```sql
-- Se connecter à la base postgres (par défaut)
\c postgres

-- Renommer la base de données
ALTER DATABASE railway RENAME TO siblhish;
```

### Étape 2 : Mettre à jour la variable PGDATABASE

1. Railway → Service Postgres → **"Variables"**
2. Modifier **`PGDATABASE`** : `railway` → `siblhish`
3. **Save**

### Étape 3 : Vérifier

1. Railway → Postgres → **"Database"** → **"Query"**
2. Sélectionner `siblhish` dans le menu déroulant
3. Exécuter : `SELECT current_database();`
4. Vous devriez voir `siblhish`

---

## ✅ Vérification finale

### Vérifier que la base s'appelle "siblhish"

```sql
SELECT current_database();
```

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

## 🔄 Mise à jour du backend Spring Boot

**Aucune modification nécessaire !** 

Railway mettra automatiquement à jour `DATABASE_URL` et `PGDATABASE` quand vous modifiez la variable d'environnement. Le backend Spring Boot utilisera automatiquement la nouvelle base de données.

---

## 📝 Notes importantes

1. **Sauvegarder les données** : Si vous avez déjà des données dans `railway`, pensez à les exporter avant de renommer
2. **Redémarrer les services** : Après avoir changé `PGDATABASE`, redémarrer le service Spring Boot pour qu'il se reconnecte
3. **Vérifier les connexions** : Tous les services connectés à PostgreSQL utiliseront automatiquement la nouvelle base

---

## 🎯 Recommandation

**Utiliser la Méthode 1** (créer une nouvelle base) si :
- Vous n'avez pas encore de données importantes
- Vous voulez un environnement propre

**Utiliser la Méthode 2** (renommer) si :
- Vous avez déjà des données dans `railway`
- Vous voulez conserver les données existantes

---

**Besoin d'aide ?** Utilisez Railway Dashboard → Postgres → Database → Query pour exécuter les commandes SQL ! ✅

