package ma.siblhish.dto;

/**
 * DTO pour la requête d'enregistrement du token FCM
 */
public class FcmTokenRequest {
    private String fcmToken;

    public FcmTokenRequest() {
    }

    public FcmTokenRequest(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}

