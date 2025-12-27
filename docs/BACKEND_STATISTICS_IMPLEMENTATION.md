# Implémentation Backend - Filtre par Date pour Statistiques

## 📋 Résumé des modifications

Remplacement du paramètre `period` par `startDate` et `endDate` dans les endpoints de statistiques.

## 🔧 Fichiers à modifier

### 1. StatisticsController.java

**Localisation** : `src/main/java/ma/siblhish/controller/StatisticsController.java`

**Modifications** :
- Supprimer le paramètre `@RequestParam String period`
- Ajouter les paramètres `@RequestParam LocalDate startDate` et `@RequestParam LocalDate endDate`
- Ajouter `@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)` pour le parsing des dates

### 2. StatisticsService.java

**Localisation** : `src/main/java/ma/siblhish/service/StatisticsService.java`

**Modifications** :
- Modifier la signature de `getExpenseAndIncomeByPeriod()` pour accepter `startDate` et `endDate`
- Modifier la signature de `getExpensesByCategory()` pour accepter `startDate` et `endDate`
- Supprimer toute logique basée sur `period`
- Implémenter la détermination automatique de la granularité selon la plage de dates
- Modifier les requêtes SQL pour utiliser `startDate` et `endDate` au lieu de calculs basés sur `period`

## 📝 Code complet

### StatisticsController.java

```java
package ma.siblhish.controller;

import ma.siblhish.dto.MonthlySummaryDto;
import ma.siblhish.service.StatisticsService;
import ma.siblhish.dto.ApiResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/statistics")
public class StatisticsController {

    private final StatisticsService statisticsService;

    public StatisticsController(StatisticsService statisticsService) {
        this.statisticsService = statisticsService;
    }

    /**
     * Obtenir les revenus et dépenses par période
     * @param userId ID de l'utilisateur
     * @param startDate Date de début (format: YYYY-MM-DD)
     * @param endDate Date de fin (format: YYYY-MM-DD)
     * @return Liste des résumés mensuels dans la plage de dates
     */
    @GetMapping("/expense-and-income-by-period/{userId}")
    public ResponseEntity<ApiResponse<List<MonthlySummaryDto>>> getExpenseAndIncomeByPeriod(
            @PathVariable Long userId,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        try {
            // Validation : startDate doit être <= endDate
            if (startDate.isAfter(endDate)) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("La date de début doit être antérieure ou égale à la date de fin"));
            }

            List<MonthlySummaryDto> summaries = statisticsService.getExpenseAndIncomeByPeriod(
                    userId, startDate, endDate
            );
            return ResponseEntity.ok(ApiResponse.success(summaries));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Erreur lors de la récupération des statistiques: " + e.getMessage()));
        }
    }

    /**
     * Obtenir les dépenses par catégorie
     * @param userId ID de l'utilisateur
     * @param startDate Date de début (format: YYYY-MM-DD)
     * @param endDate Date de fin (format: YYYY-MM-DD)
     * @return Map contenant les dépenses par catégorie
     */
    @GetMapping("/expenses-by-category/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getExpensesByCategory(
            @PathVariable Long userId,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        try {
            // Validation : startDate doit être <= endDate
            if (startDate.isAfter(endDate)) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("La date de début doit être antérieure ou égale à la date de fin"));
            }

            Map<String, Object> categoryExpenses = statisticsService.getExpensesByCategory(
                    userId, startDate, endDate
            );
            return ResponseEntity.ok(ApiResponse.success(categoryExpenses));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Erreur lors de la récupération des dépenses par catégorie: " + e.getMessage()));
        }
    }
}
```

### StatisticsService.java (exemple de structure)

```java
package ma.siblhish.service;

import ma.siblhish.dto.MonthlySummaryDto;
import ma.siblhish.repository.ExpenseRepository;
import ma.siblhish.repository.IncomeRepository;
import ma.siblhish.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StatisticsService {

    private final ExpenseRepository expenseRepository;
    private final IncomeRepository incomeRepository;
    private final EntityMapper entityMapper;

    /**
     * Obtenir les revenus et dépenses par période
     * La granularité est déterminée automatiquement selon la plage de dates
     */
    public List<MonthlySummaryDto> getExpenseAndIncomeByPeriod(
            Long userId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        // Déterminer la granularité selon la plage de dates
        long daysBetween = ChronoUnit.DAYS.between(startDate, endDate);
        
        if (daysBetween <= 7) {
            // Agrégation par jour (≤ 7 jours)
            return aggregateByDay(userId, startDate, endDate);
        } else if (daysBetween <= 90) {
            // Agrégation par semaine (≤ 90 jours)
            return aggregateByWeek(userId, startDate, endDate);
        } else {
            // Agrégation par mois (> 90 jours)
            return aggregateByMonth(userId, startDate, endDate);
        }
    }

    /**
     * Obtenir les dépenses par catégorie dans une plage de dates
     */
    public Map<String, Object> getExpensesByCategory(
            Long userId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        // Implémenter la requête pour obtenir les dépenses par catégorie
        // Utiliser startDate et endDate dans la clause WHERE
        // Retourner un Map avec la clé "categories" contenant la liste
        
        Map<String, Object> result = new HashMap<>();
        // result.put("categories", categoryExpenses);
        return result;
    }

    /**
     * Agrégation par jour
     */
    private List<MonthlySummaryDto> aggregateByDay(Long userId, LocalDate startDate, LocalDate endDate) {
        // Implémenter la requête SQL avec GROUP BY DATE(date)
        // Utiliser startDate et endDate dans WHERE
        return new ArrayList<>();
    }

    /**
     * Agrégation par semaine
     */
    private List<MonthlySummaryDto> aggregateByWeek(Long userId, LocalDate startDate, LocalDate endDate) {
        // Implémenter la requête SQL avec GROUP BY DATE_TRUNC('week', date)
        // Utiliser startDate et endDate dans WHERE
        return new ArrayList<>();
    }

    /**
     * Agrégation par mois
     */
    private List<MonthlySummaryDto> aggregateByMonth(Long userId, LocalDate startDate, LocalDate endDate) {
        // Implémenter la requête SQL avec GROUP BY TO_CHAR(date, 'YYYY-MM')
        // Utiliser startDate et endDate dans WHERE
        return new ArrayList<>();
    }
}
```

## 🔍 Points importants

1. **Validation des dates** : Vérifier que `startDate <= endDate`
2. **Granularité automatique** : Déterminer automatiquement la granularité selon la plage
3. **Format des dates** : Utiliser `@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)` pour le parsing
4. **Requêtes SQL** : Modifier toutes les requêtes pour utiliser `startDate` et `endDate` au lieu de calculs basés sur `period`

## ✅ Checklist de migration

- [ ] Modifier `StatisticsController.java`
- [ ] Modifier `StatisticsService.java`
- [ ] Mettre à jour toutes les requêtes SQL
- [ ] Supprimer toute référence à `period` dans les méthodes de service
- [ ] Tester avec différentes plages de dates
- [ ] Vérifier que les données retournées sont correctes

