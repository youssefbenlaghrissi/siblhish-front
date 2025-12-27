import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart' as models;
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../models/scheduled_payment.dart';
import '../services/user_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/category_service.dart';
import '../services/goal_service.dart';
import '../services/home_service.dart';
import '../services/scheduled_payment_service.dart';
import '../services/statistics_service.dart';
import '../services/favorite_service.dart';
import '../services/local_storage_service.dart';
import '../services/card_service.dart';
import '../services/budget_service.dart';
import '../models/statistics.dart';
import '../models/card.dart';
import '../models/budget_vs_actual.dart';
import '../models/top_budget_category.dart';
import '../models/budget_efficiency.dart';
import '../models/budget_distribution.dart';

class BudgetProvider extends ChangeNotifier {
  // Données
  User? _currentUser;
  final List<Expense> _expenses = [];
  final List<Income> _incomes = [];
  final List<models.Category> _categories = [];
  final List<Budget> _budgets = [];
  final List<Goal> _goals = [];
  final List<ScheduledPayment> _scheduledPayments = [];
  final List<dynamic> _homeRecentTransactions = []; // Transactions récentes pour la page d'accueil
  final List<dynamic> _filteredTransactions = []; // Transactions filtrées pour l'écran Transactions

  // Données statistiques
  List<MonthlySummary> _monthlySummary = [];
  List<CategoryExpense> _categoryExpenses = [];
  List<String> _statisticsCardsPreferences = [];
  
  // Données statistiques budgets
  List<dynamic> _budgetVsActual = [];
  List<dynamic> _topBudgetCategories = [];
  dynamic _budgetEfficiency;
  List<dynamic> _budgetDistribution = [];
  bool _statisticsCardsPreferencesLoaded = false;
  List<Map<String, dynamic>> _cardFavorites = []; // Favoris complets avec ordre
  bool _cardFavoritesLoaded = false;
  List<Card> _availableCards = []; // Cartes disponibles depuis l'API
  bool _availableCardsLoaded = false;
  
  // Cache pour les couleurs personnalisées des catégories
  Map<String, String>? _cachedCategoryColors;
  DateTime? _categoryColorsCacheTime;
  static const _categoryColorsCacheDuration = Duration(minutes: 5);

  // États de chargement
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Map<String, dynamic>? _balanceData;
  bool _isLoadingCategories = false; // Flag pour éviter les appels multiples
  bool _categoriesLoaded = false; // Flag pour savoir si on a déjà chargé les catégories (ne changent pas souvent)
  bool _isLoadingStatistics = false; // Flag pour éviter les appels multiples pour les statistiques
  bool _isLoadingHomeData = false; // Flag pour éviter les appels multiples pour les données de l'accueil
  bool _isLoadingGoals = false; // Flag pour éviter les appels multiples pour les objectifs

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoadingHomeData => _isLoadingHomeData;
  bool get isLoadingStatistics => _isLoadingStatistics;
  bool get isLoadingBudgets => _isLoadingBudgets;

  // Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Les données sont déjà triées par le backend
  List<Expense> get expenses => List.from(_expenses);

  List<Income> get incomes => List.from(_incomes);

  List<models.Category> get categories => List.from(_categories);
  bool get categoriesLoaded => _categoriesLoaded;

  List<Budget> get budgets => _budgets;

  List<Goal> get goals => List.from(_goals);

  List<ScheduledPayment> get scheduledPayments => List.from(_scheduledPayments);

  // Transactions récentes (traitement côté backend)
  List<dynamic> get homeRecentTransactions => List.from(_homeRecentTransactions);
  
  // Transactions filtrées pour l'écran Transactions
  List<dynamic> get filteredTransactions => List.from(_filteredTransactions);

  // Données statistiques
  List<MonthlySummary> get monthlySummary => List.from(_monthlySummary);
  List<CategoryExpense> get categoryExpenses => List.from(_categoryExpenses);
  
  // Données statistiques budgets
  List<BudgetVsActual> get budgetVsActual => List.from(_budgetVsActual);
  List<TopBudgetCategory> get topBudgetCategories => List.from(_topBudgetCategories);
  BudgetEfficiency? get budgetEfficiency => _budgetEfficiency;
  List<BudgetDistribution> get budgetDistribution => List.from(_budgetDistribution);
  List<String> get statisticsCardsPreferences => List.from(_statisticsCardsPreferences);
  bool get statisticsCardsPreferencesLoaded => _statisticsCardsPreferencesLoaded;
  List<Map<String, dynamic>> get cardFavorites => List.from(_cardFavorites);
  bool get cardFavoritesLoaded => _cardFavoritesLoaded;
  List<Card> get availableCards => List.from(_availableCards);
  bool get availableCardsLoaded => _availableCardsLoaded;

