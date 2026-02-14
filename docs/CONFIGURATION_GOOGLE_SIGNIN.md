# Configuration Google Sign-In - Résolution des erreurs

## 🚨 Problème : Erreur `PlatformException android.gms.common.api.ApiException`

Cette erreur se produit généralement lorsque :
1. Le SHA-1 n'est pas configuré dans Firebase Console
2. Le package name ne correspond pas
3. L'OAuth client n'est pas configuré correctement

## ✅ Solution : Configurer le SHA-1 dans Firebase Console

### Étape 1 : Obtenir le SHA-1

#### Pour Windows (PowerShell) :

```powershell
cd android
.\gradlew signingReport
```

Ou avec keytool directement :

```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Pour macOS/Linux :

```bash
cd android
./gradlew signingReport
```

Ou avec keytool :

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Étape 2 : Copier le SHA-1

Dans la sortie, cherchez la ligne qui contient `SHA1:` et copiez la valeur (avec les `:`).

**Votre SHA-1 actuel :**
```
63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84
```

Copiez cette valeur complète : `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`

### Étape 3 : Ajouter le SHA-1 dans Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet `siblhish-app`
3. Cliquez sur l'icône ⚙️ (Paramètres du projet)
4. Allez dans l'onglet **"Vos applications"**
5. Cliquez sur votre application Android (`ma.siblhish`)
6. Cliquez sur **"Ajouter une empreinte digitale"**
7. Collez votre SHA-1
8. Cliquez sur **"Enregistrer"**

### Étape 4 : Télécharger le nouveau `google-services.json`

1. Dans la même page Firebase Console
2. Cliquez sur **"Télécharger google-services.json"**
3. Remplacez le fichier `android/app/google-services.json` par le nouveau

### Étape 5 : Rebuild l'application

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## 🔍 Vérification

Après avoir ajouté le SHA-1, attendez quelques minutes (2-5 minutes) pour que Firebase mette à jour la configuration.

Ensuite, testez à nouveau la connexion Google.

## 📝 Note importante

Si vous changez le package name ou le keystore, vous devez :
1. Ajouter le nouveau SHA-1 dans Firebase Console
2. Télécharger le nouveau `google-services.json`
3. Rebuild l'application

## 🆘 Si le problème persiste

1. Vérifiez que le package name dans `android/app/build.gradle.kts` correspond à celui dans Firebase Console :
   ```kotlin
   applicationId = "ma.siblhish"
   ```

2. Vérifiez que le `serverClientId` dans `lib/services/auth_service.dart` est correct :
   ```dart
   serverClientId: '179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h.apps.googleusercontent.com',
   ```

3. Vérifiez que le fichier `google-services.json` est bien dans `android/app/`

4. Vérifiez que le plugin Google Services est bien configuré dans `android/app/build.gradle.kts` :
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

