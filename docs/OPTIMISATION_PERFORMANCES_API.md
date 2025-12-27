# Optimisation des Performances API - Statistiques

## 📊 Analyse de la Situation Actuelle

### Appels API dans StatisticsScreen

Actuellement, lors du chargement de l'écran statistiques, on fait **jusqu'à 6 appels API séparés** :

1. `GET /statistics/expense-and-income-by-period/{userId}` - Pour bar chart, savings, average expense/income
2. `GET /statistics/expenses-by-category/{userId}` - Pour pie chart
3. `GET /statistics/budget-vs-actual/{userId}` - Pour Budget vs Réel
4. `GET /statistics/top-budget-categories/{userId}` - Pour Top Catégories (appelle budget-vs-actual en interne)
5. `GET /statistics/budget-efficiency/{userId}` - Pour Efficacité Budgétaire
6. `GET /statistics/budget-distribution/{userId}` - Pour Répartition des Budgets

### Problèmes Identifiés

1. **Latence élevée** : 6 requêtes HTTP séquentielles/parallèles = temps de chargement long
2. **Charge serveur** : 6 connexions DB + traitement pour chaque utilisateur
3. **Redondance** : Les 4 endpoints budgets font des requêtes similaires sur la même table
4. **Pas de cache** : Même données rechargées à chaque changement de période
5. **Appels inutiles** : Toutes les données budgets sont chargées même si certaines cartes ne sont pas affichées

---

## 🚀 Solutions d'Optimisation Proposées

### Solution 1 : Endpoint Unifié pour Statistiques Budgets ⭐ RECOMMANDÉE

**Objectif** : Réduire les 4 appels budgets en 1 seul appel

**Avantages** :
- ✅ Réduction de 4 à 1 appel API
- ✅ Une seule requête SQL optimisée au lieu de 4
- ✅ Réduction de la latence réseau
- ✅ Moins de charge sur le serveur

**Implémentation** :

#### Backend : Créer un DTO unifié et un endpoint

```java
// Nouveau DTO unifié
public class UnifiedBudgetStatisticsDto {
    private List<BudgetVsActualDto> budgetVsActual;
    private BudgetEfficiencyDto efficiency;
    private List<BudgetDistributionDto> distribution;
    
    // Getters/Setters
}

// Nouveau endpoint dans StatisticsController
@GetMapping("/all-budget-statistics/{userId}")
public ResponseEntity<ApiResponse<UnifiedBudgetStatisticsDto>> getAllBudgetStatistics(
    @PathVariable Long userId,
    @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
    @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
) {
    UnifiedBudgetStatisticsDto data = statisticsService.getAllBudgetStatisticsUnified(userId, startDate, endDate);
    return ResponseEntity.ok(ApiResponse.success(data));
}

// Nouvelle méthode dans StatisticsService
public UnifiedBudgetStatisticsDto getAllBudgetStatisticsUnified(Long userId, LocalDate startDate, LocalDate endDate) {
    // Utiliser la méthode privée getBudgetStatisticsData() existante
    List<Object[]> categoryResults = getBudgetStatisticsData(userId, startDate, endDate);
    
    // Requête pour budgets individuels (pour efficiency)
    List<Object[]> budgetResults = getBudgetIndividualData(userId, startDate, endDate);
    
    // Construire le DTO unifié
    UnifiedBudgetStatisticsDto unified = new UnifiedBudgetStatisticsDto();
    unified.setBudgetVsActual(mapToBudgetVsActual(categoryResults));
    unified.setEfficiency(calculateEfficiency(categoryResults, budgetResults));
    unified.setDistribution(mapToDistribution(categoryResults));
    
    return unified;
}
```

#### Frontend : Adapter le service et le provider

