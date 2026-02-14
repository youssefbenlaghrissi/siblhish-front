# Checklist : Vérification Notifications Firebase

## 📱 Frontend (Flutter) - Vérifications

### ✅ Configuration Firebase

- [x] **Firebase Core initialisé** (`lib/main.dart`)
  - ✅ `Firebase.initializeApp()` appelé
  - ✅ `firebase_options.dart` présent

- [x] **Packages Firebase installés** (`pubspec.yaml`)
  - ✅ `firebase_core: ^3.6.0`
  - ✅ `firebase_messaging: ^15.1.3`
  - ✅ `flutter_local_notifications: ^18.0.1`

- [x] **Handler background configuré** (`lib/firebase_messaging_handler.dart`)
  - ✅ `firebaseMessagingBackgroundHandler` défini
  - ✅ Affiche les notifications locales en arrière-plan

- [x] **Service de notifications** (`lib/services/push_notification_service.dart`)
  - ✅ Permissions demandées
  - ✅ Token FCM obtenu
  - ✅ Token envoyé au backend
  - ✅ Handlers configurés (foreground, background, opened)

- [x] **Permissions Android** (`android/app/src/main/AndroidManifest.xml`)
  - ✅ `POST_NOTIFICATIONS`
  - ✅ `VIBRATE`
  - ✅ `RECEIVE_BOOT_COMPLETED`

- [x] **Configuration Android** (`android/app/build.gradle.kts`)
  - ✅ Plugin Google Services activé
  - ✅ `google-services.json` présent

### ⚠️ Points à vérifier

- [ ] **Token FCM envoyé après connexion**
  - Vérifier que `PushNotificationService.setUserId()` est appelé après la connexion
  - Vérifier les logs : `✅ Token FCM envoyé au backend`

- [ ] **Permissions accordées**
  - Vérifier dans les paramètres Android que les notifications sont activées
  - Tester avec l'app fermée

## 🔧 Backend (Spring Boot) - Vérifications

### ✅ API FCM Token (Déjà implémenté)

- [x] **Endpoint pour recevoir les tokens** (`backend/UserFcmTokenController.java`)
  - ✅ `POST /api/v1/users/{userId}/fcm-token`
  - ✅ Token stocké en base de données

- [x] **Champ fcmToken dans User** (`backend/User_Entity_Field.java`)
  - ✅ Champ `fcm_token` dans la table `users`

### ❌ Service FCM (À créer)

- [ ] **Service FCM pour envoyer les notifications**
  - ❌ `FcmNotificationService.java` - À créer
  - ❌ Configuration Firebase Admin SDK - À créer

- [ ] **Configuration Firebase** (`FirebaseConfig.java`)
  - ❌ Fichier de credentials `serviceAccountKey.json` - À télécharger
  - ❌ Initialisation Firebase Admin SDK - À configurer

- [ ] **Dépendance Firebase Admin SDK**
  - ❌ Ajouter dans `pom.xml` ou `build.gradle`
  - ❌ Version : `firebase-admin:9.2.0`

### ❌ Service RecurringTransaction (À vérifier/créer)

- [ ] **Service pour traiter les revenus récurrents**
  - ❌ `RecurringTransactionService.java` - À vérifier/créer
  - ❌ `@Scheduled` pour exécuter toutes les heures
  - ❌ Création de nouveaux revenus
  - ❌ Envoi de notifications

- [ ] **@EnableScheduling activé**
  - ❌ Dans la classe de configuration principale

## 📋 Checklist complète

### Frontend

- [x] Firebase Core initialisé
- [x] Packages Firebase installés
- [x] Handler background configuré
- [x] Service de notifications implémenté
- [x] Permissions Android configurées
- [x] `google-services.json` présent
- [ ] Token FCM envoyé après connexion (vérifier les logs)
- [ ] Permissions accordées (tester)

### Backend

- [x] Endpoint pour recevoir les tokens FCM
- [x] Champ `fcm_token` dans la table `users`
- [ ] Dépendance Firebase Admin SDK ajoutée
- [ ] Fichier `serviceAccountKey.json` téléchargé
- [ ] `FirebaseConfig.java` créé
- [ ] `FcmNotificationService.java` créé
- [ ] `RecurringTransactionService.java` créé/vérifié
- [ ] `@EnableScheduling` activé
- [ ] Testé avec une notification manuelle

## 🧪 Tests à effectuer

### Test 1 : Token FCM envoyé

1. Connectez-vous à l'application
2. Vérifiez les logs : `✅ Token FCM envoyé au backend`
3. Vérifiez en base de données que le token est présent

### Test 2 : Notification manuelle

1. Créez un endpoint de test dans le backend
2. Envoyez une notification de test
3. Vérifiez que la notification apparaît même si l'app est fermée

### Test 3 : Notification automatique

1. Créez un revenu récurrent avec une date proche
2. Attendez que le batch job s'exécute
3. Vérifiez qu'un nouveau revenu est créé
4. Vérifiez qu'une notification est envoyée

## 🆘 Problèmes courants

### Frontend

1. **Token FCM non envoyé**
   - Vérifier que l'utilisateur est connecté
   - Vérifier que `setUserId()` est appelé

2. **Notifications ne fonctionnent pas en arrière-plan**
   - Vérifier les permissions Android
   - Vérifier que le handler background est configuré
   - Vérifier le format des notifications du backend

### Backend

1. **Firebase non initialisé**
   - Vérifier que `serviceAccountKey.json` est présent
   - Vérifier que la dépendance Firebase Admin SDK est ajoutée

2. **Notifications non envoyées**
   - Vérifier que le token FCM est présent en base de données
   - Vérifier les logs pour voir les erreurs
   - Tester avec une notification manuelle d'abord

3. **Batch job ne s'exécute pas**
   - Vérifier que `@EnableScheduling` est activé
   - Vérifier les logs pour voir si le service démarre

