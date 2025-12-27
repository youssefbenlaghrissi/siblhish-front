# 📊 Endpoint Unifié des Statistiques

## 🎯 Endpoint Principal

### `GET /api/v1/statistics/all-statistics/{userId}`

**Rôle** : Récupérer TOUTES les statistiques nécessaires pour tous les graphiques en un seul appel API.

**Paramètres** :
- `userId` (path) : ID de l'utilisateur
- `startDate` (query) : Date de début au format `YYYY-MM-DD` (ex: `2025-12-01`)
- `endDate` (query) : Date de fin au format `YYYY-MM-DD` (ex: `2025-12-31`)

**Réponse** : `AllStatisticsDto` contenant :
- `monthlySummary` : Liste des revenus/dépenses par période
- `categoryExpenses` : Répartition des dépenses par catégorie
- `budgetStatistics` : Toutes les statistiques budgets

---

## 📈 Rôle pour Chaque Graphique

### 1. **Bar Chart** - "Revenus vs Dépenses"
- **Données utilisées** : `monthlySummary`
- **Source** : `allStatistics.monthlySummary`
- **Affichage** : Graphique en barres comparant revenus et dépenses par période

### 2. **Pie Chart** - "Répartition des Dépenses par Catégorie"
- **Données utilisées** : `categoryExpenses.categories`
- **Source** : `allStatistics.categoryExpenses.categories`
- **Affichage** : Graphique en secteurs montrant la répartition des dépenses

### 3. **Savings Card** - "Économies"
- **Données utilisées** : `monthlySummary` (somme des balances)
- **Source** : `allStatistics.monthlySummary` → somme de tous les `balance`
- **Affichage** : Total des économies (revenus - dépenses) pour la période

### 4. **Average Expense Card** - "Moyenne Dépenses"
- **Données utilisées** : `monthlySummary` (total des dépenses)
- **Source** : `allStatistics.monthlySummary` → somme de tous les `totalExpenses`
- **Affichage** : Moyenne des dépenses par jour/semaine/mois selon la période

### 5. **Average Income Card** - "Moyenne Revenus"
- **Données utilisées** : `monthlySummary` (total des revenus)
- **Source** : `allStatistics.monthlySummary` → somme de tous les `totalIncome`
- **Affichage** : Moyenne des revenus par jour/semaine/mois selon la période

### 6. **Transaction Count Card** - "Nombre de Transactions"
- **Données utilisées** : `monthlySummary` (comptage des transactions)
- **Source** : `allStatistics.monthlySummary` → comptage des périodes avec transactions
- **Affichage** : Nombre total de transactions (revenus + dépenses) pour la période

### 7. **Budget vs Réel** - "Budget vs Réel"
- **Données utilisées** : `budgetStatistics.budgetVsActual`
- **Source** : `allStatistics.budgetStatistics.budgetVsActual`
- **Affichage** : Graphique en barres comparant budget prévu vs dépenses réelles par catégorie

### 8. **Top Catégories Budgétisées** - "Top Catégories Budgétisées"
- **Données utilisées** : `budgetStatistics.budgetVsActual` (transformé)
- **Source** : `allStatistics.budgetStatistics.budgetVsActual` → converti en `TopBudgetCategory`
- **Affichage** : Liste des catégories avec les budgets les plus importants et leur utilisation

### 9. **Efficacité Budgétaire** - "Efficacité Budgétaire"
- **Données utilisées** : `budgetStatistics.efficiency`
- **Source** : `allStatistics.budgetStatistics.efficiency`
- **Affichage** : Statistiques globales (totaux, % d'utilisation, budgets on track/exceeded)

### 10. **Répartition des Budgets** - "Répartition des Budgets"
- **Données utilisées** : `budgetStatistics.distribution`
- **Source** : `allStatistics.budgetStatistics.distribution`
- **Affichage** : Graphique en secteurs montrant la répartition du budget total par catégorie

---

## 🏗️ Structure du Service Backend

### Méthodes Publiques (utilisées par l'endpoint)

1. **`getAllStatistics(userId, startDate, endDate)`**
   - Méthode principale qui unifie toutes les statistiques
   - Appelle les 3 méthodes ci-dessous

2. **`getPeriodSummary(userId, startDate, endDate)`**
   - Retourne les revenus/dépenses par période
   - Utilisée par : `getAllStatistics()`

3. **`getExpensesByCategory(userId, startDate, endDate)`**
   - Retourne la répartition des dépenses par catégorie
   - Utilisée par : `getAllStatistics()`

4. **`getAllBudgetStatisticsUnified(userId, startDate, endDate)`**
   - Retourne toutes les statistiques budgets en une fois
   - Utilisée par : `getAllStatistics()`

### Méthodes Privées (utilisées en interne)

1. **`getBudgetStatisticsData(userId, startDate, endDate)`**
   - Requête SQL unifiée pour les données budgets par catégorie
   - Utilisée par : `getAllBudgetStatisticsUnified()`

### Méthodes Publiques (utilisées uniquement par getAllBudgetStatisticsUnified)

Ces méthodes sont utilisées en interne par `getAllBudgetStatisticsUnified()` mais ne sont plus exposées comme endpoints publics :

- `getBudgetVsActual()` - Utilisée par `getAllBudgetStatisticsUnified()`
- `getBudgetEfficiency()` - Utilisée par `getAllBudgetStatisticsUnified()`
- `getBudgetDistribution()` - Utilisée par `getAllBudgetStatisticsUnified()`

---

## ✅ État du Service

**Le service est propre** ✅

- ✅ Une seule méthode publique principale : `getAllStatistics()`
- ✅ Les autres méthodes publiques sont utilisées en interne
- ✅ Pas de code mort ou de méthodes inutilisées
- ✅ Architecture claire et modulaire

---

## 📊 Exemple de Réponse API

```json
{
  "status": "success",
  "data": {
    "monthlySummary": [
      {
        "period": "2025-12-01",
        "totalIncome": 5000.0,
        "totalExpenses": 3000.0,
        "balance": 2000.0
      }
    ],
    "categoryExpenses": {
      "total": 3000.0,
      "categories": [
        {
          "categoryId": "1",
          "categoryName": "Alimentation",
          "icon": "🍔",
          "color": "#FF5722",
          "amount": 1500.0,
          "percentage": 50.0
        }
      ]
    },
    "budgetStatistics": {
      "budgetVsActual": [
        {
          "categoryId": 1,
          "categoryName": "Alimentation",
          "icon": "🍔",
          "color": "#FF5722",
          "budgetAmount": 2000.0,
          "actualAmount": 1500.0,
          "difference": 500.0,
          "percentageUsed": 75.0
        }
      ],
      "efficiency": {
        "totalBudgetAmount": 5000.0,
        "totalSpentAmount": 3000.0,
        "totalRemainingAmount": 2000.0,
        "averagePercentageUsed": 60.0,
        "totalBudgets": 5,
        "budgetsOnTrack": 4,
        "budgetsExceeded": 1
      },
      "distribution": [
        {
          "categoryId": 1,
          "categoryName": "Alimentation",
          "icon": "🍔",
          "color": "#FF5722",
          "budgetAmount": 2000.0,
          "percentage": 40.0
        }
      ]
    }
  }
}
```

---

## 🚀 Avantages

1. **Performance** : 1 appel API au lieu de 6
2. **Cohérence** : Toutes les données calculées au même moment
3. **Simplicité** : Un seul point d'entrée
4. **Maintenabilité** : Code centralisé et facile à maintenir

