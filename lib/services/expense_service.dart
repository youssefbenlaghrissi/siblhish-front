import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'api_service.dart';

class ExpenseService {
  // Obtenir les dépenses par utilisateur
  static Future<List<Expense>> getExpenses(
    String userId, {
    int page = 0,
    int size = 20,
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    final response = await ApiService.get('/expenses/user/$userId');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Obtenir une dépense par ID
  static Future<Expense> getExpenseById(String expenseId) async {
    final response = await ApiService.get('/expenses/$expenseId');
    final data = response['data'] as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  // Créer une dépense
  static Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    final response = await ApiService.post('/expenses', expenseData);
    final data = response['data'] as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  // Mettre à jour une dépense
  static Future<Expense> updateExpense(
      String expenseId, Map<String, dynamic> expenseData) async {
    final response = await ApiService.put('/expenses/$expenseId', expenseData);
    final data = response['data'] as Map<String, dynamic>;
    debugPrint('   Date reçue: ${data['date']}');
    debugPrint('   Données complètes: $data');
    return Expense.fromJson(data);
  }

  // Supprimer une dépense
  static Future<void> deleteExpense(String expenseId) async {
    await ApiService.delete('/expenses/$expenseId');
  }

  // Obtenir les dépenses récurrentes
  static Future<List<Expense>> getRecurringExpenses(String userId) async {
    final response = await ApiService.get('/expenses/$userId/recurring');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
  }
}

