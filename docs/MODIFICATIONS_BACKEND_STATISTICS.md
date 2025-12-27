# Modifications Backend - Filtre par Date (startDate/endDate)

## 📋 Vue d'ensemble

Ce document décrit les modifications nécessaires pour remplacer le filtre par `period` par un filtre par `startDate` et `endDate` dans les endpoints de statistiques.

## 🔄 Endpoints à modifier

### 1. `GET /api/v1/statistics/expense-and-income-by-period/{userId}`

**Avant :**
```java
@GetMapping("/expense-and-income-by-period/{userId}")
public ResponseEntity<ApiResponse<List<MonthlySummaryDto>>> getExpenseAndIncomeByPeriod(
    @PathVariable Long userId,
    @RequestParam(required = false, defaultValue = "month") String period
) {
    // ...
}
```

**Après :**
```java
@GetMapping("/expense-and-income-by-period/{userId}")
public ResponseEntity<ApiResponse<List<MonthlySummaryDto>>> getExpenseAndIncomeByPeriod(
    @PathVariable Long userId,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
) {
    // ...
}
```

### 2. `GET /api/v1/statistics/expenses-by-category/{userId}`

**Avant :**
```java
@GetMapping("/expenses-by-category/{userId}")
public ResponseEntity<ApiResponse<Map<String, Object>>> getExpensesByCategory(
    @PathVariable Long userId,
    @RequestParam(required = false, defaultValue = "month") String period
) {
    // ...
}
```

**Après :**
```java
@GetMapping("/expenses-by-category/{userId}")
public ResponseEntity<ApiResponse<Map<String, Object>>> getExpensesByCategory(
    @PathVariable Long userId,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
) {
    // ...
}
```

## 📝 Modifications détaillées

### StatisticsController.java

```java
package ma.siblhish.controller;

import ma.siblhish.dto.MonthlySummaryDto;
import ma.siblhish.service.StatisticsService;
import ma.siblhish.dto.ApiResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        try {
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
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        try {
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

### StatisticsService.java

```java
package ma.siblhish.service;

