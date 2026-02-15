import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart' as models;

class HomeService {
  // Obtenir le solde
  static Future<Map<String, dynamic>> getBalance(String userId) async {
    final response = await ApiService.get('/home/balance/$userId');
    return response['data'] as Map<String, dynamic>;
  }

  // Obtenir les transactions récentes (traitement côté backend)
  static Future<List<dynamic>> getRecentTransactions(
    String userId, {
    int limit = 3,
    String? type,
    String? dateRange,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    // Construire l'URL avec les paramètres de filtres
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    
    if (dateRange != null && dateRange.isNotEmpty) {
      queryParams['dateRange'] = dateRange;
    }
    
    if (startDate != null) {
      // Envoyer seulement la date sans l'heure pour LocalDate
      queryParams['startDate'] = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    
    if (endDate != null) {
      // Envoyer seulement la date sans l'heure pour LocalDate
      queryParams['endDate'] = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    
    if (minAmount != null) {
      queryParams['minAmount'] = minAmount.toString();
    }
    
    if (maxAmount != null) {
      queryParams['maxAmount'] = maxAmount.toString();
    }
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    String endpoint = '/home/transactions/$userId?$queryString';
    
    final response = await ApiService.get(endpoint);
    final data = response['data'];
    
    // Vérifier que data est une liste
    if (data == null) {
      return [];
    }
    
    if (data is! List) {
      return [];
    }
    
    final dataList = data as List<dynamic>;
    
    // OPTIMISATION : Utiliser directement les données structurées du backend
    // Le backend retourne maintenant un objet 'category' imbriqué au lieu de champs séparés
    List<dynamic> transactions = [];
    for (var json in dataList) {
      try {
        final jsonMap = json as Map<String, dynamic>;
        final transactionType = jsonMap['type'] as String?;
        
        // Vérifier que les champs requis sont présents
        if (jsonMap['id'] == null || jsonMap['amount'] == null || jsonMap['date'] == null) {
          continue;
        }
        
        if (transactionType == 'expense') {
          // OPTIMISATION : Utiliser directement l'objet category du backend
          models.Category? category;
          String? categoryId;
          
          // Vérifier si le backend retourne l'objet category (nouveau format optimisé)
          if (jsonMap['category'] != null) {
            final categoryJson = jsonMap['category'] as Map<String, dynamic>;
            categoryId = categoryJson['id']?.toString();
            category = models.Category(
              id: categoryId ?? '',
              name: categoryJson['name'] as String? ?? '',
              icon: categoryJson['icon'] as String?,
              color: categoryJson['color'] as String?,
            );
          }
          // Fallback pour compatibilité avec l'ancien format (champs séparés)
          else if (jsonMap['categoryName'] != null) {
            categoryId = jsonMap['categoryId']?.toString();
            category = models.Category(
              id: categoryId ?? '',
              name: jsonMap['categoryName'] as String,
              icon: jsonMap['categoryIcon'] as String?,
              color: jsonMap['categoryColor'] as String?,
            );
          }
          
          // Parser la date en heure locale (le backend envoie la date en heure locale)
          DateTime transactionDate;
          if (jsonMap['date'] != null) {
            // ✅ Utiliser la string date qui est en heure locale (évite les problèmes de timezone)
            final dateString = jsonMap['date'] as String;
            // Parser la date et créer un DateTime local (sans timezone)
            final parsed = DateTime.parse(dateString);
            // Créer un DateTime local à partir des composants (évite la conversion UTC)
            transactionDate = DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
            );
          } else {
            continue;
          }
          
          transactions.add(Expense(
            id: jsonMap['id'].toString(),
            amount: (jsonMap['amount'] as num).toDouble(),
            paymentMethod: jsonMap['method'] as String? ?? 'CASH',
            date: transactionDate,
            description: jsonMap['description'] as String?,
            location: jsonMap['location'] as String?,
            isRecurring: jsonMap['isRecurring'] ?? false,
            recurrenceFrequency: jsonMap['recurrenceFrequency'],
            recurrenceEndDate: jsonMap['recurrenceEndDate'] != null 
                ? DateTime.parse(jsonMap['recurrenceEndDate'])
                : null,
            recurrenceDaysOfWeek: _parseRecurrenceDaysOfWeek(jsonMap['recurrenceDaysOfWeek']),
            recurrenceDayOfMonth: jsonMap['recurrenceDayOfMonth'],
            recurrenceDayOfYear: jsonMap['recurrenceDayOfYear'],
            userId: '0',
            categoryId: categoryId,
            category: category,
          ));
        } else {
          // Parser la date en heure locale (le backend envoie la date en heure locale)
          DateTime transactionDate;
          if (jsonMap['date'] != null) {
            // ✅ Utiliser la string date qui est en heure locale (évite les problèmes de timezone)
            final dateString = jsonMap['date'] as String;
            // Parser la date et créer un DateTime local (sans timezone)
            final parsed = DateTime.parse(dateString);
            // Créer un DateTime local à partir des composants (évite la conversion UTC)
            transactionDate = DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
            );
          } else {
            continue;
          }
          
          transactions.add(Income(
            id: jsonMap['id'].toString(),
            amount: (jsonMap['amount'] as num).toDouble(),
            paymentMethod: jsonMap['method'] as String? ?? 'CASH',
            date: transactionDate,
            description: jsonMap['description'] as String?,
            source: jsonMap['source'] as String?,
            isRecurring: jsonMap['isRecurring'] ?? false,
            recurrenceFrequency: jsonMap['recurrenceFrequency'],
            recurrenceEndDate: jsonMap['recurrenceEndDate'] != null 
                ? DateTime.parse(jsonMap['recurrenceEndDate'])
                : null,
            recurrenceDaysOfWeek: _parseRecurrenceDaysOfWeek(jsonMap['recurrenceDaysOfWeek']),
            recurrenceDayOfMonth: jsonMap['recurrenceDayOfMonth'],
            recurrenceDayOfYear: jsonMap['recurrenceDayOfYear'],
            userId: '0',
          ));
        }
      } catch (e) {
        debugPrint('   Données: $json');
        // Continuer avec la transaction suivante
      }
    }
    
    
    return transactions;
  }

  // Helper pour parser recurrenceDaysOfWeek (peut être une liste ou une chaîne)
  static List<int>? _parseRecurrenceDaysOfWeek(dynamic value) {
    if (value == null) return null;
    
    // Si c'est déjà une liste
    if (value is List) {
      return value.map((e) => e is int ? e : int.tryParse(e.toString())).whereType<int>().toList();
    }
    
    // Si c'est une chaîne (depuis STRING_AGG), la parser
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        return value.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
}

