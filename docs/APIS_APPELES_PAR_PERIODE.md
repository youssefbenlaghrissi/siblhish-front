# APIs Appelées à Chaque Changement de Période

## 📋 Vue d'ensemble

Lorsqu'un utilisateur change la période dans le filtre des statistiques, le système appelle automatiquement les APIs nécessaires pour recharger les données des graphiques sélectionnés.

## 🔄 Flux d'exécution

### 1. Changement de période
L'utilisateur sélectionne une nouvelle période dans le filtre :
- **Quotidien** (`daily`)
- **Hebdomadaire** (`weekly`)
- **Mensuel** (`monthly`)
- **3 Mois** (`3months`)
- **6 Mois** (`6months`)

### 2. Calcul des dates
La période sélectionnée et la date sélectionnée sont utilisées pour calculer `startDate` et `endDate` :

| Période Frontend | Calcul des dates | Description |
|------------------|------------------|-------------|
| `daily` | Jour sélectionné uniquement | `startDate` et `endDate` = date sélectionnée |
| `weekly` | Semaine complète (lundi à dimanche) | `startDate` = lundi de la semaine, `endDate` = dimanche |
| `monthly` | Mois complet (1er au dernier jour) | `startDate` = 1er du mois, `endDate` = dernier jour du mois |
| `3months` | 3 derniers mois | `startDate` = 1er jour du mois il y a 3 mois, `endDate` = date sélectionnée |
| `6months` | 6 derniers mois | `startDate` = 1er jour du mois il y a 6 mois, `endDate` = date sélectionnée |

**Note importante** : 
- Le backend détermine automatiquement la granularité d'agrégation selon la plage de dates
- **≤ 7 jours** : Agrégation par jour
- **≤ 90 jours** : Agrégation par semaine
- **> 90 jours** : Agrégation par mois

### 3. Détermination des APIs à appeler
Le système vérifie quelles cartes sont sélectionnées et appelle les APIs correspondantes :

#### Si ces cartes sont sélectionnées :
- **Bar Chart** (`bar_chart`)
- **Savings Card** (`savings_card`)
- **Average Expense Card** (`average_expense_card`)
- **Average Income Card** (`average_income_card`)

**→ API appelée :**
```
GET /api/v1/statistics/expense-and-income-by-period/{userId}?startDate={startDate}&endDate={endDate}
```

**Paramètres :**
- `userId` : ID de l'utilisateur
- `startDate` : Date de début au format `YYYY-MM-DD` (ex: `2025-12-23`)
- `endDate` : Date de fin au format `YYYY-MM-DD` (ex: `2025-12-23`)

**Réponse :**
```json
{
  "status": "success",
  "data": [
    {
      "period": "2025-01",
      "totalIncome": 5000.0,
      "totalExpenses": 3000.0,
      "savings": 2000.0
    },
    ...
  ]
}
```

#### Si ces cartes sont sélectionnées :
- **Pie Chart** (`pie_chart`)
- **Top Category Card** (`top_category_card`)

**→ API appelée :**
```
GET /api/v1/statistics/expenses-by-category/{userId}?startDate={startDate}&endDate={endDate}
```

**Paramètres :**
- `userId` : ID de l'utilisateur
- `startDate` : Date de début au format `YYYY-MM-DD` (ex: `2025-12-23`)
- `endDate` : Date de fin au format `YYYY-MM-DD` (ex: `2025-12-23`)

**Réponse :**
```json
{
  "status": "success",
  "data": {
    "categories": [
      {
        "categoryId": "1",
        "categoryName": "Café",
        "categoryIcon": "☕",
        "totalAmount": 500.0,
        "percentage": 25.5
      },
      ...
    ]
  }
}
```

## 📊 Exemple concret

### Scénario : Utilisateur sélectionne "3 Mois"

1. **Période sélectionnée** : `3months`
2. **Date sélectionnée** : 23 décembre 2025
3. **Calcul des dates** : 
   - `startDate` = 2025-10-01 (1er octobre 2025)
   - `endDate` = 2025-12-23 (23 décembre 2025)
4. **Cartes sélectionnées** : Bar Chart + Pie Chart
5. **APIs appelées en parallèle** :
   ```
   GET /api/v1/statistics/expense-and-income-by-period/1?startDate=2025-10-01&endDate=2025-12-23
   GET /api/v1/statistics/expenses-by-category/1?startDate=2025-10-01&endDate=2025-12-23
   ```
6. **Données rechargées** :
   - `monthlySummary` (pour Bar Chart) - agrégées par mois automatiquement
   - `categoryExpenses` (pour Pie Chart)

## ⚡ Optimisations

### Appels en parallèle
Les APIs sont appelées en parallèle avec `Future.wait()` pour améliorer les performances :
```dart
final futures = <Future>[];
if (hasBarChart || hasSavingsCard || ...) {
  futures.add(provider.loadMonthlySummary(period: periodFormat));
}
if (hasPieChart || hasTopCategoryCard) {
  futures.add(provider.loadCategoryExpenses(period: periodFormat));
}
await Future.wait(futures);
```

### Chargement conditionnel
Seules les APIs nécessaires sont appelées selon les cartes sélectionnées par l'utilisateur.

## 🔍 Code source

### Méthode principale
**Fichier** : `lib/screens/statistics_screen.dart`

```dart
Future<void> _onPeriodChanged(String period, BudgetProvider provider) async {
  if (_selectedPeriod == period) return;
  
  setState(() {
    _selectedPeriod = period;
  });
  
  // Recharger tous les graphiques sélectionnés avec la nouvelle période
  await _loadChartsDataIfNeeded(provider);
}
```

### Conversion de période
```dart
String _getPeriodFormat(String period) {
  switch (period) {
    case 'daily':
      return 'day';
    case 'weekly':
      return 'day';
    case 'monthly':
      return 'month';
    case '3months':
      return 'month';
    case '6months':
      return 'month';
    default:
      return 'month';
  }
}
```

### Chargement des données
```dart
Future<void> _loadChartsDataIfNeeded(BudgetProvider provider) async {
  final periodFormat = _getPeriodFormat(_selectedPeriod);
  
  final futures = <Future>[];
  
  if (hasBarChart || hasSavingsCard || ...) {
    futures.add(provider.loadMonthlySummary(period: periodFormat));
  }
  
  if (hasPieChart || hasTopCategoryCard) {
    futures.add(provider.loadCategoryExpenses(period: periodFormat));
  }
  
  if (futures.isNotEmpty) {
    await Future.wait(futures);
  }
}
```

## 📝 Notes importantes

1. **Backend doit gérer les filtres** : Pour `3months` et `6months`, le backend doit filtrer les données sur les 3 ou 6 derniers mois même si `period=month` est envoyé.

2. **Weekly** : Actuellement, `weekly` est converti en `day` avec un filtre de 7 jours. Le backend peut être adapté pour mieux gérer cette période.

3. **Pas de cache** : À chaque changement de période, les données sont rechargées depuis le backend pour garantir la fraîcheur des données.

4. **Skeleton loader** : Pendant le chargement, un skeleton loader est affiché pour améliorer l'UX.

