# Comment accéder à Cloud Messaging Analytics dans Firebase Console

## 📍 Où cliquer (d'après votre écran actuel)

Vous êtes actuellement dans **Analytics Dashboard**. Dans le **menu latéral gauche**, sous **"Raccourcis de projet"**, vous devriez voir :

```
Raccourcis de projet
├── Analytics Dashboard  ← Vous êtes ici
└── Messaging  ← CLIQUEZ ICI ! (icône cloud ☁️)
```

## 🎯 Étapes précises

1. **Dans le menu latéral gauche**, cherchez la section **"Raccourcis de projet"**
2. **Cliquez sur "Messaging"** (avec l'icône cloud ☁️)
3. Vous serez redirigé vers la page Cloud Messaging où vous verrez :
   - Analytics des notifications
   - Historique des messages
   - Options pour envoyer des messages de test

## 📊 Ce que vous verrez dans "Messaging"

Une fois que vous cliquez sur "Messaging", vous devriez voir :

### Onglets disponibles :
- **Analytics** : Statistiques des notifications envoyées
- **Messages** : Historique des messages
- **Send test message** : Envoyer un message de test

### Informations affichées :
- Nombre total de messages envoyés
- Taux de livraison
- Graphiques de performance
- Détails de chaque message

## 🔍 Si vous ne voyez pas "Messaging"

### Option 1 : Chercher dans le menu
- Faites défiler le menu latéral
- Cherchez "Messaging" ou "Cloud Messaging"
- Il peut être dans une autre section du menu

### Option 2 : URL directe
Essayez d'accéder directement via cette URL :
```
https://console.firebase.google.com/project/siblhish-app/notification
```

### Option 3 : Via la recherche
1. Utilisez la barre de recherche en haut de Firebase Console
2. Tapez "Messaging" ou "Cloud Messaging"
3. Sélectionnez le résultat

## 💡 Alternative : Utiliser les logs backend

Si vous ne trouvez pas la section Messaging dans Firebase Console, **les logs backend sont la source la plus fiable** pour voir chaque notification envoyée :

Chaque notification génère un log :
```
✅ Notification envoyée avec succès à l'utilisateur X: ... (messageId: ...)
```

Ces logs sont **plus détaillés** que Firebase Console pour voir chaque notification individuelle.

## 🎯 Résumé

**Action immédiate :**
1. Menu latéral gauche → **"Raccourcis de projet"**
2. Cliquez sur **"Messaging"** (icône cloud ☁️)
3. Vous verrez les analytics et l'historique des notifications

**Si ça ne fonctionne pas :**
- Utilisez les **logs backend** (plus fiable)
- Ou essayez l'URL directe ci-dessus