```dart
// Dans StatisticsService
static Future<UnifiedBudgetStatistics> getAllBudgetStatistics(
  String userId, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final queryParams = <String, String>{
    'startDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
  };
  
  final queryString = queryParams.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  
  final response = await ApiService.get('/statistics/all-budget-statistics/$userId?$queryString');
  final data = response['data'];
  return UnifiedBudgetStatistics.fromJson(data);
}

// Dans BudgetProvider
Future<void> loadAllBudgetStatistics({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (_currentUser == null) return;
  try {
    final unified = await StatisticsService.getAllBudgetStatistics(
      _currentUser!.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    _budgetVsActual = unified.budgetVsActual;
    _budgetEfficiency = unified.efficiency;
    _budgetDistribution = unified.distribution;
    // TopBudgetCategories est dérivé de BudgetVsActual
    _topBudgetCategories = unified.budgetVsActual.map((item) {
      return TopBudgetCategory(
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        icon: item.icon,
        color: item.color,
        budgetAmount: item.budgetAmount,
        spentAmount: item.actualAmount,
        remainingAmount: item.difference,
        percentageUsed: item.percentageUsed,
      );
    }).toList();
    
    notifyListeners();
  } catch (e) {
    _budgetVsActual = [];
    _budgetEfficiency = null;
    _budgetDistribution = [];
    _topBudgetCategories = [];
    notifyListeners();
  }
}

// Dans StatisticsScreen._loadChartsDataIfNeeded
// Remplacer les 4 appels par 1 seul
futures.add(provider.loadAllBudgetStatistics(
  startDate: startDate,
  endDate: endDate,
));
```

**Gain** : **-3 appels API** (de 6 à 3 appels)

---

### Solution 2 : Endpoint Unifié pour TOUTES les Statistiques ⭐⭐ OPTIMAL

**Objectif** : Réduire tous les appels en 1 seul appel

**Avantages** :
- ✅ Réduction de 6 à 1 appel API
- ✅ Temps de chargement minimal
- ✅ Meilleure expérience utilisateur
- ✅ Moins de charge réseau

**Implémentation** :

#### Backend : Créer un DTO unifié complet

```java
public class AllStatisticsDto {
    private List<MonthlySummaryDto> monthlySummary;
    private List<CategoryExpenseDto> categoryExpenses;
    private UnifiedBudgetStatisticsDto budgetStatistics;
    
    // Getters/Setters
}

@GetMapping("/all-statistics/{userId}")
public ResponseEntity<ApiResponse<AllStatisticsDto>> getAllStatistics(
    @PathVariable Long userId,
    @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
    @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
) {
    AllStatisticsDto data = statisticsService.getAllStatistics(userId, startDate, endDate);
    return ResponseEntity.ok(ApiResponse.success(data));
}

// Dans StatisticsService
public AllStatisticsDto getAllStatistics(Long userId, LocalDate startDate, LocalDate endDate) {
    AllStatisticsDto all = new AllStatisticsDto();
    
    // Charger toutes les données en parallèle côté service
    all.setMonthlySummary(getPeriodSummary(userId, startDate, endDate));
    all.setCategoryExpenses(getExpensesByCategory(userId, startDate, endDate));
    all.setBudgetStatistics(getAllBudgetStatisticsUnified(userId, startDate, endDate));
    
    return all;
}
```

#### Frontend : Adapter le provider

```dart
// Dans StatisticsService
static Future<AllStatistics> getAllStatistics(
  String userId, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final queryParams = <String, String>{
    'startDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
  };
  
  final queryString = queryParams.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  
  final response = await ApiService.get('/statistics/all-statistics/$userId?$queryString');
  final data = response['data'];
  return AllStatistics.fromJson(data);
}

// Dans BudgetProvider
Future<void> loadAllStatistics({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (_currentUser == null) return;
  try {
    final allStats = await StatisticsService.getAllStatistics(
      _currentUser!.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    // Mettre à jour toutes les données
    _monthlySummary = allStats.monthlySummary;
    _categoryExpenses = allStats.categoryExpenses;
    _budgetVsActual = allStats.budgetStatistics.budgetVsActual;
    _budgetEfficiency = allStats.budgetStatistics.efficiency;
    _budgetDistribution = allStats.budgetStatistics.distribution;
    _topBudgetCategories = allStats.budgetStatistics.budgetVsActual.map(...).toList();
    
    notifyListeners();
  } catch (e) {
    // Gestion d'erreur
  }
}

// Dans StatisticsScreen._loadChartsDataIfNeeded
// Un seul appel
await provider.loadAllStatistics(
  startDate: startDate,
  endDate: endDate,
);
```

