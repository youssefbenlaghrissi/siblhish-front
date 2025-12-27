# 📡 Appels API `/goals` - Documentation Complète

## 📋 Vue d'ensemble

Documentation complète de tous les appels à l'API `/goals` dans l'application, incluant quand, comment et pourquoi chaque appel est effectué.

---

## 🔍 Endpoints API Utilisés

### 1. **GET `/goals/{userId}`** - Récupérer les goals
### 2. **POST `/goals`** - Créer un goal
### 3. **PUT `/goals/{goalId}`** - Mettre à jour un goal
### 4. **POST `/goals/{goalId}/add-amount`** - Ajouter un montant à un goal
### 5. **POST `/goals/{goalId}/achieve`** - Marquer un goal comme atteint
### 6. **DELETE `/goals/{goalId}`** - Supprimer un goal

---

## 📍 1. GET `/goals/{userId}` - Récupérer les Goals

### **Quand est-il appelé ?**

#### ✅ **1.1. Chargement Initial (Lazy Loading)**
- **Fichier:** `lib/screens/goals_screen.dart`
- **Méthode:** `_loadGoalsIfNeeded()` (ligne 58)
- **Déclencheur:** 
  - L'utilisateur ouvre l'écran `GoalsScreen` pour la première fois
  - `initState()` si l'écran est visible au démarrage (ligne 36)
  - `didUpdateWidget()` quand l'écran devient visible (ligne 48)
- **Conditions:**
  - `!_goalsLoaded` (données pas encore chargées)
  - `!_isLoadingGoals` (pas déjà en cours de chargement)
  - `provider.currentUser != null`
  - `widget.isVisible == true`

#### ✅ **1.2. Rechargement Manuel**
- **Fichier:** `lib/screens/goals_screen.dart`
- **Méthode:** `_reloadGoals()` (ligne 81)
- **Déclencheur:**
  - L'écran devient visible (`didUpdateWidget`)
  - Force le rechargement même si les données sont déjà chargées
- **Comportement:**
  - Réinitialise `_goalsLoaded = false` pour afficher le skeleton
  - Appelle `provider.loadGoals(forceReload: true)`

#### ✅ **1.3. Après Création de Goal**
- **Fichier:** `lib/providers/budget_provider.dart`
- **Méthode:** `addGoal()` (ligne 1276)
- **Déclencheur:** Après création réussie d'un goal
- **Comportement:**
  - Appelle `_loadGoals(_currentUser!.id, forceReload: true)`
  - Recharge la liste complète depuis le backend

#### ✅ **1.4. Après Mise à Jour de Goal**
- **Fichier:** `lib/providers/budget_provider.dart`
- **Méthode:** `updateGoal()` (ligne 1300)
- **Déclencheur:** Après mise à jour réussie d'un goal
- **Comportement:**
  - Appelle `_loadGoals(_currentUser!.id, forceReload: true)`
  - Recharge la liste complète depuis le backend

#### ✅ **1.5. Après Suppression de Goal**
- **Fichier:** `lib/providers/budget_provider.dart`
- **Méthode:** `deleteGoal()` (ligne 1327)
- **Déclencheur:** Après suppression réussie d'un goal
- **Comportement:**
  - Appelle `_loadGoals(_currentUser!.id, forceReload: true)`
  - Recharge la liste complète depuis le backend

#### ✅ **1.6. Après Ajout de Montant à un Goal**
- **Fichier:** `lib/providers/budget_provider.dart`
- **Méthode:** `addAmountToGoal()` (ligne 1342)
- **Déclencheur:** Après ajout de montant à un goal
- **Comportement:**
  - Appelle `_loadGoals(userId, forceReload: true)`
  - Recharge la liste complète depuis le backend

#### ✅ **1.7. Initialisation de l'Application**
- **Fichier:** `lib/providers/budget_provider.dart`
- **Méthode:** `initialize()` (ligne 444)
- **Déclencheur:** Au démarrage de l'application
- **Comportement:**
  - Appelle `loadGoals()` si `forceReload = false`
  - Charge les goals en parallèle avec d'autres données

### **Code Source**

```dart
// lib/providers/budget_provider.dart
Future<void> _loadGoals(String userId, {bool forceReload = false}) async {
  if (!forceReload && _goalsLoaded) {
    return; // Déjà chargé, ne pas recharger
  }
  
  try {
    debugPrint('📤 Appel API: GET /goals/$userId');
    _goals.clear();
    _goals.addAll(await GoalService.getGoals(userId));
    _goalsLoaded = true;
    notifyListeners();
  } catch (e) {
    _goals.clear();
    _goalsLoaded = false;
    rethrow;
  }
}
```

### **Paramètres Optionnels**
- `achieved`: Filtrer par statut (atteint/non atteint)
- `categoryId`: Filtrer par catégorie (non utilisé actuellement)

