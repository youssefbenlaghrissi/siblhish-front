# 📡 Documentation Complète des APIs

## 📋 Vue d'ensemble

Ce document décrit **toutes les APIs** utilisées dans l'application Siblhish, leur fonction, et **quand elles sont appelées**.

**URL de base:** `https://siblhish-api-production.up.railway.app/api/v1`

---

## 🏠 APIs Accueil (Home)

### 1. `GET /home/balance/{userId}`

**Service:** `HomeService.getBalance()`

**Description:** Récupère le solde total, les revenus totaux et les dépenses totales de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart`
- **Conditions:**
  - `!_homeDataLoaded` (données pas encore chargées)
  - `!_isLoadingHomeData` (pas déjà en cours de chargement)

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'une transaction**
  - Méthodes: `addExpense()`, `updateExpense()`, `deleteExpense()`, `addIncome()`, `updateIncome()`, `deleteIncome()`
- **Après confirmation d'un paiement planifié**
  - Méthode: `confirmScheduledPayment()`
- **Rafraîchissement manuel (pull-to-refresh)**
  - Méthode: `_onRefresh()` dans `home_screen.dart`

**Données retournées:**
- `balance`: Solde total
- `totalIncome`: Revenus totaux
- `totalExpense`: Dépenses totales

---

### 2. `GET /home/transactions/{userId}?limit={limit}&type={type}&dateRange={dateRange}&startDate={startDate}&endDate={endDate}&minAmount={minAmount}&maxAmount={maxAmount}`

**Service:** `HomeService.getRecentTransactions()`

**Description:** Récupère les transactions (dépenses et revenus) avec support de filtres. **API unifiée utilisée pour HomeScreen et TransactionsScreen.**

**Quand est-elle appelée ?**

#### ✅ **Chargement initial - HomeScreen**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart` → `loadRecentTransactions(limit: 3)`
- **Paramètres par défaut:** `limit=3`

#### ✅ **Chargement initial - TransactionsScreen**
- **Déclencheur:** L'utilisateur ouvre l'écran `TransactionsScreen`
- **Méthode:** `loadFilteredTransactions()` dans `budget_provider.dart` → `HomeService.getRecentTransactions()`
- **Paramètres:** `limit=2147483647` (toutes les transactions) + filtres optionnels
- **Filtres supportés:** `type`, `dateRange`, `startDate`, `endDate`, `minAmount`, `maxAmount`

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'une transaction**
  - Méthodes: `addExpense()`, `updateExpense()`, `deleteExpense()`, `addIncome()`, `updateIncome()`, `deleteIncome()`
- **Après confirmation d'un paiement planifié**
  - Méthode: `confirmScheduledPayment()`
- **Rafraîchissement manuel (pull-to-refresh)**
  - HomeScreen: `_onRefresh()` dans `home_screen.dart`
  - TransactionsScreen: `_onRefresh()` dans `transactions_screen.dart` → `loadFilteredTransactions()`
- **Application de filtres**
  - HomeScreen: `loadRecentTransactions(limit: 3)` avec filtres
  - TransactionsScreen: `_applyFilters()` → `loadFilteredTransactions()` avec tous les filtres

**Données retournées:**
- Liste des transactions (dépenses et revenus) avec catégories imbriquées
- Format unifié avec champ `type` pour distinguer `expense` et `income`

---

## 📊 APIs Statistiques

### 3. `GET /statistics/all-statistics/{userId}?startDate={startDate}&endDate={endDate}`

**Service:** `StatisticsService.getAllStatistics()`

**Description:** Récupère **toutes les statistiques** en un seul appel (optimisé - remplace 6 appels séparés).

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `StatisticsScreen` pour la première fois
- **Méthode:** `_loadChartsDataIfNeeded()` dans `statistics_screen.dart`
- **Conditions:**
  - `widget.isVisible == true` (écran visible)
  - `!_statisticsDataLoaded` (données pas encore chargées)
  - `!_isLoadingStatistics` (pas déjà en cours de chargement)

#### ✅ **Rechargement**
- **Changement de période dans le filtre**
  - Méthode: `_onPeriodChanged()` → `_loadChartsDataIfNeeded()`
  - Périodes: daily, weekly, monthly, 3months, 6months
- **Navigation précédent/suivant dans le filtre**
  - Méthodes: `_previousPeriod()` ou `_nextPeriod()` → `_loadChartsDataIfNeeded()`
- **L'écran redevient visible**
  - Méthode: `didUpdateWidget()` → `_loadStatisticsDataIfNeeded()` → `_loadChartsDataIfNeeded()`
