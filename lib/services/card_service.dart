import 'package:flutter/foundation.dart';
import '../models/card.dart';
import 'api_service.dart';

class CardService {
  /// Récupérer toutes les cartes disponibles depuis l'API
  static Future<List<Card>> getCards() async {
    try {
      final response = await ApiService.get('/cards');
      final data = response['data'] as List<dynamic>;
      return data
          .map((json) => Card.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement cartes: $e');
      rethrow;
    }
  }
}

