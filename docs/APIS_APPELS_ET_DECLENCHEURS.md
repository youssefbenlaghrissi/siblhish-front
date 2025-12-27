# 📡 APIs Appelées et Déclencheurs

## 📋 Vue d'ensemble

Ce document liste toutes les APIs appelées dans l'application, quand elles sont appelées et quand elles sont rappelées.

---

## 🎯 APIs Statistiques

### 1. `GET /statistics/all-statistics/{userId}?startDate={startDate}&endDate={endDate}`

**Service:** `StatisticsService.getAllStatistics()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `StatisticsScreen` pour la première fois
- **Méthode:** `_loadChartsDataIfNeeded()` dans `statistics_screen.dart`
- **Conditions:**
  - `widget.isVisible == true` (écran visible)
  - `!_statisticsDataLoaded` (données pas encore chargées)
  - `!_isLoadingStatistics` (pas déjà en cours de chargement)
- **Moment:** Dans `initState()` via `addPostFrameCallback()`

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Changement de période dans le filtre
  - **Méthode:** `_onPeriodChanged()` → `_loadChartsDataIfNeeded()`
  - **Quand:** Utilisateur sélectionne une nouvelle période (daily, weekly, monthly, 3months, 6months)
  
- **Déclencheur 2:** Navigation précédent/suivant dans le filtre
  - **Méthode:** `_previousPeriod()` ou `_nextPeriod()` → `_loadChartsDataIfNeeded()`
  - **Quand:** Utilisateur clique sur les chevrons pour naviguer entre les périodes
  
- **Déclencheur 3:** L'écran redevient visible
  - **Méthode:** `didUpdateWidget()` → `_loadStatisticsDataIfNeeded()` → `_loadChartsDataIfNeeded()`
  - **Quand:** L'utilisateur revient sur l'écran Statistiques depuis un autre onglet

- **Déclencheur 4:** Rafraîchissement manuel (pull-to-refresh)
  - **Méthode:** `_onRefresh()` → `_loadChartsDataIfNeeded()`
  - **Quand:** L'utilisateur fait un geste de rafraîchissement

**Données retournées:**
- `monthlySummary`: Liste des revenus/dépenses par période (pour bar chart, savings, averages)
- `categoryExpenses`: Dépenses par catégorie (pour pie chart)
- `budgetStatistics`: Toutes les statistiques budgets (Budget vs Réel, Top Catégories, Efficacité, Répartition)

**Optimisation:** 
- ✅ **1 seul appel API** au lieu de 6 appels séparés
- ✅ Réduit la latence et améliore les performances

---

## 🏠 APIs Accueil (Home)

### 2. `GET /home/balance/{userId}`

**Service:** `HomeService.getBalance()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart`
- **Conditions:**
  - `!_homeDataLoaded` (données pas encore chargées)
  - `!_isLoadingHomeData` (pas déjà en cours de chargement)

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'une transaction
  - **Méthodes:** `addExpense()`, `updateExpense()`, `deleteExpense()`, `addIncome()`, `updateIncome()`, `deleteIncome()`
  - **Quand:** L'utilisateur crée, modifie ou supprime une dépense/revenu
  
- **Déclencheur 2:** Après confirmation d'un paiement planifié
  - **Méthode:** `confirmScheduledPayment()`
  - **Quand:** L'utilisateur confirme un paiement planifié
  
- **Déclencheur 3:** Rafraîchissement manuel (pull-to-refresh)
  - **Méthode:** `_onRefresh()` dans `home_screen.dart`
  - **Quand:** L'utilisateur fait un geste de rafraîchissement

**Données retournées:**
- Balance totale, revenus totaux, dépenses totales

---

### 3. `GET /home/transactions/{userId}?limit={limit}`

**Service:** `HomeService.getRecentTransactions()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart`
- **Conditions:** Même que `getBalance()`

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'une transaction
  - **Méthodes:** `addExpense()`, `updateExpense()`, `deleteExpense()`, `addIncome()`, `updateIncome()`, `deleteIncome()`
  
- **Déclencheur 2:** Après confirmation d'un paiement planifié
  - **Méthode:** `confirmScheduledPayment()`
  
- **Déclencheur 3:** Rafraîchissement manuel (pull-to-refresh)
  - **Méthode:** `_onRefresh()` dans `home_screen.dart`
  
- **Déclencheur 4:** Application de filtres dans `HomeScreen`
  - **Méthode:** `loadRecentTransactions(limit: 3)` dans `home_screen.dart`
  - **Quand:** L'utilisateur applique des filtres (type, date, montant)

**Données retournées:**
- Liste des transactions récentes (dépenses et revenus)

---

### 4. `GET /scheduled-payments/user/{userId}`

**Service:** `ScheduledPaymentService.getScheduledPayments()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart`
- **Conditions:** Même que `getBalance()`

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'un paiement planifié
  - **Méthodes:** `addScheduledPayment()`, `updateScheduledPayment()`, `deleteScheduledPayment()`
  
- **Déclencheur 2:** Après confirmation d'un paiement planifié
  - **Méthode:** `confirmScheduledPayment()`
  
- **Déclencheur 3:** Rafraîchissement manuel (pull-to-refresh)
  - **Méthode:** `_onRefresh()` dans `home_screen.dart`

**Données retournées:**
- Liste des paiements planifiés

---

## 📊 APIs Transactions

### 5. `GET /expenses/user/{userId}`

**Service:** `ExpenseService.getExpenses()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `TransactionsScreen` ou `StatisticsScreen`
- **Méthode:** `_loadExpenses()` dans `budget_provider.dart`
- **Conditions:**
  - `_expenses.isEmpty` (liste vide)
  - Ou si la carte `topExpenseCard` est sélectionnée dans les statistiques

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'une dépense
  - **Méthodes:** `addExpense()`, `updateExpense()`, `deleteExpense()`
  
