# Comment consulter les notifications dans Firebase Console

## 📍 Où trouver les notifications dans Firebase Console

### 1. **Cloud Messaging > Analytics** (Recommandé)

**Chemin :**
```
Firebase Console → Votre projet (siblhish-app) → 
Engage → Cloud Messaging → Analytics
```

**Ce que vous verrez :**
- Nombre total de messages envoyés
- Taux de livraison
- Taux d'ouverture
- Statistiques par date
- Graphiques de performance

### 2. **Cloud Messaging > Messages** (Historique)

**Chemin :**
```
Firebase Console → Votre projet (siblhish-app) → 
Engage → Cloud Messaging → Messages
```

**Ce que vous verrez :**
- Historique des messages envoyés
- Messages de test
- Messages programmés
- Détails de chaque message (titre, corps, date d'envoi)

**Note :** Cette section affiche principalement les messages envoyés via la console Firebase, pas nécessairement tous les messages envoyés via l'API.

### 3. **Cloud Messaging > Reports** (Rapports détaillés)

**Chemin :**
```
Firebase Console → Votre projet (siblhish-app) → 
Engage → Cloud Messaging → Reports
```

**Ce que vous verrez :**
- Rapports détaillés par message
- Statistiques de livraison
- Erreurs de livraison
- Analyse par appareil (Android/iOS)

## 🔍 Comment voir les notifications envoyées depuis votre backend

### Option 1 : Via les logs backend (Recommandé)

Les logs de votre backend montrent chaque notification envoyée :

```
✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
```

Le `messageId` est l'ID unique retourné par Firebase.

### Option 2 : Via Firebase Console (Limité)

**Important :** Firebase Console ne montre pas automatiquement tous les messages envoyés via l'API. Pour voir les messages envoyés depuis votre backend :

1. **Allez dans Cloud Messaging > Analytics**
   - Vous verrez les statistiques globales
   - Nombre de messages envoyés
   - Taux de succès

2. **Utilisez Firebase Admin SDK Logs**
   - Les logs backend contiennent le `messageId` de chaque notification
   - Vous pouvez utiliser ce `messageId` pour rechercher dans Firebase Console

### Option 3 : Créer un endpoint de test

Vous pouvez créer un endpoint dans votre backend pour voir l'historique des notifications envoyées :

```java
@GetMapping("/notifications/sent")
public ResponseEntity<List<NotificationLog>> getSentNotifications() {
    // Retourner l'historique des notifications envoyées
    // (vous devrez stocker cela dans une table si vous voulez un historique complet)
}
```

## 📊 Statistiques disponibles dans Firebase Console

### Dans Cloud Messaging > Analytics :

1. **Messages envoyés**
   - Nombre total de messages
   - Messages par jour/semaine/mois

2. **Taux de livraison**
   - Messages livrés avec succès
   - Messages échoués
   - Messages en attente

3. **Engagement**
   - Taux d'ouverture
   - Clics sur les notifications
   - Actions effectuées

4. **Par plateforme**
   - Android vs iOS
   - Versions d'appareils
   - Versions d'OS

## 🧪 Tester et voir les notifications

### Test depuis Firebase Console :

1. **Allez dans Cloud Messaging > Send test message**
2. **Entrez le token FCM** de votre appareil
3. **Envoyez un message de test**
4. **Vérifiez dans Messages** que le message apparaît

### Test depuis votre backend :

1. **Créez un revenu récurrent**
2. **Vérifiez les logs backend** pour voir :
   ```
   ✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
   ```
3. **Vérifiez dans Cloud Messaging > Analytics** que le compteur de messages augmente

## ⚠️ Limitations

- **Firebase Console ne montre pas tous les messages API** : Seuls les messages envoyés via la console ou avec certaines configurations apparaissent dans l'historique
- **Les statistiques sont agrégées** : Vous verrez les totaux, pas nécessairement chaque message individuel
- **Délai d'affichage** : Les statistiques peuvent prendre quelques minutes à apparaître

## 💡 Recommandation

Pour un suivi complet des notifications envoyées depuis votre backend :

1. **Utilisez les logs backend** (le plus fiable)
2. **Consultez Cloud Messaging > Analytics** pour les statistiques globales
3. **Créez une table de logs** dans votre base de données si vous voulez un historique complet

## 🔗 Accès direct

URL directe vers Cloud Messaging Analytics :
```
https://console.firebase.google.com/project/siblhish-app/notification
```

Ou :
```
https://console.firebase.google.com/project/siblhish-app/notification/analytics
```