**Gain** : **-5 appels API** (de 6 à 1 appel)

---

### Solution 3 : Mise en Cache Intelligente ⭐ COMPLÉMENTAIRE

**Objectif** : Éviter les appels redondants pour les mêmes paramètres

**Avantages** :
- ✅ Réduction des appels API inutiles
- ✅ Amélioration de la réactivité UI
- ✅ Économie de bande passante

**Implémentation** :

```dart
// Dans BudgetProvider
String? _lastStatisticsCacheKey;
Map<String, dynamic>? _cachedStatistics;

String _generateCacheKey(DateTime startDate, DateTime endDate) {
  return '${startDate.toIso8601String()}_${endDate.toIso8601String()}';
}

Future<void> loadAllStatistics({
  required DateTime startDate,
  required DateTime endDate,
  bool forceReload = false,
}) async {
  if (_currentUser == null) return;
  
  final cacheKey = _generateCacheKey(startDate, endDate);
  
  // Vérifier le cache
  if (!forceReload && _lastStatisticsCacheKey == cacheKey && _cachedStatistics != null) {
    // Utiliser les données en cache
    _applyCachedStatistics(_cachedStatistics!);
    notifyListeners();
    return;
  }
  
  try {
    final allStats = await StatisticsService.getAllStatistics(
      _currentUser!.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    // Mettre en cache
    _lastStatisticsCacheKey = cacheKey;
    _cachedStatistics = allStats.toJson();
    
    // Appliquer les données
    _applyStatisticsData(allStats);
    notifyListeners();
  } catch (e) {
    // Gestion d'erreur
  }
}

void _applyStatisticsData(AllStatistics stats) {
  _monthlySummary = stats.monthlySummary;
  _categoryExpenses = stats.categoryExpenses;
  _budgetVsActual = stats.budgetStatistics.budgetVsActual;
  _budgetEfficiency = stats.budgetStatistics.efficiency;
  _budgetDistribution = stats.budgetStatistics.distribution;
  _topBudgetCategories = stats.budgetStatistics.budgetVsActual.map(...).toList();
}

void _applyCachedStatistics(Map<String, dynamic> cached) {
  // Appliquer les données depuis le cache
  // ...
}

// Invalider le cache lors d'un changement de données
void invalidateStatisticsCache() {
  _lastStatisticsCacheKey = null;
  _cachedStatistics = null;
}
```

**Gain** : **Réduction des appels redondants** (ex: changement de période → pas de rechargement si mêmes dates)

---

### Solution 4 : Lazy Loading Intelligent

**Objectif** : Ne charger que les données nécessaires selon les cartes sélectionnées

**Avantages** :
- ✅ Réduction des appels si certaines cartes ne sont pas affichées
- ✅ Chargement plus rapide si l'utilisateur n'affiche que quelques graphiques

**Implémentation** :

```dart
// Dans StatisticsScreen._loadChartsDataIfNeeded
Future<void> _loadChartsDataIfNeeded(BudgetProvider provider) async {
  if (_isLoadingCharts) return;
  
  _isLoadingCharts = true;
  setState(() {});
  
  try {
    final selectedCardIds = provider.statisticsCardsPreferences;
    final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
    final startDate = dateRange['startDate']!;
    final endDate = dateRange['endDate']!;
    
    // Déterminer quelles données sont nécessaires
    final needsGeneralStats = selectedCardIds.any((id) => 
      ['1', 'bar_chart', '4', 'savings_card', '5', 'average_expense_card', 
       '7', 'average_income_card', '2', 'pie_chart'].contains(id)
    );
    
    final needsBudgetStats = selectedCardIds.any((id) => 
      ['11', 'budget_vs_actual_chart', '12', 'top_budget_categories_card',
       '13', 'budget_efficiency_card', '15', 'budget_distribution_pie_chart'].contains(id)
    );
    
    final futures = <Future>[];
    
    if (needsGeneralStats) {
      // Charger toutes les stats générales en une fois
      futures.add(provider.loadGeneralStatistics(
        startDate: startDate,
        endDate: endDate,
      ));
    }
    
    if (needsBudgetStats) {
      // Charger toutes les stats budgets en une fois
      futures.add(provider.loadAllBudgetStatistics(
        startDate: startDate,
        endDate: endDate,
      ));
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  } catch (e) {
    // Gestion d'erreur
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingCharts = false;
      });
    }
  }
}
```

