# Instructions d'implémentation - API FCM Token

## 📋 Résumé

Cette API permet d'enregistrer le token FCM (Firebase Cloud Messaging) des utilisateurs dans la base de données, ce qui permet au backend d'envoyer des notifications push.

## 🔧 Étapes d'implémentation

### 1. Ajouter le champ `fcmToken` dans l'entité User

**Fichier : `src/main/java/ma/siblhish/entity/User.java`**

Ajoutez ce champ dans votre classe User :

```java
@Column(name = "fcm_token", length = 500, nullable = true)
private String fcmToken;

// Getters et Setters
public String getFcmToken() {
    return fcmToken;
}

public void setFcmToken(String fcmToken) {
    this.fcmToken = fcmToken;
}
```

### 2. Créer la migration SQL

**Option A : Si vous utilisez Flyway/Liquibase**

Créez un fichier de migration :
- `src/main/resources/db/migration/Vxxx__add_fcm_token_to_users.sql`

**Option B : Si vous utilisez JPA avec auto-update**

Exécutez directement cette requête SQL :

```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500) NULL;
```

Voir le fichier `Migration_SQL.sql` pour le script complet.

### 3. Créer le DTO FcmTokenRequest

**Fichier : `src/main/java/ma/siblhish/dto/FcmTokenRequest.java`**

Copiez le contenu du fichier `FcmTokenRequest.java` que j'ai créé.

### 4. Ajouter la méthode dans UserService

**Fichier : `src/main/java/ma/siblhish/service/UserService.java`**

Ajoutez cette méthode :

```java
public void updateFcmToken(Long userId, String fcmToken) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID: " + userId));
    
    user.setFcmToken(fcmToken);
    userRepository.save(user);
}
```

### 5. Créer le Controller

**Fichier : `src/main/java/ma/siblhish/controller/UserFcmTokenController.java`**

Copiez le contenu du fichier `UserFcmTokenController.java` que j'ai créé.

**Important :** Vérifiez que le package correspond à votre structure de projet.

### 6. Tester l'endpoint

**Avec curl :**
```bash
curl -X POST http://localhost:8081/api/v1/users/1/fcm-token \
  -H "Content-Type: application/json" \
  -d '{"fcmToken": "test_token_123"}'
```

**Avec Postman :**
- Method: POST
- URL: `http://localhost:8081/api/v1/users/1/fcm-token`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "fcmToken": "test_token_123"
}
```

**Réponse attendue :**
```json
{
  "status": "success",
  "message": "Token FCM enregistré avec succès",
  "data": {
    "userId": 1,
    "fcmToken": "test_token_123"
  }
}
```

## ✅ Checklist

- [ ] Champ `fcmToken` ajouté dans l'entité User
- [ ] Migration SQL exécutée
- [ ] DTO FcmTokenRequest créé
- [ ] Méthode `updateFcmToken` ajoutée dans UserService
- [ ] Controller UserFcmTokenController créé
- [ ] Endpoint testé avec Postman/curl
- [ ] Token vérifié en base de données

## 🚀 Prochaines étapes

Une fois cette API implémentée, vous pourrez :

1. **Recevoir les tokens FCM** depuis l'application Flutter
2. **Stocker les tokens** dans la base de données
3. **Envoyer des notifications** en utilisant l'API FCM de Google (nécessite une configuration supplémentaire)

Pour envoyer des notifications, vous devrez :
- Ajouter la dépendance Firebase Admin SDK dans votre backend
- Configurer les credentials Firebase
- Créer un service pour envoyer des notifications via l'API FCM

## 📝 Notes

- Le token FCM peut être long (jusqu'à 500 caractères), d'où la longueur VARCHAR(500)
- Le token peut être NULL (utilisateur peut refuser les notifications)
- Le token peut changer, donc l'endpoint doit être appelé à chaque connexion

