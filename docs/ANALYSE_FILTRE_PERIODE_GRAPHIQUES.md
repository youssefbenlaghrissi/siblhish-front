# Analyse du Comportement des Graphiques avec le Filtre de Période

## Vue d'ensemble

Ce document explique le comportement actuel de chaque graphique/widget de statistiques vis-à-vis du nouveau filtre de période (daily, weekly, monthly, 3months, 6months).

---

## 📊 Graphiques qui **RÉAGISSENT** au filtre de période

Ces graphiques utilisent les données filtrées par `startDate` et `endDate` calculées selon la période sélectionnée.

### 1. **BarChartWidget** - "Revenus vs Dépenses"
- **Données utilisées** : `provider.monthlySummary`
- **Chargement** : `provider.loadMonthlySummary(startDate, endDate)` dans `_loadChartsDataIfNeeded()`
- **Comportement** : ✅ **Réagit au filtre**
  - Affiche les revenus et dépenses pour la période sélectionnée
  - L'agrégation backend varie selon la période (jour, semaine, mois)
  - Le graphique se met à jour automatiquement lors du changement de période

### 2. **PieChartWidget** - "Répartition des Dépenses"
- **Données utilisées** : `provider.categoryExpenses`
- **Chargement** : `provider.loadCategoryExpenses(startDate, endDate)` dans `_loadChartsDataIfNeeded()`
- **Comportement** : ✅ **Réagit au filtre**
  - Affiche la répartition des dépenses par catégorie pour la période sélectionnée
  - Les montants sont filtrés selon `startDate` et `endDate`

### 3. **SavingsCardWidget** - "Économies"
- **Données utilisées** : `provider.monthlySummary` (somme des balances)
- **Calcul** : Somme de toutes les `balance` dans `monthlySummary` pour la période
- **Comportement** : ✅ **Réagit au filtre**
  - Affiche le total des économies (revenus - dépenses) pour la période sélectionnée
  - Se recalcule automatiquement selon la période

### 4. **AverageExpenseCardWidget** - "Moyenne Dépenses"
- **Données utilisées** : `provider.monthlySummary` (total des dépenses)
- **Calcul** : 
  - `daily` : total / 30 jours
  - `weekly` : total / 12 semaines
  - Autres : total / nombre réel de périodes avec données
- **Comportement** : ✅ **Réagit au filtre**
  - Calcule la moyenne des dépenses pour la période sélectionnée
  - Note : Le calcul utilise des valeurs fixes (30 jours, 12 semaines) pour daily/weekly, ce qui peut être inexact

### 5. **AverageIncomeCardWidget** - "Moyenne Revenus"
- **Données utilisées** : `provider.monthlySummary` (total des revenus)
- **Calcul** : 
  - `daily` : total / 30 jours
  - `weekly` : total / 12 semaines
  - Autres : total / nombre réel de périodes avec données
- **Comportement** : ✅ **Réagit au filtre**
  - Calcule la moyenne des revenus pour la période sélectionnée
  - Note : Même problème que AverageExpenseCardWidget avec les valeurs fixes

### 6. **TopCategoriesCardWidget** - "Top Catégories"
- **Données utilisées** : `provider.categoryExpenses` (top 5)
- **Chargement** : `provider.loadCategoryExpenses(startDate, endDate)` dans `_loadChartsDataIfNeeded()`
- **Comportement** : ✅ **Réagit au filtre**
  - Affiche les 5 catégories avec les dépenses les plus élevées pour la période sélectionnée

---

## 🚫 Graphiques qui **NE RÉAGISSENT PAS** au filtre de période

Ces graphiques utilisent des données chargées indépendamment du filtre de période ou sont des widgets mock.

### 1. **GoalsProgressCardWidget** - "Progression des Objectifs" ⚠️
- **Données utilisées** : 
  - `provider.goals` (tous les objectifs, sans filtre)
  - `provider.balance` (solde actuel global, sans filtre)
- **Chargement** : `provider.loadGoals()` appelé dans `loadHomeData()`, **sans paramètres de période**
- **Comportement** : ❌ **NE RÉAGIT PAS au filtre**
  - Affiche la progression de **tous** les objectifs, indépendamment de la période sélectionnée
  - Utilise le solde global (`balance`) qui n'est pas filtré par période
  - **Problème identifié** : Le graphique devrait idéalement filtrer les objectifs ou montrer la progression dans la période sélectionnée

### 2. **BalanceCardWidget** - "Solde"
- **Données utilisées** : `provider.balance`
- **Chargement** : `provider.loadBalance()` appelé dans `loadHomeData()`, **sans filtre de période**
- **Comportement** : ❌ **NE RÉAGIT PAS au filtre**
  - Affiche le solde global actuel, pas le solde pour la période sélectionnée
  - **Note** : Cela peut être intentionnel (solde = état actuel du compte)

### 3. **TransactionCountCardWidget** - "Nombre de Transactions"
- **Données utilisées** : 
  - `provider.expenses.length`
  - `provider.incomes.length`
- **Chargement** : Ces listes sont chargées dans `loadHomeData()`, **sans filtre de période**
- **Comportement** : ❌ **NE RÉAGIT PAS au filtre**
  - Affiche le nombre total de transactions, pas le nombre pour la période sélectionnée

### 4. **ScheduledPaymentsCardWidget** - "Paiements Planifiés"
- **Données utilisées** : `provider.scheduledPayments`
- **Chargement** : `provider.loadScheduledPayments()` appelé dans `loadHomeData()`, **sans filtre de période**
- **Comportement** : ❌ **NE RÉAGIT PAS au filtre**
  - Affiche tous les paiements planifiés (à venir et en retard), indépendamment de la période
  - **Note** : Cela peut être intentionnel (paiements planifiés = futurs)

