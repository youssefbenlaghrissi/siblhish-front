# 🔔 Workflow Complet des Notifications

## 📋 Vue d'ensemble

Ce document décrit le flux complet des notifications push dans l'application Siblhish, depuis l'installation jusqu'à la réception des notifications.

---

## 🚀 Phase 1 : Installation et Premier Login

### 1.1 Installation de l'application

```
1. L'utilisateur installe l'application
   ↓
2. L'app démarre → SplashScreen
   ↓
3. L'app vérifie si l'utilisateur est connecté
   → Non connecté → Redirige vers LoginScreen
```

### 1.2 Premier Login (Google Sign-In)

```
1. L'utilisateur clique sur "Continuer avec Google"
   ↓
2. Authentification Google SDK
   → Popup Google pour sélectionner le compte
   ↓
3. Après authentification Google réussie
   ↓
4. 📱 DEMANDE DES PERMISSIONS SYSTÈME (première fois)
   → Popup système : "Autoriser Siblhish à envoyer des notifications ?"
   ↓
5a. Si l'utilisateur ACCEPTE :
    → notificationsEnabled = true
    → Permissions système = AUTORISÉES
    
5b. Si l'utilisateur REFUSE :
    → notificationsEnabled = false
    → Permissions système = REFUSÉES
   ↓
6. Envoi au backend : POST /auth/social
   Body: {
     "provider": "google",
     "email": "user@example.com",
     "displayName": "John Doe",
     "photoUrl": "https://...",
     "notificationsEnabled": true/false  ← Selon la réponse de l'utilisateur
   }
   ↓
7. Backend traite la requête :
   → Vérifie si l'utilisateur existe (par email)
   → Si NOUVEL utilisateur :
     * Crée l'utilisateur dans la DB
     * Utilise notificationsEnabled envoyé
     * notificationsEnabled sauvegardé dans la table users
   → Si utilisateur EXISTANT :
     * Récupère l'utilisateur existant
     * GARDE son notificationsEnabled existant (ignore celui envoyé)
   ↓
8. Backend retourne UserProfileDto avec notificationsEnabled réel
   Response: {
     "status": "success",
     "data": {
       "id": 1,
       "firstName": "John",
       "lastName": "Doe",
       "email": "user@example.com",
       "notificationsEnabled": true/false  ← Statut réel depuis la DB
     }
   }
   ↓
9. Frontend sauvegarde les données utilisateur localement
   ↓
10. Frontend appelle BudgetProvider.initialize(userId)
    ↓
11. BudgetProvider charge le profil utilisateur
    → Récupère notificationsEnabled depuis la DB
    ↓
12. PushNotificationService.initialize()
    → Vérifie notificationsEnabled depuis la DB
    → Si false → Arrêt (pas d'initialisation)
    → Si true → Continue l'initialisation
    ↓
13. Initialisation des notifications :
    → Initialise flutter_local_notifications
    → Obtient le token FCM
    → Envoie le token au backend : POST /users/{userId}/fcm-token
    → Configure les handlers pour les notifications
    ↓
14. ✅ Notifications prêtes à fonctionner
```

---

## 🔄 Phase 2 : Utilisateur Existant (Déconnexion puis Reconnexion)

### 2.1 Déconnexion

```
1. L'utilisateur se déconnecte
   ↓
2. AuthService.logout()
   → Déconnexion Google SDK
   → Suppression de la session locale
   → BudgetProvider.clearAllData()
```

### 2.2 Reconnexion

