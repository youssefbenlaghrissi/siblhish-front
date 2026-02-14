package ma.siblhish.controller;

import ma.siblhish.dto.FcmTokenRequest;
import ma.siblhish.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Controller pour gérer les tokens FCM des utilisateurs
 * 
 * Endpoint: POST /api/v1/users/{userId}/fcm-token
 * 
 * À quoi ça sert ?
 * - Enregistrer le token FCM de l'utilisateur dans la base de données
 * - Permettre au backend d'envoyer des notifications push à cet utilisateur
 * - Mettre à jour le token si l'utilisateur se connecte depuis un autre appareil
 */
@RestController
@RequestMapping("/api/v1/users")
public class UserFcmTokenController {

    @Autowired
    private UserService userService;

    /**
     * Enregistrer ou mettre à jour le token FCM d'un utilisateur
     * 
     * @param userId ID de l'utilisateur
     * @param request Contient le token FCM
     * @return Réponse de succès
     */
    @PostMapping("/{userId}/fcm-token")
    public ResponseEntity<Map<String, Object>> registerFcmToken(
            @PathVariable Long userId,
            @RequestBody FcmTokenRequest request) {
        
        try {
            // Valider le token
            if (request.getFcmToken() == null || request.getFcmToken().trim().isEmpty()) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("status", "error");
                errorResponse.put("message", "Le token FCM est requis");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            // Mettre à jour le token FCM dans la base de données
            userService.updateFcmToken(userId, request.getFcmToken());

            // Réponse de succès
            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Token FCM enregistré avec succès");
            
            Map<String, Object> data = new HashMap<>();
            data.put("userId", userId);
            data.put("fcmToken", request.getFcmToken());
            response.put("data", data);

            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", "Erreur lors de l'enregistrement du token: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}

