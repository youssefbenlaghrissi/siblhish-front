# Fichiers Backend à Créer pour les Notifications Firebase

## 📋 Résumé

Votre backend a déjà l'API pour **recevoir** les tokens FCM, mais il manque les services pour **envoyer** les notifications.

## 🔧 Fichiers à créer dans votre backend Spring Boot

### 1. Dépendance Firebase Admin SDK

**Fichier : `pom.xml` (Maven)**

Ajoutez dans `<dependencies>` :

```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.2.0</version>
</dependency>
```

**Fichier : `build.gradle` (Gradle)**

Ajoutez dans `dependencies` :

```gradle
implementation 'com.google.firebase:firebase-admin:9.2.0'
```

### 2. Configuration Firebase

**Fichier : `src/main/java/ma/siblhish/config/FirebaseConfig.java`**

```java
package ma.siblhish.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;

@Configuration
public class FirebaseConfig {
    
    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);
    
    @Bean
    public FirebaseApp firebaseApp() {
        // Vérifier si Firebase est déjà initialisé
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                // Option 1 : Utiliser le fichier serviceAccountKey.json dans resources
                InputStream serviceAccount = new ClassPathResource("serviceAccountKey.json").getInputStream();
                
                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
                
                FirebaseApp app = FirebaseApp.initializeApp(options);
                log.info("✅ Firebase initialisé avec succès");
                return app;
                
            } catch (Exception e) {
                // Option 2 : Utiliser les variables d'environnement (pour production)
                try {
                    FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build();
                    
                    FirebaseApp app = FirebaseApp.initializeApp(options);
                    log.info("✅ Firebase initialisé avec les credentials par défaut");
                    return app;
                    
                } catch (Exception e2) {
                    log.error("❌ Erreur lors de l'initialisation de Firebase: {}", e2.getMessage());
                    throw new RuntimeException("Impossible d'initialiser Firebase", e2);
                }
            }
        } else {
            return FirebaseApp.getInstance();
        }
    }
    
    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp firebaseApp) {
        return FirebaseMessaging.getInstance(firebaseApp);
    }
}
```

### 3. Service FCM

**Fichier : `src/main/java/ma/siblhish/service/FcmNotificationService.java`**

```java
package ma.siblhish.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class FcmNotificationService {
    
    private static final Logger log = LoggerFactory.getLogger(FcmNotificationService.class);
    
    @Autowired
    private FirebaseMessaging firebaseMessaging;
    
    /**
     * Envoyer une notification push avec notification payload (RECOMMANDÉ)
     * FCM affiche automatiquement la notification même en arrière-plan
     */
    public String sendNotification(String fcmToken, String title, String body) {
        if (fcmToken == null || fcmToken.trim().isEmpty()) {
            log.warn("Token FCM vide, notification non envoyée");
            return null;
        }
        
        try {
            Message message = Message.builder()
                .setNotification(Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build())
                .setToken(fcmToken)
                .build();
            
            String response = firebaseMessaging.send(message);
            log.info("✅ Notification envoyée avec succès: {}", response);
            return response;
            
        } catch (FirebaseMessagingException e) {
            log.error("❌ Erreur FCM: {}", e.getMessage());
            return null;
        } catch (Exception e) {
            log.error("❌ Erreur inattendue: {}", e.getMessage());
            return null;
        }
    }
    
    /**
     * Envoyer une notification avec des données supplémentaires
     */
    public String sendNotificationWithData(String fcmToken, String title, String body, Map<String, String> data) {
        if (fcmToken == null || fcmToken.trim().isEmpty()) {
            log.warn("Token FCM vide, notification non envoyée");
            return null;
        }
        
        try {
            Message.Builder messageBuilder = Message.builder()
                .setNotification(Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build())
                .setToken(fcmToken);
            
            if (data != null && !data.isEmpty()) {
                messageBuilder.putAllData(data);
            }
            
            String response = firebaseMessaging.send(messageBuilder.build());
            log.info("✅ Notification avec données envoyée: {}", response);
            return response;
            
        } catch (FirebaseMessagingException e) {
            log.error("❌ Erreur FCM: {}", e.getMessage());
            return null;
        } catch (Exception e) {
            log.error("❌ Erreur inattendue: {}", e.getMessage());
            return null;
        }
    }
}
```

### 4. Service RecurringTransaction (si pas déjà existant)

**Fichier : `src/main/java/ma/siblhish/service/RecurringTransactionService.java`**

