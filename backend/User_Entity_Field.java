package ma.siblhish.entity;

/**
 * Champ à ajouter dans l'entité User.java
 * 
 * Ajoutez ce champ dans votre classe User :
 */
public class User_Entity_Field {

    /**
     * Token FCM (Firebase Cloud Messaging) pour les notifications push
     * Longueur maximale : 500 caractères (les tokens FCM peuvent être longs)
     */
    @Column(name = "fcm_token", length = 500, nullable = true)
    private String fcmToken;

    // Getters et Setters
    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}

