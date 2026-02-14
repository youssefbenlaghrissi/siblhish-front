package ma.siblhish.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import ma.siblhish.dto.ApiResponse;
import ma.siblhish.dto.UserPreferencesRequest;
import ma.siblhish.dto.UserProfileDto;
import ma.siblhish.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Endpoint pour mettre à jour uniquement les préférences utilisateur
 * (notificationsEnabled et language)
 * 
 * Endpoint: PATCH /api/v1/users/{userId}/preferences
 */
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

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
}

