# 📡 API pour Mettre à Jour les Préférences Utilisateur

## Endpoint

```
PATCH /api/v1/users/{userId}/preferences
```

## Description

Cet endpoint permet de mettre à jour **uniquement** les préférences utilisateur :
- `notificationsEnabled` : Statut des notifications (true/false)
- `language` : Langue de l'application (ex: "fr", "en")

**Important** : Cet endpoint ne permet PAS de modifier le nom, prénom ou email.

## Headers

```
Content-Type: application/json
Authorization: Bearer {token}  (si authentification requise)
```

## Body de la Requête

Les deux champs sont **optionnels**. Vous pouvez envoyer uniquement celui que vous souhaitez modifier.

### Exemple 1 : Désactiver les notifications uniquement

```json
{
  "notificationsEnabled": false
}
```

### Exemple 2 : Changer la langue uniquement

```json
{
  "language": "en"
}
```

### Exemple 3 : Modifier les deux en même temps

```json
{
  "notificationsEnabled": true,
  "language": "fr"
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
  "message": "Préférences mises à jour avec succès",
  "errors": null
}
```

## Réponse Erreur (400/404/500)

```json
{
  "status": "error",
  "message": "Utilisateur non trouvé avec l'ID: 123",
  "errors": null
}
```

## Code Frontend

### Mettre à jour uniquement les notifications

```dart
await UserService.updatePreferences(
  userId,
  notificationsEnabled: false,
);
```

### Mettre à jour uniquement la langue

```dart
await UserService.updatePreferences(
  userId,
  language: "en",
);
```

### Mettre à jour les deux

```dart
await UserService.updatePreferences(
  userId,
  notificationsEnabled: true,
  language: "fr",
);
```

## Différence avec l'endpoint `/profile`

| Endpoint | Méthode | Champs modifiables |
|----------|---------|-------------------|
| `/users/{userId}/profile` | PUT | Tous les champs (firstName, lastName, email, language, notificationsEnabled) |
| `/users/{userId}/preferences` | PATCH | Uniquement `notificationsEnabled` et `language` |

## Avantages

1. **Sécurité** : L'utilisateur ne peut pas modifier son nom/prénom/email via cet endpoint
2. **Simplicité** : Pas besoin d'envoyer tous les champs du profil
3. **Flexibilité** : Chaque champ est optionnel, on peut modifier uniquement ce qu'on veut

