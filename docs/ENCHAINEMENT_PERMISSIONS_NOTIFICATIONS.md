# Enchaînement de la demande de permissions de notifications

## 🔄 Flux complet

### 1. **Au démarrage de l'application** (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(...);
  
  // Initialiser le service de notifications push
  await PushNotificationService.initialize(); // ← ICI
}
```

### 2. **Dans `PushNotificationService.initialize()`**

```dart
static Future<void> initialize() async {
  // 1. Vérifier d'abord le statut actuel des permissions
  NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();
  
  // 2. Si les permissions ne sont pas encore demandées
  if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
    // ← DEMANDE DE PERMISSIONS ICI (une seule fois)
    settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  } else {
    // Les permissions ont déjà été demandées, utiliser le statut actuel
    settings = currentSettings;
  }
  
  // 3. Continuer l'initialisation...
}
```

## ⏰ Quand la permission est demandée ?

### ✅ **Une seule fois** au premier démarrage

1. **Premier lancement de l'app** :
   - `authorizationStatus == AuthorizationStatus.notDetermined`
   - → **Popup de permission s'affiche** (une seule fois)
   - L'utilisateur choisit : Accepter / Refuser

2. **Lancements suivants** :
   - `authorizationStatus` est déjà défini (authorized, denied, ou provisional)
   - → **Pas de popup**, on utilise le statut existant

## 📋 États possibles des permissions

### `AuthorizationStatus.notDetermined`
- **Premier lancement** : Permission jamais demandée
- **Action** : Popup s'affiche

### `AuthorizationStatus.authorized`
- **Utilisateur a accepté** : Notifications activées
- **Action** : Pas de popup, notifications fonctionnent

### `AuthorizationStatus.denied`
- **Utilisateur a refusé** : Notifications désactivées
- **Action** : Pas de popup, notifications ne fonctionnent pas
- **Note** : L'utilisateur peut réactiver dans les paramètres Android

### `AuthorizationStatus.provisional` (iOS uniquement)
- **Notifications silencieuses** : Reçues mais pas affichées automatiquement
- **Action** : Pas de popup

## 🔍 Ordre d'exécution détaillé

```
1. Application démarre
   ↓
2. main() est appelé
   ↓
3. Firebase.initializeApp() ← Initialise Firebase
   ↓
4. PushNotificationService.initialize() ← Appelé
   ↓
5. Vérification du statut actuel :
   getNotificationSettings()
   ↓
6. Si notDetermined (première fois) :
   → Popup de permission s'affiche
   → Utilisateur choisit
   ↓
7. Si déjà déterminé (lancements suivants) :
   → Pas de popup
   → Utilise le statut existant
   ↓
8. Initialisation continue :
   - Initialiser les notifications locales
   - Obtenir le token FCM
   - Configurer les handlers
```

## 🎯 Comportement selon le scénario

### Scénario 1 : Premier lancement (jamais ouvert l'app)
```
1. App démarre
2. Firebase initialisé
3. PushNotificationService.initialize() appelé
4. Statut = notDetermined
5. → POPUP S'AFFICHE (une seule fois)
6. Utilisateur accepte/refuse
7. Statut sauvegardé par le système
```

### Scénario 2 : Lancements suivants (déjà ouvert l'app)
```
1. App démarre
2. Firebase initialisé
3. PushNotificationService.initialize() appelé
4. Statut = authorized/denied (déjà défini)
5. → PAS DE POPUP
6. Utilise le statut existant
```

### Scénario 3 : Utilisateur a désactivé dans les paramètres
```
1. App démarre
2. Firebase initialisé
3. PushNotificationService.initialize() appelé
4. Statut = denied
5. → PAS DE POPUP
6. Notifications ne fonctionnent pas
7. L'utilisateur doit réactiver dans Paramètres Android
```

## 📱 Où l'utilisateur peut modifier les permissions ?

### Android :
1. **Paramètres** → **Applications** → **Siblhish** → **Notifications**
2. Activer/Désactiver les notifications
3. Modifier les canaux de notifications

### iOS :
1. **Paramètres** → **Notifications** → **Siblhish**
2. Activer/Désactiver les notifications
3. Modifier les types de notifications

## ⚠️ Points importants

1. **Une seule demande** : La popup n'apparaît qu'une seule fois au premier lancement
2. **Sauvegarde système** : Le choix de l'utilisateur est sauvegardé par Android/iOS
3. **Pas de re-demande automatique** : Si l'utilisateur refuse, il doit réactiver manuellement dans les paramètres
4. **Vérification à chaque démarrage** : Le code vérifie le statut, mais ne redemande pas si déjà déterminé

## 🔧 Code actuel

Le code vérifie d'abord le statut avant de demander :

```dart
// Vérifier d'abord le statut actuel
NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();

// Si les permissions ne sont pas encore demandées
if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
  // Demander les permissions (une seule fois)
  settings = await _firebaseMessaging.requestPermission(...);
} else {
  // Utiliser le statut existant (pas de popup)
  settings = currentSettings;
}
```

## 💡 Résumé

- **Premier lancement** : Popup s'affiche (une seule fois)
- **Lancements suivants** : Pas de popup, utilise le statut existant
- **Si refusé** : L'utilisateur doit réactiver dans les paramètres système
- **Vérification** : Le code vérifie le statut à chaque démarrage, mais ne redemande pas

