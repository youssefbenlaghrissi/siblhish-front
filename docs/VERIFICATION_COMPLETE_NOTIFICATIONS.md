# Vérification Complète : Notifications Firebase

## 📱 Frontend (Flutter) - État Actuel

### ✅ Configuration Firebase - COMPLET

- [x] **Firebase Core initialisé** (`lib/main.dart`)
  - ✅ `Firebase.initializeApp()` appelé avec `DefaultFirebaseOptions`
  - ✅ `firebase_options.dart` présent et configuré
  - ✅ Handler background configuré : `FirebaseMessaging.onBackgroundMessage()`

- [x] **Packages Firebase installés** (`pubspec.yaml`)
  - ✅ `firebase_core: ^3.6.0`
  - ✅ `firebase_messaging: ^15.1.3`
  - ✅ `flutter_local_notifications: ^18.0.1`

- [x] **Service de notifications** (`lib/services/push_notification_service.dart`)
  - ✅ Permissions demandées automatiquement
  - ✅ Token FCM obtenu et envoyé au backend
  - ✅ Handlers configurés :
    - ✅ Foreground : `FirebaseMessaging.onMessage`
    - ✅ Background : `FirebaseMessaging.onMessageOpenedApp`
    - ✅ App fermée : `getInitialMessage()`
  - ✅ `setUserId()` appelé après connexion (ligne 174 dans `budget_provider.dart`)

- [x] **Handler background** (`lib/firebase_messaging_handler.dart`)
  - ✅ Affiche les notifications locales même quand l'app est fermée
  - ✅ Gère les deux formats (notification payload et data payload)

- [x] **Permissions Android** (`android/app/src/main/AndroidManifest.xml`)
  - ✅ `POST_NOTIFICATIONS`
  - ✅ `VIBRATE`
  - ✅ `RECEIVE_BOOT_COMPLETED`

- [x] **Configuration Android**
  - ✅ Plugin Google Services activé (`android/app/build.gradle.kts`)
  - ✅ `google-services.json` présent (`android/app/google-services.json`)
  - ✅ `build.gradle.kts` avec classpath Google Services

- [x] **Configuration iOS**
  - ✅ `GoogleService-Info.plist` présent
  - ✅ `AppDelegate.swift` configure Firebase

### ⚠️ Points à vérifier manuellement

1. **Token FCM envoyé après connexion**
   - ✅ Code présent : `PushNotificationService.setUserId()` appelé ligne 174
   - ⚠️ **À tester** : Vérifier les logs après connexion : `✅ Token FCM envoyé au backend`

2. **Permissions accordées**
   - ⚠️ **À tester** : Vérifier dans les paramètres Android que les notifications sont activées
   - ⚠️ **À tester** : Tester avec l'app fermée

---

## 🔧 Backend (Spring Boot - siblhish-api) - État Actuel

### ✅ API FCM Token - COMPLET

- [x] **Endpoint pour recevoir les tokens** (`backend/UserFcmTokenController.java`)
  - ✅ `POST /api/v1/users/{userId}/fcm-token`
  - ✅ Validation du token
  - ✅ Token stocké en base de données

- [x] **Champ fcmToken dans User** (`backend/User_Entity_Field.java`)
  - ✅ Champ `fcm_token VARCHAR(500)` dans la table `users`
  - ✅ Migration SQL disponible

- [x] **Service User** (`backend/UserService_FCM_Method.java`)
  - ✅ Méthode `updateFcmToken()` disponible

### ❌ Service FCM pour ENVOYER les notifications - À CRÉER

**Fichiers nécessaires dans votre backend Spring Boot :**

1. **`src/main/java/ma/siblhish/service/FcmNotificationService.java`**
   - ❌ À créer
   - Service pour envoyer les notifications via Firebase Admin SDK

2. **`src/main/java/ma/siblhish/config/FirebaseConfig.java`**
   - ❌ À créer
   - Configuration Firebase Admin SDK

3. **`src/main/resources/serviceAccountKey.json`**
   - ❌ À télécharger depuis Firebase Console
   - ⚠️ **NE JAMAIS COMMITER** dans Git

4. **Dépendance Firebase Admin SDK**
   - ❌ À ajouter dans `pom.xml` ou `build.gradle`
   ```xml
   <dependency>
       <groupId>com.google.firebase</groupId>
       <artifactId>firebase-admin</artifactId>
       <version>9.2.0</version>
   </dependency>
   ```

### ❌ Service RecurringTransaction - À VÉRIFIER/CRÉER

**Fichier nécessaire :**

1. **`src/main/java/ma/siblhish/service/RecurringTransactionService.java`**
   - ❌ À vérifier/créer
   - Doit avoir `@Scheduled` pour s'exécuter toutes les heures
   - Doit créer les nouveaux revenus
   - Doit envoyer les notifications via `FcmNotificationService`

