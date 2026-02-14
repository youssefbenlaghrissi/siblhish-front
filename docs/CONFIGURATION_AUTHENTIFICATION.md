# Configuration de l'Authentification (Google & Facebook)

## 📊 État Actuel

### ✅ Ce qui est configuré :
- ✅ Package `google_sign_in: ^6.2.1` installé dans `pubspec.yaml`
- ✅ Code d'authentification Google dans `lib/services/auth_service.dart`
- ✅ `serverClientId` configuré dans le code
- ✅ **Google Sign-In fonctionne sur Android** (utilise `serverClientId` pour l'authentification côté serveur)

### ⚠️ Configuration actuelle :
Le package `google_sign_in` peut fonctionner avec uniquement le `serverClientId` pour l'authentification côté serveur. Le `google-services.json` est principalement nécessaire pour Firebase, mais pas obligatoire pour Google Sign-In basique.

### ❓ À vérifier pour Google Sign-In :

#### **Android** :
- ✅ Fonctionne actuellement avec `serverClientId`
- ℹ️ Pour une configuration complète (optionnel) : `google-services.json` et plugin Google Services

#### **iOS** :
1. ❓ Fichier `GoogleService-Info.plist` - À vérifier
2. ❓ Configuration `CFBundleURLSchemes` dans `Info.plist` - À vérifier
3. ❓ `REVERSED_CLIENT_ID` - À vérifier

### ❌ Facebook :
- ❌ Non configuré (rollback effectué)

---

## 🔧 Configuration Google Sign-In

> **Note** : Google Sign-In fonctionne déjà sur Android avec le `serverClientId`. Les étapes ci-dessous sont pour une configuration complète ou pour iOS.

### **Étape 1 : Créer/Configurer le projet dans Google Cloud Console**

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créer ou sélectionner un projet
3. Activer l'API "Google Sign-In"
4. Créer des identifiants OAuth 2.0 :

#### **Pour Android** :
- Type : **Application Android**
- Nom du package : `com.example.siblhish_front`
- SHA-1 : Obtenir avec la commande ci-dessous
- Télécharger `google-services.json`

#### **Pour iOS** :
- Type : **Application iOS**
- Bundle ID : Votre Bundle ID iOS (ex: `com.example.siblhishFront`)
- Télécharger `GoogleService-Info.plist`

### **Étape 2 : Obtenir le SHA-1 pour Android** (Optionnel - pour configuration complète)

> **Note** : Si Google Sign-In fonctionne déjà, cette étape est optionnelle. Elle est nécessaire uniquement si vous voulez utiliser Firebase ou une configuration complète.

```bash
# Windows (PowerShell)
cd android
.\gradlew signingReport

# Ou avec keytool
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copier le SHA-1 et l'ajouter dans Google Cloud Console.

### **Étape 3 : Configuration Android** (Optionnel - pour configuration complète)

#### 3.1. Ajouter le plugin Google Services

**Fichier : `android/build.gradle.kts`**
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**Fichier : `android/app/build.gradle.kts`**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Ajouter cette ligne
}
```

#### 3.2. Ajouter `google-services.json`

1. Télécharger `google-services.json` depuis Google Cloud Console
2. Placer le fichier dans : `android/app/google-services.json`

### **Étape 4 : Configuration iOS** (⚠️ Nécessaire si iOS ne fonctionne pas)

#### 4.1. Ajouter `GoogleService-Info.plist`

1. Télécharger `GoogleService-Info.plist` depuis Google Cloud Console
2. Placer le fichier dans : `ios/Runner/GoogleService-Info.plist`
3. L'ajouter au projet Xcode (glisser-déposer dans Xcode)

#### 4.2. Modifier `Info.plist`

**Fichier : `ios/Runner/Info.plist`**

Ajouter avant `</dict></plist>` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Remplacer par votre REVERSED_CLIENT_ID depuis GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h</string>
        </array>
    </dict>
</array>
```

**⚠️ Important** : Le `REVERSED_CLIENT_ID` se trouve dans `GoogleService-Info.plist` sous la clé `REVERSED_CLIENT_ID`.

### **Étape 5 : Vérifier le code Flutter**

Le code dans `lib/services/auth_service.dart` est correct, mais pour iOS, il faut aussi spécifier le `clientId` :

```dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h.apps.googleusercontent.com',
  // Pour iOS, ajouter aussi :
  // clientId: 'VOTRE_CLIENT_ID_IOS.apps.googleusercontent.com', // Si différent
);
```

---

## 🔵 Configuration Facebook Login

### **Étape 1 : Créer une application Facebook**

1. Aller sur [Facebook Developers](https://developers.facebook.com/)
2. Créer une nouvelle application
3. Ajouter le produit "Facebook Login"
4. Configurer les paramètres :

#### **Pour Android** :
- Package Name : `com.example.siblhish_front`
- Class Name : `com.example.siblhish_front.MainActivity`
- Key Hash : Obtenir avec la commande ci-dessous

#### **Pour iOS** :
- Bundle ID : Votre Bundle ID iOS
- URL Scheme : `fb{VOTRE_APP_ID}`

### **Étape 2 : Installer le package Flutter**

**Fichier : `pubspec.yaml`**
```yaml
dependencies:
  flutter_facebook_auth: ^7.0.2
```

Puis exécuter :
```bash
flutter pub get
```

### **Étape 3 : Obtenir le Key Hash pour Android**

```bash
# Windows (PowerShell)
keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" | openssl sha1 -binary | openssl base64
```

Ajouter ce Key Hash dans les paramètres Android de l'application Facebook.

### **Étape 4 : Configuration Android**

#### 4.1. Ajouter dans `AndroidManifest.xml`

**Fichier : `android/app/src/main/AndroidManifest.xml`**

Ajouter dans `<application>` :

```xml
<meta-data 
    android:name="com.facebook.sdk.ApplicationId" 
    android:value="@string/facebook_app_id"/>