- **Rafraîchissement manuel (pull-to-refresh)**
  - Méthode: `_onRefresh()` → `_loadChartsDataIfNeeded()`

**Données retournées:**
- `monthlySummary`: Liste des revenus/dépenses par période (pour bar chart, savings, averages)
- `categoryExpenses`: Dépenses par catégorie (pour pie chart)
- `budgetStatistics`: Toutes les statistiques budgets (Budget vs Réel, Top Catégories, Efficacité, Répartition)

**Optimisation:** ✅ **1 seul appel API** au lieu de 6 appels séparés (réduction de 83%)

---

## 💸 APIs Transactions - Dépenses (Expenses)

### 4. `GET /expenses/user/{userId}`

**Service:** `ExpenseService.getExpenses()`

**Description:** Récupère toutes les dépenses de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `StatisticsScreen` avec certaines cartes sélectionnées
- **Méthode:** `_loadExpenses()` dans `budget_provider.dart`
- **Conditions:**
  - Si la carte `topExpenseCard` est sélectionnée dans les statistiques
  - Ou si certaines cartes statistiques nécessitent les données de dépenses
  - Appelé via `loadStatisticsData()` dans `budget_provider.dart`

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'une dépense**
  - Méthodes: `addExpense()`, `updateExpense()`, `deleteExpense()`
  - **Note:** Ces opérations rechargent aussi les données home via `loadRecentTransactions()`

**Données retournées:**
- Liste complète des dépenses de l'utilisateur avec catégories

---

### 5. `POST /expenses`

**Service:** `ExpenseService.createExpense()`

**Description:** Crée une nouvelle dépense.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur crée une nouvelle dépense
- **Méthode:** `addExpense()` dans `budget_provider.dart`
- **Après création:** Recharge automatique des données home et transactions

**Données envoyées:**
- `userId`, `amount`, `categoryId`, `date`, `description`, `location`, `paymentMethod`, etc.

**Données retournées:**
- Dépense créée avec ID généré

---

### 6. `PUT /expenses/{expenseId}`

**Service:** `ExpenseService.updateExpense()`

**Description:** Met à jour une dépense existante.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie une dépense existante
- **Méthode:** `updateExpense()` dans `budget_provider.dart`
- **Après modification:** Recharge automatique des données home et transactions

**Données envoyées:**
- Tous les champs modifiables de la dépense

**Données retournées:**
- Dépense mise à jour

---

### 7. `DELETE /expenses/{expenseId}`

**Service:** `ExpenseService.deleteExpense()`

**Description:** Supprime une dépense.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime une dépense
- **Méthode:** `deleteExpense()` dans `budget_provider.dart`
- **Après suppression:** Recharge automatique des données home et transactions

---

## 💰 APIs Transactions - Revenus (Incomes)

### 8. `GET /incomes/user/{userId}`

**Service:** `IncomeService.getIncomes()`

**Description:** Récupère tous les revenus de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `StatisticsScreen` avec certaines cartes sélectionnées
- **Méthode:** `_loadIncomes()` dans `budget_provider.dart`
- **Conditions:**
  - Si la carte `transactionCountCard` est sélectionnée dans les statistiques
  - Ou si certaines cartes statistiques nécessitent les données de revenus
  - Appelé via `loadStatisticsData()` dans `budget_provider.dart`

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'un revenu**
  - Méthodes: `addIncome()`, `updateIncome()`, `deleteIncome()`
  - **Note:** Ces opérations rechargent aussi les données home via `loadRecentTransactions()`

**Données retournées:**
- Liste complète des revenus de l'utilisateur

---

### 9. `POST /incomes`

**Service:** `IncomeService.createIncome()`

**Description:** Crée un nouveau revenu.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur crée un nouveau revenu
- **Méthode:** `addIncome()` dans `budget_provider.dart`
- **Après création:** Recharge automatique des données home et transactions

**Données envoyées:**
- `userId`, `amount`, `date`, `description`, `source`, `paymentMethod`, etc.

**Données retournées:**
- Revenu créé avec ID généré

---

### 10. `PUT /incomes/{incomeId}`

**Service:** `IncomeService.updateIncome()`

**Description:** Met à jour un revenu existant.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie un revenu existant
- **Méthode:** `updateIncome()` dans `budget_provider.dart`
- **Après modification:** Recharge automatique des données home et transactions

**Données retournées:**
- Revenu mis à jour

---

