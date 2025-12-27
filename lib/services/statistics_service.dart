import '../services/api_service.dart';
import '../models/statistics.dart';

class StatisticsService {
  // Note: Les préférences des cartes sont maintenant gérées par FavoriteService
  // Utiliser FavoriteService.getStatisticsCardsPreferences() et updateStatisticsCardsPreferences()

  // Endpoint unifié pour récupérer TOUTES les statistiques en une seule requête
  // Optimise les performances en réduisant les appels API de 6 à 1
  static Future<Statistics> getAllStatistics(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = <String, String>{
      'startDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
    };
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final response = await ApiService.get('/statistics/all-statistics/$userId?$queryString');
    final data = response['data'] as Map<String, dynamic>;
    return Statistics.fromJson(data);
  }
}

