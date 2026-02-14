# Où le statut des permissions de notifications est sauvegardé ?

## 📍 Réponse courte

Le statut des permissions de notifications est **sauvegardé par le système d'exploitation** (Android/iOS), **pas par votre application**.

## 🔍 Détails par plateforme

### Android

**Emplacement :**
- Sauvegardé dans les **paramètres système Android**
- Fichier système : `/data/system/users/0/package-restrictions.xml` (non accessible directement)
- Géré par le **PackageManager** d'Android

**Comment y accéder :**
1. **Paramètres Android** → **Applications** → **Siblhish** → **Notifications**
2. Le statut est visible et modifiable ici
3. L'application peut **lire** le statut via `getNotificationSettings()`
4. L'application **ne peut pas modifier** le statut directement (seul l'utilisateur peut)

**Persistance :**
- Sauvegardé **permanemment** jusqu'à ce que l'utilisateur change
- **Persiste** même après :
  - Désinstallation/réinstallation de l'app
  - Mise à jour de l'app
  - Redémarrage du téléphone

### iOS

**Emplacement :**
- Sauvegardé dans les **paramètres système iOS**
- Géré par le **UserNotifications framework** d'iOS

**Comment y accéder :**
1. **Paramètres iOS** → **Notifications** → **Siblhish**
2. Le statut est visible et modifiable ici
3. L'application peut **lire** le statut via `getNotificationSettings()`
4. L'application **ne peut pas modifier** le statut directement (seul l'utilisateur peut)

**Persistance :**
- Sauvegardé **permanemment** jusqu'à ce que l'utilisateur change
- **Persiste** même après :
  - Désinstallation/réinstallation de l'app
  - Mise à jour de l'app
  - Redémarrage du téléphone

## 🔄 Comment l'application accède au statut ?

### Code actuel

```dart
// Lire le statut (sauvegardé par le système)
NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();

// Le statut peut être :
// - AuthorizationStatus.notDetermined (jamais demandé)
// - AuthorizationStatus.authorized (accepté)
// - AuthorizationStatus.denied (refusé)
// - AuthorizationStatus.provisional (iOS - notifications silencieuses)
```

### Ce que fait `getNotificationSettings()`

1. **Interroge le système** (Android/iOS)
2. **Lit le statut** sauvegardé par le système
3. **Retourne** le statut actuel
4. **Ne modifie pas** le statut (lecture seule)

## 📊 Flux de sauvegarde

### Premier lancement

```
1. Application démarre
   ↓
2. getNotificationSettings() → Retourne "notDetermined"
   ↓
3. requestPermission() → Popup s'affiche
   ↓
4. Utilisateur choisit (Accepter/Refuser)
   ↓
5. Système Android/iOS SAUVEGARDE le choix
   ↓
6. Statut sauvegardé dans les paramètres système
```

### Lancements suivants

```
1. Application démarre
   ↓
2. getNotificationSettings() → Lit le statut depuis le système
   ↓
3. Retourne le statut sauvegardé (authorized/denied)
   ↓
4. Pas de popup (statut déjà déterminé)
```

## 🔐 Sécurité

### Pourquoi le système sauvegarde ?

1. **Sécurité** : Empêche les applications de modifier les permissions sans consentement
2. **Expérience utilisateur** : L'utilisateur n'est pas harcelé par des popups répétées
3. **Contrôle** : L'utilisateur garde le contrôle via les paramètres système

### L'application ne peut pas :

- ❌ Modifier le statut directement
- ❌ Forcer une nouvelle demande si déjà refusé
- ❌ Contourner le refus de l'utilisateur

### L'application peut :

- ✅ Lire le statut actuel
- ✅ Demander la permission (une seule fois si notDetermined)
- ✅ Vérifier si les notifications sont activées

## 🔍 Vérifier le statut manuellement

### Android

1. **Paramètres** → **Applications** → **Siblhish** → **Notifications**
2. Voir le statut actuel (Activé/Désactivé)
3. Modifier si nécessaire

### iOS

1. **Paramètres** → **Notifications** → **Siblhish**
2. Voir le statut actuel
3. Modifier si nécessaire

## 💾 Persistance

### Le statut persiste même si :

- ✅ L'application est désinstallée puis réinstallée
- ✅ L'application est mise à jour
- ✅ Le téléphone est redémarré
- ✅ L'application est mise à jour via Play Store/App Store

### Le statut est réinitialisé si :

- ⚠️ L'utilisateur **réinitialise les paramètres** du téléphone
- ⚠️ L'utilisateur **désinstalle complètement** l'app ET **efface les données** (Android)
- ⚠️ L'utilisateur **change manuellement** dans les paramètres

## 📝 Résumé

| Question | Réponse |
|----------|---------|
| **Où est sauvegardé ?** | Dans les paramètres système Android/iOS |
| **Qui sauvegarde ?** | Le système d'exploitation (pas l'application) |
| **L'application peut modifier ?** | Non, seulement lire |
| **Qui peut modifier ?** | L'utilisateur via les paramètres système |
| **Persiste après désinstallation ?** | Oui (sur Android, peut persister) |
| **Persiste après mise à jour ?** | Oui |

## 🎯 Conclusion

Le statut des permissions de notifications est **géré et sauvegardé par le système d'exploitation**, pas par votre application. Votre application peut seulement :

1. **Lire** le statut via `getNotificationSettings()`
2. **Demander** la permission (une seule fois si `notDetermined`)
3. **Vérifier** si les notifications sont activées

Le système garantit que l'utilisateur garde le contrôle total sur les permissions.

