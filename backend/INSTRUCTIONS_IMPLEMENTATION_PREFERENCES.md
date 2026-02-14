# Instructions d'implémentation - API Préférences Utilisateur

## 📋 Résumé

Cet endpoint permet de mettre à jour **uniquement** les préférences utilisateur (`notificationsEnabled` et `language`) sans pouvoir modifier le nom, prénom ou email.

## 🔧 Étapes d'implémentation

### 1. Créer le DTO `UserPreferencesRequest`

**Fichier : `src/main/java/ma/siblhish/dto/UserPreferencesRequest.java`**

Copiez le contenu du fichier `backend/UserPreferencesRequest.java` que j'ai créé.

```java
package ma.siblhish.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferencesRequest {
    private Boolean notificationsEnabled;
    private String language;
}
```

### 2. Ajouter la méthode dans `UserService`

**Fichier : `src/main/java/ma/siblhish/service/UserService.java`**

Ajoutez cette méthode dans votre classe `UserService` :

```java
/**
 * Mettre à jour uniquement les préférences utilisateur
 * (notificationsEnabled et language)
 * 
 * @param userId ID de l'utilisateur
 * @param notificationsEnabled Nouveau statut des notifications (peut être null)
 * @param language Nouvelle langue (peut être null)
 * @return UserProfileDto mis à jour
 */
@Transactional
public UserProfileDto updatePreferences(Long userId, Boolean notificationsEnabled, String language) {
    User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID: " + userId));
    
    // Mettre à jour uniquement si les valeurs sont fournies
    if (notificationsEnabled != null) {
        user.setNotificationsEnabled(notificationsEnabled);
    }
    
    if (language != null && !language.trim().isEmpty()) {
        user.setLanguage(language);
    }
    
    User savedUser = userRepository.save(user);
    return mapper.toUserProfileDto(savedUser);
}
```

### 3. Ajouter l'endpoint dans `UserController`

**Fichier : `src/main/java/ma/siblhish/controller/UserController.java`**

Ajoutez cette méthode dans votre classe `UserController` :

```java
/**
 * Mettre à jour uniquement les préférences utilisateur
 * (notificationsEnabled et language)
 * 
 * @param userId ID de l'utilisateur
 * @param request DTO contenant notificationsEnabled et language
 * @return UserProfileDto mis à jour
 */
@PatchMapping("/{userId}/preferences")
public ResponseEntity<ApiResponse<UserProfileDto>> updatePreferences(
        @PathVariable Long userId,
        @Valid @RequestBody UserPreferencesRequest request) {
    
    UserProfileDto updatedProfile = userService.updatePreferences(
        userId, 
        request.getNotificationsEnabled(), 
        request.getLanguage()
    );
    
    return ResponseEntity.ok(ApiResponse.success(updatedProfile, "Préférences mises à jour avec succès"));
}
```

## 📝 Notes importantes

1. **Méthode HTTP** : Utilisez `PATCH` (mise à jour partielle), pas `PUT`
2. **Champs optionnels** : Les deux champs (`notificationsEnabled` et `language`) sont optionnels dans le DTO
3. **Validation** : Le backend ne met à jour que les champs fournis (non-null)
4. **Sécurité** : Cet endpoint ne permet PAS de modifier `firstName`, `lastName` ou `email`

## ✅ Test

### Exemple 1 : Désactiver les notifications

```bash
curl -X PATCH http://localhost:8080/api/v1/users/1/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "notificationsEnabled": false
  }'
```

### Exemple 2 : Changer la langue

```bash
curl -X PATCH http://localhost:8080/api/v1/users/1/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "language": "en"
  }'
```

### Exemple 3 : Modifier les deux

```bash
curl -X PATCH http://localhost:8080/api/v1/users/1/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "notificationsEnabled": true,
    "language": "fr"
  }'
```

