import '../models/income.dart';
import 'api_service.dart';

class IncomeService {
  // Obtenir les revenus avec pagination
  static Future<List<Income>> getIncomes(
    String userId, {
    int page = 0,
    int size = 20,
    String? startDate,
    String? endDate,
    String? source,
  }) async {
    String endpoint = '/incomes/$userId?page=$page&size=$size';
    if (startDate != null) endpoint += '&startDate=$startDate';
    if (endDate != null) endpoint += '&endDate=$endDate';
    if (source != null) endpoint += '&source=$source';

    final response = await ApiService.get(endpoint);
    final data = response['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content.map((json) => Income.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Obtenir un revenu par ID
  static Future<Income> getIncomeById(String incomeId) async {
    final response = await ApiService.get('/incomes/$incomeId');
    final data = response['data'] as Map<String, dynamic>;
    return Income.fromJson(data);
  }

  // Créer un revenu
  static Future<Income> createIncome(Map<String, dynamic> incomeData) async {
    final response = await ApiService.post('/incomes', incomeData);
    final data = response['data'] as Map<String, dynamic>;
    return Income.fromJson(data);
  }

  // Mettre à jour un revenu
  static Future<Income> updateIncome(
      String incomeId, Map<String, dynamic> incomeData) async {
    final response = await ApiService.put('/incomes/$incomeId', incomeData);
    final data = response['data'] as Map<String, dynamic>;
    return Income.fromJson(data);
  }

  // Supprimer un revenu
  static Future<void> deleteIncome(String incomeId) async {
    await ApiService.delete('/incomes/$incomeId');
  }

  // Obtenir les revenus récurrents
  static Future<List<Income>> getRecurringIncomes(String userId) async {
    final response = await ApiService.get('/incomes/$userId/recurring');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Income.fromJson(json as Map<String, dynamic>)).toList();
  }
}

