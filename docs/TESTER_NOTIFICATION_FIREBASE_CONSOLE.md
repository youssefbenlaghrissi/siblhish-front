# Comment tester les notifications via Firebase Console

## 🎯 Objectif

Envoyer un message de test depuis Firebase Console pour vérifier que :
1. Les notifications fonctionnent
2. Les rapports s'affichent dans Firebase Console
3. Vous recevez la notification sur votre appareil

## 📱 Étape 1 : Obtenir votre token FCM

### Depuis l'application Flutter :

1. **Ouvrez l'application** sur votre téléphone
2. **Vérifiez les logs Flutter** (dans Android Studio ou VS Code)
3. **Cherchez cette ligne** :
   ```
   📱 Token FCM obtenu: abc123def456...
   ```
4. **Copiez le token complet** (il fait environ 150-200 caractères)

### Alternative : Depuis la base de données

Si vous avez déjà connecté l'app, le token est stocké en base :

```sql
SELECT id, email, fcm_token 
FROM users 
WHERE id = VOTRE_USER_ID;
```

Copiez le `fcm_token` de la base de données.

## 🔧 Étape 2 : Envoyer un message de test depuis Firebase Console

### Option A : Via "Send test message"

1. **Dans Firebase Console**, allez dans **Messaging**
2. **Cliquez sur l'onglet "Campagnes"** (ou cherchez "Send test message")
3. **Cliquez sur "Créer ma première campagne"** ou **"Send test message"**
4. **Remplissez le formulaire** :
   - **Notification title** : "Test depuis Firebase Console"
   - **Notification text** : "Ceci est un test de notification"
   - **FCM registration token** : Collez votre token FCM (obtenu à l'étape 1)
5. **Cliquez sur "Test"** ou **"Envoyer"**

### Option B : Via l'URL directe

Accédez directement à :
```
https://console.firebase.google.com/project/siblhish-app/notification/compose
```

Puis suivez les étapes ci-dessus.

## 📊 Étape 3 : Vérifier les résultats

### Dans Firebase Console :

1. **Allez dans Messaging → Rapports**
2. **Attendez quelques minutes** (les données peuvent prendre du temps à apparaître)
3. **Vous devriez voir** :
   - Nombre d'envois : 1
   - Reçus : 1 (si la notification a été reçue)
   - Impressions : 1 (si la notification a été vue)

### Sur votre appareil :

1. **Si l'app est ouverte** : Vous devriez voir une notification locale
2. **Si l'app est fermée** : Vous devriez recevoir une notification push

## 🧪 Test complet : Vérifier le flux complet

### Test 1 : Message depuis Firebase Console

1. Envoyez un message de test depuis Firebase Console
2. Vérifiez que vous le recevez sur votre téléphone
3. Vérifiez dans Firebase Console → Rapports que les données apparaissent

### Test 2 : Message depuis votre backend

1. Créez un revenu récurrent
2. Vérifiez les logs backend pour voir :
   ```
   ✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
   ```
3. Vérifiez que vous recevez la notification sur votre téléphone
4. **Note** : Ce message peut ne pas apparaître dans Firebase Console (c'est normal)

## ⚠️ Différences importantes

### Messages depuis Firebase Console :
- ✅ Apparaissent dans Firebase Console → Rapports
- ✅ Statistiques détaillées disponibles
- ✅ Utile pour les tests et campagnes

### Messages depuis votre backend (API) :
- ❌ N'apparaissent **PAS** toujours dans Firebase Console → Rapports
- ✅ Fonctionnent parfaitement (vérifiez via les logs backend)
- ✅ Utile pour les notifications automatiques (revenus récurrents, etc.)

## 💡 Recommandation

**Pour tester que tout fonctionne :**

1. **Testez d'abord depuis Firebase Console** pour vérifier que :
   - Votre token FCM est valide
   - Les notifications arrivent sur votre appareil
   - Les rapports s'affichent dans Firebase Console

2. **Testez ensuite depuis votre backend** pour vérifier que :
   - Les notifications automatiques fonctionnent
   - Les logs backend montrent les succès
   - Vous recevez les notifications sur votre appareil

## 🔍 Si le message de test ne fonctionne pas

### Vérifications :

1. **Token FCM valide** : Vérifiez que le token n'est pas expiré
2. **Permissions** : Vérifiez que les notifications sont activées sur votre téléphone
3. **App installée** : L'app doit être installée sur l'appareil avec le token
4. **Connexion Internet** : L'appareil doit être connecté à Internet

### Obtenir un nouveau token :

Si le token ne fonctionne pas, reconnectez-vous à l'app pour obtenir un nouveau token FCM.

