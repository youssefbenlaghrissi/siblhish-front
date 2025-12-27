# Analyse et Optimisation des Appels API

## Problèmes identifiés

### 1. Chargement séquentiel des catégories (Profil)

**Problème actuel :**
```dart
// Dans loadCategoriesIfNeeded() et reloadCategories()
final categories = await CategoryService.getAllCategories(); // Appel 1
// ... attente ...
final categoryColors = await FavoriteService.getCategoryColors(_currentUser!.id); // Appel 2
```

**Impact :** 
- Temps total = Temps appel 1 + Temps appel 2
- Si chaque appel prend 500ms, le total = 1000ms

**Solution :** Faire les appels en parallèle avec `Future.wait()`

### 2. Chargement séquentiel dans loadCategoryExpenses (Statistiques)

**Problème actuel :**
```dart
_categoryExpenses = await StatisticsService.getExpensesByCategory(...); // Appel 1
// ... attente ...
final categoryColors = await FavoriteService.getCategoryColors(...); // Appel 2
```

**Impact :** Même problème que pour les catégories

**Solution :** Faire les appels en parallèle

### 3. Pas de cache pour les couleurs personnalisées

**Problème actuel :**
- Chaque fois qu'on charge les catégories, on refait un appel API pour les couleurs
- Même si les couleurs n'ont pas changé depuis le dernier chargement

**Impact :** Appels API redondants

**Solution :** Ajouter un cache pour les couleurs personnalisées

## Optimisations proposées

### Optimisation 1 : Chargement parallèle des catégories

**Avant :**
```dart
final categories = await CategoryService.getAllCategories();
final categoryColors = await FavoriteService.getCategoryColors(_currentUser!.id);
```

**Après :**
```dart
final results = await Future.wait([
  CategoryService.getAllCategories(),
  FavoriteService.getCategoryColors(_currentUser!.id),
]);
final categories = results[0] as List<Category>;
final categoryColors = results[1] as List<Map<String, dynamic>>;
```

**Gain estimé :** ~50% de réduction du temps (de 1000ms à 500ms si les appels sont parallèles)

### Optimisation 2 : Cache des couleurs personnalisées

**Ajouter :**
```dart
Map<String, String>? _cachedCategoryColors;
DateTime? _categoryColorsCacheTime;
static const _categoryColorsCacheDuration = Duration(minutes: 5);

Future<Map<String, String>> _getCategoryColorsCached(String userId) async {
  // Si le cache est valide, le retourner
  if (_cachedCategoryColors != null && 
      _categoryColorsCacheTime != null &&
      DateTime.now().difference(_categoryColorsCacheTime!) < _categoryColorsCacheDuration) {
    return _cachedCategoryColors!;
  }
  
  // Sinon, charger depuis l'API
  final categoryColors = await FavoriteService.getCategoryColors(userId);
  final colorMap = <String, String>{};
  for (var favorite in categoryColors) {
    final categoryId = favorite['targetEntity']?.toString();
    final color = favorite['value'] as String?;
    if (categoryId != null && color != null) {
      colorMap[categoryId] = color;
    }
  }
  
  // Mettre en cache
  _cachedCategoryColors = colorMap;
  _categoryColorsCacheTime = DateTime.now();
  
  return colorMap;
}
```

**Gain estimé :** Élimination des appels redondants lors des rechargements fréquents

### Optimisation 3 : Chargement parallèle dans loadCategoryExpenses

**Avant :**
```dart
_categoryExpenses = await StatisticsService.getExpensesByCategory(...);
final categoryColors = await FavoriteService.getCategoryColors(...);
```

**Après :**
```dart
final results = await Future.wait([
  StatisticsService.getExpensesByCategory(_currentUser!.id, period: period),
  _getCategoryColorsCached(_currentUser!.id),
]);
_categoryExpenses = results[0] as List<CategoryExpense>;
final colorMap = results[1] as Map<String, String>;
```

**Gain estimé :** ~50% de réduction du temps

## Résumé des gains

| Optimisation | Gain estimé | Impact |
|-------------|-------------|--------|
| Chargement parallèle catégories | ~50% | ⭐⭐⭐⭐⭐ |
| Cache couleurs personnalisées | Variable | ⭐⭐⭐⭐ |
| Chargement parallèle categoryExpenses | ~50% | ⭐⭐⭐⭐ |

## Recommandations

1. **Priorité haute** : Implémenter le chargement parallèle des catégories
2. **Priorité moyenne** : Ajouter le cache des couleurs personnalisées
3. **Priorité moyenne** : Optimiser loadCategoryExpenses

## Notes

- Les appels API indépendants doivent toujours être faits en parallèle
- Le cache doit avoir une durée de vie raisonnable (5 minutes suggéré)
- Le cache doit être invalidé lors de la modification des couleurs

