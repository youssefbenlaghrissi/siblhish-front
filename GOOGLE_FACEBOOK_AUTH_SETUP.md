# 🔐 Configuration Google & Facebook Auth

## 📋 Vue d'ensemble

L'authentification sociale est implémentée dans l'application Flutter. Voici les étapes pour configurer Google et Facebook.

---

## 🔵 Configuration Google Sign-In

### 1. Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Créer un nouveau projet : `siblhish`
3. Activer Google Analytics (optionnel)

### 2. Ajouter l'application Android

1. Dans Firebase Console → **"Add app"** → **Android**
2. Package name : `com.siblhish.siblhish_front` (vérifier dans `android/app/build.gradle`)
3. Télécharger `google-services.json`
4. Placer dans `android/app/google-services.json`

### 3. Configurer le SHA-1

```powershell
cd android
./gradlew signingReport
```

Copier le SHA-1 et l'ajouter dans Firebase Console → Project Settings → Your apps → Android → Add fingerprint

### 4. Activer Google Sign-In dans Firebase

1. Firebase Console → **Authentication** → **Sign-in method**
2. Activer **Google**
3. Configurer l'email de support

### 5. Modifier `android/build.gradle`

Ajouter dans `buildscript.dependencies` :

```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### 6. Modifier `android/app/build.gradle`

Ajouter à la fin :

```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 🔵 Configuration Facebook Login

### 1. Créer une application Facebook

1. Aller sur [Facebook Developers](https://developers.facebook.com)
2. **My Apps** → **Create App**
3. Type : **Consumer**
4. Nom : `Siblhish`

### 2. Configurer Facebook Login

1. Dans votre app → **Add Product** → **Facebook Login** → **Set Up**
2. Sélectionner **Android**

### 3. Ajouter les informations Android

1. Package name : `com.siblhish.siblhish_front`
2. Default Activity Class Name : `com.siblhish.siblhish_front.MainActivity`
3. Key Hashes : Générer avec :

```powershell
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

### 4. Modifier `android/app/src/main/res/values/strings.xml`

Créer le fichier s'il n'existe pas :

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">VOTRE_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbVOTRE_APP_ID</string>
    <string name="facebook_client_token">VOTRE_CLIENT_TOKEN</string>
</resources>
```

### 5. Modifier `android/app/src/main/AndroidManifest.xml`

Ajouter dans `<application>` :

```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>

<activity android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />
<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

---

## 🖥️ Configuration Backend (Railway)

### Ajouter l'endpoint OAuth dans Spring Boot

Le backend doit avoir un endpoint `/api/v1/auth/social` qui :

1. Vérifie le token Google/Facebook
2. Crée ou récupère l'utilisateur
3. Retourne les informations utilisateur

**Exemple de contrôleur :**

```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    
    @PostMapping("/social")
    public ResponseEntity<?> socialLogin(@RequestBody SocialLoginRequest request) {
        // Vérifier le token avec Google/Facebook
        // Créer ou récupérer l'utilisateur
        // Retourner les infos utilisateur
    }
}
```

---

## ✅ Test

### 1. Installer les dépendances

```powershell
flutter pub get
```

### 2. Lancer l'application

```powershell
flutter run -d 46210DLAQ000NV
```

### 3. Tester la connexion

1. L'écran de login s'affiche
2. Cliquer sur "Continuer avec Google" ou "Continuer avec Facebook"
3. Suivre le flux d'authentification
4. L'application devrait rediriger vers l'écran principal

---

## 🔄 Flux d'authentification

```
1. Utilisateur clique sur "Continuer avec Google/Facebook"
2. SDK ouvre la page de connexion Google/Facebook
3. Utilisateur se connecte
4. SDK retourne le token
5. App envoie le token au backend Railway
6. Backend vérifie le token et crée/récupère l'utilisateur
7. Backend retourne les infos utilisateur
8. App sauvegarde l'ID utilisateur localement
9. App redirige vers l'écran principal
```

---

## 📝 Notes importantes

1. **Mode développement** : L'authentification fonctionne même sans backend OAuth grâce au fallback
2. **Production** : Implémenter l'endpoint `/api/v1/auth/social` dans le backend
3. **Sécurité** : Ne jamais stocker les tokens sensibles en clair

---

## 🐛 Dépannage

### Erreur : "DEVELOPER_ERROR" (Google)

- Vérifier que le SHA-1 est correct dans Firebase
- Vérifier que `google-services.json` est à jour

### Erreur : "Invalid key hash" (Facebook)

- Régénérer le key hash
- Ajouter tous les key hashes (debug et release) dans Facebook Developer Console

### L'app ne compile pas

- Exécuter `flutter clean && flutter pub get`
- Vérifier les versions des dépendances

---

## 🎯 Prochaines étapes

1. ✅ Créer le projet Firebase
2. ✅ Configurer Google Sign-In
3. ✅ Créer l'app Facebook Developer
4. ✅ Configurer Facebook Login
5. ⏳ Implémenter l'endpoint OAuth dans le backend
6. ⏳ Tester le flux complet

---

**Besoin d'aide ?** Consultez la documentation officielle :
- [google_sign_in](https://pub.dev/packages/google_sign_in)
- [flutter_facebook_auth](https://pub.dev/packages/flutter_facebook_auth)

