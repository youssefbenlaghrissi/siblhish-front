# Implémentation Backend - Statistiques Budgets

## 📋 Vue d'ensemble

Implémentation des endpoints backend pour les 5 graphiques de statistiques budgets :
1. **Budget vs Réel** - Comparaison budget prévu vs dépenses réelles
2. **Top Catégories Budgétisées** - Catégories avec les budgets les plus importants
3. **Efficacité Budgétaire** - Mesure globale de l'efficacité des budgets
4. **Tendance Mensuelle Budgets** - Évolution des budgets sur plusieurs mois
5. **Répartition des Budgets** - Répartition du budget total par catégorie (pie chart)

---

## 📁 Fichiers Créés/Modifiés

### DTOs Créés

1. **`BudgetVsActualDto.java`**
   - Compare budget prévu vs dépenses réelles par catégorie
   - Champs : `categoryId`, `categoryName`, `icon`, `color`, `budgetAmount`, `actualAmount`, `difference`, `percentageUsed`

2. **`TopBudgetCategoryDto.java`**
   - Liste les catégories avec les budgets les plus importants
   - Champs : `categoryId`, `categoryName`, `icon`, `color`, `budgetAmount`, `spentAmount`, `remainingAmount`, `percentageUsed`

3. **`BudgetEfficiencyDto.java`**
   - Mesure globale de l'efficacité
   - Champs : `totalBudgetAmount`, `totalSpentAmount`, `totalRemainingAmount`, `averagePercentageUsed`, `totalBudgets`, `budgetsOnTrack`, `budgetsExceeded`

4. **`MonthlyBudgetTrendDto.java`**
   - Évolution mensuelle des budgets
   - Champs : `month` (format "YYYY-MM"), `totalBudgetAmount`, `totalSpentAmount`, `averagePercentageUsed`, `budgetCount`

5. **`BudgetDistributionDto.java`**
   - Répartition par catégorie (pie chart)
   - Champs : `categoryId`, `categoryName`, `icon`, `color`, `budgetAmount`, `percentage`

### Service Modifié

**`StatisticsService.java`** - Ajout de 5 nouvelles méthodes :

1. **`getBudgetVsActual(Long userId, LocalDate startDate, LocalDate endDate)`**
   - Compare les budgets avec les dépenses réelles
   - Gère les budgets globaux (categoryId = null) et par catégorie
   - Calcule la différence et le pourcentage utilisé

2. **`getTopBudgetCategories(Long userId, LocalDate startDate, LocalDate endDate, Integer limit)`**
   - Retourne les catégories avec les budgets les plus importants
   - Limite par défaut : 5 résultats
   - Calcule le montant dépensé et restant

3. **`getBudgetEfficiency(Long userId, LocalDate startDate, LocalDate endDate)`**
   - Calcule les statistiques globales d'efficacité
   - Compte les budgets respectés vs dépassés
   - Calcule le pourcentage moyen utilisé

4. **`getMonthlyBudgetTrend(Long userId, LocalDate startDate, LocalDate endDate)`**
   - Agrège les budgets par mois (format "YYYY-MM")
   - Calcule les totaux et moyennes par mois

5. **`getBudgetDistribution(Long userId, LocalDate startDate, LocalDate endDate)`**
   - Répartition du budget total par catégorie
   - Calcule les pourcentages pour le pie chart

### Controller Modifié

**`StatisticsController.java`** - Ajout de 5 nouveaux endpoints :

1. **`GET /statistics/budget-vs-actual/{userId}`**
   - Paramètres : `startDate`, `endDate`
   - Retourne : `List<BudgetVsActualDto>`

2. **`GET /statistics/top-budget-categories/{userId}`**
   - Paramètres : `startDate`, `endDate`, `limit` (optionnel, défaut: 5)
   - Retourne : `List<TopBudgetCategoryDto>`

3. **`GET /statistics/budget-efficiency/{userId}`**
   - Paramètres : `startDate`, `endDate`
   - Retourne : `BudgetEfficiencyDto`

4. **`GET /statistics/monthly-budget-trend/{userId}`**
   - Paramètres : `startDate`, `endDate`
   - Retourne : `List<MonthlyBudgetTrendDto>`

5. **`GET /statistics/budget-distribution/{userId}`**
   - Paramètres : `startDate`, `endDate`
   - Retourne : `List<BudgetDistributionDto>`

---

## 🔍 Logique Métier

### Gestion des Budgets Globaux vs Par Catégorie

Les budgets peuvent être :
- **Globaux** : `categoryId = null` → Toutes les dépenses de l'utilisateur sont comptabilisées
- **Par catégorie** : `categoryId != null` → Seules les dépenses de cette catégorie sont comptabilisées

### Calcul des Dépenses Réelles

