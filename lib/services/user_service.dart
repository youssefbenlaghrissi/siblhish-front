import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // Obtenir le profil utilisateur
  static Future<User> getProfile(String userId) async {
    try {
      final response = await ApiService.get('/users/$userId/profile');
      if (response['status'] != 'success') {
        throw Exception('API returned error: ${response['message']}');
      }
      final data = response['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le profil
  static Future<User> updateProfile(
      String userId, Map<String, dynamic> updateData) async {
    final response = await ApiService.put('/users/$userId/profile', updateData);
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  // Changer le mot de passe
  static Future<void> changePassword(
      String userId, String oldPassword, String newPassword) async {
    await ApiService.put('/users/$userId/password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}

