package ma.siblhish.service;

/**
 * Méthode à ajouter dans UserService.java
 * 
 * Cette méthode met à jour le token FCM d'un utilisateur dans la base de données
 */
public class UserService_FCM_Method {

    /**
     * Mettre à jour le token FCM d'un utilisateur
     * 
     * @param userId ID de l'utilisateur
     * @param fcmToken Token FCM à enregistrer
     * @throws RuntimeException si l'utilisateur n'existe pas
     */
    public void updateFcmToken(Long userId, String fcmToken) {
        // Récupérer l'utilisateur depuis la base de données
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID: " + userId));
        
        // Mettre à jour le token FCM
        user.setFcmToken(fcmToken);
        
        // Sauvegarder dans la base de données
        userRepository.save(user);
    }
}