Pour chaque budget, les dépenses sont calculées en fonction de :
- La période du budget (`start_date` et `end_date`)
- La période de filtrage (`startDate` et `endDate`)
- Le type de budget (global ou par catégorie)

**Formule** : Les dépenses sont comptabilisées dans l'intersection des deux périodes :
- Date de début effective : `GREATEST(budget.start_date, filter.startDate)`
- Date de fin effective : `LEAST(budget.end_date, filter.endDate)`

### Performance

Les requêtes utilisent des sous-requêtes corrélées pour calculer les dépenses réelles. Pour optimiser :
- Les budgets sont filtrés en premier (`WHERE b.start_date <= :endDate AND b.end_date >= :startDate`)
- Les dépenses sont calculées uniquement pour les budgets pertinents
- Les résultats sont groupés par catégorie pour éviter les doublons

---

## 📊 Exemples de Réponses API

### Budget vs Réel

```json
{
  "success": true,
  "data": [
    {
      "categoryId": 1,
      "categoryName": "Alimentation",
      "icon": "restaurant",
      "color": "#FF5722",
      "budgetAmount": 2000.0,
      "actualAmount": 1500.0,
      "difference": 500.0,
      "percentageUsed": 75.0
    },
    {
      "categoryId": null,
      "categoryName": "Budget Global",
      "icon": "",
      "color": "#9E9E9E",
      "budgetAmount": 5000.0,
      "actualAmount": 4500.0,
      "difference": 500.0,
      "percentageUsed": 90.0
    }
  ]
}
```

### Top Catégories Budgétisées

```json
{
  "success": true,
  "data": [
    {
      "categoryId": null,
      "categoryName": "Budget Global",
      "icon": "",
      "color": "#9E9E9E",
      "budgetAmount": 5000.0,
      "spentAmount": 4500.0,
      "remainingAmount": 500.0,
      "percentageUsed": 90.0
    },
    {
      "categoryId": 1,
      "categoryName": "Alimentation",
      "icon": "restaurant",
      "color": "#FF5722",
      "budgetAmount": 2000.0,
      "spentAmount": 1500.0,
      "remainingAmount": 500.0,
      "percentageUsed": 75.0
    }
  ]
}
```

### Efficacité Budgétaire

```json
{
  "success": true,
  "data": {
    "totalBudgetAmount": 10000.0,
    "totalSpentAmount": 8500.0,
    "totalRemainingAmount": 1500.0,
    "averagePercentageUsed": 85.0,
    "totalBudgets": 5,
    "budgetsOnTrack": 4,
    "budgetsExceeded": 1
  }
}
```

### Tendance Mensuelle

```json
{
  "success": true,
  "data": [
    {
      "month": "2025-10",
      "totalBudgetAmount": 5000.0,
      "totalSpentAmount": 4500.0,
      "averagePercentageUsed": 90.0,
      "budgetCount": 3
    },
    {
      "month": "2025-11",
      "totalBudgetAmount": 5500.0,
      "totalSpentAmount": 5000.0,
      "averagePercentageUsed": 90.9,
      "budgetCount": 4
    }
  ]
}
```

### Répartition des Budgets

```json
{
  "success": true,
  "data": [
    {
      "categoryId": null,
      "categoryName": "Budget Global",
      "icon": "",
      "color": "#9E9E9E",
      "budgetAmount": 5000.0,
      "percentage": 50.0
    },
    {
      "categoryId": 1,
      "categoryName": "Alimentation",
      "icon": "restaurant",
      "color": "#FF5722",
      "budgetAmount": 2000.0,
      "percentage": 20.0
    }
  ]
}
```

---

## ✅ Validation

Tous les endpoints incluent :
- Validation des dates (`startDate <= endDate`)
- Gestion des budgets globaux (`categoryId = null`)
- Calcul correct des dépenses dans l'intersection des périodes
- Gestion des cas où il n'y a pas de budgets (retourne des listes vides ou des valeurs par défaut)

---

## 🚀 Prochaines Étapes

1. **Tests** : Créer des tests unitaires et d'intégration pour chaque endpoint
2. **Optimisation** : Si nécessaire, optimiser les requêtes SQL avec des vues ou des index
3. **Frontend** : Intégrer ces endpoints dans les widgets Flutter correspondants
4. **Documentation** : Ajouter la documentation Swagger/OpenAPI pour chaque endpoint

---

## 📝 Notes Techniques

- Les requêtes utilisent PostgreSQL (`TO_CHAR`, `GREATEST`, `LEAST`)
- Les budgets sont filtrés par période avec intersection des dates
- Les budgets globaux sont identifiés par `categoryId = null` ou `categoryId = 0`
- Les pourcentages sont calculés avec une précision de 2 décimales
- Les montants sont en `Double` (MAD)

