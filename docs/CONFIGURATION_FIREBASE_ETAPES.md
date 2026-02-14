# Configuration Firebase - Étapes Détaillées

## 📋 Prérequis

1. Avoir un compte Google
2. Avoir créé un projet Firebase (ou en créer un nouveau)
3. Avoir accès à Firebase Console : https://console.firebase.google.com/

---

## 🔧 ÉTAPE 1 : Créer/Ajouter le projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur **"Ajouter un projet"** ou sélectionner un projet existant
3. Si nouveau projet :
   - Nom du projet : `Siblhish` (ou votre choix)
   - Activer Google Analytics (optionnel mais recommandé)
   - Créer le projet

---

## 📱 ÉTAPE 2 : Configurer Android

### 2.1. Ajouter l'application Android dans Firebase

1. Dans Firebase Console, cliquer sur l'icône **Android** (ou "Ajouter une application")
2. Remplir les informations :
   - **Package name** : `com.example.siblhish_front`
     - ⚠️ **Important** : Ce doit être exactement le même que dans `android/app/build.gradle.kts` (ligne `applicationId`)
   - **App nickname** : `Siblhish Android` (optionnel)
   - **Debug signing certificate SHA-1** : (optionnel pour le moment, on peut l'ajouter après)
3. Cliquer sur **"Enregistrer l'application"**

### 2.2. Télécharger `google-services.json`

1. Après avoir ajouté l'app, Firebase affiche un écran de téléchargement
2. Cliquer sur **"Télécharger google-services.json"**
3. **Placer le fichier** dans : `android/app/google-services.json`
   - ⚠️ **Important** : Le fichier doit être exactement dans `android/app/`, pas ailleurs

### 2.3. Obtenir le SHA-1 (pour plus tard, optionnel mais recommandé)

Le SHA-1 est nécessaire pour certaines fonctionnalités Firebase (comme Google Sign-In).

**Windows (PowerShell) :**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Cherchez la ligne `SHA1:` et copiez la valeur (ex: `63:3D:D0:8F:A9:29:...`)

**Ajouter le SHA-1 dans Firebase :**
1. Firebase Console → Paramètres du projet (⚙️) → Vos applications
2. Cliquer sur votre application Android
3. Cliquer sur **"Ajouter une empreinte"**
4. Coller le SHA-1
5. Enregistrer

---

## 🍎 ÉTAPE 3 : Configurer iOS

### 3.1. Ajouter l'application iOS dans Firebase

1. Dans Firebase Console, cliquer sur l'icône **iOS** (ou "Ajouter une application")
2. Remplir les informations :
   - **Bundle ID** : `com.example.siblhishFront`
     - ⚠️ **Important** : Ce doit être exactement le même que dans `ios/Runner.xcodeproj/project.pbxproj` (ligne `PRODUCT_BUNDLE_IDENTIFIER`)
   - **App nickname** : `Siblhish iOS` (optionnel)
   - **App Store ID** : (laisser vide pour le moment)
3. Cliquer sur **"Enregistrer l'application"**

### 3.2. Télécharger `GoogleService-Info.plist`

1. Après avoir ajouté l'app, Firebase affiche un écran de téléchargement
2. Cliquer sur **"Télécharger GoogleService-Info.plist"**
3. **Placer le fichier** dans : `ios/Runner/GoogleService-Info.plist`
   - ⚠️ **Important** : Le fichier doit être exactement dans `ios/Runner/`, pas ailleurs

### 3.3. Ajouter le fichier au projet Xcode (si vous utilisez Xcode)

1. Ouvrir le projet dans Xcode : `ios/Runner.xcworkspace`
2. Glisser-déposer `GoogleService-Info.plist` dans le dossier `Runner` dans Xcode
3. Cocher **"Copy items if needed"** et **"Add to targets: Runner"**
4. Cliquer sur **"Finish"**

---

## ✅ ÉTAPE 4 : Vérifier les Package Names

Avant de continuer, vérifiez que les package names correspondent :

### Android
- Firebase Console : `com.example.siblhish_front`
- Votre code (`android/app/build.gradle.kts`) : `com.example.siblhish_front`
- ✅ Doivent être identiques

### iOS
- Firebase Console : `com.example.siblhishFront`
- Votre code (`ios/Runner.xcodeproj/project.pbxproj`) : `com.example.siblhishFront`
- ✅ Doivent être identiques

---

## 📝 ÉTAPE 5 : Checklist de Vérification

Avant de passer au code, vérifiez :

### Android :
- [ ] Application Android ajoutée dans Firebase Console
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] Package name correspond (`com.example.siblhish_front`)
- [ ] SHA-1 ajouté (optionnel mais recommandé)

### iOS :
- [ ] Application iOS ajoutée dans Firebase Console
- [ ] `GoogleService-Info.plist` téléchargé et placé dans `ios/Runner/`
- [ ] Bundle ID correspond (`com.example.siblhishFront`)
- [ ] Fichier ajouté au projet Xcode (si vous utilisez Xcode)

---

## 🎯 Prochaines Étapes (Code)

Une fois ces étapes terminées, je pourrai vous aider à :
1. Installer les packages Firebase dans `pubspec.yaml`
2. Configurer les fichiers Gradle pour Android
3. Configurer `AppDelegate.swift` pour iOS
4. Créer le code Flutter pour initialiser Firebase
5. Créer le service de notifications push

---

## 🚨 Problèmes Courants

### Le package name ne correspond pas
- **Solution** : Vérifiez dans `android/app/build.gradle.kts` (ligne `applicationId`) et dans Firebase Console

### Le Bundle ID ne correspond pas
- **Solution** : Vérifiez dans `ios/Runner.xcodeproj/project.pbxproj` (ligne `PRODUCT_BUNDLE_IDENTIFIER`) et dans Firebase Console

### Le fichier `google-services.json` n'est pas trouvé
- **Solution** : Vérifiez qu'il est exactement dans `android/app/google-services.json` (pas dans `android/` ou ailleurs)

### Le fichier `GoogleService-Info.plist` n'est pas trouvé
- **Solution** : Vérifiez qu'il est exactement dans `ios/Runner/GoogleService-Info.plist`

---

## 📞 Besoin d'aide ?

Une fois que vous avez terminé ces étapes, dites-moi et je vous aiderai avec la partie code !