<meta-data 
    android:name="com.facebook.sdk.ClientToken" 
    android:value="@string/facebook_client_token"/>
```

#### 4.2. Créer `strings.xml`

**Fichier : `android/app/src/main/res/values/strings.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Siblhish</string>
    <string name="facebook_app_id">VOTRE_APP_ID_FACEBOOK</string>
    <string name="facebook_client_token">VOTRE_CLIENT_TOKEN</string>
</resources>
```

### **Étape 5 : Configuration iOS**

#### 5.1. Modifier `Info.plist`

**Fichier : `ios/Runner/Info.plist`**

Ajouter dans `<dict>` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb{VOTRE_APP_ID_FACEBOOK}</string>
        </array>
    </dict>
</array>
<key>FacebookAppID</key>
<string>VOTRE_APP_ID_FACEBOOK</string>
<key>FacebookClientToken</key>
<string>VOTRE_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Siblhish</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
</array>
```

### **Étape 6 : Ajouter le code Facebook dans Flutter**

**Fichier : `lib/services/auth_service.dart`**

```dart
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// ==================== Facebook Sign In ====================

/// Connexion avec Facebook
static Future<Map<String, dynamic>?> signInWithFacebook() async {
  try {
    // Lancer la connexion Facebook
    final LoginResult result = await FacebookAuth.instance.login();
    
    if (result.status == LoginStatus.success) {
      // Récupérer les informations utilisateur
      final userData = await FacebookAuth.instance.getUserData();
      
      // Envoyer au backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/social'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'provider': 'facebook',
          'email': userData['email'],
          'displayName': userData['name'] ?? userData['email']?.split('@').first,
          'photoUrl': userData['picture']?['data']?['url'],
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parser la réponse (même logique que Google)
        final body = response.body;
        final idMatch = RegExp(r'"id":(\d+)').firstMatch(body);
        final firstNameMatch = RegExp(r'"firstName":"([^"]*)"').firstMatch(body);
        final lastNameMatch = RegExp(r'"lastName":"([^"]*)"').firstMatch(body);
        final emailMatch = RegExp(r'"email":"([^"]*)"').firstMatch(body);
        
        final userData = {
          'id': idMatch?.group(1) ?? '1',
          'firstName': firstNameMatch?.group(1) ?? 'User',
          'lastName': lastNameMatch?.group(1) ?? '',
          'email': emailMatch?.group(1) ?? userData['email'],
        };
        
        await _saveUserData(userData);
        return userData;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } else {
      return null;
    }
  } catch (e) {
    rethrow;
  }
}

/// Déconnexion Facebook
static Future<void> logout() async {
  try {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();  // ← Ajouter
    // ... reste du code
  } catch (e) {
    rethrow;
  }
}
```

---

## ✅ Checklist de Vérification

### Google Sign-In Android :
- [x] ✅ **Fonctionne actuellement** avec `serverClientId`
- [ ] (Optionnel) `google-services.json` ajouté dans `android/app/` - Pour configuration complète
- [ ] (Optionnel) Plugin Google Services ajouté dans `build.gradle.kts` - Pour configuration complète
- [ ] (Optionnel) SHA-1 enregistré dans Google Cloud Console - Pour configuration complète

### Google Sign-In iOS :
- [ ] `GoogleService-Info.plist` ajouté dans `ios/Runner/` - **À vérifier**
- [ ] `CFBundleURLSchemes` configuré dans `Info.plist` - **À vérifier**
- [ ] Bundle ID correspond dans Google Cloud Console - **À vérifier**

### Facebook Android :
- [ ] Package `flutter_facebook_auth` installé
- [ ] `strings.xml` créé avec App ID et Client Token
- [ ] Key Hash ajouté dans Facebook Developers
- [ ] Meta-data ajoutés dans `AndroidManifest.xml`

### Facebook iOS :
- [ ] `CFBundleURLSchemes` configuré dans `Info.plist`
- [ ] `FacebookAppID` et `FacebookClientToken` ajoutés
- [ ] Bundle ID correspond dans Facebook Developers

---

## 🧪 Test

### Tester Google Sign-In :
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### Tester Facebook :
1. S'assurer que l'application est en mode développement dans Facebook Developers
2. Ajouter des utilisateurs de test si nécessaire
3. Tester la connexion

---

## 📝 Notes Importantes

1. **En développement** : Utiliser les clés de debug (SHA-1 debug, etc.)
2. **En production** : Créer des clés de release et les enregistrer
3. **iOS** : Pour tester sur un appareil réel, configurer le provisioning profile
4. **Backend** : Vérifier que l'endpoint `/auth/social` accepte `provider: 'facebook'`

---

## 🚨 Problèmes Courants

### Google Sign-In ne fonctionne pas sur Android :
- Vérifier que `google-services.json` est au bon endroit
- Vérifier que le SHA-1 correspond
- Vérifier que le package name est correct

### Google Sign-In ne fonctionne pas sur iOS :
- Vérifier que `GoogleService-Info.plist` est ajouté au projet Xcode
- Vérifier que `CFBundleURLSchemes` contient le bon `REVERSED_CLIENT_ID`

### Facebook ne fonctionne pas :
- Vérifier que l'application Facebook est en mode développement
- Vérifier que les Key Hashes sont corrects
- Vérifier que les permissions sont demandées dans le code

