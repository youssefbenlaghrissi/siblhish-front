# Créer un OAuth Client Android dans Google Cloud Console

## 🎯 Problème

Le fichier `google-services.json` n'a pas d'OAuth clients car Firebase ne les génère pas automatiquement. Pour que Google Sign-In fonctionne, il faut créer manuellement un **OAuth Client Android** dans Google Cloud Console.

## ✅ Solution : Créer l'OAuth Client Android

### Étape 1 : Aller dans Google Cloud Console

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet **`siblhish-app`** (ou le projet lié à Firebase)

### Étape 2 : Activer l'API Google Sign-In

1. Allez dans **"APIs & Services"** → **"Library"**
2. Cherchez **"Google Sign-In API"**
3. Cliquez dessus et activez-la si elle n'est pas déjà activée

### Étape 3 : Créer l'OAuth Client Android

1. Allez dans **"APIs & Services"** → **"Credentials"**
2. Cliquez sur **"+ CREATE CREDENTIALS"** en haut
3. Sélectionnez **"OAuth client ID"**
4. Si c'est la première fois, configurez l'écran de consentement OAuth :
   - Choisissez **"External"** (pour les tests)
   - Remplissez les informations de base
   - Cliquez sur **"Save and Continue"** jusqu'à la fin
5. Dans le formulaire de création :
   - **Application type** : Sélectionnez **"Android"**
   - **Name** : `Siblhish Android` (ou un nom de votre choix)
   - **Package name** : `ma.siblhish`
   - **SHA-1 certificate fingerprint** : `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`
6. Cliquez sur **"Create"**

### Étape 4 : Vérifier les OAuth Clients

Vous devriez maintenant avoir **deux** OAuth clients :

1. **OAuth client Web** (pour le `serverClientId`) :
   - Client ID: `179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h.apps.googleusercontent.com`
   - Type: Web application

2. **OAuth client Android** (nouvellement créé) :
   - Client ID: `XXXXX-XXXXX.apps.googleusercontent.com` (un nouveau ID)
   - Type: Android
   - Package name: `ma.siblhish`
   - SHA-1: `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`

## 🔄 Étape 5 : Rebuild l'application

Après avoir créé l'OAuth client Android :

```bash
flutter clean
flutter pub get
flutter run
```

## 🧪 Étape 6 : Tester

Essayez de vous connecter avec Google. Ça devrait fonctionner maintenant !

## 📝 Note importante

- Le `google-services.json` n'a pas besoin d'avoir des OAuth clients pour Google Sign-In
- Le `serverClientId` dans le code est l'OAuth client Web
- L'OAuth client Android que vous venez de créer est utilisé automatiquement par Google Sign-In SDK

## 🆘 Si ça ne fonctionne toujours pas

1. Vérifiez que le package name correspond exactement : `ma.siblhish`
2. Vérifiez que le SHA-1 correspond exactement (majuscules/minuscules)
3. Attendez 2-5 minutes après la création pour que Google synchronise
4. Vérifiez les logs dans la console pour voir le code d'erreur exact