  // Données du backend
  double get totalIncome => (_balanceData?['totalIncome'] as num?)?.toDouble() ?? 0.0;

  double get totalExpenses => (_balanceData?['totalExpenses'] as num?)?.toDouble() ?? 0.0;

  double get balance => (_balanceData?['currentBalance'] as num?)?.toDouble() ?? 0.0;

  // Initialisation - Charger uniquement les données essentielles au démarrage
  Future<void> initialize(String userId) async {
    // Si déjà initialisé pour cet utilisateur, ne rien faire
    if (_isInitialized && _currentUser?.id == userId) {
      return;
    }

    // Si un autre utilisateur, nettoyer d'abord
    if (_currentUser != null && _currentUser!.id != userId) {
      clearAllData();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // OPTIMISATION : Charger le profil et le cache en parallèle
      await Future.wait([
        _loadUser(userId),
        _loadCachedBalance(userId), // Pas de retry pour le cache (non critique)
      ]);

      _isInitialized = true;
      _isLoading = false;
      // OPTIMISATION : Un seul notifyListeners() à la fin
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Nettoyer toutes les données (déconnexion, fermeture app, nouvelle auth)
  void clearAllData() {
    _currentUser = null;
    _expenses.clear();
    _incomes.clear();
    _categories.clear();
    _categoriesLoaded = false;
    _budgets.clear();
    _isLoadingBudgets = false;
    _goals.clear();
    _scheduledPayments.clear();
    _homeRecentTransactions.clear();
    _balanceData = null;
    // Nettoyer le stockage local du balance
    LocalStorageService.clearBalanceData();
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    _isLoadingCategories = false;
    _isLoadingHomeData = false;
    // Nettoyer les favoris et préférences des cartes statistiques
    _cardFavorites.clear();
    _cardFavoritesLoaded = false;
    _statisticsCardsPreferences.clear();
    _statisticsCardsPreferencesLoaded = false;
    // Nettoyer le cache des couleurs personnalisées
    _cachedCategoryColors = null;
    _categoryColorsCacheTime = null;
    _availableCards.clear();
    _availableCardsLoaded = false;
    notifyListeners();
  }

  // Obtenir les couleurs personnalisées avec cache
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

  // Invalider le cache des couleurs (appelé après modification)
  void invalidateCategoryColorsCache() {
    _cachedCategoryColors = null;
    _categoryColorsCacheTime = null;
  }

  // Charger les catégories à la demande
  Future<void> loadCategoriesIfNeeded() async {
    // Si déjà chargées (ne changent pas souvent), ne pas recharger
    if (_categoriesLoaded) {
      return;
    }
    
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoadingCategories) {
      return;
    }
    
    _isLoadingCategories = true;
    try {
      _categories.clear();
      
      // OPTIMISATION : Charger les catégories et les couleurs en parallèle
      if (_currentUser != null) {
        final results = await Future.wait([
          CategoryService.getAllCategories(),
          _getCategoryColorsCached(_currentUser!.id),
        ]);
        final categories = results[0] as List<models.Category>;
        final colorMap = results[1] as Map<String, String>;
        
        // Fusionner les couleurs personnalisées avec les catégories
        final categoriesWithColors = categories.map((category) {
          final customColor = colorMap[category.id];
          if (customColor != null) {
            return models.Category(
              id: category.id,
              name: category.name,
              icon: category.icon,
              color: customColor, // Utiliser la couleur personnalisée
            );
          }
          return category;
        }).toList();
        
        _categories.addAll(categoriesWithColors);
      } else {
        final categories = await CategoryService.getAllCategories();
        _categories.addAll(categories);
      }
      
      _categoriesLoaded = true; // Marquer comme chargé
      notifyListeners();
    } catch (e) {
      rethrow;
} finally {
      _isLoadingCategories = false;
    }
  }

  // Recharger les catégories (force toujours le rechargement)
  Future<void> reloadCategories() async {
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoadingCategories) {
      return;
    }
    
    _isLoadingCategories = true;
    _categoriesLoaded = false; // Réinitialiser le flag pour forcer le rechargement
    invalidateCategoryColorsCache(); // Invalider le cache pour forcer le rechargement
    try {
      _categories.clear();
      
      // OPTIMISATION : Charger les catégories et les couleurs en parallèle
      if (_currentUser != null) {
        final results = await Future.wait([
          CategoryService.getAllCategories(),
          _getCategoryColorsCached(_currentUser!.id),
        ]);
        final categories = results[0] as List<models.Category>;
        final colorMap = results[1] as Map<String, String>;
        
        // Fusionner les couleurs personnalisées avec les catégories
        final categoriesWithColors = categories.map((category) {
          final customColor = colorMap[category.id];
          if (customColor != null) {
            return models.Category(
              id: category.id,
              name: category.name,
              icon: category.icon,
              color: customColor, // Utiliser la couleur personnalisée
            );
          }
          return category;
        }).toList();
        
        _categories.addAll(categoriesWithColors);
      } else {
        final categories = await CategoryService.getAllCategories();
        _categories.addAll(categories);
      }
      
      _categoriesLoaded = true; // Marquer comme chargé
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingCategories = false;
    }
  }

