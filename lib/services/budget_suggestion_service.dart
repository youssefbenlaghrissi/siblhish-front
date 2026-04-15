import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BudgetSuggestionService {
  /// Suggérer des budgets basés sur le revenu, la situation et les catégories
  static Future<Map<String, dynamic>> suggestBudgets({
    required double monthlyIncome,
    required String situation,
    required String location,
    required List<int> categoryIds,
  }) async {
    final url = '${ApiConfig.baseUrl}/budgets/suggest';
    final body = {
      'monthlyIncome': monthlyIncome,
      'situation': situation,
      'location': location,
      'categoryIds': categoryIds,
    };

    if (kDebugMode) {
      debugPrint('[BudgetSuggestionService] POST $url');
      debugPrint('[BudgetSuggestionService] Body: $body');
    }
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(body),
      ).timeout(ApiConfig.timeout);

      if (kDebugMode) {
        debugPrint('[BudgetSuggestionService] Status: ${response.statusCode}');
        debugPrint('[BudgetSuggestionService] Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (kDebugMode) debugPrint('[BudgetSuggestionService] Success');
          return jsonResponse['data'];
        } else {
          if (kDebugMode) debugPrint('[BudgetSuggestionService] Error: ${jsonResponse['message']}');
          throw Exception(jsonResponse['message'] ?? 'Erreur lors du calcul des budgets');
        }
      } else {
        final errorBody = json.decode(response.body);
        if (kDebugMode) debugPrint('[BudgetSuggestionService] Server error ${response.statusCode}: ${errorBody['message']}');
        throw Exception(errorBody['message'] ?? 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BudgetSuggestionService] Exception: $e');
      rethrow;
    }
  }
}