---

## 📍 2. POST `/goals` - Créer un Goal

### **Quand est-il appelé ?**

#### ✅ **2.1. Création d'un Nouveau Goal**
- **Fichier:** `lib/widgets/add_goal_modal.dart`
- **Méthode:** `_submit()` (ligne 50)
- **Déclencheur:** 
  - L'utilisateur clique sur "Créer l'objectif" dans le modal
  - Le formulaire est valide
- **Données Envoyées:**
  ```dart
  {
    'userId': int,
    'name': string,
    'description': string? (optionnel),
    'targetAmount': double,
    'targetDate': string? (optionnel, format: YYYY-MM-DD),
    'categoryId': int? (optionnel), // ✅ NOUVEAU
  }
  ```
- **Après Création:**
  - Appelle `GET /goals/{userId}` pour recharger la liste
  - Ferme le modal
  - Affiche un message de succès

### **Code Source**

```dart
// lib/providers/budget_provider.dart
Future<void> addGoal(Goal goal) async {
  try {
    final goalData = {
      'userId': int.tryParse(goal.userId) ?? goal.userId,
      'name': goal.name,
      'description': goal.description,
      'targetAmount': goal.targetAmount,
      'targetDate': goal.targetDate?.toIso8601String().split('T')[0],
      'categoryId': goal.categoryId != null 
          ? (int.tryParse(goal.categoryId!) ?? goal.categoryId) 
          : null, // ✅ Optionnel
    };
    await GoalService.createGoal(goalData);
    // Recharger la liste
    if (_currentUser != null) {
      await _loadGoals(_currentUser!.id, forceReload: true);
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

---

## 📍 3. PUT `/goals/{goalId}` - Mettre à Jour un Goal

### **Quand est-il appelé ?**

#### ✅ **3.1. Modification d'un Goal Existant**
- **Fichier:** `lib/widgets/edit_goal_modal.dart`
- **Méthode:** `_submit()` (ligne 62)
- **Déclencheur:**
  - L'utilisateur clique sur "Enregistrer" dans le modal d'édition
  - Le formulaire est valide
- **Données Envoyées:**
  ```dart
  {
    'userId': int,
    'name': string,
    'description': string? (optionnel),
    'targetAmount': double,
    'currentAmount': double,
    'targetDate': string? (optionnel, format: YYYY-MM-DD),
    'categoryId': int? (optionnel), // ✅ NOUVEAU
  }
  ```
- **Après Mise à Jour:**
  - Appelle `GET /goals/{userId}` pour recharger la liste
  - Ferme le modal
  - Affiche un message de succès

### **Code Source**

```dart
// lib/providers/budget_provider.dart
Future<void> updateGoal(Goal goal) async {
  try {
    final goalData = {
      'userId': int.tryParse(goal.userId) ?? goal.userId,
      'name': goal.name,
      'description': goal.description,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'targetDate': goal.targetDate?.toIso8601String().split('T')[0],
      'categoryId': goal.categoryId != null 
          ? (int.tryParse(goal.categoryId!) ?? goal.categoryId) 
          : null, // ✅ Optionnel
    };
    await GoalService.updateGoal(goal.id, goalData);
    // Recharger la liste
    if (_currentUser != null) {
      await _loadGoals(_currentUser!.id, forceReload: true);
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

---

## 📍 4. POST `/goals/{goalId}/add-amount` - Ajouter un Montant

### **Quand est-il appelé ?**

#### ✅ **4.1. Ajout de Montant à un Goal**
- **Fichier:** `lib/screens/goals_screen.dart`
- **Méthode:** `_showAddAmountDialog()` → `addAmountToGoal()` (ligne 625)
- **Déclencheur:**
  - L'utilisateur clique sur "Ajouter" dans la carte de goal
  - Saisit un montant et clique sur "Ajouter" dans le dialog
- **Données Envoyées:**
  ```dart
  {
    'amount': double,
  }
  ```
- **Après Ajout:**
  - Appelle `GET /goals/{userId}` pour recharger la liste
  - Ferme le dialog
  - Affiche un message de succès

### **Code Source**

```dart
// lib/providers/budget_provider.dart
Future<void> addAmountToGoal(String goalId, double amount) async {
  try {
    await GoalService.addAmountToGoal(goalId, amount);
    // Recharger la liste
    if (_currentUser != null) {
      final userId = _currentUser!.id;
      await _loadGoals(userId, forceReload: true);
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

---

## 📍 5. POST `/goals/{goalId}/achieve` - Marquer comme Atteint

### **Quand est-il appelé ?**

#### ⚠️ **5.1. Non Utilisé Actuellement**
- **Fichier:** Aucun
- **Méthode:** `achieveGoal()` existe dans `GoalService` mais n'est pas appelée
- **Statut:** API disponible mais non utilisée dans l'UI

### **Code Source (Disponible mais Non Utilisé)**

```dart
// lib/services/goal_service.dart
static Future<Goal> achieveGoal(String goalId) async {
  final response = await ApiService.post('/goals/$goalId/achieve', {});
  final data = response['data'] as Map<String, dynamic>;
  return Goal.fromJson(data);
}
```

---

## 📍 6. DELETE `/goals/{goalId}` - Supprimer un Goal

### **Quand est-il appelé ?**

#### ✅ **6.1. Suppression d'un Goal**
- **Fichier:** `lib/screens/goals_screen.dart`
- **Méthode:** `_showDeleteConfirmationDialog()` → `_deleteGoal()` → `deleteGoal()` (ligne 707)
- **Déclencheur:**
  - L'utilisateur clique sur l'icône de suppression dans la carte de goal
  - Confirme la suppression dans le dialog
- **Après Suppression:**
  - Appelle `GET /goals/{userId}` pour recharger la liste
  - Ferme le dialog
  - Affiche un message de succès

### **Code Source**

```dart
// lib/providers/budget_provider.dart
Future<void> deleteGoal(String id) async {
  try {
    await GoalService.deleteGoal(id);
    // Recharger la liste
    if (_currentUser != null) {
      await _loadGoals(_currentUser!.id, forceReload: true);
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

---

## 📊 Résumé des Appels

| Endpoint | Méthode | Quand | Fréquence |
|----------|---------|-------|-----------|
| `GET /goals/{userId}` | GET | Chargement initial, après CRUD | ⭐⭐⭐⭐⭐ Très fréquent |
| `POST /goals` | POST | Création de goal | ⭐⭐⭐ Moyen |
| `PUT /goals/{goalId}` | PUT | Modification de goal | ⭐⭐⭐ Moyen |
| `POST /goals/{goalId}/add-amount` | POST | Ajout de montant | ⭐⭐⭐ Moyen |
| `POST /goals/{goalId}/achieve` | POST | ❌ Non utilisé | ⭐ Aucun |
| `DELETE /goals/{goalId}` | DELETE | Suppression de goal | ⭐⭐ Rare |

---

## 🔄 Flux de Données

### **Chargement Initial**
```
GoalsScreen.initState() 
  → _loadGoalsIfNeeded() 
    → provider.loadGoals() 
      → _loadGoals() 
        → GoalService.getGoals() 
          → GET /goals/{userId}
```

### **Création de Goal**
```
AddGoalModal._submit() 
  → provider.addGoal() 
    → GoalService.createGoal() 
      → POST /goals
    → _loadGoals(forceReload: true) 
      → GET /goals/{userId}
```

### **Modification de Goal**
```
EditGoalModal._submit() 
  → provider.updateGoal() 
    → GoalService.updateGoal() 
      → PUT /goals/{goalId}
    → _loadGoals(forceReload: true) 
      → GET /goals/{userId}
```

### **Suppression de Goal**
```
_DeleteConfirmationDialog._deleteGoal() 
  → provider.deleteGoal() 
    → GoalService.deleteGoal() 
      → DELETE /goals/{goalId}
    → _loadGoals(forceReload: true) 
      → GET /goals/{userId}
```

### **Ajout de Montant**
```
_GoalCard._showAddAmountDialog() 
  → provider.addAmountToGoal() 
    → GoalService.addAmountToGoal() 
      → POST /goals/{goalId}/add-amount
    → _loadGoals(forceReload: true) 
      → GET /goals/{userId}
```

---

## ⚠️ Points d'Attention

### **1. Rechargement Systématique**
- **Problème:** Après chaque opération CRUD, la liste complète est rechargée
- **Impact:** Appel API supplémentaire même si la réponse contient déjà les données
- **Optimisation Possible:** Utiliser la réponse de l'API pour mettre à jour localement

### **2. Lazy Loading Strict**
- **Comportement:** Les goals ne sont chargés que quand l'écran devient visible
- **Avantage:** Économise les appels API inutiles
- **Inconvénient:** L'utilisateur doit attendre le chargement à chaque ouverture

### **3. API `achieveGoal` Non Utilisée**
- **Statut:** L'API existe mais n'est pas utilisée dans l'UI
- **Recommandation:** Implémenter un bouton "Marquer comme atteint" dans la carte de goal

---

## ✅ Conclusion

L'API `/goals` est appelée dans les cas suivants :

1. **GET** : Chargement initial, après chaque opération CRUD
2. **POST** : Création de goal
3. **PUT** : Modification de goal
4. **POST /add-amount** : Ajout de montant
5. **DELETE** : Suppression de goal
6. **POST /achieve** : ❌ Non utilisé

**Total d'appels API :** ~5-10 par session utilisateur (selon les actions)