  // Charger les données nécessaires pour la page d'accueil (lazy loading)
  Future<void> loadHomeData() async {
    if (_currentUser == null) return;
    
    // Éviter les appels multiples
    if (_isLoadingHomeData) {
      return;
    }
    
    _isLoadingHomeData = true;
    final userId = _currentUser!.id;
    try {
      
      // OPTIMISATION : Charger TOUT en parallèle pour maximiser la vitesse
      await Future.wait([
        _loadBalance(userId),
        loadRecentTransactions(limit: 3),
        _loadScheduledPayments(userId), // Charger tous les paiements (pas de limite)
      ]);
      
      // OPTIMISATION : Un seul notifyListeners() après tous les chargements
      notifyListeners();
      
      // Charger les cartes disponibles et les favoris en arrière-plan après l'affichage de la page d'accueil
      _loadAvailableCardsInBackground();
      _loadCardFavoritesInBackground(userId);
    } catch (e) {
      // Ne pas rethrow, laisser les listes vides
    } finally {
      _isLoadingHomeData = false;
    }
  }

  // Charger les transactions récentes (traitement côté backend)
  // RETRY LOGIC : Retry pour cet appel critique (affiché sur l'accueil)
  Future<void> loadRecentTransactions({
    int limit = 3,
  }) async {
    if (_currentUser == null) return;
    
    final userId = _currentUser!.id;
    try {
      final transactions = await HomeService.getRecentTransactions(userId, limit: limit);
      
      // Ne vider que si le chargement réussit, pour éviter la disparition des widgets
      _homeRecentTransactions.clear();
      _homeRecentTransactions.addAll(transactions);
      
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante (loadHomeData)
    } catch (e) {
      // Ne pas vider en cas d'erreur pour garder les données existantes
      // Pas de notifyListeners() ici - sera géré par la méthode appelante
    }
  }

