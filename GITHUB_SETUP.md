# 📦 Guide : Ajouter le projet sur GitHub

## 🎯 Étapes pour publier sur GitHub

### Étape 1 : Créer un repository sur GitHub

1. Aller sur [github.com](https://github.com)
2. Cliquer sur le **"+"** en haut à droite → **"New repository"**
3. Remplir les informations :
   - **Repository name** : `siblhish-front` (ou votre choix)
   - **Description** : `Application Flutter de gestion de budget - Frontend`
   - **Visibility** : Public ou Private (selon votre choix)
   - **NE PAS** cocher "Initialize this repository with a README" (le projet existe déjà)
4. Cliquer sur **"Create repository"**

### Étape 2 : Noter l'URL du repository

GitHub vous donnera une URL, par exemple :
```
https://github.com/VOTRE_USERNAME/siblhish-front.git
```

### Étape 3 : Ajouter tous les fichiers et faire le premier commit

```bash
# Ajouter tous les fichiers
git add .

# Faire le premier commit
git commit -m "Initial commit: Application Flutter Siblhish"
```

### Étape 4 : Ajouter le remote GitHub

```bash
# Remplacer VOTRE_USERNAME par votre nom d'utilisateur GitHub
git remote add origin https://github.com/VOTRE_USERNAME/siblhish-front.git
```

### Étape 5 : Pousser le code sur GitHub

```bash
# Pousser sur la branche main (ou master)
git branch -M main
git push -u origin main
```

Si votre branche s'appelle `master` :
```bash
git push -u origin master
```

---

## ✅ Vérification

1. Aller sur votre repository GitHub
2. Vous devriez voir tous vos fichiers
3. Le code est maintenant sur GitHub !

---

## 🔄 Commandes Git utiles pour la suite

### Voir l'état
```bash
git status
```

### Ajouter des fichiers modifiés
```bash
git add .
git commit -m "Description des changements"
git push
```

### Voir l'historique
```bash
git log
```

### Créer une branche
```bash
git checkout -b nom-de-la-branche
```

---

## 📝 Notes importantes

1. **Ne jamais commiter** :
   - Fichiers avec mots de passe
   - Clés API
   - `google-services.json` (si utilisé)
   - Fichiers de build (`/build/`)

2. **Le `.gitignore`** est déjà configuré pour exclure les fichiers sensibles

3. **Pour le backend** : Créer un repository séparé `siblhish-api`

---

Une fois le code sur GitHub, vous pourrez le connecter à Railway pour le déploiement automatique !