2. **`@EnableScheduling`**
   - ❌ À vérifier dans votre classe principale (ex: `Application.java`)

---

## 📋 Checklist Complète

### Frontend ✅

- [x] Firebase Core initialisé
- [x] Packages Firebase installés
- [x] Handler background configuré
- [x] Service de notifications implémenté
- [x] Permissions Android configurées
- [x] `google-services.json` présent
- [x] `GoogleService-Info.plist` présent (iOS)
- [x] Token FCM envoyé après connexion (code présent)
- [ ] **À tester** : Token FCM envoyé (vérifier les logs)
- [ ] **À tester** : Permissions accordées (tester avec app fermée)

### Backend ❌

- [x] Endpoint pour recevoir les tokens FCM
- [x] Champ `fcm_token` dans la table `users`
- [ ] **À créer** : Dépendance Firebase Admin SDK
- [ ] **À créer** : Fichier `serviceAccountKey.json`
- [ ] **À créer** : `FirebaseConfig.java`
- [ ] **À créer** : `FcmNotificationService.java`
- [ ] **À vérifier** : `RecurringTransactionService.java`
- [ ] **À vérifier** : `@EnableScheduling` activé
- [ ] **À tester** : Notification manuelle
- [ ] **À tester** : Notification automatique (batch job)

---

## 🚀 Actions Requises dans le Backend

### Étape 1 : Ajouter la dépendance Firebase Admin SDK

**Fichier : `pom.xml` (Maven)**
```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.2.0</version>
</dependency>
```

**Fichier : `build.gradle` (Gradle)**
```gradle
implementation 'com.google.firebase:firebase-admin:9.2.0'
```

### Étape 2 : Télécharger le fichier de credentials

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet `siblhish-app`
3. Paramètres du projet → Comptes de service
4. Cliquez sur "Générer une nouvelle clé privée"
5. Téléchargez le fichier JSON
6. Renommez-le en `serviceAccountKey.json`
7. Placez-le dans `src/main/resources/serviceAccountKey.json`

**⚠️ Important :** Ajoutez dans `.gitignore` :
```
src/main/resources/serviceAccountKey.json
```

### Étape 3 : Créer les fichiers Java

Voir les fichiers d'exemple dans le dossier `backend/` :
- `FirebaseConfig.java` → `src/main/java/ma/siblhish/config/`
- `FcmNotificationService.java` → `src/main/java/ma/siblhish/service/`
- `RecurringTransactionService.java` → `src/main/java/ma/siblhish/service/`

### Étape 4 : Activer le scheduling

Dans votre classe principale (ex: `Application.java` ou `@SpringBootApplication`) :
```java
@SpringBootApplication
@EnableScheduling  // ← Ajouter cette annotation
public class Application {
    // ...
}
```

---

## 🧪 Tests à Effectuer

### Test 1 : Token FCM envoyé ✅

1. Connectez-vous à l'application
2. Vérifiez les logs : `✅ Token FCM envoyé au backend`
3. Vérifiez en base de données :
   ```sql
   SELECT id, email, fcm_token FROM users WHERE id = VOTRE_USER_ID;
   ```

### Test 2 : Notification manuelle ❌

1. Créez un endpoint de test dans le backend
2. Envoyez une notification de test
3. Vérifiez que la notification apparaît même si l'app est fermée

### Test 3 : Notification automatique ❌

1. Créez un revenu récurrent avec une date proche (aujourd'hui ou demain)
2. Attendez que le batch job s'exécute (toutes les heures à :00)
3. Vérifiez qu'un nouveau revenu est créé
4. Vérifiez qu'une notification est envoyée

---

## 📊 Résumé

### Frontend : ✅ PRÊT

Le frontend est **complètement configuré** et prêt à recevoir des notifications. Il ne reste qu'à tester.

### Backend : ❌ À COMPLÉTER

Le backend a l'API pour **recevoir** les tokens FCM, mais il manque :
- Le service pour **envoyer** les notifications
- La configuration Firebase Admin SDK
- Le service pour traiter les revenus récurrents

---

## 🎯 Prochaines Étapes

1. **Dans le backend** : Créer les fichiers Java nécessaires (voir fichiers d'exemple dans `backend/`)
2. **Dans le backend** : Ajouter la dépendance Firebase Admin SDK
3. **Dans le backend** : Télécharger `serviceAccountKey.json`
4. **Tester** : Envoyer une notification manuelle depuis le backend
5. **Tester** : Vérifier que les notifications fonctionnent en arrière-plan

Une fois ces étapes complétées, votre application sera prête pour les notifications push Firebase !

