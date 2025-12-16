import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart' as models;
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/category_service.dart';
import '../services/goal_service.dart';
import '../services/home_service.dart';

class BudgetProvider extends ChangeNotifier {
  // Données
  User? _currentUser;
  final List<Expense> _expenses = [];
  final List<Income> _incomes = [];
  final List<models.Category> _categories = [];
  final List<Budget> _budgets = [];
  final List<Goal> _goals = [];

  // États de chargement
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Map<String, dynamic>? _balanceData;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  List<Expense> get expenses => List.from(_expenses)
    ..sort((a, b) => b.date.compareTo(a.date));

  List<Income> get incomes => List.from(_incomes)
    ..sort((a, b) => b.date.compareTo(a.date));

  List<models.Category> get categories => List.from(_categories);

  List<Budget> get budgets => _budgets.where((b) => b.isActive).toList();

  List<Goal> get goals => List.from(_goals);

  // Calculs basés sur les données chargées
  double get totalIncome => incomes.fold(0.0, (sum, income) => sum + income.amount);

  double get totalExpenses => expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  double get balance {
    if (_balanceData != null) {
      return (_balanceData!['currentBalance'] as num?)?.toDouble() ?? 
             (totalIncome - totalExpenses);
    }
    return totalIncome - totalExpenses;
  }

  // Initialisation - Charger toutes les données depuis l'API
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUser?.id == userId) {
      return; // Déjà initialisé pour cet utilisateur
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger les données séquentiellement pour éviter les problèmes de connexion
      // Commencer par l'utilisateur (le plus important)
      await _loadUser(userId);
      
      // Puis charger les autres données
      await _loadCategories(userId);
      await _loadExpenses(userId);
      await _loadIncomes(userId);
      await _loadGoals(userId);
      await _loadBalance(userId);

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Charger le profil utilisateur
  Future<void> _loadUser(String userId) async {
    try {
      debugPrint('👤 Loading user with ID: $userId');
      _currentUser = await UserService.getProfile(userId);
      debugPrint('✅ User loaded: ${_currentUser?.firstName} ${_currentUser?.lastName}');
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      // Ne pas créer d'utilisateur par défaut, laisser null pour afficher l'erreur
      rethrow;
    }
  }

  // Charger les catégories
  Future<void> _loadCategories(String userId) async {
    try {
      _categories.clear();
      _categories.addAll(await CategoryService.getUserCategories(userId));
    } catch (e) {
      // En cas d'erreur, essayer de charger les catégories par défaut
      try {
        _categories.clear();
        _categories.addAll(await CategoryService.getDefaultCategories());
      } catch (e2) {
        // Si même les catégories par défaut échouent, laisser la liste vide
      }
    }
  }

  // Charger les dépenses
  Future<void> _loadExpenses(String userId) async {
    try {
      _expenses.clear();
      _expenses.addAll(await ExpenseService.getExpenses(userId, page: 0, size: 100));
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _expenses.clear();
    }
  }

  // Charger les revenus
  Future<void> _loadIncomes(String userId) async {
    try {
      _incomes.clear();
      _incomes.addAll(await IncomeService.getIncomes(userId, page: 0, size: 100));
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _incomes.clear();
    }
  }

  // Charger les objectifs
  Future<void> _loadGoals(String userId) async {
    try {
      _goals.clear();
      _goals.addAll(await GoalService.getGoals(userId));
    } catch (e) {
      // En cas d'erreur, laisser la liste vide
      _goals.clear();
    }
  }

  // Charger le solde
  Future<void> _loadBalance(String userId) async {
    try {
      _balanceData = await HomeService.getBalance(userId);
    } catch (e) {
      // En cas d'erreur, utiliser les calculs locaux
      _balanceData = null;
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
    try {
      final expenseData = expense.toJson();
      final createdExpense = await ExpenseService.createExpense(expenseData);
      _expenses.add(createdExpense);
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await ExpenseService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final expenseData = expense.toJson();
      final updatedExpense = await ExpenseService.updateExpense(expense.id, expenseData);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
      }
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Income operations
  Future<void> addIncome(Income income) async {
    try {
      final incomeData = income.toJson();
      final createdIncome = await IncomeService.createIncome(incomeData);
      _incomes.add(createdIncome);
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await IncomeService.deleteIncome(id);
      _incomes.removeWhere((i) => i.id == id);
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final incomeData = income.toJson();
      final updatedIncome = await IncomeService.updateIncome(income.id, incomeData);
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = updatedIncome;
      }
      notifyListeners();
      // Recharger le solde
      if (_currentUser != null) {
        await _loadBalance(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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

  // Budget operations (non implémenté dans le backend pour l'instant)
  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
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
      final createdGoal = await GoalService.createGoal(goalData);
      _goals.add(createdGoal);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
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
      final updatedGoal = await GoalService.updateGoal(goal.id, goalData);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await GoalService.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addAmountToGoal(String goalId, double amount) async {
    try {
      final updatedGoal = await GoalService.addAmountToGoal(goalId, amount);
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
      notifyListeners();
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
        'type': user.type,
        'language': user.language,
        'monthlySalary': user.monthlySalary,
      };
      _currentUser = await UserService.updateProfile(user.id, updateData);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Statistics
  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      final categoryId = expense.effectiveCategoryId;
      final category = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => models.Category(id: '', name: 'Autre'),
      );
      categoryTotals[category.name] = (categoryTotals[category.name] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Map<String, double> get monthlyIncome {
    final Map<String, double> monthly = {};
    for (var income in incomes) {
      final key = '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + income.amount;
    }
    return monthly;
  }

  Map<String, double> get monthlyExpenses {
    final Map<String, double> monthly = {};
    for (var expense in expenses) {
      final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + expense.amount;
    }
    return monthly;
  }

  // Obtenir les transactions récentes depuis l'API
  Future<List<dynamic>> getRecentTransactions({int limit = 10}) async {
    if (_currentUser == null) return [];
    
    try {
      return await HomeService.getRecentTransactions(_currentUser!.id, limit: limit);
    } catch (e) {
      // En cas d'erreur, retourner les transactions locales
      final transactions = [
        ...expenses.take(limit),
        ...incomes.take(limit),
      ];
      return transactions;
    }
  }
}
