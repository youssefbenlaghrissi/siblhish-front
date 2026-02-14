# Explication du système `notificationsEnabled`

## 🎯 Objectif

Le champ `notificationsEnabled` dans la table `users` contrôle si l'utilisateur **souhaite recevoir des notifications** ou non. C'est une préférence utilisateur sauvegardée dans votre base de données.

## 📊 Deux niveaux de contrôle

Il y a **DEUX** choses différentes à comprendre :

### 1. **Permissions système** (Android/iOS)
- Contrôlées par le **système d'exploitation**
- Sauvegardées dans les **paramètres du téléphone**
- L'utilisateur peut les activer/désactiver dans : **Paramètres → Applications → Siblhish → Notifications**
- L'application **ne peut pas modifier** ces permissions directement

### 2. **Préférence utilisateur** (`notificationsEnabled` dans la DB)
- Contrôlée par **votre application**
- Sauvegardée dans la **table `users`** de votre base de données
- L'utilisateur peut l'activer/désactiver depuis **l'interface de l'application** (écran de paramètres)
- Le backend vérifie ce champ **avant d'envoyer** des notifications

## 🔄 Flux complet (étape par étape)

### Scénario 1 : Premier lancement de l'app

```
1. L'utilisateur ouvre l'app pour la première fois
   ↓
2. L'app charge le profil utilisateur depuis l'API
   → notificationsEnabled = true (par défaut dans la DB)
   ↓
3. L'app appelle PushNotificationService.initialize(notificationsEnabled: true)
   ↓
4. L'app demande les permissions système à l'utilisateur
   → Popup système : "Autoriser Siblhish à envoyer des notifications ?"
   ↓
5a. Si l'utilisateur accepte :
    → Permissions système = AUTORISÉES
    → notificationsEnabled reste = true
    → Les notifications fonctionnent ✅

5b. Si l'utilisateur refuse :
    → Permissions système = REFUSÉES
    → notificationsEnabled est mis à false dans la DB
    → Les notifications ne fonctionnent pas ❌
```

### Scénario 2 : L'utilisateur désactive les notifications depuis l'app

```
1. L'utilisateur va dans Paramètres → Notifications
   ↓
2. L'utilisateur désactive le switch "Notifications"
   ↓
3. L'app appelle updateNotificationsEnabled(false)
   ↓
4. notificationsEnabled est mis à false dans la DB
   ↓
5. Le backend vérifie notificationsEnabled avant d'envoyer
   → Si false → Le backend N'ENVOIE PAS la notification ❌
```

### Scénario 3 : L'utilisateur réactive les notifications depuis l'app

```
1. L'utilisateur va dans Paramètres → Notifications
   ↓
2. L'utilisateur active le switch "Notifications"
   ↓
3. L'app appelle updateNotificationsEnabled(true)
   ↓
4. notificationsEnabled est mis à true dans la DB
   ↓
5. L'app vérifie les permissions système
   ↓
6a. Si les permissions système sont AUTORISÉES :
    → Les notifications fonctionnent immédiatement ✅

6b. Si les permissions système sont REFUSÉES :
    → L'app doit redemander les permissions système
    → Si acceptées → Les notifications fonctionnent ✅
    → Si refusées → notificationsEnabled reste true mais notifications ne fonctionnent pas ❌
```

### Scénario 4 : L'utilisateur désactive les notifications depuis les paramètres système

```
1. L'utilisateur va dans Paramètres Android/iOS → Applications → Siblhish → Notifications
   ↓
2. L'utilisateur désactive les notifications système
   ↓
3. L'app détecte le changement (au prochain lancement)
   ↓
4. L'app met notificationsEnabled à false dans la DB
   ↓
5. Le backend ne peut plus envoyer de notifications ❌
```

## 💡 Pourquoi cette logique ?

### `notificationsEnabled = false` → Pas d'initialisation

**Raison :** Si l'utilisateur a explicitement désactivé les notifications depuis l'app, on ne doit **pas** lui redemander les permissions système. C'est sa préférence.

```dart
if (notificationsEnabledFromDB == false) {
  // L'utilisateur a désactivé les notifications depuis l'app
  // On ne demande PAS les permissions système
  return; // Arrêt ici
}
```

### `notificationsEnabled = true` → Demander les permissions

**Raison :** Si l'utilisateur a activé les notifications depuis l'app, on doit vérifier que les permissions système sont accordées pour que ça fonctionne.

```dart
if (notificationsEnabledFromDB == true) {
  // L'utilisateur veut recevoir des notifications
  // On demande les permissions système si pas encore demandées
  await _firebaseMessaging.requestPermission(...);
}
```

## 🔍 Vérification côté backend

Le backend vérifie **TOUJOURS** `notificationsEnabled` avant d'envoyer :

```java
// Dans FcmNotificationService.java
if (Boolean.FALSE.equals(user.getNotificationsEnabled())) {
    log.info("⚠️ Utilisateur {} a désactivé les notifications, notification ignorée", user.getId());
    return false; // ❌ N'envoie PAS la notification
}
```

## 📝 Résumé visuel

```
┌─────────────────────────────────────────────────────────┐
│  notificationsEnabled (DB) = true                      │
│  Permissions système = AUTORISÉES                       │
│  → ✅ Les notifications FONCTIONNENT                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  notificationsEnabled (DB) = true                      │
│  Permissions système = REFUSÉES                         │
│  → ❌ Les notifications NE FONCTIONNENT PAS             │
│  → (L'app mettra notificationsEnabled à false)         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  notificationsEnabled (DB) = false                     │
│  Permissions système = N'IMPORTE QUOI                  │
│  → ❌ Les notifications NE FONCTIONNENT PAS             │
│  → (Le backend ne vérifie même pas les permissions)    │
└─────────────────────────────────────────────────────────┘
```

## 🎯 En pratique

1. **L'utilisateur contrôle** `notificationsEnabled` depuis l'app (écran paramètres)
2. **Le système contrôle** les permissions système (paramètres Android/iOS)
3. **Les deux doivent être activés** pour que les notifications fonctionnent
4. **Le backend vérifie** `notificationsEnabled` avant d'envoyer (sécurité)

