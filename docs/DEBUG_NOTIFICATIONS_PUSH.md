# Debug : Notifications Push Non Reçues

## 🔍 Problème

Le backend insère le revenu et la notification en base de données, mais aucune notification push n'est reçue côté frontend.

## ✅ Vérifications à faire

### 1. Vérifier que le token FCM est enregistré

**Dans les logs backend**, cherchez :
- `⚠️ Utilisateur X n'a pas de token FCM, notification ignorée` → Le token n'est pas enregistré
- `📬 Token FCM de l'utilisateur: NULL ou VIDE` → Le token n'est pas enregistré

**Solution :**
1. Vérifiez que le frontend envoie bien le token FCM après la connexion
2. Vérifiez les logs frontend : `✅ Token FCM envoyé au backend`
3. Vérifiez que l'endpoint `POST /users/{userId}/fcm-token` fonctionne

### 2. Vérifier que Firebase est initialisé

**Dans les logs backend au démarrage**, cherchez :
- `✅ Firebase initialisé depuis classpath: firebase/siblhish-app-firebase-adminsdk-fbsvc-05ce4c5f95.json`
- `✅ Firebase Messaging initialisé avec succès`

Si ces logs n'apparaissent pas :
- Vérifiez que le fichier `src/main/resources/firebase/siblhish-app-firebase-adminsdk-fbsvc-05ce4c5f95.json` existe
- Vérifiez la configuration dans `application.properties`

### 3. Vérifier les logs lors de l'envoi

**Quand un revenu récurrent est créé**, vous devriez voir dans les logs backend :
```
📬 Création de notification pour l'utilisateur X - Titre: ..., Description: ...
📬 Token FCM de l'utilisateur: abc123...
📤 Tentative d'envoi de notification push à l'utilisateur X avec le token: abc123...
✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
✅ Notification push envoyée avec succès pour l'utilisateur X
```

**Si vous voyez :**
- `⚠️ Utilisateur X n'a pas de token FCM` → Le token n'est pas enregistré
- `❌ Erreur FCM lors de l'envoi` → Problème avec Firebase (token invalide, credentials, etc.)

### 4. Vérifier côté frontend

**Dans les logs Flutter**, cherchez :
- `📱 Token FCM obtenu: ...`
- `✅ Token FCM envoyé au backend`
- `📬 Notification reçue au premier plan: ...` (si l'app est ouverte)
- `📬 Notification reçue en arrière-plan: ...` (si l'app est fermée)

**Si vous ne voyez pas ces logs :**
- Vérifiez que Firebase est initialisé dans `main.dart`
- Vérifiez que les permissions de notifications sont accordées
- Vérifiez que `PushNotificationService.setUserId()` est appelé après la connexion

## 🛠️ Actions de debug

### 1. Vérifier le token FCM en base de données

Exécutez cette requête SQL :
```sql
SELECT id, email, fcm_token, notifications_enabled 
FROM users 
WHERE id = VOTRE_USER_ID;
```

**Résultats possibles :**
- `fcm_token` est `NULL` → Le token n'a pas été enregistré
- `fcm_token` a une valeur → Le token est enregistré, vérifiez les autres points
- `notifications_enabled` est `false` → Les notifications sont désactivées pour cet utilisateur

### 2. Tester manuellement l'envoi

Créez un endpoint de test dans votre backend :

```java
@PostMapping("/test-notification/{userId}")
public ResponseEntity<String> testNotification(@PathVariable Long userId) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new RuntimeException("User not found"));
    
    boolean sent = fcmNotificationService.sendNotification(
        user, 
        "Test Notification", 
        "Ceci est un test de notification push"
    );
    
    return ResponseEntity.ok(sent ? "Notification envoyée" : "Échec de l'envoi");
}
```

### 3. Vérifier les permissions Android

Sur votre téléphone Android :
1. Paramètres → Applications → Siblhish → Notifications
2. Vérifiez que les notifications sont activées
3. Vérifiez que le canal "Siblhish Notifications" est activé

## 📋 Checklist de debug

- [ ] Le token FCM est enregistré en base de données (vérifier avec SQL)
- [ ] Firebase est initialisé au démarrage du backend (vérifier les logs)
- [ ] Les logs montrent que la notification est envoyée (vérifier les logs backend)
- [ ] Le frontend a reçu le token FCM (vérifier les logs Flutter)
- [ ] Les permissions de notifications sont accordées (vérifier les paramètres Android)
- [ ] L'app a envoyé le token au backend après la connexion (vérifier les logs Flutter)

## 🎯 Prochaines étapes

1. **Vérifiez les logs backend** après avoir créé un revenu récurrent
2. **Vérifiez le token FCM en base de données** avec la requête SQL
3. **Vérifiez les logs frontend** pour voir si le token est envoyé
4. **Partagez les logs** pour que je puisse identifier le problème exact

