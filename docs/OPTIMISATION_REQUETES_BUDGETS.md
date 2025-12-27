# Optimisation des Requêtes Budgets

## 🔍 Problème Actuel

Les 5 requêtes SQL utilisent des **sous-requêtes corrélées** qui sont exécutées pour chaque ligne de budget. Cela signifie :
- Si vous avez 10 budgets, chaque requête exécute 10+ sous-requêtes
- Les mêmes calculs sont répétés dans chaque requête
- Performance dégradée avec beaucoup de budgets

## ✅ Solution : Utiliser des CTEs (Common Table Expressions)

### Approche 1 : Optimiser chaque requête avec des CTEs

Au lieu de sous-requêtes corrélées, utiliser des CTEs pour calculer les dépenses réelles **une seule fois** puis les joindre.

### Approche 2 : Créer un endpoint unifié (Recommandé)

Créer un seul endpoint qui retourne toutes les statistiques budgets en une seule requête optimisée.

---

## 🚀 Solution Recommandée : Endpoint Unifié

### Avantages :
- ✅ **Une seule requête SQL** au lieu de 5
- ✅ **Réduction du nombre d'appels API** (1 au lieu de 5)
- ✅ **Meilleure performance** (calculs partagés)
- ✅ **Cohérence des données** (toutes calculées au même moment)
- ✅ **Moins de charge sur le serveur**

### DTO Unifié

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BudgetStatisticsDto {
    private List<BudgetVsActualDto> budgetVsActual;
    private List<TopBudgetCategoryDto> topBudgetCategories;
    private BudgetEfficiencyDto efficiency;
    private List<MonthlyBudgetTrendDto> monthlyTrend;
    private List<BudgetDistributionDto> distribution;
}
```

### Endpoint Unifié

```java
@GetMapping("/budget-statistics/{userId}")
public ResponseEntity<ApiResponse<BudgetStatisticsDto>> getBudgetStatistics(
        @PathVariable Long userId,
        @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
        @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
        @RequestParam(required = false) Integer topCategoriesLimit) {
    // ...
}
```

---

## 📊 Requête SQL Optimisée avec CTEs

```sql
WITH budget_expenses AS (
    -- Étape 1 : Récupérer tous les budgets pertinents
    SELECT 
        b.id as budget_id,
        b.category_id,
        b.amount,
        b.start_date,
        b.end_date,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color
    FROM budgets b
    LEFT JOIN categories c ON b.category_id = c.id
    WHERE b.user_id = :userId
      AND b.start_date <= :endDate
      AND b.end_date >= :startDate
),
actual_expenses AS (
    -- Étape 2 : Calculer les dépenses réelles UNE SEULE FOIS
    SELECT 
        be.budget_id,
        be.category_id,
        COALESCE(SUM(e.amount), 0) as spent_amount
    FROM budget_expenses be
    LEFT JOIN expenses e ON e.user_id = :userId
      AND DATE(e.creation_date) >= GREATEST(be.start_date, :startDate)
      AND DATE(e.creation_date) <= LEAST(be.end_date, :endDate)
      AND (be.category_id IS NULL OR e.category_id = be.category_id)
    GROUP BY be.budget_id, be.category_id
),
budget_category_summary AS (
    -- Étape 3 : Agréger par catégorie
    SELECT 
        COALESCE(be.category_id, 0) as category_id,
        be.category_name,
        be.category_icon,
        be.category_color,
        SUM(be.amount) as budget_amount,
        SUM(COALESCE(ae.spent_amount, 0)) as spent_amount
    FROM budget_expenses be
    LEFT JOIN actual_expenses ae ON be.budget_id = ae.budget_id
    GROUP BY be.category_id, be.category_name, be.category_icon, be.category_color
),
budget_monthly_summary AS (
    -- Étape 4 : Agréger par mois
    SELECT 
        TO_CHAR(be.start_date, 'YYYY-MM') as month,
        COUNT(DISTINCT be.budget_id) as budget_count,
        SUM(be.amount) as budget_amount,
        SUM(COALESCE(ae.spent_amount, 0)) as spent_amount
    FROM budget_expenses be
    LEFT JOIN actual_expenses ae ON be.budget_id = ae.budget_id
    GROUP BY TO_CHAR(be.start_date, 'YYYY-MM')
),
budget_global_summary AS (
    -- Étape 5 : Statistiques globales
    SELECT 
        COUNT(DISTINCT be.budget_id) as total_budgets,
        SUM(be.amount) as total_budget_amount,
        SUM(COALESCE(ae.spent_amount, 0)) as total_spent_amount,
        COUNT(DISTINCT CASE 
            WHEN COALESCE(ae.spent_amount, 0) <= be.amount THEN be.budget_id 
            ELSE NULL 
        END) as budgets_on_track,
        COUNT(DISTINCT CASE 
            WHEN COALESCE(ae.spent_amount, 0) > be.amount THEN be.budget_id 
            ELSE NULL 
        END) as budgets_exceeded
    FROM budget_expenses be
    LEFT JOIN actual_expenses ae ON be.budget_id = ae.budget_id
)
-- Maintenant, on peut utiliser ces CTEs pour construire tous les résultats
SELECT 
    -- Budget vs Réel
    (SELECT json_agg(json_build_object(
        'categoryId', category_id,
        'categoryName', category_name,
        'icon', category_icon,
        'color', category_color,
        'budgetAmount', budget_amount,
        'actualAmount', spent_amount,
        'difference', budget_amount - spent_amount,
        'percentageUsed', CASE WHEN budget_amount > 0 THEN (spent_amount / budget_amount) * 100 ELSE 0 END
    )) FROM budget_category_summary) as budget_vs_actual,
    
    -- Top Catégories (limité)
    (SELECT json_agg(json_build_object(
        'categoryId', category_id,
        'categoryName', category_name,
        'icon', category_icon,
        'color', category_color,
        'budgetAmount', budget_amount,
        'spentAmount', spent_amount,
        'remainingAmount', budget_amount - spent_amount,
        'percentageUsed', CASE WHEN budget_amount > 0 THEN (spent_amount / budget_amount) * 100 ELSE 0 END
    )) FROM (
        SELECT * FROM budget_category_summary 
        ORDER BY budget_amount DESC 
        LIMIT :limit
    ) top_cats) as top_categories,
    
    -- Efficacité
    (SELECT json_build_object(
        'totalBudgets', total_budgets,
        'totalBudgetAmount', total_budget_amount,
        'totalSpentAmount', total_spent_amount,
        'totalRemainingAmount', total_budget_amount - total_spent_amount,
        'averagePercentageUsed', CASE WHEN total_budget_amount > 0 THEN (total_spent_amount / total_budget_amount) * 100 ELSE 0 END,
        'budgetsOnTrack', budgets_on_track,
        'budgetsExceeded', budgets_exceeded
    ) FROM budget_global_summary) as efficiency,
    
    -- Tendance Mensuelle
    (SELECT json_agg(json_build_object(
        'month', month,
        'budgetCount', budget_count,
        'totalBudgetAmount', budget_amount,
        'totalSpentAmount', spent_amount,
        'averagePercentageUsed', CASE WHEN budget_amount > 0 THEN (spent_amount / budget_amount) * 100 ELSE 0 END
    )) FROM budget_monthly_summary ORDER BY month) as monthly_trend,
    
    -- Répartition
    (SELECT json_agg(json_build_object(
        'categoryId', category_id,
        'categoryName', category_name,
        'icon', category_icon,
        'color', category_color,
        'budgetAmount', budget_amount,
        'percentage', CASE WHEN (SELECT SUM(budget_amount) FROM budget_category_summary) > 0 
            THEN (budget_amount / (SELECT SUM(budget_amount) FROM budget_category_summary)) * 100 
            ELSE 0 END
    )) FROM budget_category_summary ORDER BY budget_amount DESC) as distribution