### 5. **BudgetVsActualChartWidget** - "Budget vs Réel"
- **Données utilisées** : Aucune (widget mock)
- **Comportement** : ❌ **Widget mock**
  - Affiche uniquement un message "Données non disponibles"
  - Pas encore implémenté côté backend

### 6. **TopBudgetCategoriesCardWidget** - "Top Catégories Budgétisées"
- **Données utilisées** : Aucune (widget mock)
- **Comportement** : ❌ **Widget mock**
  - Affiche uniquement un message "Données non disponibles"
  - Pas encore implémenté côté backend

### 7. **BudgetEfficiencyCardWidget** - "Efficacité Budgétaire"
- **Données utilisées** : Aucune (widget mock)
- **Comportement** : ❌ **Widget mock**
  - Affiche uniquement un message "Données non disponibles"
  - Pas encore implémenté côté backend

### 8. **MonthlyBudgetTrendWidget** - "Tendance Mensuelle"
- **Données utilisées** : Aucune (widget mock)
- **Comportement** : ❌ **Widget mock**
  - Affiche uniquement un message "Données non disponibles"
  - Pas encore implémenté côté backend

### 9. **BudgetDistributionPieChartWidget** - "Répartition des Budgets"
- **Données utilisées** : Aucune (widget mock)
- **Comportement** : ❌ **Widget mock**
  - Affiche uniquement un message "Données non disponibles"
  - Pas encore implémenté côté backend

---

## 📋 Résumé

### Graphiques fonctionnels qui réagissent au filtre (6) :
1. ✅ BarChartWidget (Revenus vs Dépenses)
2. ✅ PieChartWidget (Répartition des Dépenses)
3. ✅ SavingsCardWidget (Économies)
4. ✅ AverageExpenseCardWidget (Moyenne Dépenses)
5. ✅ AverageIncomeCardWidget (Moyenne Revenus)
6. ✅ TopCategoriesCardWidget (Top Catégories)

### Graphiques fonctionnels qui NE réagissent PAS au filtre (4) :
1. ❌ **GoalsProgressCardWidget** (Progression des Objectifs) - **Problème identifié**
2. ❌ BalanceCardWidget (Solde) - Peut être intentionnel
3. ❌ TransactionCountCardWidget (Nombre de Transactions)
4. ❌ ScheduledPaymentsCardWidget (Paiements Planifiés) - Peut être intentionnel

### Widgets mock (5) :
1. ❌ BudgetVsActualChartWidget
2. ❌ TopBudgetCategoriesCardWidget
3. ❌ BudgetEfficiencyCardWidget
4. ❌ MonthlyBudgetTrendWidget
5. ❌ BudgetDistributionPieChartWidget

---

## 🔍 Détails techniques

### Méthode de chargement des données filtrées

Dans `statistics_screen.dart`, la méthode `_loadChartsDataIfNeeded()` :

```dart
// Calculer startDate et endDate selon la période et la date sélectionnée
final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
final startDate = dateRange['startDate']!;
final endDate = dateRange['endDate']!;

// Charger les données filtrées
if (hasBarChart || hasSavingsCard || hasAverageExpenseCard || hasAverageIncomeCard) {
  futures.add(provider.loadMonthlySummary(
    startDate: startDate,
    endDate: endDate,
  ));
}

if (hasPieChart || hasTopCategoryCard) {
  futures.add(provider.loadCategoryExpenses(
    startDate: startDate,
    endDate: endDate,
  ));
}
```

### Méthode de chargement des données NON filtrées

Les données non filtrées sont chargées dans `loadHomeData()` du `BudgetProvider` :
- `loadGoals()` - Tous les objectifs
- `loadBalance()` - Solde global
- `loadExpenses()` / `loadIncomes()` - Toutes les transactions
- `loadScheduledPayments()` - Tous les paiements planifiés

Ces méthodes ne reçoivent **aucun paramètre de période**.

---

## 💡 Recommandations

### Pour GoalsProgressCardWidget (priorité élevée) :

**Option 1** : Filtrer les objectifs par date de création ou période d'activité
- Modifier `loadGoals()` pour accepter `startDate` et `endDate`
- Filtrer les objectifs créés ou actifs dans la période sélectionnée
- Adapter l'affichage pour montrer la progression dans la période

**Option 2** : Filtrer les transactions utilisées pour calculer la progression
- Garder tous les objectifs visibles
- Filtrer les transactions qui contribuent à la progression selon la période
- Recalculer `currentAmount` pour chaque objectif selon la période

**Option 3** : Afficher la progression globale mais avec un indicateur de période
- Garder le comportement actuel
- Ajouter un texte indiquant que la progression est globale, pas filtrée par période

### Pour TransactionCountCardWidget :

- Modifier pour charger les transactions filtrées par période
- Utiliser `loadExpenses()` et `loadIncomes()` avec `startDate` et `endDate`

### Pour les widgets mock :

- Implémenter les APIs backend correspondantes
- Ajouter le support du filtre de période dès l'implémentation

---

## 📝 Notes importantes

1. **AverageExpenseCardWidget et AverageIncomeCardWidget** : 
   - Utilisent des valeurs fixes (30 jours, 12 semaines) pour daily/weekly
   - Devraient utiliser le nombre réel de jours/semaines dans la période sélectionnée

2. **GoalsProgressCardWidget** :
   - C'est le seul graphique fonctionnel qui ne réagit pas au filtre et qui devrait probablement le faire
   - La progression des objectifs est une métrique importante qui devrait être visualisable par période

3. **BalanceCardWidget** :
   - Le solde global peut être intentionnel (état actuel du compte)
   - Mais on pourrait aussi afficher le solde à la fin de la période sélectionnée

