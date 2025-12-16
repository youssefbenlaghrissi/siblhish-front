import '../models/goal.dart';
import 'api_service.dart';

class GoalService {
  // Obtenir les objectifs de l'utilisateur
  static Future<List<Goal>> getGoals(
    String userId, {
    bool? achieved,
    String? categoryId,
  }) async {
    String endpoint = '/goals/$userId';
    if (achieved != null) endpoint += '?achieved=$achieved';
    if (categoryId != null) endpoint += '?categoryId=$categoryId';

    final response = await ApiService.get(endpoint);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Créer un objectif
  static Future<Goal> createGoal(Map<String, dynamic> goalData) async {
    final response = await ApiService.post('/goals', goalData);
    final data = response['data'] as Map<String, dynamic>;
    return Goal.fromJson(data);
  }

  // Mettre à jour un objectif
  static Future<Goal> updateGoal(
      String goalId, Map<String, dynamic> goalData) async {
    final response = await ApiService.put('/goals/$goalId', goalData);
    final data = response['data'] as Map<String, dynamic>;
    return Goal.fromJson(data);
  }

  // Ajouter de l'argent à un objectif
  static Future<Goal> addAmountToGoal(String goalId, double amount) async {
    final response = await ApiService.post('/goals/$goalId/add-amount', {
      'amount': amount,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Goal.fromJson(data);
  }

  // Marquer un objectif comme atteint
  static Future<Goal> achieveGoal(String goalId) async {
    final response = await ApiService.post('/goals/$goalId/achieve', {});
    final data = response['data'] as Map<String, dynamic>;
    return Goal.fromJson(data);
  }

  // Supprimer un objectif
  static Future<void> deleteGoal(String goalId) async {
    await ApiService.delete('/goals/$goalId');
  }
}