- **Déclencheur 2:** Rafraîchissement manuel dans `TransactionsScreen`
  - **Méthode:** `_onRefresh()` dans `transactions_screen.dart`
  
- **Déclencheur 3:** Changement de filtre dans `TransactionsScreen`
  - **Méthode:** `_applyFilters()` dans `transactions_screen.dart`
  - **Quand:** L'utilisateur change les filtres (type, catégorie, date, montant)

**Données retournées:**
- Liste complète des dépenses de l'utilisateur

---

### 6. `GET /incomes/user/{userId}`

**Service:** `IncomeService.getIncomes()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `TransactionsScreen` ou `StatisticsScreen`
- **Méthode:** `_loadIncomes()` dans `budget_provider.dart`
- **Conditions:**
  - `_incomes.isEmpty` (liste vide)
  - Ou si la carte `transactionCountCard` est sélectionnée dans les statistiques

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'un revenu
  - **Méthodes:** `addIncome()`, `updateIncome()`, `deleteIncome()`
  
- **Déclencheur 2:** Rafraîchissement manuel dans `TransactionsScreen`
  - **Méthode:** `_onRefresh()` dans `transactions_screen.dart`
  
- **Déclencheur 3:** Changement de filtre dans `TransactionsScreen`
  - **Méthode:** `_applyFilters()` dans `transactions_screen.dart`

**Données retournées:**
- Liste complète des revenus de l'utilisateur

---

## 🎯 APIs Objectifs (Goals)

### 7. `GET /goals/{userId}`

**Service:** `GoalService.getGoals()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `StatisticsScreen` avec la carte `goalsProgressCard` sélectionnée
- **Méthode:** `_loadGoals()` dans `budget_provider.dart`
- **Conditions:**
  - `_goals.isEmpty` (liste vide)
  - Et la carte `goalsProgressCard` est sélectionnée

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'un objectif
  - **Méthodes:** `addGoal()`, `updateGoal()`, `deleteGoal()`
  
- **Déclencheur 2:** Après ajout de montant à un objectif
  - **Méthode:** `addAmountToGoal()`
  
- **Déclencheur 3:** Après marquage d'un objectif comme atteint
  - **Méthode:** `achieveGoal()`

**Données retournées:**
- Liste des objectifs de l'utilisateur

---

## 📁 APIs Catégories

### 8. `GET /categories/{userId}`

**Service:** `CategoryService.getUserCategories()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre n'importe quel écran nécessitant les catégories
- **Méthode:** `loadCategoriesIfNeeded()` dans `budget_provider.dart`
- **Conditions:**
  - `!_categoriesLoaded` (catégories pas encore chargées)
  - `!_isLoadingCategories` (pas déjà en cours de chargement)

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'une catégorie
  - **Méthodes:** `addCategory()`, `updateCategory()`, `deleteCategory()`
  
- **Déclencheur 2:** Rafraîchissement manuel
  - **Méthode:** `reloadCategories()` dans `budget_provider.dart`
  - **Quand:** L'utilisateur force le rechargement

**Données retournées:**
- Liste des catégories personnalisées de l'utilisateur

---

### 9. `GET /categories`

**Service:** `CategoryService.getAllCategories()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre n'importe quel écran nécessitant les catégories par défaut
- **Méthode:** `loadCategoriesIfNeeded()` dans `budget_provider.dart`
- **Conditions:** Même que `getUserCategories()`

#### ✅ **Rappel (Rechargement)**
- **Déclencheur:** Rafraîchissement manuel
  - **Méthode:** `reloadCategories()` dans `budget_provider.dart`

