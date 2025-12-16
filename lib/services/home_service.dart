import '../models/expense.dart';
import '../models/income.dart';
import 'api_service.dart';

class HomeService {
  // Obtenir le solde
  static Future<Map<String, dynamic>> getBalance(String userId) async {
    final response = await ApiService.get('/home/balance/$userId');
    return response['data'] as Map<String, dynamic>;
  }

  // Obtenir les transactions récentes
  static Future<List<dynamic>> getRecentTransactions(
    String userId, {
    int limit = 10,
    String? type,
  }) async {
    String endpoint = '/home/transactions/$userId?limit=$limit';
    if (type != null) endpoint += '&type=$type';

    final response = await ApiService.get(endpoint);
    return response['data'] as List<dynamic>;
  }

  // Ajouter rapidement une dépense
  static Future<Expense> addQuickExpense(Map<String, dynamic> expenseData) async {
    final response = await ApiService.post('/home/expenses/quick', expenseData);
    final data = response['data'] as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  // Ajouter rapidement un revenu
  static Future<Income> addQuickIncome(Map<String, dynamic> incomeData) async {
    final response = await ApiService.post('/home/incomes/quick', incomeData);
    final data = response['data'] as Map<String, dynamic>;
    return Income.fromJson(data);
  }
}