```
1. L'utilisateur clique sur "Continuer avec Google"
   ↓
2. Authentification Google SDK
   ↓
3. 📱 Vérification des permissions système
   → Les permissions ont déjà été demandées
   → Utilise le statut actuel (AUTORISÉES ou REFUSÉES)
   → Ne redemande PAS les permissions
   ↓
4. Envoi au backend : POST /auth/social
   Body: {
     "provider": "google",
     "email": "user@example.com",
     "displayName": "John Doe",
     "notificationsEnabled": true/false  ← Selon le statut système actuel
   }
   ↓
5. Backend traite la requête :
   → Utilisateur EXISTANT trouvé (par email)
   → GARDE son notificationsEnabled existant dans la DB
   → Ignore notificationsEnabled envoyé
   ↓
6. Backend retourne UserProfileDto avec notificationsEnabled réel
   Response: {
     "data": {
       "notificationsEnabled": true/false  ← Statut réel depuis la DB
     }
   }
   ↓
7. Frontend appelle BudgetProvider.initialize(userId)
   ↓
8. BudgetProvider charge le profil utilisateur
   → Récupère notificationsEnabled depuis la DB
   ↓
9. PushNotificationService.initialize()
   → Vérifie notificationsEnabled depuis la DB
   → Si false → Arrêt (pas d'initialisation)
   → Si true → Continue l'initialisation
   ↓
10. ✅ Notifications initialisées selon le statut de la DB
```

---

## ⚙️ Phase 3 : Changement de Statut depuis l'Application

### 3.1 L'utilisateur désactive les notifications

```
1. L'utilisateur va dans Paramètres → Notifications
   ↓
2. L'utilisateur désactive le switch "Notifications"
   ↓
3. Frontend appelle : BudgetProvider.updateNotificationsEnabled(false)
   ↓
4. Frontend envoie au backend : PUT /users/{userId}/profile
   Body: {
     "notificationsEnabled": false
   }
   ↓
5. Backend met à jour notificationsEnabled = false dans la DB
   ↓
6. Frontend met à jour _currentUser.notificationsEnabled = false
   ↓
7. ❌ Les notifications sont désactivées
   → Le backend vérifie notificationsEnabled avant d'envoyer
   → Si false → N'envoie PAS la notification
```

### 3.2 L'utilisateur réactive les notifications

```
1. L'utilisateur va dans Paramètres → Notifications
   ↓
2. L'utilisateur active le switch "Notifications"
   ↓
3. Frontend appelle : BudgetProvider.updateNotificationsEnabled(true)
   ↓
4. Frontend envoie au backend : PUT /users/{userId}/profile
   Body: {
     "notificationsEnabled": true
   }
   ↓
5. Backend met à jour notificationsEnabled = true dans la DB
   ↓
6. Frontend met à jour _currentUser.notificationsEnabled = true
   ↓
7. Frontend vérifie les permissions système
   → Si AUTORISÉES → ✅ Notifications fonctionnent immédiatement
   → Si REFUSÉES → L'app doit redemander les permissions
   ↓
8. ✅ Les notifications sont réactivées
```

---

## 📬 Phase 4 : Envoi de Notifications

### 4.1 Création d'une notification dans la DB

```
1. Un événement se produit (ex: paiement planifié, revenu récurrent)
   ↓
2. Backend crée une entrée dans la table notifications
   → INSERT INTO notifications (title, description, user_id, ...)
   ↓
3. NotificationService.createNotification()
   → Récupère l'utilisateur depuis la DB
   → Vérifie notificationsEnabled
   ↓
4. Si notificationsEnabled = false :
   → ❌ Arrêt (notification non envoyée)
   → Log : "Utilisateur a désactivé les notifications"
   ↓
5. Si notificationsEnabled = true :
   → Continue le processus
   ↓
6. Vérifie que l'utilisateur a un fcmToken
   → Si pas de token → ❌ Arrêt
   → Si token présent → Continue
   ↓
7. FcmNotificationService.sendNotification()
   → Utilise Firebase Admin SDK
   → Envoie la notification via FCM
   ↓
8. ✅ Notification envoyée avec succès
```

### 4.2 Réception de la notification

#### Scénario A : App ouverte (premier plan)

```
1. Firebase reçoit la notification
   ↓
2. FirebaseMessaging.onMessage.listen() déclenché
   ↓
3. PushNotificationService._showLocalNotification()
   → Affiche une notification locale
   → L'utilisateur voit la notification dans l'app
   ↓
4. ✅ Notification affichée
```

#### Scénario B : App en arrière-plan