FROM budget_global_summary;
```

---

## ⚠️ Note sur PostgreSQL

La requête ci-dessus utilise `json_agg` et `json_build_object` qui sont spécifiques à PostgreSQL. Si vous utilisez une autre base de données, il faudra adapter.

---

## 🔄 Alternative : Garder les Endpoints Séparés mais Optimiser avec CTEs

Si vous préférez garder les endpoints séparés, optimisez chaque requête avec des CTEs :

### Exemple : Budget vs Réel Optimisé

```sql
WITH budget_expenses AS (
    SELECT 
        b.id as budget_id,
        b.category_id,
        b.amount,
        b.start_date,
        b.end_date,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color
    FROM budgets b
    LEFT JOIN categories c ON b.category_id = c.id
    WHERE b.user_id = :userId
      AND b.start_date <= :endDate
      AND b.end_date >= :startDate
),
actual_expenses AS (
    SELECT 
        be.budget_id,
        COALESCE(SUM(e.amount), 0) as spent_amount
    FROM budget_expenses be
    LEFT JOIN expenses e ON e.user_id = :userId
      AND DATE(e.creation_date) >= GREATEST(be.start_date, :startDate)
      AND DATE(e.creation_date) <= LEAST(be.end_date, :endDate)
      AND (be.category_id IS NULL OR e.category_id = be.category_id)
    GROUP BY be.budget_id
)
SELECT 
    COALESCE(be.category_id, 0) as category_id,
    COALESCE(be.category_name, 'Budget Global') as category_name,
    COALESCE(be.category_icon, '') as category_icon,
    COALESCE(be.category_color, '#9E9E9E') as category_color,
    SUM(be.amount) as budget_amount,
    SUM(COALESCE(ae.spent_amount, 0)) as actual_amount
FROM budget_expenses be
LEFT JOIN actual_expenses ae ON be.budget_id = ae.budget_id
GROUP BY be.category_id, be.category_name, be.category_icon, be.category_color
HAVING SUM(be.amount) > 0
ORDER BY budget_amount DESC;
```

---

## 📈 Comparaison Performance

### Avant (Sous-requêtes corrélées)
- **5 requêtes SQL**
- **N sous-requêtes** par requête (N = nombre de budgets)
- **Total : ~5N sous-requêtes**

### Après (CTEs)
- **1 requête SQL** (endpoint unifié) ou **5 requêtes optimisées**
- **1 calcul des dépenses** partagé
- **Total : 1 calcul + agrégations**

### Gain Estimé
- **Réduction de 80-90%** du temps d'exécution
- **Réduction de 80%** des appels API (si endpoint unifié)
- **Meilleure scalabilité** avec beaucoup de budgets

---

## 🎯 Recommandation

**Option 1 : Endpoint Unifié** (Meilleure performance)
- Créer `/budget-statistics/{userId}` qui retourne toutes les données
- Frontend fait 1 appel au lieu de 5
- Backend optimise avec CTEs

**Option 2 : Optimiser les Endpoints Existants** (Plus simple)
- Garder les 5 endpoints
- Optimiser chaque requête avec CTEs
- Frontend fait toujours 5 appels mais plus rapides

Quelle approche préférez-vous ?

