package ma.siblhish.dto;

import lombok.Data;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * DTO pour la requête de connexion sociale (Google, Facebook, etc.)
 */
@Data
public class SocialLoginRequest {
    
    @NotBlank(message = "Le provider est requis (google, facebook, etc.)")
    private String provider;
    
    @NotBlank(message = "L'email est requis")
    @Email(message = "L'email doit être valide")
    private String email;
    
    private String displayName;
    
    private String photoUrl;
    
    /**
     * Statut des notifications activées ou non
     * true si l'utilisateur a accepté les permissions de notifications
     * false si l'utilisateur a refusé les permissions
     * null si les permissions n'ont pas encore été demandées
     */
    private Boolean notificationsEnabled;
}