**Données retournées:**
- Liste de toutes les catégories (par défaut + personnalisées)

---

## 💰 APIs Budgets

### 10. `GET /budgets/user/{userId}`

**Service:** `BudgetService.getBudgets()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `BudgetsScreen`
- **Méthode:** `loadBudgets()` dans `budget_provider.dart`
- **Conditions:**
  - `_budgets.isEmpty` (liste vide)
  - Ou si les budgets ne sont pas encore chargés

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après ajout/modification/suppression d'un budget
  - **Méthodes:** `addBudget()`, `updateBudget()`, `deleteBudget()`
  
- **Déclencheur 2:** Rafraîchissement manuel dans `BudgetsScreen`
  - **Méthode:** `_onRefresh()` dans `budgets_screen.dart`

**Données retournées:**
- Liste des budgets de l'utilisateur

---

## ⭐ APIs Favoris

### 11. `GET /favorites/{userId}/type/{type}`

**Service:** `FavoriteService.getFavoritesByType()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen` ou `StatisticsScreen`
- **Méthode:** `_loadCardFavoritesInBackground()` dans `budget_provider.dart`
- **Conditions:**
  - `!_cardFavoritesLoaded` (favoris pas encore chargés)
  - Type: `CARD` (pour les préférences des cartes statistiques)

#### ✅ **Rappel (Rechargement)**
- **Déclencheur 1:** Après modification des préférences des cartes
  - **Méthode:** `updateStatisticsCardsPreferences()` dans `budget_provider.dart`
  - **Quand:** L'utilisateur modifie les cartes sélectionnées dans `StatisticsScreen`
  
- **Déclencheur 2:** Après modification des couleurs de catégories
  - **Méthode:** `updateCategoryColor()` dans `budget_provider.dart`
  - **Type:** `CATEGORY_COLOR`

**Données retournées:**
- Liste des favoris selon le type (CARD, CATEGORY_COLOR, etc.)

---

## 🔔 APIs Notifications

### 12. `GET /notifications/{userId}`

**Service:** `NotificationService.getNotifications()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** L'utilisateur ouvre l'écran des notifications
- **Méthode:** `getNotifications()` dans `notification_service.dart`
- **Conditions:** Selon l'implémentation de l'écran

#### ✅ **Rappel (Rechargement)**
- **Déclencheur:** Rafraîchissement manuel
  - **Méthode:** `_onRefresh()` dans l'écran des notifications

**Données retournées:**
- Liste des notifications de l'utilisateur

---

### 13. `GET /notifications/{userId}/unread-count`

**Service:** `NotificationService.getUnreadCount()`

**Quand est-elle appelée ?**

#### ✅ **Appel périodique**
- **Déclencheur:** Vérification périodique du nombre de notifications non lues
- **Méthode:** `getUnreadCount()` dans `notification_service.dart`
- **Fréquence:** Selon l'implémentation (peut être appelé toutes les X secondes)

**Données retournées:**
- Nombre de notifications non lues

---

## 👤 APIs Utilisateur

### 14. `GET /users/{userId}/profile`

**Service:** `UserService.getUserProfile()`

**Quand est-elle appelée ?**

#### ✅ **Premier appel (Chargement initial)**
- **Déclencheur:** Initialisation de l'application
- **Méthode:** `initialize()` dans `budget_provider.dart`
- **Conditions:**
  - `_currentUser == null` (utilisateur pas encore chargé)
  - `!_isLoading` (pas déjà en cours de chargement)

#### ✅ **Rappel (Rechargement)**
- **Déclencheur:** Après modification du profil
  - **Méthode:** `updateUserProfile()` dans `budget_provider.dart`
  - **Quand:** L'utilisateur modifie son profil

**Données retournées:**
- Profil complet de l'utilisateur

---

## 📝 APIs CRUD (Create, Read, Update, Delete)

### Dépenses (Expenses)

- **POST /expenses** - Création d'une dépense
  - **Déclencheur:** `addExpense()` dans `budget_provider.dart`
  
- **PUT /expenses/{expenseId}** - Modification d'une dépense
  - **Déclencheur:** `updateExpense()` dans `budget_provider.dart`
  
- **DELETE /expenses/{expenseId}** - Suppression d'une dépense
  - **Déclencheur:** `deleteExpense()` dans `budget_provider.dart`

### Revenus (Incomes)

- **POST /incomes** - Création d'un revenu
  - **Déclencheur:** `addIncome()` dans `budget_provider.dart`
  
- **PUT /incomes/{incomeId}** - Modification d'un revenu
  - **Déclencheur:** `updateIncome()` dans `budget_provider.dart`
  
- **DELETE /incomes/{incomeId}** - Suppression d'un revenu
  - **Déclencheur:** `deleteIncome()` dans `budget_provider.dart`

