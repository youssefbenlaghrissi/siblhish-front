# Implémentation des Budgets Récurrents - Backend Spring Boot

## 📋 Vue d'ensemble

Cette fonctionnalité permet de créer automatiquement des budgets récurrents chaque mois (du 1er au dernier jour du mois) pour les budgets marqués comme récurrents.

## 🔧 Modifications nécessaires

### 1. Ajouter le champ `isRecurring` à l'entité Budget

**Fichier : `src/main/java/ma/siblhish/entities/Budget.java`**

```java
package ma.siblhish.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "budgets")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Budget {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Double amount;

    @Column(nullable = false)
    private String period; // DAILY, WEEKLY, MONTHLY, YEARLY

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "end_date")
    private LocalDateTime endDate;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "category_id")
    private Long categoryId;

    @Column(name = "is_recurring", nullable = false)
    private Boolean isRecurring = false; // NOUVEAU CHAMP

    @Column(name = "creation_date", nullable = false, updatable = false)
    private LocalDateTime creationDate;

    @Column(name = "update_date")
    private LocalDateTime updateDate;

    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
        updateDate = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updateDate = LocalDateTime.now();
    }
}
```

### 2. Migration SQL pour ajouter la colonne `is_recurring`

**Fichier : `src/main/resources/db/migration/V7__add_is_recurring_to_budgets.sql`**

```sql
-- Ajouter la colonne is_recurring à la table budgets
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN NOT NULL DEFAULT FALSE;

-- Mettre à jour les budgets existants avec period = 'MONTHLY' et dates correspondant au mois complet
UPDATE budgets 
SET is_recurring = TRUE 
WHERE period = 'MONTHLY' 
  AND start_date IS NOT NULL 
  AND end_date IS NOT NULL
  AND EXTRACT(DAY FROM start_date) = 1
  AND EXTRACT(DAY FROM end_date) = EXTRACT(DAY FROM (DATE_TRUNC('month', end_date) + INTERVAL '1 month' - INTERVAL '1 day'));
```

### 3. Mettre à jour le DTO Budget

**Fichier : `src/main/java/ma/siblhish/dto/BudgetDto.java`**

```java
package ma.siblhish.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BudgetDto {
    private Long id;
    private Long userId;
    private Double amount;
    private String period;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean isActive;
    private Long categoryId;
    private Boolean isRecurring; // NOUVEAU CHAMP
    private LocalDateTime creationDate;
    private LocalDateTime updateDate;
}
```

**Fichier : `src/main/java/ma/siblhish/dto/BudgetRequestDto.java`**

```java
package ma.siblhish.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BudgetRequestDto {
    @NotNull(message = "User ID is required")
    private Long userId;

    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private Double amount;

    @NotNull(message = "Period is required")
    private String period;

    private LocalDateTime startDate;
    private LocalDateTime endDate;
    
    private Boolean isActive = true;
    private Long categoryId;
    private Boolean isRecurring = false; // NOUVEAU CHAMP
}
```

### 4. Mettre à jour le Repository

**Fichier : `src/main/java/ma/siblhish/repository/BudgetRepository.java`**

```java
package ma.siblhish.repository;

import ma.siblhish.entities.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, Long> {
    List<Budget> findByUserId(Long userId);
    
    List<Budget> findByUserIdAndIsActiveTrue(Long userId);
    
    // NOUVELLE MÉTHODE : Trouver tous les budgets récurrents actifs
    @Query("SELECT b FROM Budget b WHERE b.isRecurring = true AND b.isActive = true")
    List<Budget> findAllRecurringActiveBudgets();
    
    // Trouver les budgets récurrents d'un utilisateur spécifique
    List<Budget> findByUserIdAndIsRecurringTrueAndIsActiveTrue(Long userId);
}
```

### 5. Mettre à jour le Service Budget

**Fichier : `src/main/java/ma/siblhish/service/BudgetService.java`**

Ajouter les méthodes suivantes :