### 11. `DELETE /incomes/{incomeId}`

**Service:** `IncomeService.deleteIncome()`

**Description:** Supprime un revenu.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime un revenu
- **Méthode:** `deleteIncome()` dans `budget_provider.dart`
- **Après suppression:** Recharge automatique des données home et transactions

---

## 💰 APIs Budgets

### 12. `GET /budgets/user/{userId}`

**Service:** `BudgetService.getBudgets()`

**Description:** Récupère tous les budgets de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `ProfileScreen` (Budgets)
- **Méthode:** `loadBudgetsIfNeeded()` dans `budget_provider.dart`
- **Comportement:** L'appel est effectué **à chaque ouverture** de l'écran, sans vérification `isEmpty`
- **Moment:** Dans `initState()` de `profile_screen.dart`

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'un budget**
  - Méthodes: `addBudget()`, `updateBudget()`, `deleteBudget()`
- **Changement de mois sélectionné**
  - Méthode: `_selectMonth()` dans `profile_screen.dart`
  - **Quand:** L'utilisateur change le mois affiché
- **Rafraîchissement manuel**
  - Méthode: `_onRefresh()` dans `profile_screen.dart`

**Données retournées:**
- Liste des budgets de l'utilisateur avec catégories

---

### 17. `POST /budgets`

**Service:** `BudgetService.createBudget()`

**Description:** Crée un nouveau budget.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur crée un nouveau budget
- **Méthode:** `addBudget()` dans `budget_provider.dart`
- **Après création:** Recharge automatique de la liste des budgets

**Données envoyées:**
- `userId`, `categoryId`, `amount`, `startDate`, `endDate`, `isRecurring`, etc.

**Données retournées:**
- Budget créé avec ID généré

---

### 18. `PUT /budgets/{budgetId}`

**Service:** `BudgetService.updateBudget()`

**Description:** Met à jour un budget existant.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie un budget existant (ex: dans `EditBudgetModal`)
- **Méthode:** `updateBudget()` dans `budget_provider.dart`
- **Après modification:** Recharge automatique de la liste des budgets

**Données retournées:**
- Budget mis à jour

---

### 19. `DELETE /budgets/{budgetId}`

**Service:** `BudgetService.deleteBudget()`

**Description:** Supprime un budget.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime un budget (ex: dans `EditBudgetModal`)
- **Méthode:** `deleteBudget()` dans `budget_provider.dart`
- **Après suppression:** Recharge automatique de la liste des budgets

---

## 🎯 APIs Objectifs (Goals)

### 16. `GET /goals/{userId}`

**Service:** `GoalService.getGoals()`

**Description:** Récupère tous les objectifs de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `GoalsScreen`
- **Méthode:** `loadGoals()` dans `budget_provider.dart` → `_loadGoals()`
- **Comportement:** L'appel est effectué **à chaque ouverture** de l'écran `GoalsScreen`
- **Moment:** 
  - Dans `initState()` de `goals_screen.dart` si l'écran est déjà visible au démarrage
  - Dans `didUpdateWidget()` de `goals_screen.dart` quand l'écran devient visible (transition de `isVisible: false` à `isVisible: true`)
- **Méthode utilisée:** `_reloadGoals()` qui force le rechargement depuis le backend (réinitialise `_goalsLoaded` pour afficher le skeleton)

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'un objectif**
  - Méthodes: `addGoal()`, `updateGoal()`, `deleteGoal()`
  - **Comportement:** Recharge automatique via `_loadGoals()` dans `budget_provider.dart`
- **Après ajout de montant à un objectif**
  - Méthode: `addAmountToGoal()`
  - **Comportement:** Recharge automatique via `_loadGoals()` dans `budget_provider.dart`
- **Après marquage d'un objectif comme atteint**
  - Méthode: `achieveGoal()`
  - **Comportement:** Recharge automatique via `_loadGoals()` dans `budget_provider.dart`

**Données retournées:**
- Liste complète des objectifs de l'utilisateur

---

### 17. `POST /goals`

**Service:** `GoalService.createGoal()`

**Description:** Crée un nouvel objectif.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur crée un nouvel objectif
- **Méthode:** `addGoal()` dans `budget_provider.dart`
- **Après création:** Recharge automatique de la liste des objectifs

**Données envoyées:**
- `userId`, `name`, `targetAmount`, `currentAmount`, `categoryId`, `deadline`, etc.

**Données retournées:**
- Objectif créé avec ID généré

---

### 18. `PUT /goals/{goalId}`

