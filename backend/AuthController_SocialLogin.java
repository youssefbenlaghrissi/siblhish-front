package ma.siblhish.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import ma.siblhish.dto.SocialLoginRequest;
import ma.siblhish.dto.ApiResponse;
import ma.siblhish.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

/**
 * Exemple de code pour le controller d'authentification sociale
 * 
 * À intégrer dans votre AuthController existant
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController_SocialLogin {

    private final AuthService authService;

    /**
     * Endpoint pour la connexion sociale (Google, Facebook, etc.)
     * 
     * POST /auth/social
     * 
     * Body:
     * {
     *   "provider": "google",
     *   "email": "user@example.com",
     *   "displayName": "John Doe",
     *   "photoUrl": "https://...",
     *   "notificationsEnabled": true
     * }
     * 
     * Response:
     * {
     *   "status": "success",
     *   "data": {
     *     "id": 1,
     *     "firstName": "John",
     *     "lastName": "Doe",
     *     "email": "user@example.com",
     *     "notificationsEnabled": true
     *   },
     *   "message": "Connexion réussie"
     * }
     */
    @PostMapping("/social")
    public ResponseEntity<ApiResponse<Object>> socialLogin(
            @Valid @RequestBody SocialLoginRequest request) {
        try {
            log.info("🔐 Tentative de connexion sociale - Provider: {}, Email: {}, NotificationsEnabled: {}", 
                request.getProvider(), request.getEmail(), request.getNotificationsEnabled());
            
            // Appeler le service pour créer/récupérer l'utilisateur
            var user = authService.handleSocialLogin(request);
            
            log.info("✅ Connexion sociale réussie - User ID: {}, NotificationsEnabled: {}", 
                user.getId(), user.getNotificationsEnabled());
            
            return ResponseEntity.ok(ApiResponse.success(user, "Connexion réussie"));
            
        } catch (Exception e) {
            log.error("❌ Erreur lors de la connexion sociale: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Erreur lors de la connexion: " + e.getMessage()));
        }
    }
}