```java
package ma.siblhish.service;

import ma.siblhish.entities.Budget;
import ma.siblhish.repository.BudgetRepository;
import ma.siblhish.dto.BudgetDto;
import ma.siblhish.dto.BudgetRequestDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class BudgetService {
    
    @Autowired
    private BudgetRepository budgetRepository;
    
    // ... méthodes existantes ...
    
    /**
     * Créer automatiquement les budgets récurrents pour le mois en cours
     * Cette méthode doit être appelée chaque mois (via un scheduler)
     */
    @Transactional
    public void createRecurringBudgetsForCurrentMonth() {
        LocalDate now = LocalDate.now();
        YearMonth currentMonth = YearMonth.from(now);
        
        // Date de début : 1er jour du mois à 00:00:00
        LocalDateTime startDate = currentMonth.atDay(1).atStartOfDay();
        
        // Date de fin : dernier jour du mois à 23:59:59
        LocalDateTime endDate = currentMonth.atEndOfMonth().atTime(23, 59, 59);
        
        // Récupérer tous les budgets récurrents actifs
        List<Budget> recurringBudgets = budgetRepository.findAllRecurringActiveBudgets();
        
        for (Budget templateBudget : recurringBudgets) {
            // Vérifier si un budget pour ce mois existe déjà
            boolean budgetExists = budgetRepository.findByUserIdAndIsActiveTrue(templateBudget.getUserId())
                .stream()
                .anyMatch(b -> 
                    b.getCategoryId() != null && b.getCategoryId().equals(templateBudget.getCategoryId()) &&
                    b.getStartDate() != null && b.getStartDate().toLocalDate().equals(startDate.toLocalDate()) &&
                    b.getEndDate() != null && b.getEndDate().toLocalDate().equals(endDate.toLocalDate())
                );
            
            if (!budgetExists) {
                // Créer un nouveau budget pour ce mois
                Budget newBudget = new Budget();
                newBudget.setUserId(templateBudget.getUserId());
                newBudget.setAmount(templateBudget.getAmount());
                newBudget.setPeriod("MONTHLY");
                newBudget.setStartDate(startDate);
                newBudget.setEndDate(endDate);
                newBudget.setIsActive(true);
                newBudget.setCategoryId(templateBudget.getCategoryId());
                newBudget.setIsRecurring(true); // Le nouveau budget est aussi récurrent
                
                budgetRepository.save(newBudget);
            }
        }
    }
    
    /**
     * Créer automatiquement les budgets récurrents pour un mois spécifique
     */
    @Transactional
    public void createRecurringBudgetsForMonth(YearMonth yearMonth) {
        LocalDateTime startDate = yearMonth.atDay(1).atStartOfDay();
        LocalDateTime endDate = yearMonth.atEndOfMonth().atTime(23, 59, 59);
        
        List<Budget> recurringBudgets = budgetRepository.findAllRecurringActiveBudgets();
        
        for (Budget templateBudget : recurringBudgets) {
            boolean budgetExists = budgetRepository.findByUserIdAndIsActiveTrue(templateBudget.getUserId())
                .stream()
                .anyMatch(b -> 
                    b.getCategoryId() != null && b.getCategoryId().equals(templateBudget.getCategoryId()) &&
                    b.getStartDate() != null && b.getStartDate().toLocalDate().equals(startDate.toLocalDate()) &&
                    b.getEndDate() != null && b.getEndDate().toLocalDate().equals(endDate.toLocalDate())
                );
            
            if (!budgetExists) {
                Budget newBudget = new Budget();
                newBudget.setUserId(templateBudget.getUserId());
                newBudget.setAmount(templateBudget.getAmount());
                newBudget.setPeriod("MONTHLY");
                newBudget.setStartDate(startDate);
                newBudget.setEndDate(endDate);
                newBudget.setIsActive(true);
                newBudget.setCategoryId(templateBudget.getCategoryId());
                newBudget.setIsRecurring(true);
                
                budgetRepository.save(newBudget);
            }
        }
    }
    
    // Mettre à jour la méthode de création pour inclure isRecurring
    public BudgetDto createBudget(BudgetRequestDto requestDto) {
        Budget budget = new Budget();
        budget.setUserId(requestDto.getUserId());
        budget.setAmount(requestDto.getAmount());
        budget.setPeriod(requestDto.getPeriod());
        budget.setStartDate(requestDto.getStartDate());
        budget.setEndDate(requestDto.getEndDate());
        budget.setIsActive(requestDto.getIsActive() != null ? requestDto.getIsActive() : true);
        budget.setCategoryId(requestDto.getCategoryId());
        budget.setIsRecurring(requestDto.getIsRecurring() != null ? requestDto.getIsRecurring() : false);
        
        Budget saved = budgetRepository.save(budget);
        return convertToDto(saved);
    }
    
    // Mettre à jour la méthode de conversion pour inclure isRecurring
    private BudgetDto convertToDto(Budget budget) {
        BudgetDto dto = new BudgetDto();
        dto.setId(budget.getId());
        dto.setUserId(budget.getUserId());
        dto.setAmount(budget.getAmount());
        dto.setPeriod(budget.getPeriod());
        dto.setStartDate(budget.getStartDate());
        dto.setEndDate(budget.getEndDate());
        dto.setIsActive(budget.getIsActive());
        dto.setCategoryId(budget.getCategoryId());
        dto.setIsRecurring(budget.getIsRecurring()); // NOUVEAU
        dto.setCreationDate(budget.getCreationDate());
        dto.setUpdateDate(budget.getUpdateDate());
        return dto;
    }
}
```

### 6. Créer le Scheduler pour l'exécution automatique

**Fichier : `src/main/java/ma/siblhish/scheduler/RecurringBudgetScheduler.java`**