**Service:** `GoalService.updateGoal()`

**Description:** Met à jour un objectif existant.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie un objectif existant
- **Méthode:** `updateGoal()` dans `budget_provider.dart`
- **Après modification:** Recharge automatique de la liste des objectifs

**Données retournées:**
- Objectif mis à jour

---

### 19. `POST /goals/{goalId}/add-amount`

**Service:** `GoalService.addAmountToGoal()`

**Description:** Ajoute un montant à un objectif (pour suivre la progression).

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur ajoute de l'argent à un objectif
- **Méthode:** `addAmountToGoal()` dans `budget_provider.dart`
- **Après ajout:** Recharge automatique de la liste des objectifs

**Données envoyées:**
- `amount`: Montant à ajouter

**Données retournées:**
- Objectif mis à jour avec nouveau `currentAmount`

---

### 20. `POST /goals/{goalId}/achieve`

**Service:** `GoalService.achieveGoal()`

**Description:** Marque un objectif comme atteint.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur clique sur le bouton "Marquer atteint" dans la carte d'un objectif
- **Méthode:** `achieveGoal()` dans `budget_provider.dart`
- **Interface:** Dialog de confirmation dans `goals_screen.dart` (`_AchieveConfirmationDialog`)
- **Condition:** Le bouton n'est affiché que si l'objectif n'est pas déjà atteint (`!isAchieved`)
- **Après marquage:** 
  - Recharge automatique de la liste des objectifs via `_loadGoals()`
  - Affichage d'un message de succès
  - L'objectif affiche maintenant le badge "Atteint"

**Données retournées:**
- Objectif mis à jour avec `isAchieved: true`

---

### 21. `DELETE /goals/{goalId}`

**Service:** `GoalService.deleteGoal()`

**Description:** Supprime un objectif.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime un objectif
- **Méthode:** `deleteGoal()` dans `budget_provider.dart`
- **Après suppression:** Recharge automatique de la liste des objectifs

---

## 📁 APIs Catégories

### 22. `GET /categories`

**Service:** `CategoryService.getAllCategories()`

**Description:** Récupère toutes les catégories (par défaut + personnalisées).

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre n'importe quel écran nécessitant les catégories par défaut
- **Méthode:** `loadCategoriesIfNeeded()` dans `budget_provider.dart`
- **Conditions:** Même que `getUserCategories()`

#### ✅ **Rechargement**
- **Rafraîchissement manuel**
  - Méthode: `reloadCategories()` dans `budget_provider.dart`

**Données retournées:**
- Liste de toutes les catégories (par défaut + personnalisées)

---

## 📅 APIs Paiements Planifiés (Scheduled Payments)

### 23. `GET /scheduled-payments/user/{userId}`

**Service:** `ScheduledPaymentService.getScheduledPayments()`

