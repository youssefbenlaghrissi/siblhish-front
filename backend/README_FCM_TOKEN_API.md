# API FCM Token - Documentation

## 📋 À quoi sert cette API ?

Cette API permet d'enregistrer le token FCM (Firebase Cloud Messaging) des utilisateurs dans la base de données.

### Pourquoi c'est important ?

1. **Enregistrer le token FCM** : Chaque appareil a un token unique qui permet à Firebase d'envoyer des notifications
2. **Mettre à jour le token** : Le token peut changer (réinstallation, mise à jour), il faut le mettre à jour
3. **Envoyer des notifications** : Le backend utilise ce token pour envoyer des notifications push aux utilisateurs

### Flux complet :

```
1. App démarre → Firebase génère un token FCM
2. Utilisateur se connecte → App envoie le token au backend via POST /users/{userId}/fcm-token
3. Backend stocke le token dans la base de données (table users, colonne fcm_token)
4. Plus tard, backend veut notifier l'utilisateur → Utilise le token pour envoyer via FCM API
5. L'utilisateur reçoit la notification sur son téléphone
```

---

## 🔧 Fichiers à créer/modifier

### 1. Modifier l'entité User (ajouter le champ fcmToken)

**Fichier : `src/main/java/ma/siblhish/entity/User.java`**

Ajouter le champ :
```java
@Column(name = "fcm_token", length = 500)
private String fcmToken;
```

### 2. Créer le DTO pour la requête

**Fichier : `src/main/java/ma/siblhish/dto/FcmTokenRequest.java`**

### 3. Créer le Controller

**Fichier : `src/main/java/ma/siblhish/controller/UserFcmTokenController.java`**

### 4. Modifier le Service User

**Fichier : `src/main/java/ma/siblhish/service/UserService.java`**

Ajouter la méthode pour mettre à jour le token FCM.

---

## 📝 Migration SQL (si vous utilisez des migrations)

**Fichier : `src/main/resources/db/migration/Vxxx__add_fcm_token_to_users.sql`**

```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500);
```

---

## 🚀 Utilisation

### Endpoint

```
POST /api/v1/users/{userId}/fcm-token
```

### Request Body

```json
{
  "fcmToken": "token_fcm_de_l_utilisateur"
}
```

### Response (200 OK)

```json
{
  "status": "success",
  "message": "Token FCM enregistré avec succès",
  "data": {
    "userId": 1,
    "fcmToken": "token_fcm_de_l_utilisateur"
  }
}
```

---

## 📱 Exemple d'utilisation depuis le backend (pour envoyer des notifications)

Une fois le token enregistré, vous pouvez l'utiliser pour envoyer des notifications :

```java
// Exemple de service pour envoyer des notifications
@Service
public class NotificationService {
    
    public void sendNotification(String fcmToken, String title, String body) {
        // Utiliser l'API FCM de Google pour envoyer la notification
        // Voir la documentation Firebase Cloud Messaging
    }
}
```

---

## ✅ Checklist

- [ ] Ajouter le champ `fcmToken` dans l'entité User
- [ ] Créer la migration SQL (si nécessaire)
- [ ] Créer le DTO FcmTokenRequest
- [ ] Créer le Controller UserFcmTokenController
- [ ] Ajouter la méthode dans UserService
- [ ] Tester l'endpoint avec Postman/curl
- [ ] Vérifier que le token est bien enregistré en base de données