import ma.siblhish.dto.MonthlySummaryDto;
import ma.siblhish.repository.ExpenseRepository;
import ma.siblhish.repository.IncomeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final ExpenseRepository expenseRepository;
    private final IncomeRepository incomeRepository;
    private final EntityMapper entityMapper;

    /**
     * Obtenir les revenus et dépenses par période
     * Les données sont agrégées par jour, semaine ou mois selon la plage de dates
     */
    public List<MonthlySummaryDto> getExpenseAndIncomeByPeriod(
            Long userId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        // Déterminer la granularité selon la plage de dates
        long daysBetween = java.time.temporal.ChronoUnit.DAYS.between(startDate, endDate);
        
        List<MonthlySummaryDto> summaries = new ArrayList<>();
        
        if (daysBetween <= 1) {
            // Agrégation par jour (1 jour)
            summaries = aggregateByDay(userId, startDate, endDate);
        } else if (daysBetween <= 7) {
            // Agrégation par jour (jusqu'à 7 jours)
            summaries = aggregateByDay(userId, startDate, endDate);
        } else if (daysBetween <= 90) {
            // Agrégation par semaine (jusqu'à 90 jours)
            summaries = aggregateByWeek(userId, startDate, endDate);
        } else {
            // Agrégation par mois (plus de 90 jours)
            summaries = aggregateByMonth(userId, startDate, endDate);
        }
        
        return summaries;
    }

    /**
     * Obtenir les dépenses par catégorie dans une plage de dates
     */
    public Map<String, Object> getExpensesByCategory(
            Long userId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        // Requête SQL pour obtenir les dépenses par catégorie dans la plage de dates
        String sql = """
            SELECT 
                c.id as category_id,
                c.name as category_name,
                c.icon as category_icon,
                c.color as category_color,
                COALESCE(SUM(e.amount), 0) as total_amount,
                COUNT(e.id) as transaction_count
            FROM expenses e
            INNER JOIN categories c ON e.category_id = c.id
            WHERE e.user_id = :userId
            AND e.date >= :startDate
            AND e.date <= :endDate
            GROUP BY c.id, c.name, c.icon, c.color
            ORDER BY total_amount DESC
        """;
        
        // Exécuter la requête et mapper les résultats
        // ... (implémentation détaillée)
        
        Map<String, Object> result = new HashMap<>();
        // result.put("categories", categoryExpenses);
        return result;
    }

    /**
     * Agrégation par jour
     */
    private List<MonthlySummaryDto> aggregateByDay(Long userId, LocalDate startDate, LocalDate endDate) {
        String sql = """
            SELECT 
                DATE(e.date) as period,
                COALESCE(SUM(CASE WHEN e.amount > 0 THEN e.amount ELSE 0 END), 0) as total_expenses,
                COALESCE(SUM(CASE WHEN i.amount > 0 THEN i.amount ELSE 0 END), 0) as total_income
            FROM expenses e
            LEFT JOIN incomes i ON DATE(i.date) = DATE(e.date) AND i.user_id = :userId
            WHERE e.user_id = :userId
            AND DATE(e.date) >= :startDate
            AND DATE(e.date) <= :endDate
            GROUP BY DATE(e.date)
            ORDER BY period ASC
        """;
        
        // Exécuter la requête et mapper les résultats
        // ... (implémentation détaillée)
        return new ArrayList<>();
    }

    /**
     * Agrégation par semaine
     */
    private List<MonthlySummaryDto> aggregateByWeek(Long userId, LocalDate startDate, LocalDate endDate) {
        String sql = """
            SELECT 
                DATE_TRUNC('week', e.date) as period,
                COALESCE(SUM(CASE WHEN e.amount > 0 THEN e.amount ELSE 0 END), 0) as total_expenses,
                COALESCE(SUM(CASE WHEN i.amount > 0 THEN i.amount ELSE 0 END), 0) as total_income
            FROM expenses e
            LEFT JOIN incomes i ON DATE_TRUNC('week', i.date) = DATE_TRUNC('week', e.date) AND i.user_id = :userId
            WHERE e.user_id = :userId
            AND e.date >= :startDate
            AND e.date <= :endDate
            GROUP BY DATE_TRUNC('week', e.date)
            ORDER BY period ASC
        """;
        
        // Exécuter la requête et mapper les résultats
        // ... (implémentation détaillée)
        return new ArrayList<>();
    }

    /**
     * Agrégation par mois
     */
    private List<MonthlySummaryDto> aggregateByMonth(Long userId, LocalDate startDate, LocalDate endDate) {
        String sql = """
            SELECT 
                TO_CHAR(e.date, 'YYYY-MM') as period,
                COALESCE(SUM(CASE WHEN e.amount > 0 THEN e.amount ELSE 0 END), 0) as total_expenses,
                COALESCE(SUM(CASE WHEN i.amount > 0 THEN i.amount ELSE 0 END), 0) as total_income
            FROM expenses e
            LEFT JOIN incomes i ON TO_CHAR(i.date, 'YYYY-MM') = TO_CHAR(e.date, 'YYYY-MM') AND i.user_id = :userId
            WHERE e.user_id = :userId
            AND e.date >= :startDate
            AND e.date <= :endDate
            GROUP BY TO_CHAR(e.date, 'YYYY-MM')
            ORDER BY period ASC
        """;
        
        // Exécuter la requête et mapper les résultats
        // ... (implémentation détaillée)
        return new ArrayList<>();
    }
}
```

## 🔍 Points importants

1. **Suppression du paramètre `period`** : Le paramètre `period` n'est plus nécessaire car la granularité est déterminée automatiquement selon la plage de dates.

2. **Granularité automatique** :
   - **≤ 1 jour** : Agrégation par jour
   - **≤ 7 jours** : Agrégation par jour
   - **≤ 90 jours** : Agrégation par semaine
   - **> 90 jours** : Agrégation par mois

3. **Format des dates** : Les dates sont reçues au format `YYYY-MM-DD` (ISO 8601).

4. **Validation** : Ajouter une validation pour s'assurer que `startDate <= endDate`.

## ✅ Tests à effectuer

1. Tester avec différentes plages de dates :
   - 1 jour (daily)
   - 1 semaine (weekly)
   - 1 mois (monthly)
   - 3 mois (3months)
   - 6 mois (6months)

2. Vérifier que les données retournées correspondent à la plage de dates demandée.

3. Vérifier que l'agrégation est correcte selon la granularité automatique.