**Description:** Récupère tous les paiements planifiés de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen`
- **Méthode:** `loadHomeData()` dans `budget_provider.dart`
- **Conditions:** Même que `getBalance()`

#### ✅ **Rechargement**
- **Après ajout/modification/suppression d'un paiement planifié**
  - Méthodes: `addScheduledPayment()`, `updateScheduledPayment()`, `deleteScheduledPayment()`
- **Après confirmation d'un paiement planifié**
  - Méthode: `confirmScheduledPayment()`
- **Rafraîchissement manuel (pull-to-refresh)**
  - Méthode: `_onRefresh()` dans `home_screen.dart`

**Données retournées:**
- Liste complète des paiements planifiés de l'utilisateur

---

### 24. `POST /scheduled-payments`

**Service:** `ScheduledPaymentService.createScheduledPayment()`

**Description:** Crée un nouveau paiement planifié.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur crée un nouveau paiement planifié
- **Méthode:** `addScheduledPayment()` dans `budget_provider.dart`
- **Après création:** Recharge automatique de la liste des paiements planifiés

**Données envoyées:**
- `userId`, `title`, `amount`, `dueDate`, `categoryId`, `isRecurring`, `recurrenceType`, etc.

**Données retournées:**
- Paiement planifié créé avec ID généré

---

### 25. `PUT /scheduled-payments/{paymentId}`

**Service:** `ScheduledPaymentService.updateScheduledPayment()`

**Description:** Met à jour un paiement planifié existant.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie un paiement planifié existant
- **Méthode:** `updateScheduledPayment()` dans `budget_provider.dart`
- **Après modification:** Recharge automatique de la liste des paiements planifiés

**Données retournées:**
- Paiement planifié mis à jour

---

### 26. `DELETE /scheduled-payments/{paymentId}`

**Service:** `ScheduledPaymentService.deleteScheduledPayment()`

**Description:** Supprime un paiement planifié.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime un paiement planifié
- **Méthode:** `deleteScheduledPayment()` dans `budget_provider.dart`
- **Après suppression:** Recharge automatique de la liste des paiements planifiés

---

### 27. `PUT /scheduled-payments/{paymentId}/pay?paymentDate={paymentDate}`

**Service:** `ScheduledPaymentService.markAsPaid()`

**Description:** Marque un paiement planifié comme payé et crée automatiquement la transaction correspondante.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur confirme qu'un paiement planifié a été payé
- **Méthode:** `confirmScheduledPayment()` dans `budget_provider.dart`
- **Après confirmation:** 
  - Recharge automatique de la liste des paiements planifiés
  - Recharge automatique des données home (balance, transactions)

**Paramètres:**
- `paymentDate`: Date de paiement au format ISO (YYYY-MM-DDTHH:mm:ss)

**Données retournées:**
- Paiement planifié mis à jour avec `isPaid: true`
- Transaction créée automatiquement

---

## ⭐ APIs Favoris (Favorites)

### 28. `GET /favorites/{userId}/type/{type}`

**Service:** `FavoriteService.getFavoritesByType()`

**Description:** Récupère les favoris selon un type spécifique.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran `HomeScreen` ou `StatisticsScreen`
- **Méthode:** `_loadCardFavoritesInBackground()` dans `budget_provider.dart`
- **Conditions:**
  - `!_cardFavoritesLoaded` (favoris pas encore chargés)
  - Type: `CARD` (pour les préférences des cartes statistiques)

#### ✅ **Rechargement**
- **Après modification des préférences des cartes**
  - Méthode: `updateStatisticsCardsPreferences()` dans `budget_provider.dart`
  - Type: `CARD`
- **Après modification des couleurs de catégories**
  - Méthode: `updateCategoryColor()` dans `budget_provider.dart`
  - Type: `CATEGORY_COLOR`

**Types disponibles:**
- `CARD`: Préférences des cartes statistiques
- `CATEGORY_COLOR`: Couleurs personnalisées des catégories

**Données retournées:**
- Liste des favoris selon le type

---

### 29. `POST /favorites/{userId}`

**Service:** `FavoriteService.saveFavorites()`

**Description:** Sauvegarde les favoris de l'utilisateur.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur modifie ses préférences (cartes, couleurs, etc.)
- **Méthode:** `saveFavorites()` dans `favorite_service.dart`
- **Après sauvegarde:** Recharge automatique des favoris

**Données envoyées:**
- Liste des favoris avec type

**Données retournées:**
- Favoris sauvegardés

---

### 30. `DELETE /favorites/{userId}`

**Service:** `FavoriteService.deleteFavorites()`

**Description:** Supprime les favoris de l'utilisateur.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime ses préférences
- **Méthode:** `deleteFavorites()` dans `favorite_service.dart`

**Données envoyées:**
- Liste des favoris à supprimer avec type

---

## 🔔 APIs Notifications

### 31. `GET /notifications/{userId}`

**Service:** `NotificationService.getNotifications()`

**Description:** Récupère toutes les notifications de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** L'utilisateur ouvre l'écran des notifications
- **Méthode:** `getNotifications()` dans `notification_service.dart`

#### ✅ **Rechargement**
- **Rafraîchissement manuel**
  - Méthode: `_onRefresh()` dans l'écran des notifications

**Données retournées:**
- Liste des notifications de l'utilisateur

---

### 32. `GET /notifications/{userId}/unread-count`

**Service:** `NotificationService.getUnreadCount()`

**Description:** Récupère le nombre de notifications non lues.

**Quand est-elle appelée ?**
- **Appel périodique:** Vérification périodique du nombre de notifications non lues
- **Méthode:** `getUnreadCount()` dans `notification_service.dart`
- **Fréquence:** Selon l'implémentation (peut être appelé toutes les X secondes)

**Données retournées:**
- Nombre de notifications non lues

---

### 33. `PATCH /notifications/{notificationId}/read`

**Service:** `NotificationService.markAsRead()`

**Description:** Marque une notification comme lue.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur ouvre/consulte une notification
- **Méthode:** `markAsRead()` dans `notification_service.dart`
- **Après marquage:** Recharge automatique du nombre de notifications non lues

---

### 34. `PATCH /notifications/{userId}/read-all`

**Service:** `NotificationService.markAllAsRead()`

**Description:** Marque toutes les notifications comme lues.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur marque toutes les notifications comme lues
- **Méthode:** `markAllAsRead()` dans `notification_service.dart`
- **Après marquage:** Recharge automatique de la liste des notifications

---

### 35. `DELETE /notifications/{notificationId}`

**Service:** `NotificationService.deleteNotification()`

**Description:** Supprime une notification.

**Quand est-elle appelée ?**
- **Déclencheur:** L'utilisateur supprime une notification
- **Méthode:** `deleteNotification()` dans `notification_service.dart`
- **Après suppression:** Recharge automatique de la liste des notifications

---

## 👤 APIs Utilisateur

### 36. `GET /users/{userId}/profile`

**Service:** `UserService.getUserProfile()`

**Description:** Récupère le profil complet de l'utilisateur.

**Quand est-elle appelée ?**

#### ✅ **Chargement initial**
- **Déclencheur:** Initialisation de l'application
- **Méthode:** `initialize()` dans `budget_provider.dart`
- **Conditions:**
  - `_currentUser == null` (utilisateur pas encore chargé)
  - `!_isLoading` (pas déjà en cours de chargement)

#### ✅ **Rechargement**
- **Lors de l'initialisation de l'application**
  - Méthode: `initialize()` dans `budget_provider.dart`

**Données retournées:**
- Profil complet de l'utilisateur (nom, email, photo, préférences, etc.)

---

## 🎴 APIs Cartes (Cards)

### 36. `GET /cards`

**Service:** `CardService.getCards()`

**Description:** Récupère les cartes disponibles (pour les statistiques, etc.).

**Quand est-elle appelée ?**
- Lors de l'affichage des options de cartes disponibles
- Pour la configuration des cartes statistiques

**Données retournées:**
- Liste des cartes disponibles avec leurs configurations

---

## 📊 Résumé des Appels API par Écran

### 🏠 HomeScreen
- `GET /home/balance/{userId}` - Au chargement et après modifications
- `GET /home/transactions/{userId}` - Au chargement et après modifications
- `GET /scheduled-payments/user/{userId}` - Au chargement et après modifications
- `GET /favorites/{userId}/type/CARD` - Chargement des préférences des cartes

### 📊 StatisticsScreen
- `GET /statistics/all-statistics/{userId}` - Au chargement, changement de période, navigation, rafraîchissement
- `GET /expenses/user/{userId}` - Si nécessaire pour certaines cartes
- `GET /incomes/user/{userId}` - Si nécessaire pour certaines cartes
- `GET /favorites/{userId}/type/CARD` - Chargement des préférences des cartes

### 💸 TransactionsScreen
- `GET /home/transactions/{userId}` - Au chargement avec filtres (via `loadFilteredTransactions()`), après modifications, rafraîchissement et changement de filtres

### 💰 ProfileScreen (Budgets)
- `GET /budgets/user/{userId}` - À chaque ouverture de l'écran et après modifications

### 🎯 GoalsScreen
- `GET /goals/{userId}` - À chaque ouverture de l'écran et après modifications

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
- Exemple: Les dépenses et revenus ne sont chargés que si certaines cartes statistiques sont sélectionnées

---

## 📝 Notes Importantes

1. **Tous les appels API passent par `ApiService`** qui gère:
   - Les headers par défaut (`Content-Type: application/json`, `Accept: application/json`)
   - La gestion des erreurs
   - Les timeouts (10 secondes)
   - Le logging (debugPrint)

2. **Les appels API sont asynchrones** et utilisent `Future` pour ne pas bloquer l'UI

3. **Les erreurs sont gérées** dans chaque méthode avec des try-catch

4. **Les données sont mises en cache** dans le `BudgetProvider` pour éviter les rechargements inutiles

5. **Format de réponse standard:**
   ```json
   {
     "status": "success",
     "data": { ... },
     "message": "Operation successful",
     "errors": null
   }
   ```

6. **Rechargement automatique:** Après chaque opération CRUD (Create, Read, Update, Delete), les données concernées sont automatiquement rechargées pour maintenir la cohérence de l'interface.

---

## 🔢 Statistiques

- **Total d'APIs:** 37 endpoints
- **APIs GET:** 18
- **APIs POST:** 7
- **APIs PUT:** 6
- **APIs DELETE:** 3
- **APIs PATCH:** 1

---

**Dernière mise à jour:** 2024

