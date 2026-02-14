# Comment accéder aux Analytics et Messages dans Firebase Console

## 📍 Où trouver les Analytics et l'historique des messages

### ❌ Ce que vous voyez actuellement :
Vous êtes dans : **Paramètres du projet → Cloud Messaging**
- C'est la page de **configuration**
- Vous voyez les paramètres API, Sender ID, etc.
- Ce n'est **PAS** là où vous voyez les notifications envoyées

### ✅ Où aller pour voir les notifications :

## Option 1 : Via le menu latéral (Recommandé)

1. **Dans le menu latéral gauche**, cherchez la section **"Engage"** (Engagement)
2. **Cliquez sur "Cloud Messaging"** (pas dans Paramètres)
3. Vous verrez alors :
   - **Analytics** : Statistiques des notifications
   - **Messages** : Historique des messages
   - **Send test message** : Envoyer un message de test

## Option 2 : Navigation directe

**Chemin complet :**
```
Firebase Console → siblhish-app → 
Menu latéral gauche → Engage → Cloud Messaging
```

**OU**

```
Firebase Console → siblhish-app → 
Menu latéral gauche → Cloud Messaging (directement sous "Engage")
```

## 📊 Ce que vous verrez dans "Engage > Cloud Messaging"

### 1. **Analytics** (Onglet)
- Nombre total de messages envoyés
- Taux de livraison
- Graphiques de performance
- Statistiques par date

### 2. **Messages** (Onglet)
- Historique des messages envoyés
- Messages de test
- Détails de chaque message

### 3. **Send test message** (Bouton)
- Permet d'envoyer un message de test
- Utile pour vérifier que les notifications fonctionnent

## 🔍 Si vous ne voyez pas "Engage" dans le menu

### Vérification 1 : Menu latéral complet
Le menu latéral devrait avoir :
- **Build** (Crashlytics, etc.)
- **Engage** ← C'est ici !
  - Cloud Messaging
  - Remote Config
  - etc.
- **Quality**
- **Analytics**
- **Paramètres** (Settings)

### Vérification 2 : Permissions
Assurez-vous d'avoir les permissions nécessaires pour voir cette section.

### Vérification 3 : Version de Firebase Console
Parfois, l'interface peut varier selon la version. Essayez de rafraîchir la page.

## 🎯 Alternative : Voir les notifications via les logs backend

Si vous ne trouvez pas la section Analytics dans Firebase Console, **les logs backend sont la meilleure source** :

Chaque notification envoyée génère un log :
```
✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
```

Ces logs sont **plus fiables** que Firebase Console pour voir chaque notification individuelle.

## 🔗 URL directe (si disponible)

Essayez cette URL :
```
https://console.firebase.google.com/project/siblhish-app/notification
```

Ou :
```
https://console.firebase.google.com/project/siblhish-app/notification/analytics
```

## 💡 Résumé

**Pour voir les notifications envoyées :**
1. Menu latéral → **Engage** → **Cloud Messaging** → **Analytics**
2. **OU** utilisez les **logs backend** (plus fiable pour chaque notification)

**Ce que vous voyez actuellement (Paramètres) :**
- C'est pour la **configuration**, pas pour voir les notifications envoyées

