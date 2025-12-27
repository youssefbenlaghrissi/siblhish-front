import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import 'api_service.dart';

class BudgetService {
  // Obtenir tous les budgets d'un utilisateur
  // month: format YYYY-MM (ex: "2025-12") pour filtrer par mois
  static Future<List<Budget>> getBudgets(String userId, {String? month}) async {
    try {
      String endpoint = '/budgets/user/$userId';
      
      // Ajouter le paramètre de mois si fourni
      if (month != null && month.isNotEmpty) {
        endpoint += '?month=$month';
      }
      
      final response = await ApiService.get(endpoint);
      final data = response['data'] as List<dynamic>;
      return data.map((json) => Budget.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement budgets: $e');
      return [];
    }
  }

  // Créer un budget
  static Future<Budget> createBudget(Map<String, dynamic> budgetData) async {
    final response = await ApiService.post('/budgets', budgetData);
    final data = response['data'] as Map<String, dynamic>;
    return Budget.fromJson(data);
  }

  // Mettre à jour un budget
  static Future<Budget> updateBudget(String id, Map<String, dynamic> budgetData) async {
    final response = await ApiService.put('/budgets/$id', budgetData);
    final data = response['data'] as Map<String, dynamic>;
    return Budget.fromJson(data);
  }

  // Supprimer un budget
  static Future<void> deleteBudget(String id) async {
    await ApiService.delete('/budgets/$id');
  }
}