  // Charger les transactions avec filtres pour l'écran Transactions
  Future<void> loadFilteredTransactions({
    int limit = 2147483647, // Max int 32-bit
    String? type,
    String? dateRange,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    if (_currentUser == null) return;
    
    final userId = _currentUser!.id;
    try {
      
      final transactions = await HomeService.getRecentTransactions(
        userId,
        limit: limit,
        type: type,
        dateRange: dateRange,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
      
      _filteredTransactions.clear();
      _filteredTransactions.addAll(transactions);
      
      notifyListeners();
    } catch (e) {
      _filteredTransactions.clear();
      notifyListeners();
      rethrow;
    }
  }

  // Charger les objectifs à la demande (lazy loading)
  Future<void> loadGoals() async {
    if (_currentUser == null) return;
    if (_isLoadingGoals) {
      return;
    }
    _isLoadingGoals = true;
    try {
      await _loadGoals(_currentUser!.id);
      notifyListeners();
    } finally {
      _isLoadingGoals = false;
    }
  }

  // Charger les données pour les statistiques à la demande (optimisé)
  // Ne charge que les données nécessaires selon les cartes sélectionnées
  Future<void> loadStatisticsData({List<String>? requiredCardIds}) async {
    if (_currentUser == null) return;
    if (_isLoadingStatistics) return; // Éviter les appels multiples
    
    _isLoadingStatistics = true;
    final userId = _currentUser!.id;
    
    // Si aucune carte spécifique n'est demandée, charger les préférences d'abord
    if (requiredCardIds == null) {
      await _loadStatisticsCardsPreferences(userId);
      requiredCardIds = _statisticsCardsPreferences;
    }
    
    try {
      
      // Déterminer quelles données sont nécessaires
      final needsExpenses = _needsExpensesList(requiredCardIds);
      final needsIncomes = _needsIncomesList(requiredCardIds);
      final needsBalance = _needsBalance(requiredCardIds);
      final needsGoals = _needsGoals(requiredCardIds);
      
      
      final futures = <Future>[];
      
      // Charger le balance seulement si nécessaire
      if (needsBalance) {
        futures.add(_loadBalance(userId));
      }
      
      // Charger les dépenses seulement si nécessaire
      if (needsExpenses) {
        futures.add(_loadExpenses(userId));
      }
      
      // Charger les revenus seulement si nécessaire
      if (needsIncomes) {
        futures.add(_loadIncomes(userId));
      }
      
      // Charger les objectifs seulement si nécessaire
      if (needsGoals) {
        futures.add(_loadGoals(userId));
      }
      
      // Charger en parallèle
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      
      // OPTIMISATION : Un seul notifyListeners() après tous les chargements
      notifyListeners();
    } catch (e) {
    } finally {
      _isLoadingStatistics = false;
    }
  }

  // Vérifier si on a besoin de la liste complète des dépenses
  bool _needsExpensesList(List<String> cardIds) {
    // transactionCountCard (id=8) et topExpenseCard (id=6) ont besoin de toutes les dépenses
    final needs = cardIds.contains('8') || 
                  cardIds.contains('transaction_count_card') ||
                  cardIds.contains('6') ||
                  cardIds.contains('top_expense_card');
    return needs;
  }

  // Vérifier si on a besoin de la liste complète des revenus
  bool _needsIncomesList(List<String> cardIds) {
    // transactionCountCard (id=8) a besoin de tous les revenus
    return cardIds.contains('8') || cardIds.contains('transaction_count_card');
  }

  // Vérifier si on a besoin du balance
  bool _needsBalance(List<String> cardIds) {
    // balanceCard (id=3), savingsCard (id=4), et goalsProgressCard (id=12) ont besoin du balance
    return cardIds.contains('3') || 
           cardIds.contains('balance_card') ||
           cardIds.contains('4') ||
           cardIds.contains('savings_card') ||
           cardIds.contains('12') ||
           cardIds.contains('goals_progress_card');
  }
  
  // Vérifier si on a besoin des objectifs
  bool _needsGoals(List<String> cardIds) {
    // goalsProgressCard (id=12) a besoin des objectifs
    return cardIds.contains('12') || cardIds.contains('goals_progress_card');
  }

  // Charger les cartes disponibles depuis l'API en arrière-plan
  // Utilise le cache si les cartes sont déjà chargées
  Future<void> _loadAvailableCardsInBackground() async {
    // Si déjà chargées, ne pas recharger (utiliser le cache)
    if (_availableCardsLoaded && _availableCards.isNotEmpty) {
      return;
    }
    
    try {
      _availableCards = await CardService.getCards();
      _availableCardsLoaded = true;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, marquer comme chargé avec une liste vide
      // Cela permettra d'afficher un message d'erreur plutôt que d'utiliser un fallback
      _availableCardsLoaded = true;
      _availableCards = [];
      notifyListeners();
    }
  }
  
  // Forcer le rechargement des cartes disponibles depuis l'API (pour rafraîchir le cache)
  Future<void> reloadAvailableCards() async {
    _availableCardsLoaded = false;
    _availableCards.clear();
    await _loadAvailableCardsInBackground();
  }

  // Charger les favoris complets en arrière-plan (après loadHomeData)
  Future<void> _loadCardFavoritesInBackground(String userId) async {
    if (_cardFavoritesLoaded) {
      return;
    }
    
    try {
      _cardFavorites = await FavoriteService.getFavoritesByType(userId, 'CARD');
      _cardFavoritesLoaded = true;
      
      // Extraire les IDs des cartes depuis les favoris complets
      // Dédupliquer pour éviter les doublons
      _statisticsCardsPreferences = _cardFavorites
          .map((f) => f['targetEntity']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet() // Dédupliquer avec Set
          .toList();
      _statisticsCardsPreferencesLoaded = true;
      
      notifyListeners();
    } catch (e) {
      // Ne pas bloquer l'application si les favoris ne peuvent pas être chargés
    }
  }

  // Charger les préférences des cartes statistiques (pour StatisticsScreen)
  // Utilise les favoris déjà chargés si disponibles, sinon charge depuis l'API
  Future<void> _loadStatisticsCardsPreferences(String userId) async {
    // Si les favoris sont déjà chargés, utiliser les données existantes
    if (_cardFavoritesLoaded && _cardFavorites.isNotEmpty) {
      // Dédupliquer pour éviter les doublons
      _statisticsCardsPreferences = _cardFavorites
          .map((f) => f['targetEntity']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet() // Dédupliquer avec Set
          .toList();
      _statisticsCardsPreferencesLoaded = true;
      return;
    }
    
    // Sinon, charger depuis l'API (fallback)
    try {
      _statisticsCardsPreferences = await FavoriteService.getStatisticsCardsPreferences(userId);
      _statisticsCardsPreferencesLoaded = true;
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _statisticsCardsPreferences = [];
      _statisticsCardsPreferencesLoaded = true;
    }
  }

  // Vider les categoryExpenses pour forcer un rechargement (utile après modification de couleur)
  void clearCategoryExpenses() {
    _categoryExpenses = [];
    notifyListeners();
  }

  // Charger TOUTES les statistiques en une seule requête (OPTIMISÉ)
  // Réduit les appels API de 6 à 1 pour améliorer les performances
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
      
      // Mettre à jour toutes les données depuis le DTO unifié
      _monthlySummary = allStats.monthlySummary;
      
      // Mettre à jour categoryExpenses avec les couleurs personnalisées
      _categoryExpenses = allStats.categoryExpenses.categories;
      final colorMap = await _getCategoryColorsCached(_currentUser!.id);
      _categoryExpenses = _categoryExpenses.map((expense) {
        final customColor = colorMap[expense.categoryId];
        if (customColor != null) {
          return expense.copyWith(categoryColor: customColor);
        }
        return expense;
      }).toList();
      
      // Mettre à jour les données budgets
      _budgetVsActual = allStats.budgetStatistics.budgetVsActual;
      _budgetEfficiency = allStats.budgetStatistics.efficiency;
      _budgetDistribution = allStats.budgetStatistics.distribution;
      
      // TopBudgetCategories est dérivé de BudgetVsActual
      _topBudgetCategories = allStats.budgetStatistics.budgetVsActual.map((item) {
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
      debugPrint('Error loading all statistics: $e');
      // En cas d'erreur, réinitialiser toutes les données
      _monthlySummary = [];
      _categoryExpenses = [];
      _budgetVsActual = [];
      _budgetEfficiency = null;
      _budgetDistribution = [];
      _topBudgetCategories = [];
      notifyListeners();
    }
  }

  // Mettre à jour les préférences des cartes
  Future<void> updateStatisticsCardsPreferences(List<String> cardIds) async {
    if (_currentUser == null) return;
    try {
      
      // Utiliser les favoris déjà chargés si disponibles pour éviter un appel API supplémentaire
      final existingFavoritesToUse = _cardFavoritesLoaded && _cardFavorites.isNotEmpty 
          ? _cardFavorites 
          : null;
      
      // Vérifier que les cartes sont chargées avant de mettre à jour
      if (!_availableCardsLoaded || _availableCards.isEmpty) {
        throw Exception('Les cartes doivent être chargées depuis le backend avant de mettre à jour les préférences.');
      }
      
      // Utiliser la méthode optimisée qui retourne directement les favoris mis à jour
      // Cela évite un appel GET supplémentaire car la réponse POST contient déjà les favoris
      _cardFavorites = await FavoriteService.updateStatisticsCardsPreferencesWithFavorites(
        _currentUser!.id,
        cardIds,
        existingFavorites: existingFavoritesToUse,
        availableCards: _availableCards,
      );
      _cardFavoritesLoaded = true;
      
      // Extraire les IDs des cartes depuis les favoris mis à jour
      // Dédupliquer pour éviter les doublons
      _statisticsCardsPreferences = _cardFavorites
          .map((f) => f['targetEntity']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet() // Dédupliquer avec Set
          .toList();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Charger le profil utilisateur
  Future<void> _loadUser(String userId) async {
    try {
      _currentUser = await UserService.getProfile(userId);
      
      // Vérifier que l'utilisateur existe réellement dans la base
      if (_currentUser == null) {
        throw Exception('Utilisateur non trouvé dans la base de données. Veuillez vous reconnecter.');
      }
      
    } catch (e) {
      _currentUser = null; // S'assurer que currentUser est null en cas d'erreur
      // Ne pas créer d'utilisateur par défaut, laisser null pour afficher l'erreur
      rethrow;
    }
  }


  // Charger les dépenses
  Future<void> _loadExpenses(String userId) async {
    try {
      _expenses.clear();
      final loadedExpenses = await ExpenseService.getExpenses(userId, page: 0, size: 100);
      _expenses.addAll(loadedExpenses);
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _expenses.clear();
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    }
  }

  // Charger les revenus
  Future<void> _loadIncomes(String userId) async {
    try {
      _incomes.clear();
      _incomes.addAll(await IncomeService.getIncomes(userId, page: 0, size: 100));
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _incomes.clear();
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    }
  }

  // Charger les objectifs
  Future<void> _loadGoals(String userId) async {
    try {
      _goals.clear();
      _goals.addAll(await GoalService.getGoals(userId));
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _goals.clear();
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    }
  }


  // Charger les paiements planifiés
  // Charger tous les paiements planifiés (pour l'écran dédié)
  Future<void> _loadScheduledPayments(String userId) async {
    try {
      final payments = await ScheduledPaymentService.getScheduledPayments(userId);
      
      // Ne vider que si le chargement réussit, pour éviter la disparition des widgets
      _scheduledPayments.clear();
      _scheduledPayments.addAll(payments);
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    } catch (e) {
      // Ne pas vider en cas d'erreur pour garder les données existantes
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    }
  }


  // Charger le solde et notifier l'UI
  Future<void> _loadBalance(String userId) async {
    try {
      final newBalanceData = await HomeService.getBalance(userId);
      // Ne mettre à jour que si le chargement réussit, pour éviter la disparition des widgets
      _balanceData = newBalanceData;
      // Sauvegarder le balance dans le stockage local
      if (_balanceData != null) {
        await LocalStorageService.saveBalanceData(userId, _balanceData!);
      }
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    } catch (e) {
      // En cas d'erreur après retry, essayer de charger depuis le stockage local
      // Ne pas écraser les données existantes si le cache est vide
      if (_balanceData == null) {
        final cachedBalance = await LocalStorageService.getBalanceData(userId);
        if (cachedBalance != null) {
          _balanceData = cachedBalance;
        }
      }
      // OPTIMISATION : notifyListeners() sera appelé par la méthode appelante
    }
  }

  // Charger le balance depuis le stockage local au démarrage
  Future<void> _loadCachedBalance(String userId) async {
    try {
      final cachedBalance = await LocalStorageService.getBalanceData(userId);
      if (cachedBalance != null) {
        _balanceData = cachedBalance;
        notifyListeners();
      }
    } catch (e) {
      // Ignorer les erreurs de chargement du cache
    }
  }

  // Recharger toutes les données
  Future<void> refresh() async {
    if (_currentUser != null) {
      await initialize(_currentUser!.id);
    }
  }

  // Expense operations
  Future<void> addExpense(Expense expense) async {
    if (_currentUser == null) {
      throw Exception('Vous devez être connecté pour ajouter une dépense');
    }
    
    try {
      final expenseData = expense.toJson();
      final createdExpense = await ExpenseService.createExpense(expenseData);
      
      // Recharger toutes les données nécessaires : balance, transactions récentes et liste complète des dépenses
      final userId = _currentUser!.id;
      final futures = <Future>[
        _loadBalance(userId),
        loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
      ];
      
      // Recharger la liste complète des dépenses si elle est déjà chargée
      if (_expenses.isNotEmpty) {
        futures.add(_loadExpenses(userId));
      }
      
      await Future.wait(futures);
      // OPTIMISATION : Un seul notifyListeners() après tous les chargements
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners(); // Notifier l'erreur immédiatement
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await ExpenseService.deleteExpense(id);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        final futures = <Future>[
          _loadBalance(userId),
          loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
        ];
        
        // Recharger la liste complète des dépenses si elle est déjà chargée
        if (_expenses.isNotEmpty) {
          futures.add(_loadExpenses(userId));
        }
        
        await Future.wait(futures);
        // OPTIMISATION : Un seul notifyListeners() après tous les chargements
        notifyListeners();
      }
    } catch (e) {
      // Ne pas stocker l'erreur dans _error pour les actions spécifiques
      // L'erreur sera gérée localement par le widget qui appelle cette méthode
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final expenseData = expense.toJson();
      await ExpenseService.updateExpense(expense.id, expenseData);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        final futures = <Future>[
          _loadBalance(userId),
          loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
        ];
        
        // Recharger la liste complète des dépenses si elle est déjà chargée
        if (_expenses.isNotEmpty) {
          futures.add(_loadExpenses(userId));
        }
        
        await Future.wait(futures);
        // OPTIMISATION : Un seul notifyListeners() après tous les chargements
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners(); // Notifier l'erreur immédiatement
      rethrow;
    }
  }

  // Income operations
  Future<void> addIncome(Income income) async {
    if (_currentUser == null) {
      throw Exception('Vous devez être connecté pour ajouter un revenu');
    }
    
    try {
      final incomeData = income.toJson();
      await IncomeService.createIncome(incomeData);
      
      // Recharger toutes les données nécessaires : balance, transactions récentes et liste complète des revenus
      final userId = _currentUser!.id;
      final futures = <Future>[
        _loadBalance(userId),
        loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
      ];
      
      // Recharger la liste complète des revenus si elle est déjà chargée
      if (_incomes.isNotEmpty) {
        futures.add(_loadIncomes(userId));
      }
      
      await Future.wait(futures);
      // OPTIMISATION : Un seul notifyListeners() après tous les chargements
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners(); // Notifier l'erreur immédiatement
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await IncomeService.deleteIncome(id);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        final futures = <Future>[
          _loadBalance(userId),
          loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
        ];
        
        // Recharger la liste complète des revenus si elle est déjà chargée
        if (_incomes.isNotEmpty) {
          futures.add(_loadIncomes(userId));
        }
        
        await Future.wait(futures);
        // OPTIMISATION : Un seul notifyListeners() après tous les chargements
        notifyListeners();
      }
    } catch (e) {
      // Ne pas stocker l'erreur dans _error pour les actions spécifiques
      // L'erreur sera gérée localement par le widget qui appelle cette méthode
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final incomeData = income.toJson();
      await IncomeService.updateIncome(income.id, incomeData);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        final futures = <Future>[
          _loadBalance(userId),
          loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
        ];
        
        // Recharger la liste complète des revenus si elle est déjà chargée
        if (_incomes.isNotEmpty) {
          futures.add(_loadIncomes(userId));
        }
        
        await Future.wait(futures);
        // OPTIMISATION : Un seul notifyListeners() après tous les chargements
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners(); // Notifier l'erreur immédiatement
      rethrow;
    }
  }

  // Category operations
  Future<void> addCategory(models.Category category) async {
    try {
      if (_currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      // CategoryRequestDto nécessite userId
      final categoryData = {
        'userId': int.tryParse(_currentUser!.id) ?? _currentUser!.id,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
      };
      final createdCategory = await CategoryService.createCategory(categoryData);
      _categories.add(createdCategory);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await CategoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(models.Category category) async {
    try {
      // CategoryUpdateDto n'a pas besoin de userId
      final categoryData = {
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
      };
      final updatedCategory = await CategoryService.updateCategory(category.id, categoryData);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Budget operations
  bool _isLoadingBudgets = false;

  // Charger les budgets à la demande
  Future<void> loadBudgetsIfNeeded({String? month}) async {
    if (_isLoadingBudgets || _currentUser == null) return;
    
    _isLoadingBudgets = true;
    try {
      final budgets = await BudgetService.getBudgets(_currentUser!.id, month: month);
      _budgets.clear();
      _budgets.addAll(budgets);
      notifyListeners();
    } catch (e) {
      _budgets.clear();
    } finally {
      _isLoadingBudgets = false;
    }
  }

  // Recharger les budgets
  Future<void> reloadBudgets({String? month}) async {
    await loadBudgetsIfNeeded(month: month);
  }

  // Obtenir les budgets mensuels actifs pour une catégorie
  List<Budget> getBudgetsForCategory(String categoryId) {
    return _budgets.where((b) => 
      b.categoryId == categoryId
    ).toList();
  }

  // Obtenir le budget mensuel actif pour une catégorie (le plus récent)
  Budget? getMonthlyBudgetForCategory(String categoryId) {
    final budgets = getBudgetsForCategory(categoryId);
    if (budgets.isEmpty) return null;
    // Retourner le plus récent (par date de création)
    budgets.sort((a, b) => (b.startDate ?? DateTime.now()).compareTo(a.startDate ?? DateTime.now()));
    return budgets.first;
  }

  Future<void> addBudget(Budget budget) async {
    try {
      final budgetData = {
        'userId': int.tryParse(budget.userId) ?? budget.userId,
        'amount': budget.amount,
        'startDate': budget.startDate?.toIso8601String().split('T')[0],
        'endDate': budget.endDate?.toIso8601String().split('T')[0],
        'categoryId': budget.categoryId != null ? (int.tryParse(budget.categoryId!) ?? budget.categoryId) : null,
        'isRecurring': budget.isRecurring,
      };
      await BudgetService.createBudget(budgetData);
      // Recharger la liste complète des budgets depuis le backend
      if (_currentUser != null) {
        await loadBudgetsIfNeeded();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      final budgetData = {
        'userId': int.tryParse(budget.userId) ?? budget.userId,
        'amount': budget.amount,
        'startDate': budget.startDate?.toIso8601String().split('T')[0],
        'endDate': budget.endDate?.toIso8601String().split('T')[0],
        'categoryId': budget.categoryId != null ? (int.tryParse(budget.categoryId!) ?? budget.categoryId) : null,
        'isRecurring': budget.isRecurring,
      };
      await BudgetService.updateBudget(budget.id, budgetData);
      // Recharger la liste complète des budgets depuis le backend
      if (_currentUser != null) {
        await loadBudgetsIfNeeded();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await BudgetService.deleteBudget(id);
      // Recharger la liste complète des budgets depuis le backend
      if (_currentUser != null) {
        await loadBudgetsIfNeeded();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Scheduled Payment operations
  Future<void> addScheduledPayment(ScheduledPayment payment) async {
    try {
      final paymentData = payment.toJson();
      await ScheduledPaymentService.createScheduledPayment(paymentData);
      // Recharger uniquement les paiements planifiés
      if (_currentUser != null) {
        await _loadScheduledPayments(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteScheduledPayment(String id) async {
    try {
      await ScheduledPaymentService.deleteScheduledPayment(id);
      // Recharger uniquement les paiements planifiés
      if (_currentUser != null) {
        await _loadScheduledPayments(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      // Ne pas stocker l'erreur dans _error pour les actions spécifiques
      // L'erreur sera gérée localement par le widget qui appelle cette méthode
      rethrow;
    }
  }

  Future<void> updateScheduledPayment(ScheduledPayment payment) async {
    try {
      final paymentData = payment.toJson();
      await ScheduledPaymentService.updateScheduledPayment(payment.id, paymentData);
      // Recharger uniquement les paiements planifiés
      if (_currentUser != null) {
        await _loadScheduledPayments(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markScheduledPaymentAsPaid(String id, DateTime paymentDate) async {
    if (_currentUser == null) {
      throw Exception('Vous devez être connecté pour confirmer un paiement');
    }
    
    try {
      // Le backend crée automatiquement une dépense lors du marquage comme payé
      await ScheduledPaymentService.markAsPaid(id, paymentDate);
      
      // Recharger toutes les données affectées :
      // - Paiements planifiés (pour voir le paiement marqué comme payé)
      // - Solde (car une dépense a été créée)
      // - Transactions récentes (pour voir la nouvelle dépense)
      final userId = _currentUser!.id;
      await Future.wait([
        _loadScheduledPayments(userId),
        _loadBalance(userId),
        loadRecentTransactions(limit: 3), // Toujours limit=3 pour la page d'accueil
      ]);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Goal operations
  Future<void> addGoal(Goal goal) async {
    try {
      // GoalRequestDto : userId, name, description, targetAmount, targetDate, categoryId
      final goalData = {
        'userId': int.tryParse(goal.userId) ?? goal.userId,
        'name': goal.name,
        'description': goal.description,
        'targetAmount': goal.targetAmount,
        'targetDate': goal.targetDate?.toIso8601String().split('T')[0], // Format LocalDate (YYYY-MM-DD)
        'categoryId': goal.categoryId != null ? (int.tryParse(goal.categoryId!) ?? goal.categoryId) : null,
      };
      await GoalService.createGoal(goalData);
      // Recharger la liste complète des goals depuis le backend
      if (_currentUser != null) {
        await _loadGoals(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      // GoalRequestDto : userId, name, description, targetAmount, currentAmount, targetDate, categoryId
      final goalData = {
        'userId': int.tryParse(goal.userId) ?? goal.userId,
        'name': goal.name,
        'description': goal.description,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'targetDate': goal.targetDate?.toIso8601String().split('T')[0], // Format LocalDate (YYYY-MM-DD)
        'categoryId': goal.categoryId != null ? (int.tryParse(goal.categoryId!) ?? goal.categoryId) : null,
      };
      await GoalService.updateGoal(goal.id, goalData);
      // Recharger la liste complète des goals depuis le backend
      if (_currentUser != null) {
        await _loadGoals(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await GoalService.deleteGoal(id);
      // Recharger la liste complète des goals depuis le backend
      if (_currentUser != null) {
        await _loadGoals(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addAmountToGoal(String goalId, double amount) async {
    try {
      await GoalService.addAmountToGoal(goalId, amount);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        // Recharger la liste complète des goals pour mettre à jour l'affichage
        await _loadGoals(userId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> achieveGoal(String goalId) async {
    try {
      await GoalService.achieveGoal(goalId);
      if (_currentUser != null) {
        final userId = _currentUser!.id;
        // Recharger la liste complète des goals pour mettre à jour l'affichage
        await _loadGoals(userId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // User operations
  Future<void> updateUser(User user) async {
    try {
      final updateData = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'language': user.language,
        'notificationsEnabled': user.notificationsEnabled,
      };
      _currentUser = await UserService.updateProfile(user.id, updateData);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Mettre à jour uniquement les préférences de notifications
  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (_currentUser == null) return;
    try {
      // Mettre à jour directement sans recharger le profil complet
      final updatedUser = await UserService.updateProfile(_currentUser!.id, {
        'firstName': _currentUser!.firstName,
        'lastName': _currentUser!.lastName,
        'language': _currentUser!.language,
        'notificationsEnabled': enabled,
      });
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
