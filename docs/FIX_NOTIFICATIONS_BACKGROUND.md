# Fix : Notifications en arrière-plan ne fonctionnent pas

## 🔍 Problème

Les notifications fonctionnent quand l'app est ouverte (foreground) mais **pas quand l'app est fermée ou en arrière-plan** (background).

## ✅ Solution appliquée

J'ai amélioré le handler background pour afficher une notification locale quand l'app est en arrière-plan.

### Changements dans `lib/firebase_messaging_handler.dart`

Le handler background affiche maintenant une notification locale même quand l'app est fermée.

## 🔧 Vérifications supplémentaires

### 1. Vérifier le format des notifications du backend

Le backend doit envoyer les notifications avec le bon format. Il y a deux options :

#### Option A : Payload avec `notification` (Recommandé)

```json
{
  "notification": {
    "title": "Nouveau revenu récurrent",
    "body": "Vous avez un revenu de 1000 MAD prévu aujourd'hui"
  },
  "data": {
    "type": "RECURRING_INCOME",
    "incomeId": "123"
  },
  "token": "fcm_token_utilisateur"
}
```

**Avantage :** FCM affiche automatiquement la notification même en arrière-plan.

#### Option B : Payload avec seulement `data`

```json
{
  "data": {
    "title": "Nouveau revenu récurrent",
    "body": "Vous avez un revenu de 1000 MAD prévu aujourd'hui",
    "type": "RECURRING_INCOME",
    "incomeId": "123"
  },
  "token": "fcm_token_utilisateur"
}
```

**Avantage :** Plus de contrôle, mais nécessite le handler background (déjà implémenté).

### 2. Vérifier la configuration Android

Le `AndroidManifest.xml` doit avoir :
- ✅ Permission `POST_NOTIFICATIONS` (déjà présent)
- ✅ Permission `VIBRATE` (déjà présent)
- ✅ Canal de notification configuré (géré par le code)

### 3. Tester les notifications

1. **Fermez complètement l'application** (pas juste en arrière-plan)
2. **Envoyez une notification depuis le backend**
3. **Vérifiez que la notification apparaît** même si l'app est fermée

## 🐛 Problèmes possibles

### Problème 1 : Le backend n'envoie pas avec le bon format

**Solution :**
- Vérifiez que le backend envoie soit avec `notification` payload, soit avec `data` payload
- Si c'est `data` seulement, le handler background doit l'afficher (déjà implémenté)

### Problème 2 : Les permissions ne sont pas accordées

**Solution :**
- Vérifiez dans les paramètres Android que les notifications sont activées pour l'app
- Réinstallez l'app si nécessaire

### Problème 3 : Le canal de notification n'est pas créé

**Solution :**
- Le code crée automatiquement le canal `siblhish_channel`
- Vérifiez dans les paramètres Android → Applications → Siblhish → Notifications

### Problème 4 : L'app est en mode économie d'énergie

**Solution :**
- Désactivez l'optimisation de batterie pour l'app dans les paramètres Android

## 📝 Checklist

- [x] Handler background amélioré pour afficher les notifications
- [ ] Vérifier que le backend envoie avec le bon format
- [ ] Tester avec l'app fermée
- [ ] Vérifier les permissions de notifications
- [ ] Vérifier que le canal de notification est créé

## 🧪 Test

1. **Fermez complètement l'application**
2. **Demandez au backend d'envoyer une notification de test**
3. **Vérifiez que la notification apparaît** même si l'app est fermée

Si ça ne fonctionne toujours pas, vérifiez :
- Les logs du backend pour voir le format envoyé
- Les logs de l'app (via `adb logcat`) pour voir si le handler est appelé
- Les paramètres Android pour les notifications