**Gain** : **Réduction conditionnelle** (ex: si seulement stats générales → 1 appel au lieu de 6)

---

## 📈 Comparaison des Solutions

| Solution | Appels API | Latence | Complexité | Recommandation |
|----------|------------|---------|------------|----------------|
| **Actuel** | 6 appels | ~1800ms | Faible | ❌ |
| **Solution 1** | 3 appels | ~900ms | Moyenne | ⭐ Recommandée |
| **Solution 2** | 1 appel | ~300ms | Élevée | ⭐⭐ Optimale |
| **Solution 3** | Variable | ~0-300ms | Moyenne | ⭐ Complémentaire |
| **Solution 4** | 1-2 appels | ~300-600ms | Moyenne | ⭐ Complémentaire |

---

## 🎯 Recommandation Finale

**Approche Hybride** : Combiner **Solution 2** + **Solution 3**

1. **Créer l'endpoint unifié `/all-statistics`** (Solution 2)
   - Réduit à 1 appel API
   - Meilleure performance globale

2. **Ajouter la mise en cache** (Solution 3)
   - Évite les appels redondants
   - Améliore la réactivité

3. **Garder les endpoints individuels** (pour compatibilité)
   - Permet le lazy loading si nécessaire
   - Facilite le debugging

---

## 🔧 Plan d'Implémentation

### Phase 1 : Backend - Endpoint Unifié Budgets
1. Créer `UnifiedBudgetStatisticsDto`
2. Créer méthode `getAllBudgetStatisticsUnified()` dans `StatisticsService`
3. Créer endpoint `/all-budget-statistics/{userId}` dans `StatisticsController`
4. Tester

### Phase 2 : Frontend - Adapter le Provider
1. Créer modèle `UnifiedBudgetStatistics`
2. Ajouter méthode `getAllBudgetStatistics()` dans `StatisticsService`
3. Ajouter méthode `loadAllBudgetStatistics()` dans `BudgetProvider`
4. Adapter `StatisticsScreen` pour utiliser le nouvel endpoint
5. Tester

### Phase 3 : Backend - Endpoint Unifié Complet
1. Créer `AllStatisticsDto`
2. Créer méthode `getAllStatistics()` dans `StatisticsService`
3. Créer endpoint `/all-statistics/{userId}` dans `StatisticsController`
4. Tester

### Phase 4 : Frontend - Cache et Optimisation
1. Implémenter le cache dans `BudgetProvider`
2. Adapter `StatisticsScreen` pour utiliser le cache
3. Tester et mesurer les performances

---

## 📊 Métriques de Performance Attendues

### Avant Optimisation
- **Appels API** : 6
- **Temps de chargement** : ~1800ms
- **Requêtes SQL** : ~8-10
- **Bande passante** : ~150KB

### Après Optimisation (Solution 2 + 3)
- **Appels API** : 1 (ou 0 si cache)
- **Temps de chargement** : ~300ms (ou 0ms si cache)
- **Requêtes SQL** : ~3-4
- **Bande passante** : ~50KB

**Amélioration** : **~83% de réduction** du temps de chargement

---

## ✅ Checklist d'Implémentation

- [ ] Créer DTOs unifiés (Backend)
- [ ] Créer méthodes de service unifiées (Backend)
- [ ] Créer endpoints unifiés (Backend)
- [ ] Créer modèles Dart unifiés (Frontend)
- [ ] Adapter StatisticsService (Frontend)
- [ ] Adapter BudgetProvider (Frontend)
- [ ] Adapter StatisticsScreen (Frontend)
- [ ] Implémenter le cache (Frontend)
- [ ] Tests unitaires (Backend)
- [ ] Tests d'intégration (Frontend)
- [ ] Mesurer les performances
- [ ] Documenter les changements