```java
package ma.siblhish.service;

import ma.siblhish.entity.Income;
import ma.siblhish.entity.User;
import ma.siblhish.repository.IncomeRepository;
import ma.siblhish.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class RecurringTransactionService {
    
    private static final Logger log = LoggerFactory.getLogger(RecurringTransactionService.class);
    
    @Autowired
    private IncomeRepository incomeRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private FcmNotificationService fcmNotificationService;
    
    /**
     * Traiter les revenus récurrents toutes les heures
     */
    @Scheduled(cron = "0 0 * * * *") // Toutes les heures à :00
    public void processRecurringIncomes() {
        log.info("🔄 Début du traitement des revenus récurrents");
        
        try {
            List<Income> recurringIncomes = incomeRepository.findByIsRecurringTrue();
            log.info("📊 Nombre de revenus récurrents trouvés: {}", recurringIncomes.size());
            
            for (Income income : recurringIncomes) {
                try {
                    LocalDateTime nextDueDate = calculateNextDueDate(income);
                    
                    if (nextDueDate == null) continue;
                    
                    LocalDateTime now = LocalDateTime.now();
                    // Si la date est échue ou dans les 24 prochaines heures
                    if (nextDueDate.isBefore(now) || nextDueDate.isBefore(now.plusHours(24))) {
                        createNewIncome(income, nextDueDate);
                        sendNotification(income, nextDueDate);
                    }
                } catch (Exception e) {
                    log.error("❌ Erreur pour le revenu ID {}: {}", income.getId(), e.getMessage());
                }
            }
            
            log.info("✅ Fin du traitement des revenus récurrents");
        } catch (Exception e) {
            log.error("❌ Erreur lors du traitement: {}", e.getMessage());
        }
    }
    
    private LocalDateTime calculateNextDueDate(Income income) {
        LocalDateTime lastDate = income.getDate();
        String frequency = income.getRecurrenceFrequency();
        
        if (frequency == null) return null;
        
        LocalDateTime nextDate = switch (frequency) {
            case "DAILY" -> lastDate.plusDays(1);
            case "WEEKLY" -> lastDate.plusWeeks(1);
            case "MONTHLY" -> lastDate.plusMonths(1);
            case "YEARLY" -> lastDate.plusYears(1);
            default -> null;
        };
        
        if (income.getRecurrenceEndDate() != null && 
            nextDate != null && nextDate.isAfter(income.getRecurrenceEndDate())) {
            return null;
        }
        
        return nextDate;
    }
    
    private void createNewIncome(Income recurringIncome, LocalDateTime dueDate) {
        Income newIncome = new Income();
        newIncome.setAmount(recurringIncome.getAmount());
        newIncome.setPaymentMethod(recurringIncome.getPaymentMethod());
        newIncome.setDate(dueDate);
        newIncome.setDescription(recurringIncome.getDescription());
        newIncome.setSource(recurringIncome.getSource());
        newIncome.setIsRecurring(false);
        newIncome.setUserId(recurringIncome.getUserId());
        
        incomeRepository.save(newIncome);
        log.info("✅ Nouveau revenu créé: {} MAD le {}", 
            newIncome.getAmount(), 
            dueDate.format(DateTimeFormatter.ISO_DATE));
    }
    
    private void sendNotification(Income income, LocalDateTime dueDate) {
        try {
            User user = userRepository.findById(income.getUserId()).orElse(null);
            
            if (user == null || user.getFcmToken() == null || user.getFcmToken().trim().isEmpty()) {
                log.warn("⚠️ Token FCM manquant pour l'utilisateur ID: {}", income.getUserId());
                return;
            }
            
            String title = "Nouveau revenu récurrent";
            String body = String.format("Vous avez un revenu de %.2f MAD prévu le %s",
                income.getAmount(),
                dueDate.format(DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm")));
            
            Map<String, String> data = new HashMap<>();
            data.put("type", "RECURRING_INCOME");
            data.put("incomeId", income.getId().toString());
            data.put("amount", String.valueOf(income.getAmount()));
            
            String messageId = fcmNotificationService.sendNotificationWithData(
                user.getFcmToken(), title, body, data);
            
            if (messageId != null) {
                log.info("✅ Notification envoyée: {}", messageId);
            }
        } catch (Exception e) {
            log.error("❌ Erreur lors de l'envoi de la notification: {}", e.getMessage());
        }
    }
}
```

### 5. Activer le scheduling

**Fichier : Votre classe principale (ex: `Application.java`)**

```java
@SpringBootApplication
@EnableScheduling  // ← Ajouter cette annotation
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### 6. Télécharger serviceAccountKey.json

1. Firebase Console → Paramètres du projet → Comptes de service
2. "Générer une nouvelle clé privée"
3. Télécharger le fichier JSON
4. Renommer en `serviceAccountKey.json`
5. Placer dans `src/main/resources/serviceAccountKey.json`

**⚠️ Ajouter dans `.gitignore` :**
```
src/main/resources/serviceAccountKey.json
```

---

## ✅ Checklist

- [ ] Dépendance Firebase Admin SDK ajoutée
- [ ] `serviceAccountKey.json` téléchargé et placé
- [ ] `FirebaseConfig.java` créé
- [ ] `FcmNotificationService.java` créé
- [ ] `RecurringTransactionService.java` créé/vérifié
- [ ] `@EnableScheduling` activé
- [ ] Backend démarre sans erreur
- [ ] Testé avec une notification manuelle

Une fois ces fichiers créés, votre backend sera prêt à envoyer des notifications !

