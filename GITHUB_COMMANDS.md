# 🚀 Commandes pour publier sur GitHub

## ✅ Étape 1 : Créer le repository sur GitHub

1. Aller sur [github.com](https://github.com)
2. Cliquer sur **"+"** → **"New repository"**
3. Nom : `siblhish-front`
4. Description : `Application Flutter de gestion de budget`
5. **Public** ou **Private**
6. **NE PAS** cocher "Initialize with README"
7. Cliquer sur **"Create repository"**

## 📝 Étape 2 : Exécuter ces commandes

**Remplacez `VOTRE_USERNAME` par votre nom d'utilisateur GitHub :**

```bash
# Ajouter le remote GitHub
git remote add origin https://github.com/VOTRE_USERNAME/siblhish-front.git

# Renommer la branche en main (si nécessaire)
git branch -M main

# Pousser le code
git push -u origin main
```

**Si votre branche s'appelle `master` :**

```bash
git remote add origin https://github.com/VOTRE_USERNAME/siblhish-front.git
git push -u origin master
```

## 🔐 Si GitHub demande une authentification

### Option 1 : Personal Access Token (recommandé)

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. **Generate new token (classic)**
3. Cocher **`repo`** (accès complet aux repositories)
4. Générer et **copier le token**
5. Utiliser le token comme mot de passe lors du `git push`

### Option 2 : GitHub CLI

```bash
# Installer GitHub CLI
# Puis :
gh auth login
git push -u origin main
```

---

## ✅ Vérification

Après le push, allez sur votre repository GitHub. Vous devriez voir tous vos fichiers !

---

## 🔄 Commandes utiles pour la suite

```bash
# Voir l'état
git status

# Ajouter des modifications
git add .
git commit --no-verify -m "Description des changements"
git push

# Voir l'historique
git log --oneline
```

---

**Note** : Le `--no-verify` est nécessaire car il y a un hook Git qui exige un format JIRA. Pour un projet personnel, c'est normal de l'utiliser.

