import '../config/api_config.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  // Obtenir les notifications d'un utilisateur (toutes les notifications non supprimées, sans pagination)
  static Future<List<Notification>> getNotifications(String userId) async {
    final response = await ApiService.get('/notifications/$userId');
    final data = response['data'] as List<dynamic>;
    
    return data.map((json) => Notification.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Obtenir le nombre de notifications non lues
  static Future<int> getUnreadCount(String userId) async {
    final response = await ApiService.get('/notifications/$userId/unread-count');
    final data = response['data'] as Map<String, dynamic>;
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  // Marquer une notification comme lue
  static Future<Notification> markAsRead(String notificationId) async {
    final response = await ApiService.patch('/notifications/$notificationId/read', {});
    final data = response['data'] as Map<String, dynamic>;
    return Notification.fromJson(data);
  }

  // Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead(String userId) async {
    await ApiService.patch('/notifications/$userId/read-all', {});
  }

  // Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    await ApiService.delete('/notifications/$notificationId');
  }
}

