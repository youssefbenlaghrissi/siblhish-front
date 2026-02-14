# Vérification de la Configuration Google Sign-In

## ✅ Étape 1 : SHA-1 ajouté dans Firebase Console
Le SHA-1 a été ajouté avec succès dans Firebase Console.

## 🔍 Étape 2 : Vérifier dans Google Cloud Console

Pour que Google Sign-In fonctionne, il faut aussi vérifier que les identifiants OAuth sont configurés dans Google Cloud Console :

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet `siblhish-app` (ou le projet lié à Firebase)
3. Allez dans **"APIs & Services"** → **"Credentials"**
4. Vérifiez qu'il existe un **"OAuth 2.0 Client ID"** de type **"Android"** avec :
   - Package name: `ma.siblhish`
   - SHA-1: `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`

5. Vérifiez aussi qu'il existe un **"OAuth 2.0 Client ID"** de type **"Web application"** avec :
   - Client ID: `179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h.apps.googleusercontent.com`
   - C'est le `serverClientId` utilisé dans le code

## 🔄 Étape 3 : Télécharger le nouveau google-services.json

1. Dans Firebase Console, sur la page de votre application Android
2. Cliquez sur le bouton **"google-services.json"** (icône de téléchargement)
3. Remplacez le fichier `android/app/google-services.json`

## ⏱️ Étape 4 : Attendre la synchronisation

Après avoir ajouté le SHA-1, Firebase peut prendre **2-5 minutes** pour :
- Générer les OAuth clients
- Synchroniser avec Google Cloud Console
- Mettre à jour le fichier `google-services.json`

## 🧪 Étape 5 : Tester

1. Attendez 2-5 minutes après avoir ajouté le SHA-1
2. Téléchargez le nouveau `google-services.json` si disponible
3. Rebuild l'application :
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
4. Essayez de vous connecter avec Google

## 🆘 Si ça ne fonctionne toujours pas

### Vérifier que le package name est correct :
- Dans `android/app/build.gradle.kts` : `applicationId = "ma.siblhish"`
- Dans Firebase Console : doit correspondre exactement

### Vérifier le serverClientId :
- Dans `lib/services/auth_service.dart` : doit correspondre au Client ID Web dans Google Cloud Console

### Vérifier les logs :
- Regardez les logs dans la console pour voir le code d'erreur exact
- Les messages d'erreur améliorés devraient indiquer le problème spécifique