```java
package ma.siblhish.scheduler;

import ma.siblhish.service.BudgetService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Scheduler pour créer automatiquement les budgets récurrents chaque mois
 * 
 * Exécution : Le 1er de chaque mois à 00:01:00
 */
@Component
public class RecurringBudgetScheduler {
    
    private static final Logger logger = LoggerFactory.getLogger(RecurringBudgetScheduler.class);
    
    @Autowired
    private BudgetService budgetService;
    
    /**
     * Créer les budgets récurrents pour le mois en cours
     * Exécuté le 1er de chaque mois à 00:01:00
     */
    @Scheduled(cron = "0 1 0 1 * ?") // Le 1er de chaque mois à 00:01:00
    public void createRecurringBudgetsForCurrentMonth() {
        logger.info("🔄 Démarrage de la création automatique des budgets récurrents pour le mois en cours");
        
        try {
            budgetService.createRecurringBudgetsForCurrentMonth();
            logger.info("✅ Création automatique des budgets récurrents terminée avec succès");
        } catch (Exception e) {
            logger.error("❌ Erreur lors de la création automatique des budgets récurrents: {}", e.getMessage(), e);
        }
    }
}
```

### 7. Activer le scheduling dans la classe principale

**Fichier : `src/main/java/ma/siblhish/SiblhishApiApplication.java`**

```java
package ma.siblhish;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling; // AJOUTER CET IMPORT

@SpringBootApplication
@EnableScheduling // AJOUTER CETTE ANNOTATION
public class SiblhishApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(SiblhishApiApplication.class, args);
    }
}
```

### 8. Mettre à jour le Controller (optionnel - pour tester manuellement)

**Fichier : `src/main/java/ma/siblhish/controller/BudgetController.java`**

Ajouter un endpoint pour tester manuellement :

```java
package ma.siblhish.controller;

import ma.siblhish.service.BudgetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/budgets")
public class BudgetController {
    
    @Autowired
    private BudgetService budgetService;
    
    // ... endpoints existants ...
    
    /**
     * Endpoint pour créer manuellement les budgets récurrents (pour tests)
     * GET /api/v1/budgets/recurring/create
     */
    @PostMapping("/recurring/create")
    public ResponseEntity<?> createRecurringBudgetsManually() {
        try {
            budgetService.createRecurringBudgetsForCurrentMonth();
            return ResponseEntity.ok().body("Budgets récurrents créés avec succès");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Erreur: " + e.getMessage());
        }
    }
}
```

## 📝 Configuration du Scheduler

### Expression Cron utilisée

```
0 1 0 1 * ?
```

- `0` : seconde (0)
- `1` : minute (1)
- `0` : heure (00:00)
- `1` : jour du mois (1er)
- `*` : mois (tous)
- `?` : jour de la semaine (ignoré)

**Résultat :** Exécution le 1er de chaque mois à 00:01:00

### Alternatives

Si vous voulez exécuter à un autre moment :

- **Tous les jours à minuit :** `0 0 0 * * ?`
- **Le 1er de chaque mois à 02:00 :** `0 0 2 1 * ?`
- **Tous les lundis à 00:01 :** `0 1 0 ? * MON`

## 🧪 Tests

### Test manuel via endpoint

```bash
curl -X POST http://localhost:8081/api/v1/budgets/recurring/create
```

### Test unitaire

```java
@SpringBootTest
class BudgetServiceTest {
    
    @Autowired
    private BudgetService budgetService;
    
    @Test
    void testCreateRecurringBudgets() {
        budgetService.createRecurringBudgetsForCurrentMonth();
        // Vérifier que les budgets ont été créés
    }
}
```

## ✅ Checklist d'implémentation

- [ ] Ajouter le champ `isRecurring` à l'entité `Budget`
- [ ] Créer la migration SQL `V7__add_is_recurring_to_budgets.sql`
- [ ] Mettre à jour `BudgetDto` et `BudgetRequestDto`
- [ ] Mettre à jour `BudgetRepository` avec les nouvelles méthodes
- [ ] Mettre à jour `BudgetService` avec la logique de création automatique
- [ ] Créer `RecurringBudgetScheduler`
- [ ] Activer `@EnableScheduling` dans la classe principale
- [ ] Tester manuellement via l'endpoint `/api/v1/budgets/recurring/create`
- [ ] Vérifier que le scheduler s'exécute correctement

## 🔍 Notes importantes

1. **Éviter les doublons :** La méthode vérifie si un budget existe déjà pour le mois avant de créer un nouveau.

2. **Performance :** Pour de nombreux budgets récurrents, envisagez d'ajouter un index sur `is_recurring` et `is_active` :
   ```sql
   CREATE INDEX idx_budgets_recurring_active ON budgets(is_recurring, is_active);
   ```

3. **Logs :** Le scheduler log toutes les opérations pour faciliter le débogage.

4. **Gestion d'erreurs :** Les erreurs sont loggées mais n'interrompent pas l'exécution pour les autres budgets.

5. **Frontend :** Le frontend envoie déjà `isRecurring: true` dans le JSON, donc pas besoin de modification côté frontend.