```
1. Firebase reçoit la notification
   ↓
2. Si le message contient un payload "notification" :
   → Firebase affiche automatiquement la notification
   → ✅ Notification affichée par le système
   ↓
3. Si le message contient uniquement des "data" :
   → firebaseMessagingBackgroundHandler() déclenché
   → Affiche une notification locale
   → ✅ Notification affichée
```

#### Scénario C : App fermée

```
1. Firebase reçoit la notification
   ↓
2. Si le message contient un payload "notification" :
   → Firebase affiche automatiquement la notification
   → ✅ Notification affichée par le système
   ↓
3. Si le message contient uniquement des "data" :
   → firebaseMessagingBackgroundHandler() déclenché
   → Affiche une notification locale
   → ✅ Notification affichée
   ↓
4. Si l'utilisateur clique sur la notification :
   → L'app s'ouvre
   → FirebaseMessaging.getInitialMessage() récupère le message
   → Navigation vers l'écran approprié
```

---

## 🔍 Points de Vérification

### Backend

1. **Avant d'envoyer une notification** :
   ```java
   if (Boolean.FALSE.equals(user.getNotificationsEnabled())) {
       log.info("⚠️ Utilisateur {} a désactivé les notifications", user.getId());
       return false; // ❌ N'envoie PAS
   }
   ```

2. **Vérification du token FCM** :
   ```java
   if (user.getFcmToken() == null || user.getFcmToken().trim().isEmpty()) {
       log.warn("⚠️ Utilisateur {} n'a pas de token FCM", user.getId());
       return false; // ❌ N'envoie PAS
   }
   ```

### Frontend

1. **Initialisation** :
   ```dart
   if (notificationsEnabledFromDB == false) {
     return; // ❌ Pas d'initialisation
   }
   ```

2. **Utilisateur existant** :
   ```dart
   // Utilise notificationsEnabled depuis la DB
   // Ne redemande PAS les permissions système
   ```

---

## 📊 Tableau Récapitulatif

| Situation | Permissions Système | notificationsEnabled (DB) | Résultat |
|-----------|---------------------|---------------------------|----------|
| **Nouvel utilisateur accepte** | ✅ AUTORISÉES | `true` | ✅ Notifications fonctionnent |
| **Nouvel utilisateur refuse** | ❌ REFUSÉES | `false` | ❌ Pas de notifications |
| **Utilisateur existant (true)** | ✅ AUTORISÉES | `true` | ✅ Notifications fonctionnent |
| **Utilisateur existant (false)** | ❌ REFUSÉES | `false` | ❌ Pas de notifications |
| **Désactivation depuis l'app** | N'importe | `false` | ❌ Pas de notifications |
| **Réactivation depuis l'app** | ✅ AUTORISÉES | `true` | ✅ Notifications fonctionnent |
| **Réactivation depuis l'app** | ❌ REFUSÉES | `true` | ⚠️ DB = true mais permissions refusées |

---

## 🔄 Flux de Données

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Login → Demande permissions système                    │
│  2. Envoie notificationsEnabled au backend                │
│  3. Reçoit notificationsEnabled depuis la DB              │
│  4. Initialise PushNotificationService                     │
│  5. Obtient token FCM → Envoie au backend                 │
│  6. Reçoit les notifications push                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Reçoit notificationsEnabled au login                   │
│  2. Si nouvel utilisateur → Utilise notificationsEnabled  │
│  3. Si utilisateur existant → Garde son statut existant   │
│  4. Retourne notificationsEnabled réel                     │
│  5. Sauvegarde token FCM                                   │
│  6. Avant d'envoyer → Vérifie notificationsEnabled        │
│  7. Envoie notification via FCM                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│                    BASE DE DONNÉES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Table: users                                              │
│  - notifications_enabled (BOOLEAN, default: true)          │
│  - fcm_token (VARCHAR(500))                                │
│                                                             │
│  Table: notifications                                      │
│  - id, title, description, user_id, ...                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Résumé en 3 Points

1. **Au login** : Demande des permissions système → Envoie `notificationsEnabled` au backend
2. **Backend** : Si utilisateur existant → Garde son statut, sinon utilise celui envoyé
3. **Envoi** : Backend vérifie toujours `notificationsEnabled` avant d'envoyer

