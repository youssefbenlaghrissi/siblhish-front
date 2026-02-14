package ma.siblhish.service;

import lombok.RequiredArgsConstructor;
import ma.siblhish.dto.UserProfileDto;
import ma.siblhish.entities.User;
import ma.siblhish.mapper.EntityMapper;
import ma.siblhish.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Méthode à ajouter dans UserService pour mettre à jour uniquement
 * les préférences utilisateur (notificationsEnabled et language)
 */
@Service
@RequiredArgsConstructor
public class UserService {
    
    private final UserRepository userRepository;
    private final EntityMapper mapper;

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
}

