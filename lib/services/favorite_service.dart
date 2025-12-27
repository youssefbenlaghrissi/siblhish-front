import '../config/api_config.dart';
import '../services/api_service.dart';
import '../models/card.dart';

class FavoriteService {
  /// Trouver tous les favoris d'un utilisateur par type
  /// Types disponibles : "CARD" (statistiques), "CATEGORY_COLOR" (profil)
  static Future<List<Map<String, dynamic>>> getFavoritesByType(
    String userId,
    String type,
  ) async {
    final response = await ApiService.get('/favorites/$userId/type/$type');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Ajouter des favoris sélectionnés
  /// favorites : Liste de Map avec 'type', 'targetEntity' (Long), et 'value' (String)
  static Future<List<Map<String, dynamic>>> addFavorites(
    String userId,
    List<Map<String, dynamic>> favorites,
  ) async {
    final response = await ApiService.post('/favorites/$userId', favorites);
    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Supprimer des favoris sélectionnés
  /// favorites : Liste de Map avec 'type' et 'targetEntity' (Long)
  static Future<void> deleteFavorites(
    String userId,
    List<Map<String, dynamic>> favorites,
  ) async {
    await ApiService.delete('/favorites/$userId', favorites);
  }

  // ===== Méthodes utilitaires pour les cartes statistiques =====

  /// Obtenir les IDs des cartes statistiques favorites (type: "CARD")
  /// Retourne une liste de String (IDs des cartes)
  static Future<List<String>> getStatisticsCardsPreferences(String userId) async {
    final favorites = await getFavoritesByType(userId, 'CARD');
    return favorites
        .map((f) => f['targetEntity'].toString())
        .toList();
  }

  /// Convertir un code de carte (ex: "bar_chart") en ID numérique (ex: "1")
  /// Utilise uniquement la liste dynamique des cartes depuis le backend
  static String _convertCardCodeToNumericId(String cardId, {required List<Card> availableCards}) {
    // Si c'est déjà un ID numérique, le retourner tel quel
    if (int.tryParse(cardId) != null) {
      return cardId;
    }
    
    // Utiliser uniquement la liste dynamique des cartes depuis le backend
    if (availableCards.isEmpty) {
      throw FormatException('Aucune carte disponible. Les cartes doivent être chargées depuis le backend.');
    }
    
    final card = availableCards.firstWhere(
      (c) => c.code == cardId,
      orElse: () => Card(id: -1, code: '', title: ''),
    );
    
    if (card.id <= 0) {
      throw FormatException('Code de carte invalide: $cardId. Carte non trouvée dans les cartes disponibles.');
    }
    
    return card.id.toString();
  }

  /// Mettre à jour les préférences des cartes statistiques
  /// L'ordre de sélection est préservé et stocké dans value ("1", "2", "3", etc.)
  /// L'ordre est libre : chaque carte reçoit sa position dans la liste sélectionnée
  /// Note: Les positions 1 et 2 ne sont réservées qu'à la première initialisation (création du compte)
  /// Après cela, l'utilisateur peut réordonner librement toutes les cartes
  /// 
  /// [existingFavorites] : Optionnel, pour éviter un appel API supplémentaire si déjà chargé
  /// [availableCards] : Requis, liste dynamique des cartes disponibles depuis l'API
  static Future<List<String>> updateStatisticsCardsPreferences(
    String userId,
    List<String> cardIds, {
    List<Map<String, dynamic>>? existingFavorites,
    required List<Card> availableCards,
  }) async {
    // Convertir tous les codes en IDs numériques
    final numericCardIds = cardIds.map((id) => _convertCardCodeToNumericId(id, availableCards: availableCards)).toList();
    
    // Récupérer les favoris existants pour déterminer quelles cartes sont nouvelles
    // Utiliser les favoris fournis si disponibles, sinon les charger
    final favoritesToUse = existingFavorites ?? await getFavoritesByType(userId, 'CARD');
    final existingCardIds = favoritesToUse
        .map((f) => f['targetEntity'].toString())
        .toSet();

    // Séparer les cartes à supprimer et les cartes à ajouter/mettre à jour
    final cardsToDelete = existingCardIds
        .where((id) => !numericCardIds.contains(id))
        .map((id) => {
          'type': 'CARD',
          'targetEntity': int.parse(id),
        })
        .toList();

    // Supprimer les cartes qui ne sont plus sélectionnées
    if (cardsToDelete.isNotEmpty) {
      await deleteFavorites(userId, cardsToDelete);
    }

    // Déterminer l'ordre de sélection
    // L'ordre est maintenant libre : chaque carte reçoit sa position dans la liste (1, 2, 3, ...)
    // Les positions 1 et 2 ne sont plus réservées après la première initialisation
    final newFavorites = <Map<String, dynamic>>[];
    
    for (int i = 0; i < numericCardIds.length; i++) {
      final cardId = numericCardIds[i];
      final cardIdInt = int.parse(cardId);
      
      // L'ordre est simplement la position dans la liste (commence à 1)
      final orderValue = (i + 1).toString();

      newFavorites.add({
        'type': 'CARD',
        'targetEntity': cardIdInt,
        'value': orderValue,
      });
    }

    // Ajouter/mettre à jour les favoris avec leur ordre
    // La réponse POST contient déjà les favoris mis à jour, on peut la retourner
    final updatedFavorites = await addFavorites(userId, newFavorites);
    
    // Retourner les IDs numériques pour cohérence
    return numericCardIds;
  }
  
  /// Mettre à jour les préférences et retourner les favoris complets mis à jour
  /// Retourne les favoris complets avec leur ordre pour éviter un appel GET supplémentaire
  /// [availableCards] : Requis, liste dynamique des cartes disponibles depuis l'API
  static Future<List<Map<String, dynamic>>> updateStatisticsCardsPreferencesWithFavorites(
    String userId,
    List<String> cardIds, {
    List<Map<String, dynamic>>? existingFavorites,
    required List<Card> availableCards,
  }) async {
    // Convertir tous les codes en IDs numériques
    final numericCardIds = cardIds.map((id) => _convertCardCodeToNumericId(id, availableCards: availableCards)).toList();
    
    // Récupérer les favoris existants pour déterminer quelles cartes sont nouvelles
    final favoritesToUse = existingFavorites ?? await getFavoritesByType(userId, 'CARD');
    final existingCardIds = favoritesToUse
        .map((f) => f['targetEntity'].toString())
        .toSet();

    // Séparer les cartes à supprimer
    final cardsToDelete = existingCardIds
        .where((id) => !numericCardIds.contains(id))
        .map((id) => {
          'type': 'CARD',
          'targetEntity': int.parse(id),
        })
        .toList();

    // Supprimer les cartes qui ne sont plus sélectionnées
    if (cardsToDelete.isNotEmpty) {
      await deleteFavorites(userId, cardsToDelete);
    }

    // Déterminer l'ordre de sélection
    // L'ordre est maintenant libre : chaque carte reçoit sa position dans la liste (1, 2, 3, ...)
    // Les positions 1 et 2 ne sont plus réservées après la première initialisation
    final newFavorites = <Map<String, dynamic>>[];
    
    for (int i = 0; i < numericCardIds.length; i++) {
      final cardId = numericCardIds[i];
      final cardIdInt = int.parse(cardId);
      
      // L'ordre est simplement la position dans la liste (commence à 1)
      final orderValue = (i + 1).toString();

      newFavorites.add({
        'type': 'CARD',
        'targetEntity': cardIdInt,
        'value': orderValue,
      });
    }

    // Ajouter/mettre à jour les favoris avec leur ordre
    // La réponse POST contient déjà les favoris mis à jour
    final updatedFavorites = await addFavorites(userId, newFavorites);
    return updatedFavorites;
  }

  // ===== Méthodes utilitaires pour les couleurs de catégories =====

  /// Obtenir toutes les couleurs personnalisées des catégories (type: "CATEGORY_COLOR")
  static Future<List<Map<String, dynamic>>> getCategoryColors(String userId) async {
    return getFavoritesByType(userId, 'CATEGORY_COLOR');
  }

  /// Obtenir la couleur personnalisée d'une catégorie spécifique
  static Future<String?> getCategoryColor(String userId, String categoryId) async {
    final favorites = await getCategoryColors(userId);
    final favorite = favorites.firstWhere(
      (f) => f['targetEntity'].toString() == categoryId,
      orElse: () => {},
    );
    return favorite['value'] as String?;
  }

  /// Mettre à jour la couleur personnalisée d'une catégorie
  static Future<Map<String, dynamic>> updateCategoryColor(
    String userId,
    String categoryId,
    String colorHex,
  ) async {
    final favorites = await addFavorites(
      userId,
      [
        {
          'type': 'CATEGORY_COLOR',
          'targetEntity': int.parse(categoryId),
          'value': colorHex,
        }
      ],
    );
    return favorites.first;
  }

  /// Supprimer la couleur personnalisée d'une catégorie
  static Future<void> deleteCategoryColor(String userId, String categoryId) async {
    await deleteFavorites(
      userId,
      [
        {
          'type': 'CATEGORY_COLOR',
          'targetEntity': int.parse(categoryId),
        }
      ],
    );
  }
}

