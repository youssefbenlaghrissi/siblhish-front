# Accéder à Google Cloud Console depuis Firebase

## 🎯 Problème

Vous êtes dans Firebase Console, mais pour créer un OAuth client Android, il faut aller dans **Google Cloud Console**.

## ✅ Solution : Accéder à Google Cloud Console

### Méthode 1 : Depuis Firebase Console

1. Dans Firebase Console, cliquez sur l'icône ⚙️ (Paramètres du projet) en haut à gauche
2. Allez dans l'onglet **"Paramètres généraux"** (General settings)
3. Faites défiler jusqu'à la section **"Votre projet"** (Your project)
4. Cliquez sur le lien **"Gérer le projet dans Google Cloud Console"** (ou le nom de votre projet)
5. Cela vous redirigera vers Google Cloud Console

### Méthode 2 : Directement

1. Allez directement sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet **`siblhish-app`** en haut (dans le sélecteur de projet)

## 📍 Une fois dans Google Cloud Console

1. Dans le menu de gauche, cliquez sur **"APIs & Services"**
2. Cliquez sur **"Credentials"** (Identifiants)
3. Vous verrez la liste de tous les identifiants OAuth
4. Cliquez sur **"+ CREATE CREDENTIALS"** (Créer des identifiants) en haut
5. Sélectionnez **"OAuth client ID"**

## 🔍 Vérifier si un OAuth client Android existe déjà

Dans la page "Credentials", cherchez dans la liste s'il existe déjà un OAuth client de type **"Android"** avec :
- Package name: `ma.siblhish`
- SHA-1: `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`

Si vous en trouvez un, c'est bon ! Il faut juste attendre quelques minutes pour que Google synchronise.

Si vous n'en trouvez pas, créez-en un nouveau (voir `docs/CREER_OAUTH_CLIENT_ANDROID.md`).