### Budgets

- **POST /budgets** - Création d'un budget
  - **Déclencheur:** `addBudget()` dans `budget_provider.dart`
  
- **PUT /budgets/{budgetId}** - Modification d'un budget
  - **Déclencheur:** `updateBudget()` dans `budget_provider.dart`
  
- **DELETE /budgets/{budgetId}** - Suppression d'un budget
  - **Déclencheur:** `deleteBudget()` dans `budget_provider.dart`

### Objectifs (Goals)

- **POST /goals** - Création d'un objectif
  - **Déclencheur:** `addGoal()` dans `budget_provider.dart`
  
- **PUT /goals/{goalId}** - Modification d'un objectif
  - **Déclencheur:** `updateGoal()` dans `budget_provider.dart`
  
- **DELETE /goals/{goalId}** - Suppression d'un objectif
  - **Déclencheur:** `deleteGoal()` dans `budget_provider.dart`
  
- **POST /goals/{goalId}/add-amount** - Ajout de montant à un objectif
  - **Déclencheur:** `addAmountToGoal()` dans `budget_provider.dart`
  
- **POST /goals/{goalId}/achieve** - Marquage d'un objectif comme atteint
  - **Déclencheur:** `achieveGoal()` dans `budget_provider.dart`

### Catégories

- **POST /categories** - Création d'une catégorie
  - **Déclencheur:** `addCategory()` dans `budget_provider.dart`
  
- **PUT /categories/{categoryId}** - Modification d'une catégorie
  - **Déclencheur:** `updateCategory()` dans `budget_provider.dart`
  
- **DELETE /categories/{categoryId}** - Suppression d'une catégorie
  - **Déclencheur:** `deleteCategory()` dans `budget_provider.dart`

### Paiements Planifiés

- **POST /scheduled-payments** - Création d'un paiement planifié
  - **Déclencheur:** `addScheduledPayment()` dans `budget_provider.dart`
  
- **PUT /scheduled-payments/{paymentId}** - Modification d'un paiement planifié
  - **Déclencheur:** `updateScheduledPayment()` dans `budget_provider.dart`
  
- **DELETE /scheduled-payments/{paymentId}** - Suppression d'un paiement planifié
  - **Déclencheur:** `deleteScheduledPayment()` dans `budget_provider.dart`
  
- **PUT /scheduled-payments/{paymentId}/confirm** - Confirmation d'un paiement planifié
  - **Déclencheur:** `confirmScheduledPayment()` dans `budget_provider.dart`

---

## 📊 Résumé des Appels API par Écran

### 🏠 HomeScreen
- `GET /home/balance/{userId}` - Au chargement et après modifications
- `GET /home/transactions/{userId}` - Au chargement et après modifications
- `GET /scheduled-payments/user/{userId}` - Au chargement et après modifications

### 📊 StatisticsScreen
- `GET /statistics/all-statistics/{userId}` - Au chargement, changement de période, navigation, rafraîchissement
- `GET /expenses/user/{userId}` - Si nécessaire pour certaines cartes
- `GET /incomes/user/{userId}` - Si nécessaire pour certaines cartes
- `GET /goals/{userId}` - Si la carte goalsProgressCard est sélectionnée

### 💸 TransactionsScreen
- `GET /expenses/user/{userId}` - Au chargement et après modifications
- `GET /incomes/user/{userId}` - Au chargement et après modifications

### 💰 BudgetsScreen
- `GET /budgets/user/{userId}` - Au chargement et après modifications

---

## 🔄 Optimisations Implémentées

### ✅ Endpoint Unifié pour Statistiques
- **Avant:** 6 appels API séparés
- **Après:** 1 seul appel API (`GET /statistics/all-statistics/{userId}`)
- **Gain:** Réduction de 83% des appels API

### ✅ Cache et Flags de Chargement
- Utilisation de flags (`_isLoading`, `_categoriesLoaded`, etc.) pour éviter les appels multiples
- Cache des données chargées pour éviter les rechargements inutiles

### ✅ Chargement Conditionnel
- Les données ne sont chargées que si elles sont nécessaires pour les cartes sélectionnées
- Exemple: Les objectifs ne sont chargés que si `goalsProgressCard` est sélectionnée

---

## 📝 Notes Importantes

1. **Tous les appels API passent par `ApiService`** qui gère:
   - Les headers par défaut
   - La gestion des erreurs
   - Les timeouts
   - Le logging (debugPrint)

2. **Les appels API sont asynchrones** et utilisent `Future` pour ne pas bloquer l'UI

3. **Les erreurs sont gérées** dans chaque méthode avec des try-catch

4. **Les données sont mises en cache** dans le `BudgetProvider` pour éviter les rechargements inutiles

