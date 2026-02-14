# 📡 API pour Modifier les Notifications

## Endpoint

```
PUT /api/v1/users/{userId}/profile
```

## Headers

```
Content-Type: application/json
Authorization: Bearer {token}  (si authentification requise)
```

## Body de la Requête

### Exemple : Désactiver les notifications

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "language": "fr",
  "notificationsEnabled": false
}
```

### Exemple : Activer les notifications

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "language": "fr",
  "notificationsEnabled": true
}
```

## Réponse Succès (200 OK)

```json
{
  "status": "success",
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "language": "fr",
    "notificationsEnabled": false
  },
  "message": "Operation successful",
  "errors": null
}
```

## Réponse Erreur (400/500)

```json
{
  "status": "error",
  "message": "Erreur lors de la mise à jour du profil",
  "errors": null
}
```

## Code Frontend

### Appel depuis `BudgetProvider.updateNotificationsEnabled()`

```dart
final updatedUser = await UserService.updateProfile(_currentUser!.id, {
  'firstName': _currentUser!.firstName,
  'lastName': _currentUser!.lastName,
  'language': _currentUser!.language,
  'notificationsEnabled': enabled,  // true ou false
});
```

### Appel API sous-jacent

```dart
// Dans UserService.updateProfile()
ApiService.put('/users/$userId/profile', {
  'firstName': 'John',
  'lastName': 'Doe',
  'language': 'fr',
  'notificationsEnabled': true/false
});
```

## Notes Importantes

1. **Tous les champs sont requis** : Même si on ne modifie que `notificationsEnabled`, il faut envoyer tous les champs du profil (`firstName`, `lastName`, `language`).

2. **Type de données** : `notificationsEnabled` est un **Boolean** (true/false), pas une chaîne.

3. **Endpoint** : L'endpoint est `/users/{userId}/profile`, pas `/users/{userId}/notifications`.

4. **Méthode HTTP** : Utilise **PUT** (mise à jour complète), pas PATCH.

